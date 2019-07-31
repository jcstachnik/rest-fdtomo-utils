#!/bin/bash

ARGS=3

plotx=/data/SFW/share/Roecker_codes/scripts/plot_section_2.sh
#plotx=$HOME/Work/Mongolia/FDtomo/bin/plot_vel_xsection.sh

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` min max parfile "
    echo " Create ysections for a range of latitudes"
    echo " min: 48.0"
    echo " max: 52.5"
    echo " parfile: ./Vpysection.par "
    echo " Example: `basename $0` 48.0 52.5 ./Vpysection.par"
    exit
fi

ymin=$1
ymax=$2
parfile=$3

outpdf=all_ysection.pdf
echo "Using plot script $plotx"
echo " Output to composite pdf $outpdf "

# make ordered list of x's
ys=(`ls ysection.??.??? ysection.???.??? | awk -F. '{printf "%.3f\n", $2+($3/1000)}' | sort -n -k 1`)

echo -n "pdftk  " > rpdf

for y in ${ys[@]}
do

if (( $(echo "$y >= $ymin" |bc -l) )); then
if (( $(echo "$y <= $ymax" |bc -l) )); then

   echo "++ Running $plotx ysection.$y $parfile"
   $plotx ysection.$y $parfile
   echo -n "ysection.${y}.pdf " >> rpdf

fi
fi
done

echo -n " cat output $outpdf" >> rpdf
bash rpdf

/bin/rm rpdf
