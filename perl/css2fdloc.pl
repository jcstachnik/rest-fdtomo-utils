
use lib "$ENV{ANTELOPE}/data/perl";
use lib "$ENV{HOME}/lib/perl";
use strict; 
use warnings;
my $progname="css2fdloc";
my $lastmodified="01Jul2019";

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
my $outcnv;
if (!$opt{o}) {
	die "Need to specify -o, output FDLOC file\n";
} else {
	$outcnv=$opt{o};
}
my $subset="";
if ($opt{s}) {
	#$subset=$opt{s};
	$subset=qq($opt{s});
}

my @db = dbopen ("$dbname", "r+");
my @dbtemp=dbprocess(@db, "dbopen origin",
				"dbjoin event",
				"dbsubset prefor==origin.orid",
				"dbsubset $subset",
		       "dbsort time");
#				"dbsubset ml>=2.0",

my $Norids=dbquery(@dbtemp,"dbRECORD_COUNT");
print "orids in db: $dbname $Norids\n";

open(O,">$outcnv") or die "$!: $outcnv\n";
my (@time,@orid,@lat,@lon,@depth,@ml,@evid);
#$Norids=12;
for ($dbtemp[3]=0; $dbtemp[3] < $Norids; $dbtemp[3]++) {
	my $outorigin="";
    my ($ot,$o,$lt,$ln,$dep,$ml,$evid)= dbgetv(@dbtemp,qw(time orid lat lon depth ml evid));
	my $ostr=epoch2str($ot, "%y %j %H %M %S");
	my $yr=epoch2str($ot, "%Y");
	my $jd=epoch2str($ot, "%j");
	my $H=epoch2str($ot, "%H");
	my $M=epoch2str($ot, "%M");
	my $S=epoch2str($ot, "%S");
	#my $msec=substr(epoch2str($ot, "%s"),0,2);
	#note this truncates to 3 digits
	my $msec=epoch2str($ot, "%s");
	my $ss=$S+($msec/1000);
	#print STDOUT "orid: $o $yr $jd $H $M $S $msec $ss \n";
	$outorigin.=sprintf ("%4d%4d%3d%3d%9.4f%10.5f %10.5f%9.4f      %s\n", $yr, $jd, $H, $M, $ss, $lt, $ln, $dep, $o); 

	my $osub=sprintf("orid==%d",$o);
	my @dbar=dbprocess(@dbtemp, "dbsubset $osub",
								"dbjoin assoc",
								"dbjoin arrival",
								"dbsort sta iphase");
	#my $arsub=sprintf("arrival.time-origin.time<100.");
	my $arsub=sprintf("arrival.iphase=~/P|S/");
	@dbar=dbprocess(@dbar, "dbsubset $arsub");

	my $nars=dbquery(@dbar, "dbRECORD_COUNT");

	#print STDOUT "$nars Arrivals ot=$ot $ostr \n";
#    2   read(lunleq,101) sta(nsta), iyr, jday, ihr, imn, sec, usemark,
#    +      phs(nsta), rwt
#    c101    format(a6,2i4,2i3,f8.3,1x,a1,8x,f8.3)
#    101 format(a6,2i4,2i3,f8.3,a1,a1,8x,f8.3)
#
#    2013  19 18 59  30.0461  -3.03001   35.86095  10.0000                
#    MW36  2013  19 18 59  33.269 P           0.100           3.223
#    MW36  2013  19 18 59  35.631 S           0.400           5.585
#    MW43  2013  19 18 59  34.087 P           0.100           4.041

	my $outarrivals="";
	for ($dbar[3]=0; $dbar[3] < $nars; $dbar[3]++) {
		#my ($st,$ch,$phas,$at,$snr,$wgt,$res)=dbgetv(@dbar,qw(sta chan assoc.phase arrival.time snr wgt timeres));
		my ($st,$ch,$phas,$at,$snr,$wgt,$res)=dbgetv(@dbar,qw(sta chan assoc.phase arrival.time snr deltim timeres));
	    my $ayr=epoch2str($at, "%Y");
    	my $ajd=epoch2str($at, "%j");
    	my $aH=epoch2str($at, "%H");
    	my $aM=epoch2str($at, "%M");
    	my $aS=epoch2str($at, "%S");
    	#my $amsec=substr(epoch2str($at, "%s"),0,2);
    	my $amsec=epoch2str($at, "%s");
    	my $ass=$aS+($amsec/1000);
        my $phs = substr($phas,0,1);
        # here, wgt is the pick uncer. 
        # deltim null is -1.000
        my $deltim = 0.1; 
        if ($wgt == -1.000) {
            if ($phs =~ "P") {
                $deltim = 0.1;
            } else {
                $deltim = 0.4;
            }
        } else {
            $deltim = $wgt;
        }

		#print STDOUT "$o sta: $st $ayr $ajd $aH $aM $aS $amsec $ass \n";
        # timeres null is -999.000, write it to outfile if exists in db
        if ($res == -999.000) {
    		$outarrivals.=sprintf ("%-6s%4d%4d%3d%3d%8.3f %1s        %8.3f\n", $st, $ayr, $ajd, $aH, $aM, $ass, $phs, $deltim);
        } else {
    		$outarrivals.=sprintf ("%-6s%4d%4d%3d%3d%8.3f %1s        %8.3f%8.3f\n", $st, $ayr, $ajd, $aH, $aM, $ass, $phs, $deltim, $res);
        }
	}
    print O "$outorigin$outarrivals\n";
}

dbclose(@db); 
close(O);

sub init() {
    use Getopt::Std;
    my $opt_string = 'hvo:d:s:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
}

sub usage() {
print STDOUT << "MEOF";
NAME
\t$progname - Create a fdloc format event file

\tlastmodified: $lastmodified

SYNOPSIS
\t$progname [-h|-v] some_input 

\t$progname -d hvsub -o hvsub-m1.fdloc -s \"ml>=1.0\"

DESCRIPTION
\t Create fdloc format event file

OPTIONS
\t-h print this usage
\t-v spew some debug messages
\t-d dbname
\t-o  output FDLOC file
\t-s subset on origin-event join

MEOF
die "\n";
}

