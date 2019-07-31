#!/bin/bash

ARGS=3

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` filename evtfile phs"
    echo " filename: xsection.100.000"
    echo " evtfile: ../bwo/mong_goog.data "
    echo " phs: [Vp,Vs,VpVs] "
    echo " Example: `basename $0` xsection.100.000 mong_good.data Vp"
    exit
fi

infil=$1
evtfile=$2
# project events within wid km 
wid=15
phs=$3 # 0=Vp,1=Vs,2=Vp/Vs
case $phs in
"Vp")
    vmin=5.5
    vmax=8.4
    vinc=0.05
    ;;
"Vs")
    vmin=3.2
    vmax=4.8
    vinc=0.02
    ;;
"VpVs")
    vmin=1.60
    vmax=2.00
    vinc=0.01
    ;;
"TT")
    vmin=0.0
    vmax=80.0
    vinc=1.00
    ;;
esac
hitdir=../${phs}-hits
echo "Looking for hit counts in dir $hitdir..."

# ---------------------------------------------------

# Either x or y coordinate of cross section (100.400)
# assumes file is something like xsection.100.400 or ysection.54.000 
c1=`echo $infil | awk -F. '{printf "%d.%03d", $2,$3}'`
# number of nodes (points)
nval=`awk 'NR==2 {print $1*$2}' $infil`
nval2=`awk 'NR==2 {print ($1*$2)+2}' $infil`
# extract node coordinates
awk 'NR>2' $infil | head -${nval} | awk '{print $2,$1}' > xy.txt
# extract values at node coordinates
awk 'NR>n' n=$nval2 $infil > vals.txt
paste xy.txt vals.txt > xyv.txt

# determine increment in x,y direction, 
# assuming values are increasing out to 2 decimal points
xinc=`awk '{print $1}' xy.txt | sort -n -u | awk 'NR<3 {printf "%f ", $1}' | awk 'function abs(x){return ((x < 0.0) ? -x : x)} {printf "%.2f", abs($1-$2)}'`
yinc=`awk '{print $2}' xy.txt | sort -n -u | awk 'NR<3 {printf "%f ", $1}' | awk 'function abs(x){return ((x < 0.0) ? -x : x)} {printf "%.2f", abs($1-$2)}'`

# Bounds on original file
bds=(`gmtinfo -C xy.txt | awk '{printf "%.2f %.2f %.2f %.2f", $1,$2,$3,$4}'`)
xmn=${bds[0]}
xmx=${bds[1]}
#ymn=${bds[2]}
#ymx=${bds[3]}
ymn=-2
ymx=80

# Set up coords of end points
lo0=$c1
lo1=$c1
la0=${bds[0]}
la1=${bds[1]}

# Create file of projected coords:
# x y z val km
# if xsection.??, then x=lon y=lat
# if ysection.??, then x=lat y=lon
awk '{print c,$1,$2,$3}' c=$c1 xyv.txt |\
 project -C$lo0/$la0 -E$lo0/$la1 -Fxyzp -Q > xyzvkm.txt
# Roughly convert degrees to km
awk '{print ($1-x)*111.195, $2,$3}' x=$xmn xyv.txt > kmyv.txt

#J=-JX5i/-5i
#R=-R${xmn}/${xmx}/${ymn}/${ymx}

# Bounds on converted dims
bds2=(`gmtinfo -C kmyv.txt | awk '{printf "%.2f %.2f %.2f %.2f", $1,$2,$3,$4}'`)
xmn2=${bds2[0]}
xmx2=${bds2[1]}
ymn2=${bds2[2]}
ymx2=60

# Try to make 1:1 scaling
maxdim=5 # max inches in either axis
ydim=`echo "${maxdim}/(${ymx2}-(${ymn2}))" | bc -lq`
xdim=`echo "${maxdim}/(${xmx2}-(${xmn2}))" | bc -lq`
scl=0.01 # in/km
scl=$xdim
J=-Jx${scl}/-${scl}
#J=-JX5i/-3i
R=-R0/${bds2[1]}/${ymn}/${ymx}

outps=${infil}.ps
cpt=v.cpt
inc=0.05
makecpt -Cseis -T$vmin/$vmax/$inc > $cpt

# Use the Lon or Lat as X-axis
#surface xyv.txt $R -I${xinc}/${yinc} -Gv.grd
#grdimage v.grd $J $R -Crainbow -Bpxf1a1 -Bpyf1a1 -BWSen -P -K > $outps

parms="--FONT_LABEL=10p"
# Use distance (km) as X-axis
surface kmyv.txt $R -I1/${yinc} -Gv.grd
grdimage v.grd $J $R -C$cpt \
 -Bpxf20a100+l"Distance (km) along $infil" \
 -Bpyf5a20+lkm \
 -BWeN \
 $parms -P -K > $outps

#grdcontour v.grd $J $R -C0.2 -O -K >> $outps
psscale -J -R -DjCB+w4i+o0.01i/-1.0i+h -C$cpt -Bpxa1f0.2 -By+l"km/s" -O -K >> $outps
pscontour kmyv.txt -W1p $J $R -C0.2 -O -K >> $outps
pscontour kmyv.txt -W1p $J $R -C1.0 -Wc2p -O -K >> $outps
if [ -f $evtfile ]; then
    awk '$1==2014 || $1==2015 || $1==2016 {print $7,$6,$8}' $evtfile |\
     project -C$lo0/$la0 -E$lo0/$la1 -Fpz -Q -W-${wid}/${wid} |\
     psxy $J $R -Sc0.03 -Gwhite -Wblack -O -K >> $outps
fi

hitfile=${hitdir}/hits_xsection.${c1}.xyzvkm
if [ -f $hitfile ]; then
    awk '{print $5,$3,$4}' ${hitfile} |\
     pscontour $J $R -C+10 -W1p,white -O -K >> $outps
fi

psbasemap -JX${maxdim}i/1i -R${xmn}/${xmx}/${ymn}/${ymx} \
 -Bpxf0.2a1.0+l"Latitude" -BS \
 --FONT_LABEL=6p --FONT_ANNOT_PRIMARY=6p \
 -O -K -Y-0.1i >> $outps

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps 
#/bin/rm v.grd vals.txt xyv.txt xy.txt kmyv.txt
