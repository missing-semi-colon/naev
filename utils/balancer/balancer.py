#!/usr/bin/python

import argparse
import csv
import glob
import xml.etree.ElementTree as ET


class Balancer:

    def __xml2dict( self ):
        return [], {}

    def __dict2xml( self, data ):
        pass

    def __write_tree( self, tree, ofile ):
        # save the file
        tree.write( ofile, encoding="UTF-8", xml_declaration=True )
        # With python 3.9 the line below should work and make everything pretty ;)
        #ET.indent(tree).write( ofile, encoding="UTF-8", xml_declaration=True )


    def xml2csv( self, csvfile ):
        fields, data = self.__xml2dict()

        # save the outfit data
        with open(csvfile,'w') as f:
            w = csv.DictWriter( f, fieldnames=fields, quotechar='"', quoting=csv.QUOTE_ALL )
            w.writeheader()
            for n,d in data.items():
                w.writerow(d)

    def csv2xml( self, csvfile ):
        # load the outfit data
        data = {}
        with open(csvfile,'r') as f:
            r = csv.DictReader( f, quotechar='"' )
            for row in r:
                data[ row['name'] ] = row

        self.__dict2xml( data )


class OutfitBalancer(Balancer):

    def __xml2dict(self):
        # parse the xml files
        fields  = set()
        outfits = {}
        for ofile in glob.glob('dat/outfits/**/*.xml'):
            print(ofile)
            root = ET.parse( ofile ).getroot()

            oname = root.get('name')
            o = {'name':oname}

            # only getting general stuff for now
            for tag in root.find('general'):
                o[tag.tag] = tag.text
                fields.update( [tag.tag] )
            outfits[oname] = o

        fields = list(fields)
        fields.sort()
        fields.insert(0,'name')

        return fields, outfits

    def __dict2xml( self, outfits ):

        for ofile in glob.glob('dat/outfits/**/*.xml'):
            tree = ET.parse( ofile )
            root = tree.getroot()
            oname = root.get('name')
            general = root.find('general')
            for key,val in outfits[oname].items():
                # skip name and empty cells
                if key=='name' or val=='':
                    continue
                tags = general.findall(key)
                if len(tags) > 1:
                    print(f"Found duplicate tag '{key}' in '{oname}'. Removing!")
                    for i in range(1,len(tags)):
                        general.remove( tags[i] )
                tag = general.find(key)
                if tag==None:
                    # have to add new tag
                    new_tag = ET.SubElement(general,key)
                    new_tag.text = val
                else:
                    # update existing value
                    tag.text = val
            # save the file
            self.__write_tree( tree, ofile )


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Tool to save Naev xml file data to an csv file and viceversa.')
    parser.add_argument('mode', choices=['w','r'], help="Either 'r' to read from the xml or 'w' to write to the xml.")
    parser.add_argument('filename', type=str, help="CSV file to either read from or write to.")
    args = parser.parse_args()

    balancer = OutfitBalancer()
    if args.mode=='w':
        print( 'Writing to XML files from %s!' % args.filename )
        balancer.csv2xml( args.filename )
    else:
        print( 'Reading from XML files to %s!' % args.filename )
        balancer.xml2csv( args.filename )


