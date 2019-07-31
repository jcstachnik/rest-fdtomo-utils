
use lib "$ENV{ANTELOPE}/data/perl";
use lib "$ENV{HOME}/lib/perl";
use strict; 
use warnings;
my $progname="fdloc2css";
my $lastmodified="Now";

use Datascope;
use POSIX;
use vars qw/%opt/;
&init();
if ($opt{h} ) { # print help message
	&usage();
}
my $verbose=0;
if ($opt{v} ) { # print help message
	$verbose=1;
}
my $dbname;
if (!$opt{d}) {
	die "Need to specify -d, dbname\n";
} else {
	$dbname=$opt{d};
}
my $infile;
if (!$opt{i}) {
	die "Need to specify -i, input file\n";
} else {
	$infile=$opt{i};
}
# 
my $dZch = "HHZ"; # default Z comp for P
if ($opt{P}) {
    $dZch = $opt{P};
}
my $dHch = "HHN"; # default horiz comp for S
if ($opt{S}) {
    $dHch = $opt{S};
}

my @db = dbopen ("$dbname", "r+");
my @dbar=dblookup (@db, 0, "arrival", 0, 0);
my @dbas=dblookup (@db, 0, "assoc", 0, 0);
my @dbor=dblookup (@db, 0, "origin", 0, 0);
my @dboe=dblookup (@db, 0, "origerr", 0, 0);
my @dbev=dblookup (@db, 0, "event", 0, 0);

# YR JDay hr mn sec.msec lat lon depth evid \
#   stdevofres avgwt lat_er lon_er dep_er tot_er 
#2014 339  4 48   5.3685  51.35409   97.79897   0.0000 NOEVID          0.902     7.531  17.5  14.5   2.5  22.9  11   1  12       
#HV02  2014 339  4 48  23.739 P           0.292     -0.386
#HV03  2014 339  4 48  22.809 P           0.268     -0.049
#HV03  2014 339  4 48  40.379*S           1.427      4.720
#HV04  2014 339  4 48  26.329 P           0.273      0.178
#HV07  2014 339  4 48  27.059 P           0.324     -0.670
#HV08  2014 339  4 48  30.979 P           0.330     -0.576
#        write(lunfdt,200) iyr,jday,ihr,imn,sec,xlat,xlon,ezm,evid,stdmin,avfac,
#             +           delx, dely, delz, deld, npuse,nsuse,npuse+nsuse,bflag
#             c200        format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,6x,a10,1x,2f10.3,3i4,1x,a6)
#             200     format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,1x,a10,1x,2f10.3,4f6.1,3i4,1x,a6)
#
sub read_ori_fixed {
    my ($orow) = @_;
#          1         2         3         4         5         6         7         8         9         0         1
#0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
#2014 339  4 48   5.3685  51.35409   97.79897   0.0000 NOEVID          0.902     7.531  17.5  14.5   2.5  22.9  11   1  12       
#200     format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,1x,a10,1x,2f10.3,4f6.1,3i4,1x,a6)
    my $yr=substr($orow,0,4);
    my $jd=substr($orow,4,4);
    my $hr=substr($orow,8,3);
    my $mn=substr($orow,11,3);
    my $sec=substr($orow,14,9);
    my $lat=substr($orow,23,10);
    my $lon=substr($orow,34,10);
    my $dep=substr($orow,44,9);
    my $evid=substr($orow,54,10); #"NOEVID    "
    my $stdobs=substr($orow,65,10);
    my $avwt=substr($orow,75,10);
    my $late=substr($orow,85,6);
    my $lone=substr($orow,91,6);
    my $depe=substr($orow,97,6);
    my $tote=substr($orow,103,6);
    my $np=substr($orow,110,3); # num p
    my $ns=substr($orow,114,3); # num s
    my $nt=substr($orow,118,3); # nass
    return ($yr,$jd,$hr,$mn,$sec,$lat,$lon,$dep,$evid,$stdobs,$avwt,$late,$lone,$depe,$tote,$np,$ns,$nt);
}
sub read_ori_free {
    # read free format, whitespace delimited
    my @row = split(/\s+/,@_);
    #my @row = split(/\s+/,$_);
    my $yr=$row[0];
    my $jd=$row[1];
    my $hr=$row[2];
    my $mn=$row[3];
    my $sec=$row[4];
    my $lat=$row[5];
    my $lon=$row[6];
    my $dep=$row[7];
    my $evid=$row[8];
    my $stdobs=$row[9];
    my $avwt=$row[10];
    my $late=$row[11];
    my $lone=$row[12];
    my $depe=$row[13];
    my $tote=$row[14];
    my $np=$row[15]; # num p
    my $ns=$row[16]; # num s
    my $nt=$row[17]; # nass
    return ($yr,$jd,$hr,$mn,$sec,$lat,$lon,$dep,$evid,$stdobs,$avwt,$late,$lone,$depe,$tote,$np,$ns,$nt);
}

open(I, "<$infile") or die "WTF: $!\n";

#my (@time,@orid,@lat,@lon,@depth,@ml,@evid);
my $row;
my $newblock=1;
my $doarr=0;
my $auth = "fdloc";
my ($orid, $evid);
while (<I>) {
	#next if $.==1;
    #s/^\s+//; # strip leading WS
    #print STDOUT "newblock $newblock doarr $doarr\n";
    #if (/^s*$/) {
    if (/^\s*$/) {
        #print STDOUT "found blank line\n";
        $newblock=1;
        $doarr=0;
        next;
    };
	chomp;
    if ($newblock == 1 && $doarr ==0) {
        my ($yr,$jd,$hr,$mn,$sec,$lat,$lon,$dep,$evid,$stdobs,$avwt,$late,$lone,$depe,$tote,$np,$ns,$nt) = read_ori_fixed($_);
        #my ($yr,$jd,$hr,$mn,$sec,$lat,$lon,$dep,$evid,$stdobs,$avwt,$late,$lone,$depe,$tote,$np,$ns,$nt) = read_ori_free($_);
        #my @row = split(/\s+/,$_);
    	#my $yr=$row[0];
    	#my $jd=$row[1];
    	#my $hr=$row[2];
    	#my $mn=$row[3];
    	#my $sec=$row[4];
    	#my $lat=$row[5];
    	#my $lon=$row[6];
    	#my $dep=$row[7];
    	#my $evid=$row[8];
    	#my $stdobs=$row[9];
    	#my $avwt=$row[10];
    	#my $late=$row[11];
    	#my $lone=$row[12];
    	#my $depe=$row[13];
    	#my $tote=$row[14];
    	#my $np=$row[15]; # num p
    	#my $ns=$row[16]; # num s
    	#my $nt=$row[17]; # nass
        my $mag = -999;
	    my $ostr=sprintf("%d-%03d %d:%d:%.5f", $yr,$jd,$hr,$mn,$sec);
	    my ($otime,$errmsg)=str2epoch($ostr);
	    if ( ! defined $otime ) {
            die ( "Don't recognize time '$ostr':\n\t$errmsg\n" ) ; 
    	}

        #if ($evid eq "NOEVID") {
        if ($evid eq "NOEVID    ") {
            $orid = dbnextid(@dbor,"orid");
        } else {
            $orid = $evid;
        }
        $evid= dbnextid(@dbev,"evid");
        if ($verbose>0) {
            print STDOUT "ORIGIN $ostr $orid $evid $lat $lon $dep\n";
        }
        eval { $dbor[3] = dbaddv ( @dbor,
            "orid", $orid,
            "evid", $evid,
            "time", $otime,
            "lat", $lat,
            "lon", $lon,
            "depth", $dep,
            "ml", $mag,
    		"ndef",$nt,
    		"nass",$nt,
            "auth", $auth) ;
            };
        if ( $@ ne "" ) {
            print STDERR "$@" ;
        };
        eval { $dboe[3] = dbaddv ( @dboe,
            "orid", $orid,
            "smajax", $lone,
            "sminax", $late,
            "sdepth", $depe,
            "stime", $tote,
    		"sdobs", $stdobs);
    		};
        if ( $@ ne "" ) {
            print STDERR "$@" ;
        };
        eval { $dbev[3] = dbaddv ( @dbev,
            "evid", $evid,
    		"prefor", $orid);
    		};
        if ( $@ ne "" ) {
            print STDERR "$@" ;
        };
        $doarr = 1;
        next;
    };
    if ($newblock == 1 && $doarr==1) {
        #my @row = split(/\s+/,$_);
#012345678901234567890123456789012345678901234567890123456
#HV02  2014 339  4 48  23.739 P           0.292     -0.386
        my $arow = $_;
        my $ch;
        my $sta = substr($arow,0,5);
        my $yr = substr($arow,6,4);
        my $jd = substr($arow,11,3);
        my $hr = substr($arow,15,2);
        my $mn = substr($arow,18,2);
        my $sec = substr($arow,22,6);
        if ($sec == 60.000){
            $sec = 0.0;
            $mn += 1;
        }
        my $yn = substr($arow,28,1);
        my $ph = substr($arow,29,1);
        my $deltim = substr($arow,39,7);
        my $tres = substr($arow,50,7);
        my $arid= dbnextid(@dbar,"arid");
	    my $astr=sprintf("%d-%03d %d:%d:%.5f", $yr,$jd,$hr,$mn,$sec);
	    my ($atime,$errmsg)=str2epoch($astr);
	    if ( ! defined $atime ) {
            die ( "Don't recognize time '$astr':\n\t$errmsg\n" ) ; 
    	}
        #print STDOUT "ARRIVAL $sta $arid yn $yn\n";
        if ($ph eq "P"){
            $ch = $dZch;
        } elsif ($ph eq "S") {
            $ch = $dHch;
        }
        eval { $dbar[3] = dbaddv ( @dbar,
            "sta", $sta,
            "arid", $arid,
            "time", $atime,
            "chan", $ch,
            "deltim", $deltim,
            "iphase", $ph) ;
            };
        if ( $@ ne "" ) {
            print STDERR "$@" ;
        }
        if ($yn ne "*" and $yn ne "X") { # dont write assocs for tossed picks
        eval { $dbas[3] = dbaddv ( @dbas,
            "sta", $sta,
            "arid", $arid,
            "orid", $orid,
            "timeres", $tres,
            "phase", $ph) ;
            };
        if ( $@ ne "" ) {
            print STDERR "$@" ;
        }
        } # end yn
        next;
    }

	#if ($verbose>=1) {
	#print STDOUT "  yr = $yr \n";
	#print STDOUT "  mo = $mo \n";
	#print STDOUT "  dy = $dy \n";
	#print STDOUT "  hr = $hr \n";
	#print STDOUT "  mn = $mn \n";
	#print STDOUT "  sc = $sc \n";
	#print STDOUT "ostr = $ostr \n";
	#print STDOUT "otim = $otime \n";
	#print STDOUT "  la = $la \n";
	#print STDOUT "  NS = $NS \n";
	#print STDOUT " lad = $lad \n";
	#print STDOUT " lat = $lat \n";
	#print STDOUT " lon = $lon \n";
	#print STDOUT " dep = $dep \n";
	#print STDOUT " mag = $mag \n";

}

dbclose(@db); 
close(I);

sub init() {
    use Getopt::Std;
    my $opt_string = 'hvi:d:P:S:';
    getopts( "$opt_string", \%opt ) or usage();
    usage() if $opt{h};
}

sub usage() {
print STDOUT << "MEOF";
NAME
\t$progname - Convert fdloc/sphfdloc format event file to css db.

\tlastmodified: $lastmodified

SYNOPSIS
\t$progname [-h|-v] some_input 

DESCRIPTION
\t This script converts an fdloc/sphfdloc format event file
\t to css3.0 database (origin, event, arrival, assoc).
\t
\t 2012 270  2 55   7.7534  50.64556  102.21262   4.1250 NOEVID          
\t HD01  2012 270  2 56   6.950 P           0.694     -0.041
\t HD07  2012 270  2 57  18.560 S           1.495      2.215
\t HD10  2012 270  2 57   3.740 S           1.390     -1.857
\t HD16  2012 270  2 56  51.860 S           1.256      4.919
\t
\t NOTE: Arrivals do not have channels associated with them in 
\t fdloc. Use -P and -S option to change from default.  This 
\t will cause issues for mixed stations with different channel
\t names. 
\t NOTE: Arrivals that are not used in the location are designated
\t with * or X in the field before the phase name.  These picks
\t are kept in the arrival table, but not in the assoc table.

OPTIONS
\t-h print this usage
\t-v spew some debug messages
REQUIRED
\t-d dbname
\t-i  input file
OPTIONAL
\t-P Pchan  Channel name for P waves [HHZ].
\t-S Schan  Channel name for S waves [HHN].

MEOF
die "\n";
}

