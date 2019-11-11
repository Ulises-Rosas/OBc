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
my $refnamesfile;
my $include_ncbi = 'F';
my $private = 0;
my $quiet = 0;

## delete this shit
# $input = "testinput";
# $refnamesfile = "testrefnames";  
##

my %refnames  = ();

for(my $k = 0; $k <= $#ARGV; $k++){

    $output = $ARGV[$k + 1]       if ($ARGV[$k] eq '-o');
    $input  = $ARGV[$k + 1]       if ($ARGV[$k] eq '-i');
    $refnamesfile = $ARGV[$k + 1] if ($ARGV[$k] eq '-r');
    $include_ncbi = 'T'           if ($ARGV[$k] eq '-n');
    $private = 1                  if ($ARGV[$k] eq '-p');
    $quiet   = 1                  if ($ARGV[$k] eq '-q');
}

if ( not $input){
    print "Please introduce an input file\n";
    exit;
}

if ( not $output){
    print "Please introduce an output file\n";
    exit;
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
    # my @hashesFrames = @{$v};
    # my %dfSppsData = %df2;

    for(@hashesFrames){
        my $mArr = $dfSppsData{ $_->{'spps'} };

        my $sum   = sum( @{$mArr->{n}} );
        my $ninst = scalar grep {!/NA/} keys %{$mArr->{inst}};
        my @bins  = grep {!/NA/} keys %{$mArr->{bin}};
        my @taxid = &uniq( @{$mArr->{taxid}} );

        $sum = 0 if not defined $sum;

        $_->{bin}   = [@bins] if $sum;
        $_->{ninst} = $ninst;
        $_->{n}     = $sum;
        $_->{taxid} = $taxid[0];
    }
    return @hashesFrames
}

sub binData {

    my ($bins, $include_ncbi, $refnamesi, @withBins) = @_;
    # my $refnamesi = [%refnames];
    # my $bins = &collapseBins( 'bin', @withMeta );
    # my @withBins = @withMeta;
    my %refnamesi = @{$refnamesi};

    my($p1, $p2) = (
        "(unvouchered|NA)",
        "(Mined from GenBank| NCBI|unvouchered|NA)" );

    my $pat  = $include_ncbi eq 'T'? $p1 : $p2;

    my($sppat, $notsppat, $notsppat2) = (
        '\b[A-Z][a-z]+ [a-z]+\b',
        '\b[A-Z][a-z]+ sp[p|.]{0,2}\b',
        '[A-Z][a-z]+ cf\.');

    my $host  = "http://www.boldsystems.org/index.php/API_Public/specimen?";
    my $query = "bin=".$bins."&format=tsv";

    my @page          = &getContent($host, $query);
    my $pageHeader    = shift @page;
    my($bi, $sp, $in) = &checkPos(
                            $pageHeader, "F",
                            qw/bin_uri species_name institution_storing/);

    my %df3 = ();
    for ( @page ){

        my @pr    = split /\t/;
        my $pspps = &checkUndef(grep {!/$notsppat/ and !/$notsppat2/ and /$sppat/} $pr[$sp] );

        if ( not $pspps =~ /NA/){
            # print "\n\n", $pspps, "\n";

            my @t = (split " ", $pspps);
            ## downgrade tax status if there are
            ## subspecies i.e. three-word names
            if ( (scalar @t) ge 2 ){
                $pspps = join( " ", @t[0,1] );
            }

            my $pinst = &checkUndef( grep {!/$pat/} $pr[$in] );
            my $pbin  = &checkUndef( grep {/BOLD/} $pr[$bi] );

            if ( (not $pinst =~ /NA/) and (not $pbin =~ /NA/) ){
                # taking validated names
                if( %refnamesi ){

                     $pspps = $refnamesi{$pspps} if exists $refnamesi{$pspps};
                 }
                push( @{ $df3{$pbin}->{$pspps}->{$pinst} }, 1);
            }
        }
    }
    # print Dumper \%df3;
    for my $h (@withBins){
        # with Bin array
        # my $h = @withBins[3];
        my @wBa = &uniq( @{$h->{'bin'}} );
        # print Dumper @wBa;
        # print "\n";
        if ( scalar @wBa ) {

            my %spps = ();
            for my $ub ( @wBa ) {

                ## delete this
                # my $ub = $wBa[0];
                ## delete this
                for my $ub3 ( $df3{$ub} ){

                    # delete this
                    # my $ub3 = {
                    #      "Astrometis sertulifera" => { "Centre for Biodiversity Genomics" => [ 1 ] },
                    #      "Astrometis sertulifera2" => { "Centre for Biodiversity Genomics" => [ 1 ] } 
                    #      };      
                    # delete this

                    if( defined $ub3 ){

                        while (my ($k1, $v1) = each %{$ub3}) {
                            # print Dumper $k1;
                            # print Dumper $v1;
                            for(keys %{$v1}){

                                push(@{$spps{$k1}->{inst}->{$_}}, 1);
                                push(@{$spps{$k1}->{n}}, sum @{$v1->{$_}} );
                            }
                        }
                    }
                }
            }
            for my $k2 (keys %spps){

                $spps{$k2}->{n}    = sum @{ $spps{$k2}->{n} };
                $spps{$k2}->{inst} = scalar keys %{ $spps{$k2}->{inst} };
            }

            $h->{onBins} = \%spps;
        }
    }
    return @withBins
}

sub seekAndDestroy {

    my ($refnamesi, @withOnBins) = @_;

    my %refnamesi = @{$refnamesi};

    for my $sad (@withOnBins){

        if( scalar  @{$sad->{bin}} ){

            my $spps = $sad->{spps};

            if(%refnamesi){

                $spps = $refnamesi{$spps} if exists $refnamesi{$spps};
            }

            $sad->{n}      = $sad->{onBins}->{$spps}->{n};
            $sad->{ninst}  = $sad->{onBins}->{$spps}->{inst};
            $sad->{spps}   = $spps;
            $sad->{onBins} = [keys %{ $sad->{onBins} }];
        }
    }
    return @withOnBins;
}

sub classifier {
    my ($ncbied, @withBin) = @_;
    # my $ncbied = $include_ncbi;
    # my @withBin = @bb;
    for my $c ( @withBin ) {
        # my $c = $withBin[1];

        my $spps      = $c->{spps};
        my $notTarget = scalar grep {(not /$spps/) and defined} @{$c->{onBins}};
        my $nbin      = scalar @{$c->{bin}};
        # printf "%s,%s,%s\n", $spps, $notTarget, $nbin;
        if( $c->{n} <= 3 ) {
            $c->{class} =  $ncbied eq 'T'? "D": ($c->{ninst} > 0? "D": "F");

        }else{

            if ( $nbin > 1 ) {
                $c->{class} = $notTarget > 0? "E**":"C";

            }else{

                if ( $notTarget > 0 ) {
                    $c->{class} =  "E*";

                }else{
                    $c->{class} =  $c->{ninst} > 1? "A":"B";
                }
            }
        }
    }
    return @withBin;
}

sub upgradeFs {

    my ($printTool,$group,@publicClass) =  @_;
    # my ($printTool,$group,@publicClass) =  ( (not $quiet),$k, @bb );
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

        if(not defined @{$v3}[0]){

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
            next;
        }

        my @p = &getContent(
            "http://www.boldsystems.org/index.php/API_Tax/TaxonData?",
            "taxId=@{$v3}[0]&dataTypes=all" );

        if (not $p[0] =~ m/depositry":{/ ){

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
            next;
        }

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

sub quickVal {

    my ($refnamesi, @finalOut) = @_;
    my %refnamesi = @{$refnamesi};

    for my $f (@finalOut){
        # $spps = $refnamesi{$spps} if exists $refnamesi{$spps};
        $f->{spps} = $refnamesi{$f->{spps}} if exists $refnamesi{$f->{spps}};
    }
    return @finalOut
}

sub writeOut {

    my($group,$file,$pos,@frame) = @_;
    # my($group,$file,$pos,@frame) = ($k, $fh, [@metaPos], @withClass);

    my @metaPos = @{$pos};

    for(@frame){

        $_->{ninst} = '' if not defined $_->{ninst};
        $_->{taxid} = '' if not defined $_->{taxid};

        my $bStr =
            sprintf(
                join("\t", ("%s")x8)."\n",
                $group,
                $_->{spps} ,
                $_->{class},
                join(",", grep {defined} @{$_->{onBins}}),
                $_->{n},
                $_->{ninst},
                $_->{taxid},
                join(",", grep {defined} @{$_->{bin}})
            );
        $bStr = ($_->{meta} =~ s/,/\t/gr)."\t$bStr" if (@metaPos);
        printf $file "$bStr";
    }

}

if ($refnamesfile){

    my @reffile   = &readThis($refnamesfile);
    my $refheader = shift @reffile;
    my ($va,$si)  = &checkPos($refheader, "F", qw/valid_name synonyms/);

    for( @reffile ){
        my @refline = split /\t/;
        $refnames{$refline[$si]} = $refline[$va];
    }
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
                        &seekAndDestroy(
                            [%refnames],
                            &binData(
                                &collapseBins('bin', @withMeta),
                                $include_ncbi,
                                [%refnames],
                                @withMeta)));

    if(not $quiet){
        printf "\r%40s%s","Getting BINs in $k...","Ok";

    }

    if($private){
        print "\n";
        @withClass = &upgradeFs( (not $quiet),$k, @withClass );
        printf  "\r%40s%-43s", "Getting whole records in $k...", "Ok";
        print "\n";
    }

    if ($refnamesfile){
        @withClass = &quickVal([%refnames], @withClass);
    }

    &writeOut( $k, $fh, [@metaPos], @withClass);
    print "\n";
}
# print "\n";
close($fh);
