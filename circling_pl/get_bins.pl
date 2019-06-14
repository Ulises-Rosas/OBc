#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
# use LWP::Simple qw(get);


print  'number of args: ', $#ARGV, "\n";
# print @ARGV, "\n";

my $input;

for(my $k = 0; $k <= $#ARGV; $k++){

    if ( $ARGV[$k] eq '-i' ) {

        $input = $ARGV[$k + 1];
    }
}

sub readThis {

    die "Can't open file $_[0]: $!\n" if not open( INFILE, $_[0] );

    chomp(my @lines = <INFILE>);
    # print <$INFILE>;
    close(INFILE);
    @lines
}

sub checkPos {

    # header, target cols
    my($header,$anti, @target) = @_;
    my @out = ();

    my @sheader = split /\t/, $header;

    if ($anti eq "T"){
        my $pat = "(".join("|", map {"^".$_."\$"} @target).")";

        for (0..$#sheader){
            push(@out, $_) if not ($sheader[$_] =~ /$pat/)
        }
    }else{
        for my $t (@target){
            map { push(@out, $_ ) if ($sheader[$_] eq $t) } (0..$#sheader);
        }
    }
    return @out
}

sub uniq {

    my %seen;
    return grep {!$seen{ $_ }++} @_;
}

sub colPos {

    my($p, @f) = @_;

    my @sel;
    push(@sel, (split /\t/)[$p]) for @f;
    return @sel
}

sub get_frame {

    my($s,$g,$mPo,@fil) = @_;

    my @mPo = @{$mPo};
    my %df;

    for (my $i = 0; $i <= $#fil; $i++) {
        my @slt = split /\t/, $fil[$i];

        my $t_s = $slt[$s];
        my $t_g = $slt[$g];

        my $ref = {
            $t_s => {
                'meta' => join(",", @slt[@mPo]),
                'bold' => undef,
                'bin'  => undef
            }
        };
        push( @{ $df{ $t_g } }, $ref );
    }
    return %df
}

# my $chead = &header($input);
# my $input = "repTest.tsv";

my @file   = &readThis($input);
my $header = shift @file;

my @pos     = &checkPos($header, "F" ,qw/Species Group/);
my @metaPos = &checkPos($header, "T", qw/Species Group/);

my %df = &get_frame($pos[0], $pos[1], [@metaPos], @file);

print Dumper \%df;



# my %df;
#
# my $s = $pos[0];
# my $g = $pos[1];
#
# for (my $i = 0; $i <= $#file; $i++) {
#
#     my @slt = split /\t/, $file[$i];
#
#     my $t_s = $slt[$s];
#     my $t_g = $slt[$g];
#
#     my $ref = {
#         $t_s => {
#             'meta' => join(",", @slt[@metaPos]),
#             'bold' => undef,
#             'bin'  => undef
#         }
#     };
#     # print Dumper \$ref;
#     push( @{ $df{ $t_g } }, $ref );
# }

# print $#{  $hgs{'Reptilia'} };

# print Dumper \%df




# while ( my($k,@v) = each %chash) {
#
#     foreach my $n (@v){
#         say $n;
#     }
# }

# foreach my $k (keys %chash){
#
#     # for ( $chash{$k} ){
#     #     print scalar $#_;
#     # }
#     print $chash{$k}[0];
#
#
#
#
#
# }


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

