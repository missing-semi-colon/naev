--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Maikki's Father 2">
  <flags>
   <unique />
  </flags>
  <avail>
   <priority>4</priority>
   <chance>0</chance>
   <location>Bar</location>
   <planet>Minerva Station</planet>
   <done>Maikki's Father 1</done>
  </avail>
 </mission>
--]]

--[[
-- Maikki (Maisie McPherson) asks you to find her father, the famous pilot Kex
-- McPherson. She heard rumours he was still alive and at Minerva station.
-- Player found out that Za'lek doing stuff with the ship cargo.
--
-- 1. Told to try to find who could have been involved and given three places to look at.
-- Hint 1: Jorlas in Regas (University)
-- Hint 2: Cantina Station in Qulam (Trade Hub)
-- Hint 3: Jurai in Hideyoshi's Star (University)
-- 2. After talking to all three, the player is told to go to Naga in Damien (Underwater University)
-- 3. Mentions eccentric colleague at Westhaven
-- 4. Eccentric colleague makes the player mine some stupid stuff for him.
-- 5. Tells you he saved him and sent him off to "Minerva Station".
-- 6. Go back and report to Maikki confirming her info.
--
-- Eccentric Scientist in "Westhaven" (slightly senile with dementia).
--]]
local minerva = require "minerva"
local portrait = require 'portrait'
local vn = require 'vn'
require 'numstring'

maikki_name = minerva.maikki.name
maikki_description = minerva.maikki.description
maikki_portrait = minerva.maikki.portrait
maikki_image = minerva.maikki.image
maikki_colour = minerva.maikki.colour

hint1_name = _("Prof. Sato") -- Computer Science / Mathematics
hint1_description = _("You see a person in a fancy lab coat. It seems like they are enjoying their time off.")
hint1_portrait = "zalek1"
hint1_image = "zalek1.png"
hint1_colour = nil

hint2_name = _("Prof. Stova") -- Material Science
hint2_description = _("Foo")
hint2_portrait = "zalek1"
hint2_image = "zalek1.png"
hint2_colour = nil

hint3_name = _("Prof. Hsu") -- Philosophy
hint3_description = _("Foo")
hint3_portrait = "zalek1"
hint3_image = "zalek1.png"
hint3_colour = nil

hint4_name = _("Dr. Cayne") -- Dr. Shrimp
hint4_description = _("You see a young fellow intently reading a book. There seems to be a shrimp in a floating aquarium bowl floating around him.")
hint4_portrait = "drshrimp"
hint4_image = "drshrimp.png"
hint4_colour = nil

ecc_barname = _("Hologram Projector")
ecc_name = _("Dr. Strangelove")
ecc_description = _("There is a small hologram projector in the corner. It looks like you can use this to call someone.")
ecc_portrait = "zalek1"
ecc_image = "zalek1.png"
ecc_colour = nil

misn_title = _("Finding Father")
misn_reward = _("???")
misn_desc = _("Maikki wants you to help her find her father.")

hintpnt = {
   "Jorlan",
   "Cantina Station",
   "Jurai",
   "Naga",
}
hintsys = {}
for k,v in ipairs(hintpnt) do
   hintsys[k] = planet.get(v):system():nameRaw()
end
eccpnt = "Strangelove Lab"
eccdiff = "strangelove"
eccsys = "Westhaven"
eccpos = vec2.new( 7500, -6000 ) -- Should coincide with "Strangelove Lab"

-- Mission states:
--  nil: mission not yet accepted
--    0: Going to the three hints
--    1: Go to fourth hint
--    2: Go to westhaven
--    3: Found base
--    4: Mining stuff
--    5: Going back to Minerva Station
misn_state = nil


function create ()
   if not misn.claim( system.get(eccsys) ) then
      misn.finish( false )
   end
   misn.setNPC( maikki_name, maikki_portrait )
   misn.setDesc( maikki_description )
   misn.setReward( misn_reward )
   misn.setTitle( misn_title )
end


function accept ()
   approach_maikki()

   -- If not accepted, misn_state will still be nil
   if misn_state==nil then
      misn.finish(false)
      return
   end

   -- Set up mission stuff
   markerhint1 = misn.markerAdd( system.get(hintsys[1]), "low")
   markerhint2 = misn.markerAdd( system.get(hintsys[2]), "low")
   markerhint3 = misn.markerAdd( system.get(hintsys[3]), "low")
   hintosd()
   hook.land( "land" )
   hook.enter( "enter" )

   -- Re-add Maikki if accepted
   land()
end


function hintosd ()
   local osd = {
      _("Investigate the Za'lek"),
   }
   local function addhint( id )
      table.insert( osd, string.format(_("\tGo to %s in %s"), _(hintpnt[id]), _(hintsys[id])) )
   end

   if misn_state==0 then
      if not visitedhint1 then
         addhint(1)
      end
      if not visitedhint2 then
         addhint(2)
      end
      if not visitedhint3 then
         addhint(3)
      end
   elseif misn_state==1 then
      addhint(4)
   end

   misn.osdCreate( misn_title, osd )
end



function approach_maikki ()
   vn.clear()
   vn.scene()
   local maikki = vn.newCharacter( minerva.vn_maikki() )
   local function seekoutmsg ()
      maikki(string.format(_([["The three Za'lek researchers you should seek out are:
%s in the %s system,
%s in the %s system,
and %s in the %s system."]]),
         hint1_name, _(hintsys[1]),
         hint2_name, _(hintsys[2]),
         hint3_name, _(hintsys[3])
      ))
   end
   vn.fadein()

   vn.na(_("You approach Maikki who seems to have a fierce determination in her look."))
   if misn_state==nil then
      maikki(_([[She looks encouraged by your findings in the nebula.
"From what you told me, I think I have a good idea for our next lead. Would you be interested in helping again?"]]))
      vn.menu( {
         { _("Help Maikki again"), "accept" },
         { _("Decline to help"), "decline" },
      } )
      vn.label( "decline" )
      vn.na(_("You feel it is best to leave her alone for now and disappear into the crowds leaving her once again alone to her worries."))
      vn.done()

      vn.label( "accept" )
      vn.func( function ()
         misn_accept()
         misn_state = 0
      end )
      maikki(_([["I think we should be able to find out what happened to my father's ship in the nebula. It seems like someone is very interested on stuff that is being found in the nebula and is behind the scavengers you met. Whoever is behind them could also be related to whatever happened to the ship in the first place."]]))
      maikki(_([["I ran a check on Za'lek researchers that would likely be interested in stuff taken from the nebula and there seems to be less than I imagined. I was able to get a list of three researchers. I'll give you the details on them and you should pay them a visit to see if they know anything."]]))
      maikki(_([[She leans in close to you and looks into your eyes with fierce determination.
"You will do whatever it takes to find him right?"]]))
      vn.menu( {
         { _([["Yes!"]]), "doall" },
         { _([["Maybe..."]]), "dosome" },
         { _([["No"]]), "donone" },
      } )
      vn.label("doall")
      vn.func( function ()
         minerva.maikki_mood_mod( 1 )
      end )
      maikki(_([["You know the Za'lek can be very stubborn at times and may need some convincing."
She winks at you.]]))
      vn.jump("introcont")

      vn.label("dosome")
      maikki(_([["i thought that after your experience in the nebula you would understand how dangerous this can get."]]))
      vn.jump("introcont")

      vn.label("donone")
      vn.func( function ()
         minerva.maikki_mood_mod( -1 )
      end )
      maikki(_([[She glares at you.
"I hope you're joking. This is very important to me and I hope you don't lose this lead..."]]))
      vn.jump("introcont")

      vn.label("introcont")
      seekoutmsg()
      maikki(_([["Apparently the three researchers used to work together in some project about the nebula origins, but never really made anything public. I totally think that they must know something about this, the disappearance of my father was big news!"]]))
      maikki(_([[She looks at you expectantly.
"I will stay here and search for him more. Please pay those creepy Za'lek researchers a visit and see if you can find out what happened to my father!"]]))
   end

   local opts = {
      {_("Ask about the researchers"), "researchers"},
      {_("Ask about her father (Kex)"), "father"},
      {_("Leave"), "leave"},
   }
   -- TODO more options as more researchers are found
   vn.label( "menu" )
   vn.menu( opts )

   vn.label( "researchers" )
   maikki(_([["The researchers I told you about were involved in some sort of project trying to find out the origins of the incident by analyzing artifacts taken from the nebula. Most of it is classified so I wasn't able to get much information."]]))
   maikki(_([["Apparently the project was disbanded for some reason or other, and some members went missing. However, I was able to track down a few of them, but it wasn't too easy. They have some weird system called tenure that nobody understands and makes them move constantly from research laboratory to research laboratory. So droll!"]]))
   seekoutmsg()
   maikki(_([["I don't think it will be easy for you to get information from the Za'lek, they never give a straight answer and it's all "that is illogical" and "ma'am that beaker of acid is not a toy". So boring!"
She frowns and shakes her head to the sides.]]))
   -- TODO messages regarding each of the researchers
   vn.jump( "menu_msg" )

   vn.label( "father" )
   maikki(_([["I don't remember much about my father, most of what I know about him is stories from my late mother and stories told by pilots who knew him."]]))
   maikki(_([[Her eyes light up.
"Did you know that while scavenging near the incident, an asteroid hit his thrusters making them point the wrong way and he had to fly through five systems backwards through the nebula while chased by pirates? Sounds crazy!"]]))
   maikki(_([["He was also said to be the first pilot to chart the entire systems in the Nebula after the incident. Not even getting his leg crushed while recovering parts of the last emperor's flagship stopped him from going back and back to the nebula."]]))
   maikki(_([[Her eyes darken a little and her voice softens.
"His obsession with finding the truth did mean he was away from home most of the time and my mother was probably very lonely. She told me he never came to any of my birthdays..."]]))
   maikki(_([[Her eyes light up again.
"However, those were exceptional times. Most of the universe and our history as humans was lost! I would like to love to be able to meet him again and be able to ask all sorts of things."]]))
   maikki(_([["After you finding his ship in the nebula we have to get to the bottom of what happened! There is no way this was an accident, and I'm sure the Za'lek are involved in this. Since you didn't find a body, he has to be alive! We have to find out what happened and set things right!"
Her eyes sparkle with determination.]]))
   vn.jump( "menu_msg" )

   vn.label( "menu_msg" )
   maikki(_([["Is there anything you would like to know about?"]]))
   vn.jump( "menu" )

   vn.label( "leave" )
   vn.na(_("You take your leave to continue the search for her father."))
   vn.fadeout()
   vn.run()
end


function land ()
   if planet.cur() == planet.get("Minerva Station") then
      npc_maikki = misn.npcAdd( "approach_maikki", minerva.maikki.name, minerva.maikki.portrait, minerva.maikki.description )

   elseif planet.cur() == planet.get( hintpnt[1] ) then
      npc_hint1 = misn.npcAdd( "approach_hint1", hint1_name, hint1_portrait, hint1_description )

   elseif planet.cur() == planet.get( hintpnt[2] ) then
      npc_hint2 = misn.npcAdd( "approach_hint2", hint2_name, hint2_portrait, hint2_description )

   elseif planet.cur() == planet.get( hintpnt[3] ) then
      npc_hint3 = misn.npcAdd( "approach_hint3", hint3_name, hint3_portrait, hint3_description )

   elseif misn_state >= 1 and  planet.cur() == planet.get( hintpnt[4] ) then
      npc_hint4 = misn.npcAdd( "approach_hint4", hint4_name, hint4_portrait, hint4_description )

   elseif diff.isApplied(eccdiff) and planet.cur() == planet.get(eccpnt) then
      npc_ecc = misn.npcAdd( "approach_eccentric", ecc_barname, ecc_portrait, ecc_description )

   end
end


function visited ()
   if misn_state==0 and visitedhint1 and visitedhint2 and visitedhint3 then
      misn_state = 1
      markerhint4 = misn.markerAdd( system.get(hintsys[4]) )
   end
   hintosd()
end


function lasthint( prof )
   local visits = 0
   if visitedhint1 then
      visits = visits + 1
   end
   if visitedhint2 then
      visits = visits + 1
   end
   if visitedhint3 then
      visits = visits + 1
   end

   if visits > 2 then
      prof(string.format(_([["Oh, I suddenly remembered. There was also a post doctoral research working on the project by the name of Cayne. I think he was last working at %s in the %s system."]]), _(hintpnt[4]), _(hintsys[4])))
      vn.sfxBingo()
   end
end


function approach_hint1 ()
   vn.clear()
   vn.scene()
   local prof = vn.newCharacter( hint1_name, { image=hint1_image, color=hint1_colour } )
   vn.fadein()

   vn.na(_("You approach the professor."))
   prof(_([["Hello, how can I help you?"]]))
   vn.me(_("You inquire to about whether or not they are interested in artifacts from the nebula."))
   prof(_([["Very interesting, but I stopped working on that line of research several cycles ago. It was really a mess of a project. The project leader was pushing us very hard due to the other competition."]]))
   prof(_([["In the end, some papers results were falsified and the project leader was barred from doing research. That was too much for them and they took their own life. How illogical!"]]))
   prof(_([["If you are interested in the nebula research, you should go visit the museum of nebula artifacts. Although due to administrative changes, I don't think it'll open again for a few cycles."]]))
   prof(_([["Oh, you might have good luck talking to other members of the project. However, most of us have moved on from that traumatic experience and are now researching new topics."]]))
   prof(_([["Did I mention I have started working with infinitely meta-recursive hyper-tables? They are a fascinating type of data structure based on self-referencing Grassman manifold quasi-projections. They even implicitly handle non-convex elliptic reflections without any meta-heuristics!"
They are getting excited.]]))
   prof(_([["Although my grant has been rejected five times, the damn review board is still pushing the obsolete Riemann algebroid universal approximator theory and won't listen to anything else, they are definitely the future! I think they may even have a practical application!"
Their excitement grows.]]))
   vn.na(_("They don't seem like they will stop talking anytime soon... You take your leave as they start rambling in a trance-like state."))
   lasthint( prof )

   vn.fadeout()
   vn.run()

   if not visitedhint1 then
      visitedhint1 = tue
      misn.markerRm( markerhint1 )
      visited()
   end
end


function approach_hint2 ()
   vn.clear()
   vn.scene()
   local prof = vn.newCharacter( hint2_name, { image=hint2_image, color=hint2_colour } )
   vn.fadein()

   vn.na(_("You approach the professor."))
   prof(_([["What can I do for you?"]]))
   vn.me(_("You inquire to about whether or not they are interested in artifacts from the nebula."))
   prof(_([[He rubs his temples.
"Ah, the nebula artifacts... Not very good experiences with those, no, not really interested in them anymore."]]))
   prof(_([["I was part of a really ambitious project to try to track down the origin of the incident, which just end up being a bureaucratic nightmare."]]))
   prof(_([["You see, the bigger the research project, the more the project leader and co-leaders want to have meetings and goals and work packages."
He shudders when he says the word "work packages".]]))
   prof(_([["At the end, we were just chaining meetings and answering e-mails and not getting anything done. We ended up handing in a 5 page report written by an internal for the mid-project evaluation and almost lost all the funding. The project leader panicked and it all went to hell from there."]]))
   prof(_([["All nebula research is doomed to end that way. I haven't seen a project succeed yet despite all the proposal calls attempting to address the issue."]]))
   vn.na(_("You inquire about other project members."))
   prof(_([["The only logical step after that traumatic experience is to get as far away as possible fro nebula research. As far as I know all the project members moved to new topics, although none as exciting as mine."]]))
   prof(_([["Have you heard of graphene infused hydro nano lattices? By taking sheets of graphene and creating strong lateral strain under the effect of strong Coriolis electro-magnetic induction fields, it is possible to obtain a behaviour similar to turbulent hydrofoils. And what's even better is that they naturally form octahedral quasi-lattices that allow absorbing most low-spectrum frequencies!"]]))
   prof(_([["They could change material science as we know it! Image being able to create materials with almost any property you can desire! We do still have to solve the problem of the subatomic crystallite implosion, but once I finish recovering the notes from the crater left at my last laboratory, I should be able to solve it in no time. By the way, since the accident with my last assistant, I'm looking for a new one. Would you be interested?"]]))
   vn.na(_("You get away as fast as you can from them as they keep on rambling."))
   lasthint( prof )

   vn.fadeout()
   vn.run()

   if not visitedhint2 then
      visitedhint2 = true
      misn.markerRm( markerhint2 )
      visited()
   end
end


function approach_hint3 ()
   vn.clear()
   vn.scene()
   local drshrimp = vn.newCharacter( hint3_name, { image=hint3_image, color=hint3_colour } )
   vn.fadein()

   vn.na(_("You approach the professor."))
   prof(_([["Hello."]]))
   vn.me(_("You inquire to about whether or not they are interested in artifacts from the nebula."))
   prof(_([["Ah, such fond memories. I have never been interested in the artifacts from the nebula themselves, but I was part of a large project dealing with them on the philosophical and ethical committee."]]))
   prof(_([["Recently, due to the illogical imbalance between science and humanities, all large Za'lek projects are require to have at least a 10% of humanities members. This has given me lots of opportunities to work on many interesting projects."]]))
   prof(_([["Oh yes, on the nebula artifacts. I remember having fun conversations with our colleagues about whether or not the artifacts from the nebula actually do exist or not given that we are using imperfect sensorial organs to see, touch, and feel them. You see, given that we only perceive reality through our imperfect organs, can we actually know whether or not there is an absolute objective reality?"]]))
   prof(_([["It is a very fascinating topic. Since there is no way to prove the existence of an absolute reality, from a practical point of view, there are infinite relative realities, where everyone has their own. Everything else is an illusion derived from us projecting our understanding and reality onto the reality of others, deforming them to a way we can interpret them with our perfect minds."]]))
   vn.na(_("You inquire about the other members of the project."))
   prof(_([["Other members? I recall a few, but they liked me so much, they promoted me and gave me a windowless room in the basement. What an honour. Anyway, back to what I was saying."]]))
   prof(_([["We must also further question not only our sensorial organs, and the existence of nebula artifacts, but our own existence. We apparently are able to think and some would argue that by this, the only thing we can prove, given imperfect sensorial data, is our own existence. However, I argue that this too is an illusion, and that our existence itself is something we can't define."]]))
   prof(_([["Every instant, what we perceive as ourselves is ceasing to exist and a new existence, which while very close to the "ourselves" from the previous instance, is, arguably, a completely new existence. This fluidity makes it, not only impossible to perceive nor understand our self as it is, but also makes it impossible to draw a line between different individuals..."]]))
   vn.na(_("You thank him and run away while he keeps on talking to himself."))
   lasthint( prof )

   vn.fadeout()
   vn.run()

   if not visitedhint3 then
      visitedhint3 = true
      misn.markerRm( markerhint3 )
      visited()
   end
end


function approach_hint4 ()
   vn.clear()
   vn.scene()
   local drshrimp = vn.newCharacter( hint4_name, { image=hint4_image, color=hint4_colour } )
   local shrimp = vn.newCharacter( _("Floating Shrimp"), { color={0.4, 0.6, 1.0} } )
   vn.fadein()

   vn.na(_("You approach the young man who has POST-DOCTORAL RESEARCHER written on his lab coat. He seems to be really into a book titled 'SHRIMP: Anatomical studies of the Neo-neo-neocaridina species'."))
   drshrimp(_([["..."]]))
   vn.na(_("You wait to see if they notice your presence. While the young man reading the book hasn't, it does seem like the strange shrimp-like creature floating in an aquarium near them has. You feel like it's staring into your soul."))
   shrimp(_([[After what seems to be an eternity of a staring contest between you and the shrimp, you hear a loud beep and the shrimp's speaker begins to make a noise.
"PERSON. PERSON."]]))
   drshrimp(_([[The young man grumbles.
"I told you I already submitted my temporal research proposal clarification application yesterday."]]))
   drshrimp(_([[The young man suddenly breaks out of his reading stupor and looks at you as if you had appeared out of thin air.
"Wait, what? Who are you?"]]))
   shrimp(_([["PERSON. PERSON. PERSON."]]))
   drshrimp(_([["C'mon Calliope, I already know that. Here, have a pellet."]]))
   shrimp:rename("Calliope")
   shrimp(_([[A pellet of shrimp food releases into the floating aquarium. The shrimp wastes no time in getting scarfing it down.
"HAPPY. GOOD."]]))
   drshrimp(_([["What do you want"]]))
   vn.na(_("You explain to him that you are looking for information related to nebula artifacts."))
   drshrimp(_([["Ah, that hellish project. Was doomed from the start you know. The full-time professors and researchers let their egos get to their heads and it derails spectacularly. I'm glad it ended as it did, or I would be still stuck in that purgatory."]]))
   drshrimp(_([["I don't think most of the people remember me, but I was the one stuck doing most of the work. If you can call it that."]]))
   drshrimp:rename(_("Dr. Shrimp"))
   drshrimp(_([["My name is Cayne, but you can call me Dr. Shrimp. What would you like to know?"]]))

   vn.label("menu")
   vn.menu( function ()
      local opts = {
         {_([["Dr. Shrimp?"]]), "drshrimp" },
         {_("Ask about nebula artifacts"), "artifacts" },
         {_("Ask about other members."), "members" },
         {_("Leave"), "leave" },
      }
      if asked_drshrimp then
         table.insert( opts, 1, {_("Ask about Calliope"), "calliope"} )
      end
      if asked_strangelove then
         table.insert( opts, 1, {_("Ask about Dr. Strangelove"), "strangelove"} )
      elseif asked_members and asked_artifacts then
         table.insert( opts, 1, {_("Anything else?..."), "strangelove"} )
      end
      return opts end )

   vn.label("drshrimp")
   drshrimp(string.format(_([["After the nebula project, like most other researchers on the team, I got the hell away from nebula research. One day while visiting %s I found about fresh-water shrimp breeding and became enthralled. One thing led to another, and now I'm doing shrimp research."]]), _(hintpnt[4])))
   drshrimp(_([["You see, these shrimps are fascinating creatures. They have a really fast reproduction cycle, and reproduce in large numbers, allowing for simple genetic manipulation. While most are bred for colors and physical traits, some have also been trained for mental traits. Calliope here is an example of an extremely mentally capable shrimp."
He taps the tank of the floating shrimp next to him.]]))
   drshrimp(_([["The capability of these shrimp are endless, and they are helping us understand much more genetic modification than the brute-force approaches of the Soromid, although are technology is still lacking behind."]]))
   drshrimp(_([["And what's best, look how cute they are!"
He enthusiastically points towards Calliope.
"Isn't she the cutest?]]))
   drshrimp(_([["After focusing on shrimp for a few cycles, people started calling me Dr. Shrimp and the name stuck. Honestly, it's the best nickname they could give me. Makes me feel like getting my PhD was worth it!"]]))
   vn.func( function () asked_drshrimp = true end )
   vn.jump("menu_msg")

   vn.label("calliope")
   drshrimp(_([["Calliope was bred for her mental faculties. With her special floating aquarium she is able to articulate up to 20 unique words! It's incredible! Not only that, but we kept her good looks! Plus as a neo-neo-neocaridina, she is much larger than neo-neocaridinas."]]))
   shrimp(_([["FOOD. FOOD. FOOD."]]))
   drshrimp(_([["What would I do without her?"
He activates her food activation system and a pellet drops out.]]))
   shrimp(_([["HAPPY. HAPPY."]]))
   drshrimp(_([["She's the best shrimp we've been able to produce so far. She isn't capable of self-awareness yet, and tends to forget words if she isn't properly trained, but it is a start. By expanding their neural functionality we expect them to be compatible with neuro-implants eventually, and this will open up a whole set of new functionality, given that their reaction speed and neuro-motor ability is superb."]]))
   drshrimp(_([["I named her after a muse from some archaic religion I found while researching. She is the only thing that keeps me going during my 17th post doctoral fellowship."]]))
   vn.jump("menu_msg")

   vn.label("artifacts")
   drshrimp(_([["What sort of artifacts we were dealing with? All sorts. Pretty much anything we could get our hands on. We were trying to get a hold on stuff closer to the origin near Sol, but most of the time scavengers brought us stuff from the outer areas. Many times they even were trying to sell us random debris as nebula artifacts, but that's really easy to detect."]]))
   drshrimp(_([["You see, the nebula emits a specific type of radiation. We aren't too familiar with it, but it does alter the subatomic particles of space debris in nearly imperceptible ways. Our tools could detect the alterations easily."]]))
   drshrimp(_([["When the project failed, most of the artifacts were confiscated to hell who knows where, but I managed to keep a nut from what I think is a space station, but not entirely sure. It's a bit damaged beyond recognition."]]))
   drshrimp(_([["With the failure of most nebula project, I don't think there is anybody buying nebula artifacts anymore. Not much of a market for them, and most easy to access debris has all been scavenged away. Some collectors are still interested in that, but that's about it. Furthermore, it's not entirely legal if you catch my drift."]]))
   vn.func( function () asked_drshrimp = true end )
   vn.jump("menu_msg")

   vn.label("members")
   drshrimp(_([["Most of the project members were full professors, which is probably why it failed. Us post doctoral researchers do the work and get no credit."]]))
   drshrimp(_([["Many of the researchers lost their posts or went into hiding. The few I know that still are active are Prof. Stova, Prof. Sato, and Prof. Hsu. I think they even got some stupid promotion, while me and the other post docs lost our jobs."]]))
   drshrimp(_([["It's pretty incredible to think that there were originally 100ish people in the project. Yet even with all the people fired for falsification of results, not a single tenured post opened! It's ridiculous! If industry wasn't so horrible I would quit academia in an instance!"]]))
   drshrimp(_([["Now that I think of it, there was another guy. What was his name? I totally forget. Oh well."]]))
   vn.func( function () asked_drshrimp = true end )
   vn.jump("menu_msg")

   vn.label("strangelove")
   drshrimp(_([["Now I remember! There was a another post doctoral researcher who worked with me. He was a bit weird and kept obsessing with the nebula artifacts. Quite a few went missing during the project and I think it was probably him who was taking them."]]))
   drshrimp(_([["He went really upset when the project was cancelled, threw a big tantrum and all. He was locked in his office for days until they managed to coax him out. Nobody really did much as we were all busy dealing with all the paperwork of the project."]]))
   drshrimp(string.format(_([["Eventually he did get out and sort of disappeared. Last I heard, he said he was going to %s, which is a bit strange, because not only is there not a research center there, but there isn't even an inhabited planet nor station!"]]), _(eccsys)))
   drshrimp(_([["It's really weird but if you are really interested, I suppose you could try to take a look around there. The whole thing does give me the me the creeps."]]))
   vn.sfxEerie()
   vn.func( function ()
      asked_strangelove = true
      if misn_state==1 then
         misn_state = 2
         misn.markerRm( markerhint4 )
         misn.markerAdd( system.get(eccsys), "low" )
         misn.osdCreate( misn_title, {string.format(_("\tGo to %s"), _(eccsys))} )
      end
   end )
   vn.jump("menu_msg")

   vn.label("menu_msg")
   drshrimp(_([["Is there anything else you would like to know?"]]))
   vn.jump("menu")

   vn.label("leave")
   vn.na(_("You take your leave."))
   vn.fadeout()
   vn.run()
end


function enter ()
   if misn_state==2 and system.cur() == system.get(eccsys) then
      pilot.clear()
      pilot.toggleSpawn(false)
      hook.timer( 30000, "ecc_timer" )
   end
end


function ecc_timer ()
   player.msg(_("#pYour ship has detected a curious signal originating from inside the system.#0"))
   sysmarker = system.mrkAdd( _("Curious Signal"), eccpos )
   hook.timer( 500, "ecc_dist" )
end

function ecc_dist ()
   local pp = player.pilot()
   local dist = pp:pos():dist( eccpos )
   if dist < 3000 then
      system.mrkRm( sysmarker )
      local spawners = {
         "Za'lek Heavy Drone",
         "Za'lek Light Drone",
         "Za'lek Light Drone",
      }
      defense_systems = {}
      for k,v in ipairs(spawners) do
         local pos = eccpos + vec2.newP( rnd.rnd(0,100), rnd.rnd(0,359) )
         local p = pilot.addRaw( v, "zalek", pos, "Strangelove" )
         p:rename(_("Security Drone"))
         p:control()
         p:setHostile()
         p:attack( pp )
         hook.pilot( p, "death", "ecc_drone_dead" )
         table.insert( defense_systems, p )
      end
      defense_systems[1]:broadcast(_("UNAUTHORIZED VESSEL DETECTED. ELIMINATING."))
      return
   end
   hook.timer( 500, "ecc_dist" )
end


function ecc_drone_dead( p )
   for k,v in ipairs(defense_systems) do
      if v==p then
         table.remove( defense_systems, k )
         break
      end
   end

   -- All dead
   if #defense_systems==0 then
      hook.timer( 5000, "ecc_timer_dead" )
   end
end


function ecc_timer_dead ()
   player.msg(_("Your ships detect that one of the asteroids isn't what it seems..."))
   diff.apply( eccdiff )
   misn_state = 3
end


function approach_eccentric ()
   vn.clear()
   vn.scene()
   vn.fadein()
   local dr = vn.newCharacter( ecc_name, { image=ecc_image, color=ecc_colour } )

   if not ecc_visitedonce then
      vn.na(_("The hologram projector flickers as what appears to be a grumpy old man appears into view. He doesn't look very pleased to be disturbed."))
      dr(_([["How did you get in there? Who are you!"]]))
      ecc_visitedonce = true
   else
      vn.na(_("The hologram projector flickers and Dr. Strangelove comes into view. He doesn't look very happy to see you again."))
   end
   vn.label("menu_msg")
   dr(_([["What do you want?"]]))
   vn.label("menu")
   vn.menu({ function ()
      local opts = {
         {_("Ask about the nebula"), "nebula"},
         {_("Ask about this place"), "laboratory"},
         {_("Leave"), "leave"},
      }
      if misn_state==4 then
         table.insert( opts, 1, {_("Ask about job"), "job"} )
      end
      return opts
   end })

   vn.label("nebula")
   dr(_([[""]]))
   -- skip back to message if already accepted job
   vn.func( function () if misn_state>=4 then vn.jump("menu_msg") end end )
   vn.menu( {
      {_("Accept the job"), "jobaccept"},
      {_("Refuse the job"), "jobrefuse"},
   } )
   vn.label("jobrefuse")
   dr(_([["You don't scratch my back and I don't scratch yours."]]))
   vn.jump("menu_msg")

   vn.label("jobaccept")
   dr(_([[""]]))
   vn.func( function ()
      misn.osdCreate( misn_title, {"Obtain exotic minerals from the %s asteroid field",_(eccsys)} )
      misn_state = 4
   end )
   vn.jump("menu_msg")

   vn.label("job")
   dr(_([[""]]))
   vn.jump("menu_msg")

   vn.label("laboratory")
   dr(_([[""]]))
   vn.jump("menu_msg")

   vn.label("leave")
   vn.na(_("You turn off the hologram projector and Dr. Strangelove's image flickers and disappears."))
   vn.fadeout()
   vn.run()
end

