#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use List::Util qw(sum);
use HTTP::Tiny;
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
            'spps'   => $t_s,
            'meta'   => join(",", @slt[@mPo]),
            'bin'    => undef,
            'onBins' => undef,
            'ninst'  => undef,
            'n'      => undef,
            'class'  => undef
            };

        push( @{ $df{ $t_g } }, $ref );
    }
    return %df
}

sub checkUndef { 
    !$_[0]?  "NA": $_[0]; 
}

sub getContent {

    my($host,$query) = @_;

    my $ht = HTTP::Tiny->new;
    my $respo;

    while ( not $respo->{success}  ) {
        $respo = $ht->get($host.$query);
        sleep(1);
    }
    return split("\n", $respo->{'content'});
}

sub SpecimenData {

    my($include_ncbi,@taxa) = @_;

    my $host   = "http://www.boldsystems.org/index.php/API_Public/specimen?";
    my $qtaxa  = "taxon=".join("|", map {s/ /%20/r} @taxa);
    my $format = "&format=tsv";

    my @page          = &getContent($host, $qtaxa.$format);
    my $pageHeader    = shift @page;
    my($bi, $sp, $in) = &checkPos(
                            $pageHeader, "F",
                            qw/bin_uri species_name institution_storing/);
    my($p1, $p2) = (
        "(unvouchered|NA)",
        "(Mined from GenBank| NCBI|unvouchered|NA)");

    my $pat  = $include_ncbi eq 'T'? $p1 : $p2;
    my %df2  = ();

    for (@page){

        my @pr = split /\t/;

        my $pspps = &checkUndef( grep {/\b[A-Z][a-z]+ [a-z]+\b/} $pr[$sp] );
        my $pinst = &checkUndef( grep {!/$pat/} $pr[$in] );
        my $pbin  = &checkUndef( grep {/BOLD/} $pr[$bi] );
        my $pN    = $pbin =~ 'NA' || $pinst =~ 'NA'? 0 : 1;


        push( @{ $df2{$pspps}->{'n'}}, $pN);
        push( @{ $df2{$pspps}->{'bin'}->{$pbin}}, 1);
        push( @{ $df2{$pspps}->{'inst'}->{$pinst}}, 1);
    }
    return %df2;
}

sub collapseBins {

    my($ke, @ar_hash) = @_;

    join("|",
        &uniq(
            map { grep {/BOLD/} @{$_->{$ke}} } @ar_hash
        )
    );
}

sub fillFromMeta {

    my($hashesFrames,%dfSppsData) = @_;
    my @hashesFrames = @{ $hashesFrames };

    for(@hashesFrames){
        my $mArr = $dfSppsData{ $_->{'spps'} };

        my $sum   = sum( @{$mArr->{n}} );
        my $ninst = scalar grep {!/NA/} keys %{$mArr->{inst}};
        my @bins  = grep {!/NA/} keys %{$mArr->{bin}};


        $_->{bin}   = [@bins] if $sum;
        $_->{ninst} = $ninst;
        $_->{n}     = $sum;
    }
    return @hashesFrames
}

sub binData {

    my ($bins, $include_ncbi, @withBins) = @_;

    my($p1, $p2) = (
        "(unvouchered|NA)",
        "(Mined from GenBank| NCBI|unvouchered|NA)" );

    my $pat  = $include_ncbi eq 'T'? $p1 : $p2;

    my($sppat, $notsppat) = (
        '\b[A-Z][a-z]+ [a-z]+\b',
        '\b[A-Z][a-z]+ sp[p|.]{0,2}\b' );

    my $host  = "http://www.boldsystems.org/index.php/API_Public/specimen?";
    my $query = "bin=".$bins."&format=tsv";

    my @page          = &getContent($host, $query);
    my $pageHeader    = shift @page;
    my($bi, $sp, $in) = &checkPos(
                            $pageHeader, "F",
                            qw/bin_uri species_name institution_storing/);

    my %df3 = ();
    for ( @page ){

        my @pr = split /\t/;

        my $pspps = &checkUndef( grep {!/$notsppat/ and /$sppat/} $pr[$sp] );
        my $pinst = &checkUndef( grep {!/$pat/} $pr[$in] );
        my $pbin  = &checkUndef( grep {/BOLD/} $pr[$bi] );
        # print "\n";
        push( @{ $df3{$pbin}->{'spps'}->{$pspps} }, 1);
        push( @{ $df3{$pbin}->{'inst'}->{$pinst} }, 1);
    }
    # print Dumper \%df3;
    my %kspps = ();

    while( my($k2, $v2) = each %df3 ){
        push(
            @{ $kspps{$k2} },
            grep {!/NA/} keys $v2->{spps} );
    }
    # my @withBins = @{$v};
    for(@withBins){
        # with Bin array
        my @wBa = &uniq( @{$_->{'bin'}} );
        # print Dumper @wBa;
        if ( scalar @wBa ) {

            my @spps = ();
            for my $ub ( @wBa ) {
                # print Dumper $ub;
                push(@spps, @{$_}) for( $kspps{$ub} );
            }
            # print Dumper &uniq(@spps);
            $_->{onBins} = [ &uniq(@spps) ];
        }
    }
    return @withBins
}

sub classifier {
    my @withBin = @_;

    for ( @withBin ) {

        my $spps      = $_->{spps};
        my $notTarget = scalar grep {not /$spps/} &checkUndef( @{$_->{onBins}} );
        my $nbin      = scalar @{$_->{bin}};

        if( $_->{n} <= 3 ) {
            $_->{class} = "D";

        }else{
            if ( $nbin > 1 ) {
                $_->{class} = $notTarget > 1? "E**":"C";

            }else{
                if ( $notTarget > 1 ) {
                    $_->{class} = "E*";

                }else{
                    $_->{class} = $_->{ninst} > 1? "A":"B";
                }
            }
        }
    }
    return @withBin;
}

# my $chead = &header($input);
my $input = "repTest.tsv";

my @file   = &readThis($input);
my $header = shift @file;

my @pos     = &checkPos($header, "F" ,qw/Species Group/);
my @metaPos = &checkPos($header, "T", qw/Species Group/);

my %df = &get_frame($pos[0], $pos[1], [@metaPos], @file);

while ( my($k,$v) = each %df ) {
    my($k,$v) = %df;
    print Dumper $k;

    my @taxa = map {$_->{'spps'}} @{$v};
    my %df2  = &SpecimenData( "F", @taxa );

    my @withMeta  = &fillFromMeta( [@{$v}], %df2 );
    # my @withBin   = &binData( &collapseBins('bin', @withMeta), "F", @withMeta );
    # my @withClass = &classifier( @withBin );
    my @withClass = &classifier(
                          &binData(
                              &collapseBins( 'bin', @withMeta ), "F", @withMeta));

    @withClass;
}

