perl_old='#!/usr/bin/env perl'
perl_new='#!'$(which perl)

r_old='#!/usr/bin/env Rscript --vanilla'
r_new='#!'$(which Rscript)' --vanilla'

sed -ibak "s;$perl_old;$perl_new;g" circling_pl/get_bins.pl

sed -ibak "s;$r_old;$r_new;g" circling_r/plot_bars.R
sed -ibak "s;$r_old;$r_new;g" circling_r/plot_radar.R
sed -ibak "s;$r_old;$r_new;g" circling_r/plot_sankey.R
sed -ibak "s;$r_old;$r_new;g" circling_r/plot_upset.R
sed -ibak "s;$r_old;$r_new;g" circling_r/species_bold.R

$PYTHON setup.py install
