import re
import os
import argparse
from worms import *

parser = argparse.ArgumentParser(description="Utility for dealing with ids and ecopcr results")

parser.add_argument('-string', metavar='Term',
                    help='String used to search between files if taxids is requested')
parser.add_argument('-type', metavar="type",
                    default = "fasta",
                    help='Type of file to deal with <fasta, ecopcr, validate>. Default: fasta')
parser.add_argument('-sub',
                    action = 'store_true',
                    help='''Substitute species name on results if there were conflicting ids. This is due to 
                    species without taxids take ids of other species. Therefore this function restores this temporal
                    substitution''')
parser.add_argument('-tax',
                    action = 'store_true',
                    help='''Validate name''')
parser.add_argument('-input', metavar="file",
                    default = "",
                    help='''Input  file''')
args = parser.parse_args()

class Minbar:
    def __init__(self,
                 term="",
                 input=""):

        self.term = term
        self.input = input

    def select_id(self):
        """This function aids to get ids if a given term (i.e. taxon) by searching through
        either input file or intermediate directory
        """

        #self = Minbar(term="Ocenebra ingloria", input="concholepas")

        validated_name = Worms(self.term).get_accepted_name()

        if len(re.findall("[A-Z][a-z]+ [a-z]+", validated_name)) != 1:
            validated_name = Worms(self.term).taxamatch()

        if len(re.findall("[A-Z][a-z]+ [a-z]+", validated_name)) != 1:
            raise ValueError("Check your taxon!")

        lines = open(self.input, "r").readlines()

        target_string = []

        for i in lines:

            if len(re.findall(self.term + "; taxid=[0-9]+;", i)) == 1:

                target_string.append(re.sub(".*; taxid=([0-9]+);.*", "\\1", i))

        if len(set(target_string)) == 0:
            # replace point by path_ssp
            file_ids = [i for i in os.listdir("path_ssp/intermidiate_files") if re.findall("conflicting_ids",i)][0]

            conflicting_ids = open("path_ssp/intermidiate_files/" + file_ids, "r").readlines()

            target_string = [i.split(',')[0] for i in conflicting_ids if re.findall(self.term, i)]

        print("".join(set(target_string)).replace("\n", ""))

    def substitute(self):
        """This function substitutes species names randomly taken from `read_under_case_of_emergency` file
        by its real names. This is accomplished as changes are stored at an intermediate directory and it is
        restored from it
        """
        #self = Minbar(term="Ocenebra ingloria",
        #              input="Concholepas_concholepas2.ecopcr")

        path_to = "path_ssp/"

        file_ids = [i for i in os.listdir(path_to + "intermidiate_files/") if re.findall("conflicting_ids", i)][0]

        conflicting_ids = open(path_to + "intermidiate_files/" + file_ids, "r").readlines()

        ## WARNING: this input assume `-sub` and `-type ecopcr` flags are selected
        ecopcr_results = open(self.input, "r").readlines()

        names_in = []

        # get species name from conflicting_ids and also present
        # in ecopcr results
        for name in [i.split(",")[1] for i in conflicting_ids]:
            for line_results in ecopcr_results:
                # this only selects species name present on ecopcr results
                # and append it into `names_in` list
                if re.findall(name,line_results):
                    names_in.append(name)

        # only restore species which are present in
        # ecopcr results
        for to_replace in set(names_in):
            # search trough conflicting_ids again but this time
            # only with species stored at `names_in`
            for string in conflicting_ids:
                # it is searched because of this fake name (i.e. to_replace)
                # will aid to retrieve real names
                if re.findall(to_replace, string):
                    # using complete string shared between both fake and real name
                    # for extracting real names. New line metacharacter is deleted
                    # just for making sure, to_replace is redone it from string
                    # as fake_name too:
                    fake_name = string.split(",")[1]
                    real_name = string.split(",")[2].replace("\n", "")
                    # now this real name is used to get
                    # its family name as well as genus name
                    # through Worms class
                    real_obj = Worms(real_name)
                    # retrieving Family and Genus names
                    real_family= real_obj.get_rank("Family")
                    real_genus = real_obj.get_rank("Genus")
                    # enumerate rows where there were matches with ecopcr result
                    # by using fake names on it
                    for index,line_results in enumerate(ecopcr_results):
                        # get only matches between fake names and line_results
                        if re.findall(fake_name,line_results):
                            # Upon getting the match, entire string is used for
                            # substituting words (regex) with real_*.
                            # finally, index from enumerate function is used to
                            # store replacement onto the same line by indexing...
                            ecopcr_results[index] = re.sub(
                                "(.*)" + fake_name + "([ ]+\|[ ]+[0-9]+[ ]+\|[ ]+)[A-Za-z]+([ ]+\|[ ]+[0-9]+[ ]+\|[ ]+)[A-Za-z]+(.*)",
                                "\\1" + real_name + "\\2" + real_genus + "\\3" + real_family + "\\4", line_results
                            )
        return ecopcr_results

    def validate_tax(self):

        pattern1 = "^[A-Z][a-z]+ [a-z]+$"
        validated_name = Worms(self.term).get_accepted_name()

        if not re.findall(pattern1, validated_name):
            validated_name = Worms(self.term).taxamatch()

        if not re.findall(pattern1, validated_name):
            validated_name = "Check your taxon!"

        return validated_name

    def synonyms(self):

        name = Worms(self.term)

        valid = name.get_accepted_name()
        syns = name.get_synonyms()

        ## joining valid and syns in a single list
        joined_list = []

        for syn in syns:
            #print(syn + "," +valid)
            joined_list.append(syn + "," + valid)

        return joined_list

if args.sub is False and args.type == "fasta":

    Minbar(term=str(args.string),input=str(args.input)).select_id()

elif args.sub is True and args.type == "ecopcr":
    f = open("edited_" + str(args.input), "w")
    for i in Minbar(input=str(args.input)).substitute():
        f.write(i)
    f.close()

elif args.tax is True and args.type == "validate":
    print(Minbar(term=str(args.string)).validate_tax())
    #print(Minbar(term="Anolis ventrimaculatus").validate_tax())

elif args.tax is True and args.type == "synonyms":
    lines = Minbar( term=str(args.string) ).synonyms()
    
    for i in lines:
        print(i)

