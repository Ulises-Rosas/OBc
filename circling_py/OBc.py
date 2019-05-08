#!/usr/bin/env python3

import re
import os

class OBc:

    def joinFiles(self, directory, group, pattern, header):

        checkLine = lambda d, s: re.findall( "^[A-Z][a-z]+ [a-z]+[,]{0,}", open(d + s, 'r').readline() ).__len__() > 0
        ncol      = lambda d, s: re.findall( ",", open(d + s).readline() ).__len__() + 1
        nfile     = 1


        if group is None:

            groupers = [None] * len(directory)

        elif len(group) == 1:

            groupers = group * len(directory)

        elif len(group) > 1:

            if len(group) != len(directory):

                print("\033[0;31m\nError: Different length of entries between --from and --as args\033[0m")
                exit()
            else:

                groupers = group

        out = []

        for dir,grp in zip(directory,groupers):

            if dir[-1] != "/":
                dir += "/"

            selected_files = [i for i in os.listdir(dir) if re.findall(pattern, i)]

            if selected_files.__len__() > 0:

                for sf in selected_files:

                    try:
                        evalFile = checkLine(dir, sf)

                    except UnicodeDecodeError:
                        evalFile = False

                    if evalFile:

                        metadata = sf.split("_")

                        if nfile == 1 and header:

                            if ncol(dir, sf) == 3:

                                out.append("valida_name,synonyms,availability,region,subgroup,group")

                            elif ncol(dir, sf) == 1:

                                out.append("species,region,subgroup,group")

                            nfile += 1

                        for line in open(dir + sf).readlines():
                            out.append("%s,%s,%s,%s" % (line.replace("\n", ""),
                                                        metadata[0],
                                                        metadata[2],
                                                        metadata[2] if grp is None else grp))

        return out
