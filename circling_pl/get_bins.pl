#!/usr/bin/env perl

use warnings;
use strict;
# use LWP::Simple qw(get);



print  $#ARGV, "\n";
# print @ARGV, "\n";

my $input = "";

for(my $k = 0; $k <= $#ARGV; $k++){

    if ( $ARGV[$k] eq '-i' ) {

        $input = $ARGV[$k + 1];
    }
}

sub header {

    die "Can't open file $_[0]: $!\n" if not open( INFILE, $_[0] );

    chomp(my $head = <INFILE>);
    # print <$INFILE>;
    close(INFILE);
    $head
}

# my $input = "repTest.tsv";
# "Phylum	Order	Family  Genus	Group	Species";

my @cols = split /\t/, &header($input);

print $#cols


# print scalar @lines
# my @spps = ();
# #
# while (  my $line = @lines ) {
#
#     my @cols = split /\t/, $line;
#
#     push(@spps, $cols[5])
#
# }
# #
# print  join("|",@spps);
# #
# #







# open IN, "$input" or die "Could not open $input\n";

# open(INFILE, $input) or die( "Can't open file '$input': $!");








#
# # host
# my $url = "http://www.boldsystems.org/index.php/API_Public/specimen?";
# # host
#
# ## query
# my $spps = "taxon=Alopias%20pelagicus";
# my $format = "format=tsv";
# my $query = join("&", $spps, $format);
# # query
#
# my $cUrl =  $url . $query;
# print $cUrl;
#
# my @html = get $cUrl;
#
# foreach(@html) {
#     print "Line", $_;
# }







# my $html = get $url;
#
# print $html





