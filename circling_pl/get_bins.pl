#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use List::Util qw(sum);
use HTTP::Tiny;

local $| = 1;

# print  'number of args: ', $#ARGV, "\n";
# print @ARGV, "\n";

my $input;
my $output;
my $include_ncbi = 'F';
my $private = 0;
my $quiet = 0;

for(my $k = 0; $k <= $#ARGV; $k++){

    $output = $ARGV[$k + 1] if ($ARGV[$k] eq '-o');
    $input  = $ARGV[$k + 1] if ($ARGV[$k] eq '-i');
    $include_ncbi = 'T'     if ($ARGV[$k] eq '-n');
    $private = 1            if ($ARGV[$k] eq '-p');
    $quiet   = 0            if ($ARGV[$k] eq '-q');
}

if ( not $input){
    print "Please introduce an input file";
    exit;
}

if ( not $output){
    print "Please introduce an output file";
    exit;
}
# print $output."_RM", "\n";
# print $input."_RM", "\n";
# print $include_ncbi."_RM", "\n";
# print $private."_RM", "\n";
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

        my %ref = (
            'spps'   => $t_s,
            'bin'    => undef,
            'onBins' => undef,
            'ninst'  => undef,
            'n'      => undef,
            'class'  => undef,
            'taxid'  => undef
        );

        $ref{meta} = join(",", @slt[@mPo]) if(@mPo);

        push( @{ $df{ $t_g } }, \%ref );
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
    my($bi, $sp, $in, $taxid) = &checkPos(
                                    $pageHeader, "F",
                                    qw/bin_uri species_name institution_storing species_taxID/);
    my($p1, $p2) = (
        "(unvouchered|NA)",
        "(Mined from GenBank| NCBI|unvouchered|NA)");

    my $pat  = $include_ncbi eq 'T'? $p1 : $p2;
    my %df2  = ();

    for (@page){

        my @pr = split /\t/;

        my $pspps  = &checkUndef( grep {/\b[A-Z][a-z]+ [a-z]+\b/} $pr[$sp] );
        my $pinst  = &checkUndef( grep {!/$pat/} $pr[$in] );
        my $pbin   = &checkUndef( grep {/BOLD/} $pr[$bi] );
        my $ptaxid = &checkUndef( $pr[$taxid] );
        my $pN     = $pbin =~ 'NA' || $pinst =~ 'NA'? 0 : 1;

        # printf "%s,%s,%s,%s,%s\n", $pspps,$pinst, $pbin, $ptaxid, $pN;
        push( @{ $df2{$pspps}->{'n'} }, $pN);
        push( @{ $df2{$pspps}->{'taxid'} }, $ptaxid);
        push( @{ $df2{$pspps}->{'bin'}->{$pbin} }, 1);
        push( @{ $df2{$pspps}->{'inst'}->{$pinst} }, 1);
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
        my @taxid = &uniq( @{$mArr->{taxid}} );

        $_->{bin}   = [@bins] if $sum;
        $_->{ninst} = $ninst;
        $_->{n}     = $sum;
        $_->{taxid} = $taxid[0];
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
    my ($ncbied, @withBin) = @_;

    for ( @withBin ) {

        my $spps      = $_->{spps};
        my $notTarget = scalar grep {not /$spps/} &checkUndef( @{$_->{onBins}} );
        my $nbin      = scalar @{$_->{bin}};

        if( $_->{n} <= 3 ) {
            $_->{class} = $ncbied eq 'T'? "D":($_->{ninst} > 0? "D":"F");

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

sub upgradeFs {

    my ($printTool,$group,@publicClass) =  @_;
    my $pat = "(Mined from GenBank, NCBI| NCBI|unvouchered|NA)";

    my %dspps = ();

    for my $wc (@publicClass) {

        if ($wc->{class} eq 'F' ){
            push( @{ $dspps{$wc->{spps}} }, $wc->{taxid});
        }
    }

    my $n = 30;
    my $nitems = scalar keys %dspps;

    for (my $i = 1; $i <= $nitems; $i++) {

        my($k3,$v3) = each %dspps;

        my @p = &getContent(
            "http://www.boldsystems.org/index.php/API_Tax/TaxonData?",
            "taxId=@{$v3}[0]&dataTypes=all" );

        my %repos = %{ eval ( $p[0] =~ s/.*depositry":({.+?}),.*/$1/rg
                                    =~ s/:/=>/rg
                                    =~ s/"$pat"=>\d+,{0,}//rg ) };

        my($re,$su) = (scalar keys %repos, sum values %repos);

        if($re > 0){

            for my $pc (@publicClass) {

                if ($pc->{spps} eq $k3) {

                    $pc->{class} = "D";
                    $pc->{ninst} = $re;
                    $pc->{n}     = $su;

                }
            }
        }

        if ($printTool) {

            my $p  = $i/$nitems;
            my $ip = int($n*$i/$nitems);

            printf
                "\r%40s[%s%s] (%6.2f %%)",
                "Getting whole records in $group...",
                '#'x$ip,
                '-'x($n-$ip),
                $p*100;
        }

    }
    return @publicClass
}

# my $chead = &header($input);
# my $input = "repTest.tsv";
# my $input = "mamrepTest.tsv";
# my $input = "NoMetaRepTest.tsv";

my @file   = &readThis($input);
my $header = shift @file;

my @pos     = &checkPos($header, "F" ,qw/Species Group/);
my @metaPos = &checkPos($header, "T", qw/Species Group/);

my %df = &get_frame($pos[0], $pos[1], [@metaPos], @file);

open(my $fh, '>', $output);
printf  $fh
    $header . "\t" . join(
        "\t",
        ("Classification",
         "sppsOnBins",
         "N",
         "N_Institutes",
         "taxIDs",
         "BINs")
        ) . "\n";

while ( my($k,$v) = each %df ) {
    # my($k,$v) = ();
    # my($k,$v) = each %df;
    # print Dumper $k;
    my @taxa = map {$_->{'spps'}} @{$v};

    if(not $quiet){
        print "\n";
        printf "\r%40s%s","Getting metadata in $k...","";
    }

    my %df2  = &SpecimenData( $include_ncbi,  @taxa );

    if(not $quiet){
        printf "\r%40s%s","Getting metadata in $k...","Ok";
    }

    my @withMeta  = &fillFromMeta( [@{$v}], %df2 );

    if(not $quiet){
        print "\n";
        printf "\r%40s%s","Getting BINs in $k...","";
    }

    my @withClass = &classifier(
                        $include_ncbi,
                        &binData(
                            &collapseBins( 'bin', @withMeta ),
                            $include_ncbi,
                            @withMeta));
    if(not $quiet){
        printf "\r%40s%s","Getting BINs in $k...","Ok";

    }

    if($private){
        print "\n";
        @withClass = &upgradeFs( (not $quiet),$k, @withClass );
        printf  "\r%40s%-43s", "Getting whole records in $k...", "Ok";
        print "\n";
    }

    for(@withClass){

        my $bStr =
            sprintf(
                join("\t", ("%s")x8)."\n",
                $k,
                $_->{spps} ,
                $_->{class},
                join(",", @{$_->{onBins}}),
                $_->{n},
                $_->{ninst},
                $_->{taxid},
                join(",", @{$_->{bin}})
            );
        $bStr = ($_->{meta} =~ s/,/\t/gr)."\t$bStr" if (@metaPos);
        printf $fh "$bStr";
    }
    print "\n";
}
print "\n";
close($fh);
