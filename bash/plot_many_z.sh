#!/bin/bash


ARGS=3

#plotz=$HOME/Work/Mongolia/FDtomo/bin/plot_zsection.sh
plotz=/data/SFW/share/Roecker_codes/scripts/plot_zsection.sh

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` min max parfile"
    echo " Create zsections for a range of depths"
    echo " min: 0."
    echo " max: 70."
    echo " parfile: Vpzsection.par"
    echo " Example: `basename $0` 98.0 101.5 Vpzsection.par"
    exit
fi

zmin=$1
zmax=$2
parfile=$3

outpdf=all_zsection.pdf
echo "Using plot script $plotz"
echo " Output to composite pdf $outpdf "

# make ordered list of depths
zees=(`ls zsection.*.? | awk -F. '{printf "%.1f\n", $2+($3/10)}' | sort -n -k 1`)

echo -n "pdftk  " > rpdf

for z in ${zees[@]}
do

if (( $(echo "$z >= $zmin" |bc -l) )); then
if (( $(echo "$z <= $zmax" |bc -l) )); then

   echo "++ Running $plotz zsection.$z $parfile"
   $plotz zsection.$z $parfile
   echo -n "zsection.${z}.pdf " >> rpdf

fi
fi
done

echo -n " cat output $outpdf" >> rpdf
bash rpdf

/bin/rm rpdf
