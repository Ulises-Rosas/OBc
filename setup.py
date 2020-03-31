#!/usr/bin/env python3

import setuptools
from distutils.core import setup

rcode = [
      "plot_sankey.R",
      "plot_radar.R",
      "plot_bars.R",
      "plot_upset.R",
      "species_bold.R"
      ]

perlcode = [
      "get_bins.pl"
      ]

setup(name="OBc",
      version='0.1',
      author='Ulises Rosas',
      author_email='ulisesfrosasp@gmail.com',
      url='https://github.com/Ulises-Rosas/OBc',
      packages = ['circling_py', 'circling_r', 'circling_pl'],
      package_dir = {
            'circling_py': 'circling_py',
            'circling_r' : 'circling_r',
            'circling_pl' : 'circling_pl'
            },
      package_data = {
            "circling_r" : rcode,
            "circling_pl" : perlcode
            },
      scripts = [
            'circling_py/bin/auditspps',
            'circling_py/bin/barplot',
            'circling_py/bin/joinfiles',
            'circling_py/bin/sankeyplot',
            'circling_py/bin/upsetplot',
            'circling_py/bin/obis',
            'circling_py/bin/radarplot',
            # bash code
            'circling_sh/checklists',
            'circling_sh/checkspps'
            ],
      classifiers=[
            'Programming Language :: Python :: 3',
            'License :: OSI Approved :: MIT License'
            ]
      )