#!/bin/bash

# ---------------------------------------------------
evtfile=fdloc_good.data
# project events within wid km 
# Plotting Y mn and mx (read from par)
pymn=-2
pymx=70
hitdir=../Vp-hits
wid=15
xy=X
proj0=49.4
proj1=52.5
plotcont=1
plotscl=1
psa=1.0 # color scale annot level
psf=0.2 # color scale full ticks
ischeck=0 # set to 1 if checkerboard to use xyz2grd
# ---------------------------------------------------

ARGS=2

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` filename parfile "
    echo " filename: xsection.100.000"
    echo " parfile: ../Vpxsection.par "
    echo " Example: `basename $0` xsection.100.000 Vpxsection.par"
    exit
fi

infil=$1
parfile=$2
source $parfile
outps=${infil}.ps

if [ ! -f $infil ]; then
    echo "$infil Not found. Exit"
    exit
fi
# ---------------------------------------------------
# TODO: check for empty required variables
pvars=(evtfile wid hitdir vmin vmax vinc vlab cont1 cont2 \
 topogrd stafile xy pymn pymx proj0 proj1 )
np=`echo "${#pvars[@]}-1" | bc -lq`
for i in `seq 0 $np`
do
    v=${pvars[$i]}
    if [ -z "${!v}" ]; then
        echo "ERROR: variable ${v} not set in parfile"
        exit 0
    fi
done
# ---------------------------------------------------
echo "INFO: Using input $infil"
echo "INFO: Using events in $evtfile"
echo "INFO: Looking for hit counts in dir $hitdir..."
echo "INFO: Output file will be something like $outps, but a pdf"
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
xinckm=`echo "$xinc*100" | bc -lq`

# Bounds on original file
bds=(`gmtinfo -C xy.txt | awk '{printf "%.2f %.2f %.2f %.2f", $1,$2,$3,$4}'`)
xmn=${bds[0]}
xmx=${bds[1]}
iymn=${bds[2]}
iymx=${bds[3]}

# Set up coords of end points
case $xy in
"X")
    lo0=$c1
    lo1=$c1
    la0=$proj0
    la1=$proj1
    llab=Latitude
    # endpoint of line in km
    mxkm=`echo "$lo1 $la1 1" | project -C$lo0/$la0 -E$lo1/$la1 -Fp -Q`
    awk '{print c,$1,$2,$3}' c=$c1 xyv.txt |\
     project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q |\
     awk '$5>=0 && $5<=m' m=$mxkm > xyzvkm.txt
    hitfile=${hitdir}/hits_xsection.${c1}.xyzvkm
    ;;
"Y")
    la0=$c1
    la1=$c1
    lo0=$proj0
    lo1=$proj1
    llab=Longitude
    # endpoint of line in km
    mxkm=`echo "$lo1 $la1 1" | project -C$lo0/$la0 -E$lo1/$la1 -Fp -Q`
    awk '{print $1,c,$2,$3}' c=$c1 xyv.txt |\
     project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q |\
     awk '$5>=0 && $5<=m' m=$mxkm > xyzvkm.txt
    hitfile=${hitdir}/hits_ysection.${c1}.xyzvkm
    ;;
esac


# endpoint of line in km
#mxkm=`echo "$lo1 $la1 1" | project -C$lo0/$la0 -E$lo1/$la1 -Fp -Q`
# Create file of projected coords:
# x y z val km
# if xsection.??, then x=lon y=lat
# if ysection.??, then x=lat y=lon
# This just projects the coords to new endpoints,
# still contains the whole model
#awk '{print c,$1,$2,$3}' c=$c1 xyv.txt |\
# project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q > xyzvkm.txt

#awk '{print c,$1,$2,$3}' c=$c1 xyv.txt |\
# project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q |\
# awk '$5>=0 && $5<=m' m=$mxkm > xyzvkm.txt

# extract km y v to plot
awk '{print $5,$3,$4}' xyzvkm.txt > kmyv.txt

# Bounds on converted dims to plot
bds2=(`gmtinfo -C kmyv.txt | awk '{printf "%.2f %.2f %.2f %.2f", $1,$2,$3,$4}'`)
xmn2=${bds2[0]}
xmx2=${bds2[1]}
ymn2=${bds2[2]}

# Try to make 1:1 scaling
maxdim=5 # max inches in either axis
ydim=`echo "${maxdim}/(${pymx}-(${pymn}))" | bc -lq`
xdim=`echo "${maxdim}/(${xmx2}-(${xmn2}))" | bc -lq`
scl=0.01 # in/km
scl=$xdim
J=-Jx${scl}/-${scl}
#J=-JX5i/-3i
R=-R0/${xmx2}/${pymn}/${pymx}
# should be length of xaxis in inches
xinch=`echo "${xmx2} * $scl" | bc -lq`
yinch=`echo "(${pymx} - (${pymn})) * $scl" | bc -lq`

cpt=v.cpt
#makecpt -Cseis -Do -T$vmin/$vmax/$vinc > $cpt
makecpt -Cpolar -Do -I -T$vmin/$vmax/$vinc > $cpt

parms="--FONT_LABEL=8p --FONT_ANNOT_PRIMARY=8p --PROJ_LENGTH_UNIT=in"
# Use distance (km) as X-axis
if [ "$ischeck" -eq 1 ]; then
    xyz2grd kmyv.txt $R -I${xinckm}/${yinc} -Gv.grd
else
    surface kmyv.txt $R -I1/${yinc} -Gv.grd
fi
#Bpx=(-Bpxf20a100+l"Distance (km) along $infil")
Bpx=(-Bpxf20a100)
grdimage v.grd $J $R -C$cpt \
 "${Bpx[@]}" \
 -Bpyf5a20+lkm \
 -BWSe \
 $parms -P -K > $outps

if [ "$plotscl" -eq 1 ]; then
    #psscale $J $R -DjCB+w4i+o0.01i/-1.0i+h -C$cpt -Bpxa1f0.2 -By+l"km/s" -O -K >> $outps
    psscale $J $R -DjBL+w-${yinch}i/0.1i+o${xinch}i/-0.0i+e \
     -C$cpt -Bpxa${psa}f${psf}+l"$vlab" \
     --FONT_LABEL=8p --FONT_ANNOT_PRIMARY=8p \
     -O -K >> $outps

else
    echo "INFO: Not plotting color scale"
fi

if [ "$plotcont" -eq 1 ]; then
    pscontour kmyv.txt -W1p $J $R -C${cont1} -O -K $parms >> $outps
    pscontour kmyv.txt -W1p $J $R -C${cont2} -Wc2p -O -K $parms >> $outps
else
    echo "INFO: Not plotting contour lines"
fi
if [ -f $evtfile ]; then
    awk '$1==2012 || $1==2013 || $1==2014 || $1==2015 || $1==2016 {print $7,$6,$8}' $evtfile |\
     project -C$lo0/$la0 -E$lo1/$la1 -Fpz -Q -W-${wid}/${wid} |\
     psxy $J $R -Sc0.03i -Gwhite -Wblack -O -K $parms >> $outps
else
    echo "WARNING: No events: Cannot find $evtfile"
fi

if [ -f $hitfile ]; then
    awk '{print $1,$2,$3,$4}' ${hitfile} |\
    project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q |\
    awk '{print $5,$3,$4}' |\
     pscontour $J $R -C+10 -W1p,white -O -K $parms >> $outps

#    awk '{print $5,$3,$4}' ${hitfile} |\
#     pscontour $J $R -C+10 -W1p,white -O -K >> $outps
else
    echo "WARNING: No hits: Cannot find $hitfile"
fi

# Create simple axis for lat/lon display
Bpx=(-Bpxf0.2a1.0+l"km ($llab) along $infil")
psbasemap -JX${xinch}i/1i -R${proj0}/${proj1}/${pymn}/${pymx} \
 "${Bpx[@]}" -BS \
 --FONT_LABEL=8p --FONT_ANNOT_PRIMARY=6p \
 --PROJ_LENGTH_UNIT=in \
 -O -K -Y-0.3i >> $outps

if [ -f $topogrd ]; then

# Create projectionline for topo track
yo=`echo "$yinch + 0.3 + 0.1" | bc -lq`
project -C$lo0/$la0 -E$lo1/$la1 -Q -G1 > proj.line
grdtrack proj.line -G$topogrd | awk '{print $3,$4/1000}' |\
 psxy -JX${xinch}i/0.3i -R0/${xmx2}/0/4 -W1p \
 -Bpyf0.5a2 -BW \
 -O -K -Y${yo}i \
 --FONT_ANNOT_PRIMARY=6p \
 --PROJ_LENGTH_UNIT=in >> $outps

else
    echo "WARNING: $topogrd does not exist"
fi

if [ -f $stafile ]; then
    awk '{print $6,$5,$3,$4}' $stafile |\
    project -C$lo0/$la0 -E$lo1/$la1 -Q -W-20/20 -Fpz |\
    awk '{print $1,$2/1000}' |\
    psxy -JX${xinch}i/0.3i -R0/${xmx2}/0/4 -St0.1i \
    -Gblack -O -K $parms >> $outps
fi

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps 
#/bin/rm v.grd vals.txt xyv.txt xy.txt kmyv.txt
