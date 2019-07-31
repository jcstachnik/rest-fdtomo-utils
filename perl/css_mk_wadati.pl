# Calculate wadati diagrams for data in km

use lib "$ENV{ANTELOPE}/data/perl";
use lib "$ENV{HOME}/lib/perl";
use strict;
use warnings;
my $progname="css_mk_wadati";
my $lastmodified="Now";


use Datascope;
use POSIX;
use vars qw/%opt/;
&init();
if ($opt{h} ) { # print help message
        &usage();
}
my $dbname;
if (!$opt{d}) {
        die "Need to specify -d, dbname\n";
} else {
        $dbname=$opt{d};
}
my $outfile;
if (!$opt{o}) {
        die "Need to specify -o, output file \n";
} else {
        $outfile=$opt{o};
}
my $subset="";
if ($opt{s}) {
    $subset=qq($opt{s});
}

# ---------------------------------
my @db = dbopen ("$dbname", "r+");
my @dbtemp=dbprocess(@db, "dbopen origin",
                "dbjoin event",
                "dbsubset origin.orid==prefor",
                "dbsubset $subset",
               "dbsort time");

my $Norids=dbquery(@dbtemp,"dbRECORD_COUNT");
print "$Norids orids in db $dbname for subset $subset \n";

open(O,">$outfile") or die "$!: $outfile\n";
my (@time,@orid,@lat,@lon,@depth,@ml,@evid);
my ($p,$s,$sta);
#$Norids=12;
for ($dbtemp[3]=0; $dbtemp[3] < $Norids; $dbtemp[3]++) {
    my $outorigin="";
    my ($otime,$o,$lt,$ln,$dep,$ml,$evid)= dbgetv(@dbtemp,qw(time orid lat lon depth ml evid));
    my $osub=sprintf("orid==%d",$o);
    my @dbar=dbprocess(@dbtemp, "dbsubset $osub",
                                "dbjoin assoc",
                                "dbjoin arrival",
                                "dbsort sta iphase");
    #my $arsub=sprintf("arrival.time-origin.time<100.");
    my $psub=sprintf("arrival.iphase=~/P.*/");
    my @dbsubP=dbprocess(@dbar, "dbsubset $psub");

    my $narp=dbquery(@dbsubP, "dbRECORD_COUNT");
    #print "$narp P arrivals for $osub\n";
    for ($dbsubP[3] = 0 ; $dbsubP[3] < $narp; $dbsubP[3]++ ) {
        $sta = dbgetv(@dbsubP,qw(sta));
        my @dbsubS = dbsubset(@dbar,"sta == '$sta' && iphase =~ /S.*/" );
        $dbsubS[3]=0;
        my $nars = dbquery(@dbsubS, qw(dbRECORD_COUNT));
        if ($nars == 1) {
            $p = dbgetv(@dbsubP,qw(arrival.time)) -$otime;
            $s = dbgetv(@dbsubS,qw(arrival.time))- $otime;
            printf O "%s %.3f %.3f\n", $sta, $p, $s-$p;
        }
    }
}


dbclose(@db);
close($outfile);

###############################################################

sub init() {
    use Getopt::Std;
    my $opt_string = 'hvo:d:s:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
}

sub usage() {
print STDOUT << "EOF";
NAME
\t$progname - Create a wadati file

\tlastmodified: $lastmodified

SYNOPSIS
\t$progname [-h|-v] some_input 

\t$progname -d hvsub -o hvsub-m1.txt -s \"ml>=1.0\"

DESCRIPTION
\t Create file for determining Vp/VS from Wadati diagram.
\t TODO: Add subsets applied to assoc/arrival table,
\t including distance cutoff.

OPTIONS
\t-h print this usage
\t-v spew some debug messages
\t-d dbname
\t-o output file
\t-s subset on origin-event join

EOF
die "\n";
}

