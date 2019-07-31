#!/bin/bash

ARGS=4

plotx=/data/SFW/share/Roecker_codes/scripts/plot_section.sh
#plotx=$HOME/Work/Mongolia/FDtomo/bin/plot_vel_xsection.sh

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` min max evtfile phs"
    echo " Create ysections for a range of latitudes"
    echo " min: 48.0"
    echo " max: 52.5"
    echo " evtfile: ../bwo/mong_good.data "
    echo " phs: [Vp,Vs,VpVs] "
    echo " Example: `basename $0` 48.0 52.5 ../bwo/mong_good.data Vp"
    exit
fi

ymin=$1
ymax=$2
evt=$3
phs=$4

outpdf=${phs}_all_ysection.pdf
echo "Using plot script $plotx"
echo " Output to composite pdf $outpdf "

# make ordered list of x's
ys=(`ls ysection.*.??? | awk -F. '{printf "%.3f\n", $2+($3/1000)}' | sort -n -k 1`)

echo -n "pdftk  " > rpdf

for y in ${ys[@]}
do

if (( $(echo "$y >= $ymin" |bc -l) )); then
if (( $(echo "$y <= $ymax" |bc -l) )); then

   $plotx ysection.$y $evt $phs
   echo -n "ysection.${y}.pdf " >> rpdf

fi
fi
done

echo -n " cat output $outpdf" >> rpdf
bash rpdf

/bin/rm rpdf
