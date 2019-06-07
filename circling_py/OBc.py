#!/usr/bin/env python3

import re
import os
import itertools
import collections
import uuid

class OBc:

    def __init__(self):

        self.obis_header = ["valid_name,region,subgroup,group"]
        self.bold_header = ["valid_name,synonyms,availability,region,subgroup,group"]

    def __subset__(self, df, key, inv = False):

        compa = re.compile(".*,%s$" % key)

        if inv:

            return [i for i in df if not compa.match(i)]
        else:

            return [i for i in df if compa.match(i)]

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
        WARNING: keys are always ordered in function of their positions in header
        structures:
        vars = ["group", "region"]
        df   = ["valid_name,region,subgroup,group", ...]
        """
        # TODO: working with tuples/dict instead of plain strings

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

    def oneColSubset(self, df, col, key, inv = False):
        """
        Subset a list by a string which in turn is used within
        regex search. It can also be used with regular patterns
        :param df:  ["valid_name,region,subgroup,group", ...]
        :param col: ["group"]
        :param key: "Invertebrate"
        :return: ["valid_name,region,subgroup,group", ...(Invertebrate), ]
        """

        df_k = self.__groupBy_key__(df, col)

        dat = [i for i in self.__subset__(df_k[1:], key, inv=inv)]

        return [','.join(i.split(',')[:-1]) for i in [df_k[0]] + dat ]

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
        ## class calling
        # file = "data/invertebrate_bold.txt"
        # vars = 'region'
        # fill = "subgroup"
        # prop = True
        # self  = OBc()
        ##

        cols = ["valid_name", vars, fill]

        df = self.count(
                self.summarise(
                    self.readWithHeader(file), cols ), cols[1::] )

        if prop:

            df0  = self.__groupBy_key__(df, [vars])

            keys = set([i.split(",")[-1] for i in df0[1::]])
            # {'Peru', 'Colombia', 'Chile', 'Ecuador'}
            out  = []

            for k in keys:
                # k = list(keys)[1]
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

    def getOrderedGroups(self, df, group, by, withN = True , rev = True):
        """
        :param df: list
        :param group: list
        :param by: list
        :param withN: boolean
        :return: (x,n) or (x)
        """
        tItems = lambda csv: (csv.split(",")[0], int(csv.split(",")[1]))
        vals   = self.count(self.summarise(df, ['valid_name'] + group), group)[1:]

        if by is not None:
            out = []
            for i in by:
                for ii in vals:
                    if re.findall("^%s," % i, ii):
                        out.append(ii)
            sPairs = list(map(tItems, out))

        else:
            sPairs = sorted(map(tItems, vals), key = lambda kv: kv[1], reverse = rev)

        return sPairs if withN else [k[0] for k in sPairs]

    def UpsetData(self, file, group, block, line, sep = True):
        """
        :param file: "data/bold.csv"
        :param group: "group"
        :param order: ['Mammalia', 'Elasmobranchii', ...]
        :param lines: ['Colombia', 'Ecuador', ...]
        :return:
        """

        group = [group]

        ## class calling
        # file = "data/bold.csv"
        # block = None
        # line = ['Colombia', 'Ecuador']
        # group = ["group"]
        # self  = OBc()
        ##

        def orderByNspps(lilist):

            formater = lambda l: "%s%s,%.7f,%s" % tuple(l[:])

            tmp_order = sorted(lilist, key=lambda l: l[3], reverse=True)

            return list(map(formater, tmp_order))

        regexPair     = lambda iter: "(" + "|".join(iter) + ")"
        howManyRegion = lambda regex: re.findall("\|", regex).__len__() + 1
        uniqC         = lambda p, l: collections.Counter([i.split(',')[p] for i in l])
        matchCounts   = lambda n, d: [k for k, v in d.items() if v == n].__len__()
        getPos        = lambda p, d: set([i.split(',')[p] for i in d])
        subtract      = lambda d1, d2, p: len(getPos(p, d1) - getPos(p,d2))

        df = self.readWithHeader(file)

        regionGroup = self.summarise( df, ['valid_name', 'region'] + group )
        toCombine   = self.summarise( df, ["region"] )[1:] if line is None else line
        majorGroups = self.getOrderedGroups( regionGroup, group, by = block )

        Wout = []
        line = 1

        for z,n in majorGroups:
            # print(z,n)
            # z = "Invertebrates"
            # n = 1196
            dfZeta = self.oneColSubset(regionGroup, group, z)

            oneOut   = []
            groupOut = []

            for c in range(0, toCombine.__len__()):
                # print(c)
                # c = 1
                for pat in map( regexPair, itertools.combinations( toCombine, c + 1) ):
                    # print(pat)
                    # pat = "(Ecuador|Chile)"
                    nRegion = howManyRegion(pat)
                    # print(nRegion)
                    tmp_list = self.oneColSubset(dfZeta, ['region'], pat)
                    pos      = self.__checkPos__(tmp_list[0], ['valid_name'])[0]
                    # [print(i) for i in tmp_list]
                    if nRegion > 1:

                        nspps = matchCounts(nRegion, uniqC(pos, tmp_list[1:]))
                        groupOut.append( [z, pat, nspps*100/n, nspps] )
                    else:

                        notTmp_list = self.oneColSubset(dfZeta, ['region'], pat, inv=True)
                        nspps       = subtract(tmp_list[1:], notTmp_list[1:], pos )

                        pat += "<%s>" % len(tmp_list[1:])
                        oneOut.append(   [z, pat, nspps*100/n, nspps] )

            twoGroups = orderByNspps(oneOut)+orderByNspps(groupOut) if sep else orderByNspps(oneOut+groupOut)

            for zout in twoGroups:

                if line == 1:
                    Wout.append("patternUsedPlusGroup,sharing,N")
                    line += 1

                Wout.append(zout)

        return Wout

    def Upset2Bar(self, output):
        """
        :param output: from OBc().UpsetData(file, group, order, sep) [see comment]
        :return: ['group,region,n', 'Mammalia,Chile,20',...]
        """
        ## class calling
        # self  = OBc()
        # file = "data/bold.csv"
        # group = "group"
        # order = "Reptilia,Mammalia".split(',')
        # sep = True
        # output = OBc().UpsetData(file=file, group=group,
        #                          block=block, line = line, sep=sep)
        ##

        # for i in output:
        #     print(i)

        howManyRegion = lambda regex: re.findall("\|", regex).__len__() + 1
        getPos        = lambda p, d: set( [i.split(',')[p] for i in d] )
        getGroup      = lambda d: set([ re.sub("^(\w+)\(.*", "\\1", i) for i in getPos(0,d) ])
        splitCol      = lambda s: re.sub("^(\w+)\((.*)\)<(\d+)>,.*", "\\1,\\2,\\3", s)

        out  = []
        line = 1

        for i in getGroup( output[1:] ):

            for ii in output[1:]:

                if howManyRegion(ii) == 1 and re.findall("^%s\(" % i, ii):

                    if line == 1:
                        out.append("group,region,n")
                        line += 1

                    out.append( splitCol(ii) )

        return out

    def writeOut(self, out):

        tmp_filename = uuid.uuid4().hex[:14].upper()
        f = open(tmp_filename, "w")

        for i in out:
            f.write(i + "\n")

        f.close()
        return tmp_filename

    def SankeyData(self, bold, obis, regionsort, groupsort, group, debug = True):
        """
        It should be read by R like the following structure:

    Country          Group Distribution Species        Availability Availability2

1     Chile Actinopterygii           NA      47        BOLD private  BOLD private
2     Chile Actinopterygii       inside      43  BOLD public inside   BOLD public
3     Chile Actinopterygii      outside     197 BOLD public outside   BOLD public
4     Chile Actinopterygii           NA      94                  NA            NA

5     Chile Elasmobranchii           NA       2        BOLD private  BOLD private
6     Chile Elasmobranchii       inside      15  BOLD public inside   BOLD public
7     Chile Elasmobranchii      outside       9 BOLD public outside   BOLD public
8     Chile Elasmobranchii           NA       7                  NA            NA

9     Chile   Invertebrate           NA     167        BOLD private  BOLD private
10    Chile   Invertebrate       inside      60  BOLD public inside   BOLD public
11    Chile   Invertebrate      outside     456 BOLD public outside   BOLD public
12    Chile   Invertebrate           NA    1442                  NA            NA

13    Chile       Mammalia           NA       3        BOLD private  BOLD private
14    Chile       Mammalia      outside      17 BOLD public outside   BOLD public
15    Chile       Mammalia           NA       1                  NA            NA

16    Chile       Reptilia      outside       3 BOLD public outside   BOLD public

17 Colombia           ....          ...     ...                 ...           ...
        """
        group = [group]

        ## class calling
        # bold = "data/bold.csv"
        # obis = "data/obis.csv"
        # regionsort = None
        # # groupsort  = ["Reptilia", "Mammalia"] #capitalize within args
        # groupsort = None  # capitalize within args
        # group = ["group"]
        # self  = OBc()
        ##
        getPos = lambda p, d: set([i.split(',')[p] for i in d])

        def classifier(emDict, lilist, posA):
            """
            :param emDict: {"NA":0, "Bpi":0, "Bpo":0, "Bp":0}
            :param lilist: ['spps,syn,avail,r,g,subg,k',..]
            :param posA: 2, availability position
            :return: {"NA":n, "Bpi":n', "Bpo":n''', "Bp":n''''}
            """
            mStrings = lambda l, p: [s for s in l if re.findall(p, s)].__len__() > 0
            diUp     = lambda d, k: d.update({k : d[k] + 1})

            avail = getPos(posA, lilist)
            # avail = {'public_outside', 'private'}
            if len(avail) > 0:

                if mStrings(avail, "public_inside"):
                    diUp(emDict, "Bpi")
                else:
                    if mStrings(avail, "public_outside"):
                        diUp(emDict, "Bpo")

                    else:
                        diUp(emDict, "Bp")
            else:
                diUp(emDict, "NA")

        def splitS(string):
            pieces = string.split(" ")

            if len(pieces) == 1:
                return "NA,NA,NA"

            elif len(pieces) == 2:
                return "%s,%s,%s" % (string, pieces[-1], "NA")

            elif len(pieces) == 3:
                return "%s,%s,%s" % (string, pieces[-2], pieces[-1])

        treatDict = lambda d: filter(lambda kv: kv[1] > 0, d.items())
        getRow    = lambda s1, s2, n: "%s,%s,%s" % (s1, splitS(s2), n )

        bold_df = self.readWithHeader(bold)
        obis_df = self.readWithHeader(obis)
        ## Values of obis file is taken as a reference
        iterRegion = self.getOrderedGroups( df = obis_df, group = ["region"], by = regionsort, withN = False )
        iterGroup  = self.getOrderedGroups( df = obis_df, group = group, by = groupsort, withN = False )

        # WARNING: keys are always ordered in
        # function of their positions in header
        bold_k = self.__groupBy_key__(bold_df, ["valid_name", "region"] + group)

        posA = self.__checkPos__(bold_df[0], ['availability'])[0]
        posS = self.__checkPos__(obis_df[0], ['valid_name'])[0]

        head = ["Region,Group,Availability,Availability2,Distribution,Species"]
        out  = []

        if debug:
            print("Comparing files for:")

        for r in iterRegion:
            if debug:
                print("%10s in:"%r)
            # r = "Chile"`
            r_tmp = self.oneColSubset(obis_df, ["region"],r)

            for g in iterGroup:
                if debug:
                    print("%30s" % g)
                # g = "Invertebrates"
                g_tmp    = self.oneColSubset(r_tmp, group, g)
                tmp_dict = {"NA": 0, "Bpi": 0, "Bpo": 0, "Bp": 0}

                for s in getPos(posS, g_tmp[1:]):
                    # print(s)
                    # s = "Eurypon miniaceum"
                    pat      = "%s-%s-%s" % (s,r,g)
                    bold_sub = self.__subset__(bold_k, pat)
                    # print( "\t\t%s" % pat )
                    # print( "\t\t\t", bold_sub )
                    classifier(tmp_dict, bold_sub, posA)

                # print("\n\t",tmp_dict)
                twoCol = "%s,%s" % (r, g)

                for k,v in treatDict(tmp_dict):
                    if k == "Bpi":
                        out.append(
                            getRow(twoCol, "BOLD public inside", v) )
                        # print(getRow(twoCol, "BOLD public inside", v))
                    elif k == "Bpo":
                        out.append(
                            getRow(twoCol, "BOLD public outside", v) )
                        # print(getRow(twoCol, "BOLD public outside", v))
                    elif k == "Bp":
                        out.append(
                            getRow(twoCol, "BOLD private", v) )
                        # print(getRow(twoCol, "BOLD private", v))
                    elif k == "NA":
                        out.append(
                            getRow(twoCol, "NA", v) )
                        # print(getRow(twoCol, "NA", v))
                    else:
                        pass

        return head + out

    def boldSpps(self, bold, group, specificgroup):

        ### mock params
        # bold = "data/bold.csv"
        # specificgroup = None
        # specifictaxa = None
        # group = "group"
        ### mock params
        group = [group]

        getSpps = lambda d,p: set([i.split(',')[p] for i in d if re.findall(",public_",i)])
        # self  = OBc()

        df     = self.readWithHeader(bold)
        oGroup = self.getOrderedGroups(df=df, group=group, by=specificgroup, withN=False)
        P      = self.__checkPos__(df[0], ['valid_name'])[0]

        out = {"order": oGroup}

        for g in oGroup:

            tmp_sub = self.oneColSubset(df, group, g)

            out.update( {g : getSpps(tmp_sub, P)} )

        return out
