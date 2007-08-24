

#include "toolkit.h"


#include "log.h"
#include "pause.h"
#include "opengl.h"


typedef enum {
	WIDGET_NULL,
	WIDGET_BUTTON,
	WIDGET_TEXT
} WidgetType;

typedef enum {
	WIDGET_STATUS_NORMAL,
	WIDGET_STATUS_MOUSEOVER,
	WIDGET_STATUS_MOUSEDOWN
} WidgetStatus;

typedef struct {
	char* name; /* widget's name */
	WidgetType type; /* type */

	double x,y; /* position */
	double w,h; /* dimensions */

	WidgetStatus status;

	union {
		struct { /* WIDGET_BUTTON */
			void (*fptr) (char*); /* callback */
			char *string; /* stored text */
		};
		struct { /* WIDGET_TEXT */
			glFont* font;
			glColour* colour;
		};
	};
} Widget;


typedef struct {
	unsigned int id; /* unique id */

	double x,y; /* position */
	double w,h; /* dimensions */

	Widget *widgets; /* widget storage */
	int nwidgets; /* total number of widgets */
} Window;


static unsigned int genwid = 0; /* generates unique window ids */


int toolkit = 0; /* toolkit in use */

#define MIN_WINDOWS	3
static Window *windows = NULL;
static int nwindows = 0;
static int mwindows = 0;

/*
 * prototypes
 */
static Widget* window_newWidget( const unsigned int wid );
static void widget_cleanup( Widget *widget );
/* render */
static void window_render( Window* w );
static void toolkit_renderButton( Widget* btn, double bx, double by );
static void toolkit_renderText( Widget* txt, double bx, double by );


/*
 * adds a button that when pressed will trigger call passing it's name as
 * only parameter
 */
void window_addButton( const unsigned int wid,
		const int x, const int y,
		const int w, const int h,
		char* name, char* display,
		void (*call) (char*) )
{
	Widget *wgt = window_newWidget(wid);

	wgt->type = WIDGET_BUTTON;
	wgt->name = strdup(name);
	wgt->string = strdup(display);

	/* set the properties */
	wgt->x = (double) x;
	wgt->y = (double) y;
	wgt->w = (double) w;
	wgt->h = (double) h;
	wgt->fptr = call;
}


void window_addText( const unsigned int wid,
		const int x, const int y,
		const int w, const int h,
		char* name, glFont* font, glColour* colour )
{
	Widget *wgt = window_newWidget(wid);

	wgt->type = WIDGET_TEXT;
	wgt->name = strdup(name); /* displays it's name */

	/* set the properties */
	wgt->x = (double) x;
	wgt->y = (double) y;
	wgt->w = (double) w;
	wgt->h = (double) h;
	wgt->font = font;
	wgt->colour = colour;
}


/*
 * returns pointer to a newly alloced Widget
 */
static Widget* window_newWidget( const unsigned int wid )
{
	int i;
	for (i=0; i<nwindows; i++)
		if (windows[i].id == wid)
			break;
	if (i == nwindows) return NULL;

	Widget* w = NULL;

	windows[i].widgets = realloc( windows[i].widgets,
			sizeof(Widget)*(++windows[i].nwidgets) );
	if (windows[i].widgets == NULL) WARN("Out of Memory");

	w = &windows[i].widgets[ windows[i].nwidgets - 1 ]; 

	w->type = WIDGET_NULL;
	w->status = WIDGET_STATUS_NORMAL;
	return w;
}


/*
 * creates a window
 */
unsigned int window_create( const int x, const int y, const int w, const int h )
{
	if (nwindows >= mwindows) { /* at memory limit */
		windows = realloc(windows, sizeof(Window)*(++mwindows));
		if (windows==NULL) WARN("Out of memory");
	}

	const int wid = (++genwid); /* unique id */

	windows[nwindows].id = wid;

	windows[nwindows].w = (double) w;
	windows[nwindows].h = (double) h;
	if ((x==-1) && (y==-1)) { /* center */
		windows[nwindows].x = gl_screen.w/2. - windows[nwindows].w/2.;
		windows[nwindows].y = gl_screen.h/2. - windows[nwindows].h/2.;
	}
	else {
		windows[nwindows].x = (double) x;
		windows[nwindows].y = (double) y;
	}

	windows[nwindows].widgets = NULL;
	windows[nwindows].nwidgets = 0;

	nwindows++;
	
	if (toolkit==0) { /* toolkit is on */
		SDL_ShowCursor(SDL_ENABLE);
		toolkit = 1; /* enable toolkit */
	}

	return wid;
}


/*
 * destroys a widget
 */
static void widget_cleanup( Widget *widget )
{
	if (widget->name) free(widget->name);

	if ((widget->type==WIDGET_TEXT) && widget->string)
		free(widget->string);
}


/* 
 * destroys a window
 */
void window_destroy( unsigned int wid )
{
	int i,j;

	/* destroy the window */
	for (i=0; i<nwindows; i++)
		if (windows[i].id == wid) {
			for (j=0; j<windows[i].nwidgets; j++)
				widget_cleanup(&windows[i].widgets[j]);
			free(windows[i].widgets);
			break;
		}
	
	/* move other windows down a layer */
	for ( ; i<(nwindows-1); i++)
		windows[i] = windows[i+1];

	nwindows--;
	if (nwindows==0) { /* no windows left */
		SDL_ShowCursor(SDL_DISABLE);
		toolkit = 0; /* disable toolkit */
		if (paused) unpause();
	}
}


/*
 * renders a window
 */
static void window_render( Window* w )
{
	int i;
	double x, y;
	glColour *lc, *c, *dc, *oc;

	/* position */
	x = w->x - (double)gl_screen.w/2.;
	y = w->y - (double)gl_screen.h/2.;

	/* colours */
	lc = &cGrey90;
	c = &cGrey70;
	dc = &cGrey50;
	oc = &cGrey30;

	/*
	 * window shaded bg
	 */
	/* main body */
	glShadeModel(GL_SMOOTH);
	glBegin(GL_QUADS);
		COLOUR(*dc);
		glVertex2d( x + 21.,        y            );
		glVertex2d( x + w->w - 21., y            );

		COLOUR(*c);
		glVertex2d( x + w->w - 21., y + 0.6*w->h );
		glVertex2d( x + 21.,        y + 0.6*w->h );

	glEnd(); /* GL_QUADS */
	glShadeModel(GL_FLAT);
	glBegin(GL_QUADS);
		COLOUR(*c);
		glVertex2d( x + 21.,        y + 0.6*w->h );
		glVertex2d( x + w->w - 21., y + 0.6*w->h );
		glVertex2d( x + w->w - 21., y + w->h     );
		glVertex2d( x + 21.,        y + w->h     );
	glEnd(); /* GL_QUADS */
	glShadeModel(GL_SMOOTH);
	/* left side */
	glBegin(GL_POLYGON);
		COLOUR(*c);
		glVertex2d( x + 21., y + 0.6*w->h ); /* center */
		COLOUR(*dc);
		glVertex2d( x + 21., y       );
		glVertex2d( x + 15., y + 1.  );
		glVertex2d( x + 10., y + 3.  );
		glVertex2d( x + 6.,  y + 6.  );
		glVertex2d( x + 3.,  y + 10. );
		glVertex2d( x + 1.,  y + 15. );
		glVertex2d( x,       y + 21. );
		COLOUR(*c);
		glVertex2d( x,       y + 0.6*w->h ); /* infront of center */
		glVertex2d( x,       y + w->h - 21. );
		glVertex2d( x + 1.,  y + w->h - 15. );
		glVertex2d( x + 3.,  y + w->h - 10. );
		glVertex2d( x + 6.,  y + w->h - 6.  );
		glVertex2d( x + 10., y + w->h - 3.  );
		glVertex2d( x + 15., y + w->h - 1.  );
		glVertex2d( x + 21., y + w->h       );
	glEnd(); /* GL_POLYGON */
	/* right side */
	glBegin(GL_POLYGON);
		COLOUR(*c);
		glVertex2d( x + w->w - 21., y + 0.6*w->h ); /* center */
		COLOUR(*dc);
		glVertex2d( x + w->w - 21., y       );
		glVertex2d( x + w->w - 15., y + 1.  );
		glVertex2d( x + w->w - 10., y + 3.  );
		glVertex2d( x + w->w - 6.,  y + 6.  );
		glVertex2d( x + w->w - 3.,  y + 10. );
		glVertex2d( x + w->w - 1.,  y + 15. );
		glVertex2d( x + w->w,       y + 21. );
		COLOUR(*c);
		glVertex2d( x + w->w,       y + 0.6*w->h ); /* infront of center */
		glVertex2d( x + w->w,       y + w->h - 21. );
		glVertex2d( x + w->w - 1.,  y + w->h - 15. );
		glVertex2d( x + w->w - 3.,  y + w->h - 10. );
		glVertex2d( x + w->w - 6.,  y + w->h - 6.  );
		glVertex2d( x + w->w - 10., y + w->h - 3.  );
		glVertex2d( x + w->w - 15., y + w->h - 1.  );
		glVertex2d( x + w->w - 21., y + w->h       );
	glEnd(); /* GL_POLYGON */


	/* 
	 * inner outline
	 */
	glShadeModel(GL_SMOOTH);
	glBegin(GL_LINE_LOOP);
		/* left side */
		COLOUR(*c);
		glVertex2d( x + 21., y       );
		glVertex2d( x + 15., y + 1.  ); 
		glVertex2d( x + 10., y + 3.  ); 
		glVertex2d( x + 6.,  y + 6.  ); 
		glVertex2d( x + 3.,  y + 10. ); 
		glVertex2d( x + 1.,  y + 15. ); 
		glVertex2d( x,       y + 21. ); 
		COLOUR(*lc);
		glVertex2d( x,       y + 0.6*w->h ); /* infront of center */
		glVertex2d( x,       y + w->h - 21. ); 
		glVertex2d( x + 1.,  y + w->h - 15. ); 
		glVertex2d( x + 3.,  y + w->h - 10. ); 
		glVertex2d( x + 6.,  y + w->h - 6.  ); 
		glVertex2d( x + 10., y + w->h - 3.  ); 
		glVertex2d( x + 15., y + w->h - 1.  ); 
		glVertex2d( x + 21., y + w->h       ); 
		/* switch to right via top */
		glVertex2d( x + w->w - 21., y + w->h       ); 
		glVertex2d( x + w->w - 15., y + w->h - 1.  ); 
		glVertex2d( x + w->w - 10., y + w->h - 3.  ); 
		glVertex2d( x + w->w - 6.,  y + w->h - 6.  ); 
		glVertex2d( x + w->w - 3.,  y + w->h - 10. ); 
		glVertex2d( x + w->w - 1.,  y + w->h - 15. ); 
		glVertex2d( x + w->w,       y + w->h - 21. ); 
		glVertex2d( x + w->w,       y + 0.6*w->h ); /* infront of center */ 
		COLOUR(*c);
		glVertex2d( x + w->w,       y + 21. ); 
		glVertex2d( x + w->w - 1.,  y + 15. ); 
		glVertex2d( x + w->w - 3.,  y + 10. ); 
		glVertex2d( x + w->w - 6.,  y + 6.  ); 
		glVertex2d( x + w->w - 10., y + 3.  ); 
		glVertex2d( x + w->w - 15., y + 1.  ); 
		glVertex2d( x + w->w - 21., y       ); 
		glVertex2d( x + 21., y       ); /* back to beginning */
	glEnd(); /* GL_LINE_LOOP */


	/*
	 * outter outline
	 */
	glShadeModel(GL_SMOOTH);
	glBegin(GL_LINE_LOOP);
		/* left side */
		COLOUR(*oc);
		glVertex2d( x + 21.-1., y-1.       );
		glVertex2d( x + 15.-1., y + 1.-1.  );
		glVertex2d( x + 10.-1., y + 3.-1.  );
		glVertex2d( x + 6.-1.,  y + 6.-1.  );
		glVertex2d( x + 3.-1.,  y + 10.-1. );
		glVertex2d( x + 1.-1.,  y + 15.-1. );
		glVertex2d( x-1.,       y + 21.-1. );
		glVertex2d( x-1.,       y + 0.6*w->h ); /* infront of center */
		glVertex2d( x-1.,       y + w->h - 21.+1. );
		glVertex2d( x + 1.-1.,  y + w->h - 15.+1. );
		glVertex2d( x + 3.-1.,  y + w->h - 10.+1. );
		glVertex2d( x + 6.-1.,  y + w->h - 6.+1.  );
		glVertex2d( x + 10.-1., y + w->h - 3.+1.  );
		glVertex2d( x + 15.-1., y + w->h - 1.+1.  );
		glVertex2d( x + 21.-1., y + w->h+1.       );
		/* switch to right via top */
		glVertex2d( x + w->w - 21.+1., y + w->h+1.       );
		glVertex2d( x + w->w - 15.+1., y + w->h - 1.+1.  );
		glVertex2d( x + w->w - 10.+1., y + w->h - 3.+1.  );
		glVertex2d( x + w->w - 6.+1.,  y + w->h - 6.+1.  );
		glVertex2d( x + w->w - 3.+1.,  y + w->h - 10.+1. );
		glVertex2d( x + w->w - 1.+1.,  y + w->h - 15.+1. );
		glVertex2d( x + w->w+1.,       y + w->h - 21.+1. );
		glVertex2d( x + w->w+1.,       y + 0.6*w->h ); /* infront of center */
		glVertex2d( x + w->w+1.,       y + 21.-1. );
		glVertex2d( x + w->w - 1.+1.,  y + 15.-1. );
		glVertex2d( x + w->w - 3.+1.,  y + 10.-1. );
		glVertex2d( x + w->w - 6.+1.,  y + 6.-1.  );
		glVertex2d( x + w->w - 10.+1., y + 3.-1.  );
		glVertex2d( x + w->w - 15.+1., y + 1.-1.  );
		glVertex2d( x + w->w - 21.+1., y-1.       );
		glVertex2d( x + 21.-1., y-1.       ); /* back to beginning */
	glEnd(); /* GL_LINE_LOOP */


	/*
	 * widgets
	 */
	for (i=0; i<w->nwidgets; i++) {

		switch (w->widgets[i].type) {
			case WIDGET_NULL: break;

			case WIDGET_BUTTON:
				toolkit_renderButton( &w->widgets[i], x, y );
				break;

			case WIDGET_TEXT:
				toolkit_renderText( &w->widgets[i], x, y );
				break;
		}
	}
}


static void toolkit_renderButton( Widget* btn, double bx, double by )
{
	glColour *c, *dc, *oc, *lc;
	double x, y;

	x = bx + btn->x;
	y = by + btn->y;

	/* set the colours */
	switch (btn->status) {
		case WIDGET_STATUS_NORMAL:
			lc = &cGrey80;
			c = &cGrey60;
			dc = &cGrey40;
			oc = &cGrey20;
			break;
		case WIDGET_STATUS_MOUSEOVER:
			lc = &cWhite;
			c = &cGrey80;
			dc = &cGrey60;
			oc = &cGrey40;
			break;
		case WIDGET_STATUS_MOUSEDOWN:
			lc = &cGreen;
			c = &cGreen;
			dc = &cGrey40;
			oc = &cGrey20;
			break;
	}  


	/*
	 * shaded base
	 */
	glShadeModel(GL_SMOOTH);
	glBegin(GL_QUADS);

		COLOUR(*dc);
		glVertex2d( x,				y              );
		glVertex2d( x + btn->w,	y              );

		COLOUR(*c);
		glVertex2d( x + btn->w, y + 0.6*btn->h );
		glVertex2d( x,				y + 0.6*btn->h );

	glEnd(); /* GL_QUADS */

	glShadeModel(GL_FLAT);
	glBegin(GL_QUADS);
		COLOUR(*c);
		
		glVertex2d( x,          y + 0.6*btn->h );
		glVertex2d( x + btn->w, y + 0.6*btn->h );
		glVertex2d( x + btn->w, y + btn->h     );
		glVertex2d( x,          y + btn->h     );

	glEnd(); /* GL_QUADS */


	/*
	 * inner outline
	 */
	glShadeModel(GL_SMOOTH);
	/* left */
	glBegin(GL_LINES);
		COLOUR(*c);
		glVertex2d( x,          y          );
		COLOUR(*lc);
		glVertex2d( x,          y + btn->h );
	glEnd(); /* GL_LINES */
	/* right */
	glBegin(GL_LINES);
		COLOUR(*c);
		glVertex2d( x + btn->w, y          );
		COLOUR(*lc);
		glVertex2d( x + btn->w, y + btn->h );
	glEnd(); /* GL_LINES */

	glShadeModel(GL_FLAT);
	/* bottom */
	glBegin(GL_LINES);
		COLOUR(*c);
		glVertex2d( x,          y          );
		glVertex2d( x + btn->w, y          );
	glEnd(); /* GL_LINES */
	/* top */
	glBegin(GL_LINES);
		COLOUR(*lc);
		glVertex2d( x,          y + btn->h );
		glVertex2d( x + btn->w, y + btn->h );
	glEnd(); /* GL_LINES */


	/*
	 * outter outline
	 */
	glBegin(GL_LINE_LOOP);
		COLOUR(cBlack);
		/* left */
		glVertex2d( x - 1.,          y               );
		glVertex2d( x - 1.,          y + btn->h      );
		/* top */
		glVertex2d( x,               y + btn->h + 1. );
		glVertex2d( x + btn->w,      y + btn->h + 1. );
		/* right */
		glVertex2d( x + btn->w + 1., y + btn->h      );
		glVertex2d( x + btn->w + 1., y               );
		/* bottom */
		glVertex2d( x + btn->w,      y - 1.          );
		glVertex2d( x,               y - 1.          );
	glEnd(); /* GL_LINE_LOOP */


	gl_printMid( NULL, (int)btn->w,
			bx + (double)gl_screen.w/2. + btn->x,
			by + (double)gl_screen.h/2. + btn->y + (btn->h - gl_defFont.h)/2.,
			&cRed, btn->string );
}
static void toolkit_renderText( Widget* txt, double bx, double by )
{
	gl_printMax( txt->font, txt->w,
			bx + (double)gl_screen.w/2. + txt->x,
			by + (double)gl_screen.h/2. + txt->y,
			txt->colour, txt->name );
}


/*
 * renders the windows
 */
void toolkit_render (void)
{
	int i;

	if (gl_has(OPENGL_AA_LINE)) glEnable(GL_LINE_SMOOTH);
	if (gl_has(OPENGL_AA_POLYGON)) glEnable(GL_POLYGON_SMOOTH);

	for (i=0; i<nwindows; i++)
		window_render(&windows[i]);
	
	if (gl_has(OPENGL_AA_LINE)) glDisable(GL_LINE_SMOOTH);
	if (gl_has(OPENGL_AA_POLYGON)) glDisable(GL_POLYGON_SMOOTH);
}


/*
 * input
 */
static int mouse_down = 0;
void toolkit_mouseEvent( SDL_Event* event )
{
	int i;
	double x, y;
	Window *w;
	Widget *wgt;

	/* set mouse button status */
	if (event->type==SDL_MOUSEBUTTONDOWN) mouse_down = 1;
	else if (event->type==SDL_MOUSEBUTTONUP) mouse_down = 0;
	/* ignore movements if mouse is down */
	else if ((event->type==SDL_MOUSEMOTION) && mouse_down) return;

	/* absolute positions */
	if (event->type==SDL_MOUSEMOTION) {
		x = (double)event->motion.x;
		y = gl_screen.h - (double)event->motion.y;
	}
	else if ((event->type==SDL_MOUSEBUTTONDOWN) || (event->type==SDL_MOUSEBUTTONUP)) {
		x = (double)event->button.x;
		y = gl_screen.h - (double)event->button.y;
	}

	w = &windows[nwindows-1];

	if ((x < w->x) || (x > (w->x + w->w)) || (y < w->y) || (y > (w->y + w->h)))
		return; /* not in current window */

	/* relative positions */
	x -= w->x;
	y -= w->y;

	for (i=0; i<w->nwidgets; i++) {
		wgt = &w->widgets[i];
		if ((x > wgt->x) && (x < (wgt->x + wgt->w)) &&
				(y > wgt->y) && (y < (wgt->y + wgt->h)))
			switch (event->type) {
				case SDL_MOUSEMOTION:
					wgt->status = WIDGET_STATUS_MOUSEOVER;
					break;

				case SDL_MOUSEBUTTONDOWN:
					wgt->status = WIDGET_STATUS_MOUSEDOWN;
					break;

				case SDL_MOUSEBUTTONUP:
					if (wgt->status==WIDGET_STATUS_MOUSEDOWN) {
						if (wgt->type==WIDGET_BUTTON) (*wgt->fptr)(wgt->name);
					}
					wgt->status = WIDGET_STATUS_NORMAL;
					break;
			}
		else
			wgt->status = WIDGET_STATUS_NORMAL;
	}
}


/*
 * initializes the toolkit
 */
int toolkit_init (void)
{
	windows = malloc(sizeof(Window)*MIN_WINDOWS);
	nwindows = 0;
	mwindows = MIN_WINDOWS;
	SDL_ShowCursor(SDL_DISABLE);

	return 0;
}


/*
 * exits the toolkit
 */
void toolkit_exit (void)
{
	int i;
	for (i=0; i<nwindows; i++)
		window_destroy(windows[i].id);
	free(windows);
}

