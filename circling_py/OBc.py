#!/usr/bin/env python3

import re
import os

class OBc:

    def __init__(self):

        self.obis_header = ["valid_name,region,subgroup,group"]
        self.bold_header = ["valid_name,synonyms,availability,region,subgroup,group"]

    def __subset__(self, df, key):

        return [i for i in df if re.compile(".*,%s$" % key).match(i) ]

    def __checkPos__(self, head,vars):

        colPos = lambda h, p: [x for x, y in enumerate(h.split(",")) if re.findall(p, y)]

        var_pattern = "(" + "|".join(["^%s$" % i for i in vars]) + ")"

        pos = colPos(head, var_pattern)

        if len(pos) == 0:
            print("\033[0;31m\nError: Column names do not match\033[0m")
            exit()

        return pos

    def __groupBy_key__(self, df, vars):
        """
        structures:
        vars = ["group", "region"]
        df   = ["valid_name,region,subgroup,group", ...]
        """

        df2   = df[1::]
        head  = df[0]
        pos   = self.__checkPos__(head, vars)


        out = []

        for ln in df2:

            seli = []

            for ps in pos:

                seli.append( ln.split(",")[ps] )

            out.append( "%s,%s" % (ln , "-".join(seli)) )

        return [ "%s,%s" % (head, "key") ] + out

    def count(self, df, vars):
        """
        structures:
        vars = ["group", "region"]
        df   = ["valid_name,region,subgroup,group", ...]
        """
        c_match = lambda d, k: [ i for i in d if re.compile( ".*,%s$" % k ).match(i) ].__len__()

        newdf   = self.__groupBy_key__(df, vars)
        toCount = set( [i.split(",")[-1] for i in newdf[1::]] )

        out = []

        for i in toCount:
            out.append(
                "%s,%s" % (i.replace("-", ","), c_match(newdf, i))
            )

        return [",".join( vars + ["n"] )] +  out

    def summarise(self, df, vars):
        """
        structures:
        vars = ["group", "region"]
        df   = ["valid_name,region,subgroup,group", ...]
        """
        pos = self.__checkPos__(df[0], vars)

        Select = lambda t: ",".join([t[0].split(",")[ps] for ps in t[1]])

        s_head = Select( (df[0], pos) )

        s_data = list(
                    set(
                        map(
                            Select, [(i, pos) for i in df[1::]]
                            )
                        )
                    )

        return [s_head] + s_data

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

                                out.append("valid_name,synonyms,availability,region,subgroup,group")

                            elif ncol(dir, sf) == 1:

                                out.append("valid_name,region,subgroup,group")

                            nfile += 1

                        for line in open(dir + sf).readlines():
                            out.append("%s,%s,%s,%s" % (line.replace("\n", ""),
                                                        metadata[0],
                                                        metadata[2],
                                                        metadata[2] if grp is None else grp))

        return out

    def readWithHeader(self, file):

        withHeader = lambda f: re.findall(",region,subgroup,group", open(f, 'r').readline()).__len__() == 1
        ncol       = lambda f: re.findall(",", open(f, 'r').readline() ).__len__() + 1


        if not withHeader(file):

            if ncol(file) == 4:

                return self.obis_header + open(file, 'r').read().splitlines()
                # return {"obis": self.obis_header + open(file, 'r').read().splitlines()}

            elif ncol(file) == 6:

                return self.bold_header + open(file, 'r').read().splitlines()
                # return {"bold": self.bold_header + open(file, 'r').read().splitlines()}

            else:
                print("\033[0;31m\nError: unexpected number of columns in CSV\033[0m")
                exit()
        else:
            return open(file, 'r').read().splitlines()

            # tmp_val = open(file, 'r').read().splitlines()
            # return {"bold":tmp_val} if re.findall("synonyms", tmp_val[0]) else {"obis":tmp_val}

    def BarPlotData(self, file, vars, fill, prop):
        """
        :param file: ["valid_name,region,subgroup,group", ...]
        :param vars: "group"
        :param fill: "region"
        :return:     ['group,region,n', ...]
        """
        cols = ["valid_name", vars, fill]

        df = self.count(
                self.summarise(
                    self.readWithHeader(file), cols ), cols[1::] )

        if prop:

            df0 = self.__groupBy_key__(df, [vars])

            keys = set([i.split(",")[-1] for i in df0[1::]])
            # {'Peru', 'Colombia', 'Chile', 'Ecuador'}

            out = []

            for k in keys:
                # k = list(keys)[0]

                tmp_df = self.__subset__(df0[1::], k)
                # ['Peru,Echinodermata,31,Peru', ...]

                WS = sum([int(i.split(",")[-2]) for i in tmp_df])

                for ln in tmp_df:

                    lns = ln.split(",")

                    tmp_l = "%s,%s" % ( ",".join(lns[:-2]), round( int( lns[-2] ) / WS, 3) )
                    # 'Ecuador,Cnidaria,0.134'

                    out.append(tmp_l)

            df = [df[0]] + out

        return df