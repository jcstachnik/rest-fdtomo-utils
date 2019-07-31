#!/bin/bash

ARGS=1


if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` inputfile"
    echo " Example: `basename $0` fdloc-wadati"
    exit
fi

infil=$1

outps=wadati_plot.ps
J=-JX4i
xmn=0
xmx=50
ymn=0
ymx=50
R=-R$xmn/$xmx/$ymn/$ymx
Bpx=(-Bpxf5a10+l"Tp (sec)")
Bpy=(-Bpyf5a10+l"Ts-Tp (sec)")
B=(-BWSen)

awk '{print $2,$3}' $infil |\
 psxy $J $R -Sc0.03 -Gblack \
 "${Bpx[@]}" \
 "${Bpy[@]}" \
 "${B[@]}" \
 -P -K > $outps

# This works for current GMT 5.3
# TODO: update for GMT6 when installed as default
# to use gmtregress and get uncertainty
info=(`awk '{print $2,$3}' $infil | trend1d -Fp -Np1`)
np=`wc -l $infil | awk '{print $1}'`
intcpt=${info[0]}
slp=${info[1]}
vpvs=`echo 1+$slp | bc -lq | awk '{printf "%.2f", $1}'`

echo "$np Data Points, Vp/Vs = $vpvs"

seq $xmn 1 $xmx | awk '{print $1, b+m*$1}' b=$intcpt m=$slp |\
 psxy $J $R -W2p,red,dashed -O -K >> $outps

pstext $J $R -F+f12p+a0+jTL -O -K <<EOF >> $outps
$xmn $ymx Vp/Vs = $vpvs
EOF

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps
