#!/usr/bin/env python3

import setuptools
from distutils.core import setup


setup(name="OBc",
      version='0.1',
      author='Ulises Rosas',
      author_email='ulisesfrosasp@gmail.com',
      url='https://github.com/Ulises-Rosas/OBc',
      packages = ['circling_py'],
      package_dir = {'circling_py': 'circling_py'},
      scripts = [
            'circling_py/bin/auditspps',
            'circling_py/bin/barplot',
            'circling_py/bin/joinfiles',
            'circling_py/bin/sankeyplot',
            'circling_py/bin/upsetplot',
            'circling_py/bin/obis',
            'circling_py/bin/radarplot',
            # r code
            'circling_r/plot_bars.R',
            'circling_r/plot_radar.R',
            'circling_r/plot_sankey.R',
            'circling_r/plot_upset.R',
            'circling_r/species_bold.R',
            # bash code
            'circling_sh/checklists',
            'circling_sh/checkspps',
            # perl code
            'circling_pl/get_bins.pl'
            ],
      classifiers=[
            'Programming Language :: Python :: 3',
            'License :: OSI Approved :: MIT License'
            ]
      )