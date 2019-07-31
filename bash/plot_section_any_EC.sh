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
plotcont=1
plotscl=1
psa=1.0 # color scale annot level
psf=0.2 # color scale full ticks
ischeck=0 # set to 1 if checkerboard to use xyz2grd
sgrd=/data/TOPO/Slab1.0/sam_slab1.0_clip.grd # slab1.0 grd
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
 topogrd stafile xy pymn pymx )
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

# assumes file is something like 
# THIS FOR OBLIQUE
# xsection_la1_lo1_la2_lo2
# xsection_1.0_-81.0_-0.3_-79.0
la0=`echo $infil | awk -F_ '{print $2}'`
lo0=`echo $infil | awk -F_ '{print $3}'`
la1=`echo $infil | awk -F_ '{print $4}'`
lo1=`echo $infil | awk -F_ '{print $5}'`
echo "$la0 $lo0 $la1 $lo1"
# THIS FOR OBLIQUE
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
# this for X,Y only
xinckm=`echo "$xinc*100" | bc -lq`

# Bounds on original file
bds=(`gmtinfo -C xy.txt | awk '{printf "%.2f %.2f %.2f %.2f", $1,$2,$3,$4}'`)
xmn=${bds[0]}
xmx=${bds[1]}
iymn=${bds[2]}
iymx=${bds[3]}

# Set up coords of end points
# make a lon,lat file for coords along the projection line
#project -C$lo0/$la0 -E$lo1/$la1 -G0.01 > proj.line
#project -C$lo0/$la0 -E$lo1/$la1 -Q -G1 > proj.line
project -C$lo0/$la0 -E$lo1/$la1 -Q -G1 | awk '{print $1,$2,x+$3}' x=$xmn > proj.line
hinfil=hit_${infil}
# extract hits values at node coordinates
awk 'NR>n' n=$nval2 $hinfil > hvals.txt
paste xy.txt hvals.txt > xyh.txt
hitfile=xyh.txt

# extract km y v to plot
#awk '{print $5,$3,$4}' xyzvkm.txt > kmyv.txt

cp xyv.txt kmyv.txt

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
R=-R${xmn}/${xmx2}/${pymn}/${pymx}
# should be length of xaxis in inches
xinch=`echo "(${xmx2} - (${xmn2})) * $scl" | bc -lq`
yinch=`echo "(${pymx} - (${pymn})) * $scl" | bc -lq`

# Create projectionline for topo,slab track
#project -C$lo0/$la0 -E$lo1/$la1 -Q -G1 > proj.line

# Color palette
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
Bpx=(-Bpxf20a100+lkm)
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
if [ -f $sgrd ]; then
    awk '{print $1+360,$2,$3}' proj.line |\
     grdtrack -sa -G$sgrd | awk '{printf "%0.4f\t%0.4f\n",$3,$4*-1}' > slab.xy
     psxy $J $R slab.xy -Wthin,black,---- -O -K >> $outps
fi
if [ -f $evtfile ]; then
    awk '$1==2012 || $1==2013 || $1==2014 || $1==2015 || $1==2016 {print $7,$6,$8}' $evtfile |\
     project -C$lo0/$la0 -E$lo1/$la1 -Fpz -Q -W-${wid}/${wid} |\
     awk '{print x+$1,$2}' x=$xmn |\
     psxy $J $R -Sc0.03i -Gwhite -Wblack -O -K $parms >> $outps
else
    echo "WARNING: No events: Cannot find $evtfile"
fi

if [ -f $hitfile ]; then
#    awk '{print $1,$2,$3,$4}' ${hitfile} |\
#    project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q |\
#    awk '{print $5,$3,$4}' |\
#     pscontour $J $R -C+10 -W1p,white -O -K $parms >> $outps
    awk '{print $1,$2,$3}' $hitfile |\
     pscontour $J $R -C+10 -W1p,white -O -K $parms >> $outps

#    awk '{print $5,$3,$4}' ${hitfile} |\
#     pscontour $J $R -C+10 -W1p,white -O -K >> $outps
else
    echo "WARNING: No hits: Cannot find $hitfile"
fi

if [ -f $topogrd ]; then

# Create the topo track along projection line
yo=`echo "$yinch + 0.1" | bc -lq`
#tymn=0
tymn=-4
grdtrack proj.line -G$topogrd | awk '{print $3,$4/1000}' > topo1.xy
echo "0 -6" | cat - topo1.xy > topo2.xy
echo "$xmx2 -6" >> topo2.xy
mv topo2.xy topo1.xy
psbasemap -JX${xinch}i/0.3i -R${xmn2}/${xmx2}/$tymn/4 \
 -Bpyf0.5a2 -BW \
 -O -K -Y${yo}i \
 --FONT_ANNOT_PRIMARY=6p \
 --PROJ_LENGTH_UNIT=in >> $outps
psxy -JX${xinch}i/0.3i -R${xmn2}/${xmx2}/$tymn/4 -G135/206/250 -N -O -K <<EOF >> $outps
0 0
$xmx2 0
$xmx2 -6
0 -6
EOF
psxy topo1.xy -JX${xinch}i/0.3i -R${xmn2}/${xmx2}/$tymn/4 -G210 -N -O -K >> $outps
psxy topo1.xy -JX${xinch}i/0.3i -R${xmn2}/${xmx2}/$tymn/4 -Wthin,black -N -O -K >> $outps

#grdtrack proj.line -G$topogrd | awk '{print $3,$4/1000}' |\
# psxy -JX${xinch}i/0.3i -R0/${xmx2}/$tymn/4 -W1p \
# -Bpyf0.5a2 -BW \
# -N -O -K -Y${yo}i \
# --FONT_ANNOT_PRIMARY=6p \
# --PROJ_LENGTH_UNIT=in >> $outps

else
    echo "WARNING: $topogrd does not exist"
fi

if [ -f $stafile ]; then
    awk '{print $6,$5,$3,$4}' $stafile |\
    project -C$lo0/$la0 -E$lo1/$la1 -Q -W-20/20 -Fpz |\
    awk '{print x+$1,$2/1000}' x=$xmn |\
    psxy -JX${xinch}i/0.3i -R${xmn2}/${xmx2}/$tymn/4 -St0.1i \
    -Gblack -O -K -N $parms >> $outps
fi

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps 
#/bin/rm v.grd vals.txt xyv.txt xy.txt kmyv.txt

# make a quick map with the cross section line.
bds=-R-83/-75/-5/2
scl=-JM7
psxy proj.line $bds $scl -W2p -B2 -P -K > map.ps
awk '{print $6,$5,$3,$4}' $stafile |\
 psxy $bds $scl -St0.1i -O -K >> map.ps
pscoast $bds $scl -O -Di -N1/1p,black -W1/1p,black >> map.ps
psconvert -A -Tf map.ps
/bin/rm map.ps
