import re
import os
import argparse
from circling_py.worms import *

parser = argparse.ArgumentParser(description="Utility for dealing with ids and ecopcr results")

parser.add_argument('--string', metavar='<string>',
                    help='String used to search between files if taxids is requested')
parser.add_argument('--type', metavar="<string>",
                    default = "",
                    help='Type of file to deal with <synonyms,validate,ranks>')
parser.add_argument('--tax',
                    action = 'store_true',
                    help='''Actions: Validate names, Get synonyms, Ranks''')
parser.add_argument('--prefix', metavar='<string>',
                    action='store',
                    help='''Prefix string added at the beginning of output. The way how it is added may vary 
                    according to `--type` argument''')
parser.add_argument('--input', metavar="<string>",
                    default = "",
                    help='''Input  file or comma-separated string with taxonomic ranks to look for''')
args = parser.parse_args()

class Minbar:
    def __init__(self,
                 term="",
                 input=""):

        self.term = term
        self.input = input

    def validate_tax(self):
        #self = Minbar("Aega perualis")

        pattern1 = "^[A-Z][a-z]+ [a-z]+$"
        validated_name = Worms(self.term).get_accepted_name()

        if not re.findall(pattern1, validated_name):
            validated_name = Worms(self.term).taxamatch()

        if not re.findall(pattern1, validated_name):
            validated_name = "Check your taxon!"

        return validated_name

    def synonyms(self):
        #...self = Minbar("Scieane wieneri")...#
        # upon validating names, this name is used for getting
        # synonyms
        # self = Minbar("Scieane wieneri")
        #self = Minbar("Scieane wii")
        #self = Minbar("Mesoplodon densirostris")
        # self = Minbar("Lubbockia squillimana")
        #self = Minbar("Spondylus americanus")
        #self = Minbar("Aega perualis")

        valid = self.validate_tax()

        # if this name does not have any match with WoRMS database,
        # stop searching synonyms and return a single string as:
        if valid == "Check your taxon!":
            return [self.term + "," + valid]

        else:
            # however, if string is different to "Check your taxon!"
            # get synonyms.
            # Name is used for this purpose as this starts with
            # a validated name and aphiaID, needed for having synonyms_url,
            # is updated or created (e.i. when species name is miswritten)
            name = Worms(valid)


            # this is coupled with `worms.py`. Since synonyms are obtained
            # by starting with a validated_name, it could be put it directly
            # as accepted name:
            # name.accepted_name = valid
            # however, there are some species (e.g. Mesoplodon densirostris)
            # which accepted name (i.e. string) can also be unaccepted name
            # and in these cases are not worthless to redo name validation
            # (through `Worms(...).get_synonyms()`) and rely in aphia.IDs

            syns = name.get_synonyms()

            if len(syns) == 0:
                # if species is does not have any synonyms,
                # assess if this valid name is equal to self.term

                # if the following is true
                if self.term != valid:
                    # return that rare self.term in order to avoid it in
                    # another search. This was added because of some `Thais` cases
                    return [self.term + "," + valid, valid + "," + valid]

                else:

                    return [valid + "," + valid]

            else:
                ## joining valid and syns in a single list
                joined_list = []

                for syn in syns:
                    # print(syn + "," +valid)
                    joined_list.append(syn + "," + valid)

                joined_list.append(valid + "," + valid)

                return joined_list

    def ranks(self, string=""):

        spps = Worms(self.term)

        if len(spps.aphiaID) == 0 or spps.aphiaID == '-999':
            spps.get_accepted_name()

        if len(spps.aphiaID) == 0 or spps.aphiaID == '-999':
            spps.taxamatch()

        if len(spps.aphiaID) != 0 and spps.aphiaID != '-999':
            spps.get_taxonomic_ranges()

            return ",".join([spps.get_rank(i) for i in string.split(",")]) + "," + self.term

if args.tax is True and args.type == "validate":
    
    print(Minbar(term=str(args.string)).validate_tax())
    #print(Minbar(term="Anolis ventrimaculatus").validate_tax())

elif args.tax is True and args.type == "synonyms":
    lines = Minbar( term=str(args.string) ).synonyms()

    if args.prefix is None:
        for i in lines:
            print(i)

    else:
        for i in lines:
            print(args.prefix + "," + i)

elif args.tax is True and args.type == "ranks":

    whole_spps = open(str(args.input), "r").readlines()

    print( "%s,%s" % (str(args.prefix),"Species") )

    for i in whole_spps:

        Out = Minbar(term=i.replace("\n", "")).ranks(string=str(args.prefix))

        if Out is not None:
            print( Out )
