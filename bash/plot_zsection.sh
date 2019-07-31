#!/bin/bash
evtfile=fdloc_good.data
# project events within wid km 
hitdir=../Vp-hits
wid=15
plotcont=1
plotscl=1
psa=1.0 # color scale annot level
psf=0.2 # color scale full ticks
# ---------------------------------------------------

ARGS=2

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` filename parfile "
    echo " filename: zsection.100.000"
    echo " parfile: ../Vpzsection.par "
    echo " Example: `basename $0` zsection.100.000 Vpzsection.par"
    exit
fi

infil=$1
parfile=$2
source $parfile
outps=${infil}.ps

# TODO: check for empty required variables
pvars=( evtfile wid hitdir vmin vmax vinc vlab cont1 cont2 \
 topogrd stafile plotcont plotscl psa psf R J )
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
echo "INFO: using events in $evtfile"
echo "INFO: Looking for hit counts in dir $hitdir..."
echo "INFO: Output file will be something like $outps, but a pdf"
# ---------------------------------------------------
if [ ! -f $infil ]; then
    echo "ERROR: $infil does not exist"
    exit 0
fi

z=`echo $infil | awk -F. '{printf "%.1f", $1+$2}'`

# ---------------------------------------------
# number of nodes (points)
nval=`awk 'NR==2 {print $1*$2}' $infil`
nval2=`awk 'NR==2 {print ($1*$2)+2}' $infil`

# extract node coordinates
awk 'NR>2' $infil | head -${nval} | awk '{print $2,$1}' > xy.txt

# extract values at node coordinates
awk 'NR>n' n=$nval2 $infil > vals.txt
paste xy.txt vals.txt > xyv.txt

# increment in x,y direction, assuming values are increasing
# out to 2 decimal points
xinc=`awk '{print $1}' xy.txt | sort -n -u | awk 'NR<3 {printf "%f ", $1}' | awk 'function abs(x){return ((x < 0.0) ? -x : x)} {printf "%.2f", abs($1-$2)}'`
yinc=`awk '{print $2}' xy.txt | sort -n -u | awk 'NR<3 {printf "%f ", $1}' | awk 'function abs(x){return ((x < 0.0) ? -x : x)} {printf "%.2f", abs($1-$2)}'`

# Automatically determine map plot bounds
bds=(`gmtinfo -C xy.txt | awk '{printf "%.2f %.2f %.2f %.2f", $1,$2,$3,$4}'`)
axmn=${bds[0]}
axmx=${bds[1]}
aymn=${bds[2]}
aymx=${bds[3]}

bbs=(`echo "$R" | sed 's/-R//' | awk -F/ '{print $1,$2,$3,$4}'`)
xmn=${bbs[0]}
xmx=${bbs[1]}
ymn=${bbs[2]}
ymx=${bbs[3]}

#J=-JM4i
#R=-R${xmn}/${xmx}/${ymn}/${ymx}
#R=-R${bds[0]}/${bds[1]}/${bds[2]}/${bds[3]}
cpt=v.cpt
#makecpt -Cseis -Do -T$vmin/$vmax/$vinc > $cpt
makecpt -Cpolar -Do -I -T$vmin/$vmax/$vinc > $cpt

surface xyv.txt $R -I${xinc}/${yinc} -Gv.grd
grdimage v.grd $J $R -C$cpt -Bpxf1a1 -Bpyf1a1 -BWSen -Y1.0i -P -K > $outps
#grdimage v.grd $J $R -Crainbow -Bpxf1a1 -Bpyf1a1 -BWSen -P -K > $outps
pscoast $J $R -Dh -S -Na/1p,black -W2/3p,black -O -K >> $outps

if [ "$plotscl" -eq 1 ]; then
    psscale $J $R -DjCB+w4i/0.1i+o0/-1.0i+h+m+e \
    -Bpxa${psa}f${psf}+l"$vlab" \
    -C$cpt -O -K >> $outps
fi

if [ "$plotcont" -eq 1 ]; then
    grdcontour v.grd $J $R -C$cont1 -A$cont2 -O -K >> $outps
else
    echo "INFO: Not plotting contours"
fi

echo "$xmn $ymn Z=$z km" |\
 pstext $J $R -F+f10p+a0+jBL -D0/.1 -O -K -Gwhite >> $outps

if [ -f $stafile ]; then
    awk '{print $6,$5}' $stafile | psxy $J $R -St0.15 -O -K >> $outps
else
    echo "WARNING: Cannot find $stafile, not plotting stations"
fi
if [ -f $evtfile ]; then
    z1=`echo "$z - $wid" | bc -lq`
    z2=`echo "$z + $wid" | bc -lq`
    # there should be a better way
    awk '($1==2012 || $1==2013 || $1==2014 || $1==2015 || $1==2016) && ($8>=za && $8<=zb) {print $7,$6}' za=$z1 zb=$z2 $evtfile |\
     psxy $J $R -Sc0.05 -Gwhite -Wblack -O -K >> $outps
else
    echo "WARNING: Cannot find $evtfile, not plotting events"
fi
# ------------------------
hf=$hitdir/zsection.${z}
if [ -f $hf ]; then
    # number of nodes (points)
    nval=`awk 'NR==2 {print $1*$2}' $hf`
    nval2=`awk 'NR==2 {print ($1*$2)+2}' $hf`
    # extract node coordinates
    awk 'NR>2' $hf | head -${nval} | awk '{print $2,$1}' > xy.txt
    # extract values at node coordinates
    awk 'NR>n' n=$nval2 $hf > vals.txt
    paste xy.txt vals.txt > hitsxyv.txt
    pscontour hitsxyv.txt $J $R -C+10 -W1p,white -O -K >> $outps
else
    echo "WARNING: Cannot find $hf, Not plotting hitcount contour"
fi
# ------------------------

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps 
#/bin/rm v.grd xyv.txt xy.txt vals.txt

