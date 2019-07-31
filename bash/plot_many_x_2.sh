#!/bin/bash


ARGS=3

plotx=/data/SFW/share/Roecker_codes/scripts/plot_section_2.sh
#plotx=$HOME/Work/Mongolia/FDtomo/bin/plot_vel_xsection.sh

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` min max parfile "
    echo " Create xsections for a range of longitudes"
    echo " min: 98.0"
    echo " max: 101.5"
    echo " parfile: ./Vpxsection.par "
    echo " Example: `basename $0` 98.0 101.5 ./Vpxsection.par"
    exit
fi

xmin=$1
xmax=$2
parfile=$3

outpdf=all_xsection.pdf
echo "Using plot script $plotx"
echo " Output to composite pdf $outpdf "
echo ""

# make ordered list of x's
xs=(`ls xsection.???.??? xsection.??.??? | awk -F. '{printf "%.3f\n", $2+($3/1000)}' | sort -n -k 1`)

echo -n "pdftk  " > rpdf

for x in ${xs[@]}
do

if (( $(echo "$x >= $xmin" |bc -l) )); then
if (( $(echo "$x <= $xmax" |bc -l) )); then

   echo "++ Running $plotx xsection.$x $parfile "
   $plotx xsection.$x $parfile
   echo -n "xsection.${x}.pdf " >> rpdf

fi
fi
done

echo -n " cat output $outpdf" >> rpdf
bash rpdf

/bin/rm rpdf
