#!/usr/bin/env python3

# -*- coding: utf-8 -*- #

import argparse
from circling_py.OBc import *

def getOpt():

    parser = argparse.ArgumentParser(description="Data handler from OBc pipeline")

    parser.add_argument('--from',
                        nargs= '+',
                        metavar='str',
                        default=".",
                        help='path of files.....................[Default = .]')
    parser.add_argument('--as',
                        nargs='+',
                        metavar="str",
                        default=None,
                        help='grouping name.....................[Default = None]')
    parser.add_argument('--matching',
                        metavar='<str>',
                        default='_bold_',
                        help='''pattern for matching filenames....[Default = _bold_]''')
    parser.add_argument('--noheader',
                        action='store_false',
                        help='''Use a header while creating csv''')
    args = parser.parse_args()

    return args

def main():

    options = vars(getOpt())
    # print(options)
    out = OBc().joinFiles( directory = options['from'],
                           group     = options['as'],
                           pattern   = options['matching'],
                           header    = options['noheader'])

    if out is not None or out.__len__() > 0:

        for i in out:

            print(i)

if __name__ == "__main__":
    main()
