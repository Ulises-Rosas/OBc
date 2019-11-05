#!/usr/bin/env python3

# -*- coding: utf-8 -*- #

import argparse
from circling_py.OBc import *
import subprocess

levels = ["A","B","C","D","E*","E**","F"]

def getOpt():

    parser = argparse.ArgumentParser(description="Audit species barcodes from OBc pipeline", add_help=True)

    parser.add_argument('-i','--input',
                        metavar='str',
                        default=None,
                        help='[Required] input file',
                        required=False)
    parser.add_argument('--for',
                        nargs='+',
                        metavar="str",
                        default=None,
                        help='[Optional] Specific group for plotting radars. If there is any value, all groups for '
                             ' `Group` column is taken [Default = None]')
    parser.add_argument('--at',
                        nargs='+',
                        metavar="str",
                        default=None,
                        help='[Optional] Coupled with `--for` option. Split polygons inside each specific '
                             ' group correspondingly to a specific taxonomical rank (e.g. if `Family` is choosen,'
                             ' each family has its own polygon inside a radar). If there is any value, overall '
                             ' data is plotted without distinction of taxomical ranks. If there is only one value, this'
                             ' is used for all radar plots. Otherwise, an error is raised, including mismatches between '
                             ' values introduced here and available taxonomical rank from input data [Default = None]')
    parser.add_argument('--n',
                        nargs='+',
                        metavar="str",
                        default=None,
                        help='[Optional] Coupled with `--at` option. Maximum number of polygons inside each'
                             ' specific group correspondingly. If there is any value,  whole data is taken. If ' 
                             ' there is only one value, this is used for all '
                             ' radar plots. Otherwise, an error is raised'
                             ' [Default = None]')
    parser.add_argument('-l', '--legend',
                        action="store_true",
                        default=False,
                        help='''[Optional] if selected, draw legend''')
    parser.add_argument('-g', '--grades',
                        nargs='+',
                        metavar="str",
                        default=levels,
                        help='''[Optional] Specific grades to plot. Levels can be collapsed with a forward slash
                        (e.g. A/B C D E*/E** F) [Default = A B C D E* E** F] ]
                        ''')
    parser.add_argument('-p', '--pal',
                        metavar='str',
                        type=str,
                        default='NA',
                        help='[Optional] Palette of colors [Default = NA]')
    parser.add_argument('-b', '--labelsize',
                        metavar='float',
                        type=float,
                        default=12,
                        help='[Optional] Size of labels [Default = 14]')
    parser.add_argument('-L', '--linesize',
                        metavar='float',
                        type=float,
                        default=1.8,
                        help='[Optional] Size of labels [Default = 1.8]')
    parser.add_argument('-t', '--transform',
                        metavar='str',
                        type=str,
                        default="percentage",
                        help="[Optional] transform species counts. There are three options: 'percentage', 'exponential' and 'log' [Default = percentage]")
    parser.add_argument('-T', '--tnumber',
                        metavar='float',
                        type=float,
                        default=0.5,
                        help='''Transforming number and is coupled with `--transform` optio. This number is used as base when `log` 
                        is used or exponential number when using 'exponential' [Default = 0.5]
                        ''')
    parser.add_argument('-c', '--ctitle',
                        action="store_true",
                        default=False,
                        help='''if selected, title is changed according to above options''')
    parser.add_argument('-H',
                        metavar='float',
                        type=float,
                        default=5,
                        help='[Optional] Height of plot in inches [Default = 7]')
    parser.add_argument('-W',
                        metavar='float',
                        type=float,
                        default=11.5,
                        help='[Optional] Height of plot in inches [Default = 14]')
    parser.add_argument('-r',
                        metavar='float',
                        type=float,
                        default=200,
                        help='[Optional] Resolution of plot [Default = 200]')
    parser.add_argument('-o', '--output',
                        metavar='str',
                        type=str,
                        default='input_based',
                        help='[Optional] Output name [Default = <input_based>.jpeg]')
    args = parser.parse_args()
    return args


def runShell(args):
    p = subprocess.Popen(args)
    p.communicate()

def cname(s):

    tail = "_RadarPlot.jpeg"
    try:
        return s.split(".")[-2].split("/")[-1] + tail
    except IndexError:
        return s.split("/")[-1] + tail

def main():
    option = vars(getOpt())

    sameLevels = len(set(levels) - set(option['grades'])) == 0

    if not sameLevels:
        rinput = str( OBc().changeGrades( option['input'], option['grades'], write=True) )
    else:
        rinput = option['input']

    plusHeader = "labelsize,linesize,tnumber,transform,pal,legend,ctitle"
    plusOpt    = ",".join([ str(option['labelsize']),
                            str(option['linesize']),
                            str(option['tnumber']),
                            option['transform'],
                            option['pal'],
                            'TRUE' if option['legend'] else 'FALSE',
                            'TRUE' if option['ctitle'] else 'FALSE'
                            ])

    df = OBc().RadarPlotOpt( option['input'], option['for'], option['at'], option['n'] )

    out = ["%s,%s" % (df[0], plusHeader)]
    for i in df[1:]:
        out.append("%s,%s" % (i, plusOpt))


    rindications = str(OBc().writeOut(out))

    fo = option['output'] if option['output'] != "input_based" else cname(option['input'])


    Ropt = [ 'plot_radar.R',
             '-a', rinput,
             '-i', rindications,
             '-g', ",".join(sorted(option['grades'])),
             '-H', str(option['H']),
             '-W', str(option['W']),
             '-r', str(option['r']),
             '-o', fo
             ]

    runShell(Ropt)

    if not sameLevels:
        runShell(['rm', rinput])

    runShell(['rm', rindications])

if __name__ == "__main__":
    main()