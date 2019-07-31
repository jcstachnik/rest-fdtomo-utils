#!/bin/bash

# This script converts a file output from running 'section'
# to something GMT can easily parse and plot.

function convert_sect_file {

	infil=$1
	ofile=$2
    xy=$3


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

# Set up coords of end points
case $xy in
"X")
    lo0=$c1
    lo1=$c1
    la0=${bds[0]}
    la1=${bds[1]}
    awk '{print c,$1,$2,$3}' c=$c1 xyv.txt |\
     project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q > $ofile
    ;;
"Y")
    la0=$c1
    la1=$c1
    lo0=${bds[0]}
    lo1=${bds[1]}
    awk '{print $1,c,$2,$3}' c=$c1 xyv.txt |\
     project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q > $ofile
    ;;
esac
#lo0=$c1
#lo1=$c1
#la0=${bds[0]}
#la1=${bds[1]}

# Create file of projected coords:
# x y z val km
# if xsection.??, then x=lon y=lat
# if ysection.??, then x=lat y=lon
#awk '{print c,$1,$2,$3}' c=$c1 xyv.txt |\
# project -C$lo0/$la0 -E$lo1/$la1 -Fxyzp -Q > $ofile

/bin/rm xyv.txt xy.txt vals.txt
 
}

x=(`ls xsection.*.???`)
y=(`ls ysection.*.???`)
for f in ${x[@]}
do
	convert_sect_file $f hits_${f}.xyzvkm X
done
for f in ${y[@]}
do
	convert_sect_file $f hits_${f}.xyzvkm Y
done

#convert_sect_file ysection.51.010 hits.xyzvkm Y
#echo "Removing xsection.*.??? and ysection.*.??? files ..."
#/bin/rm -f xsection.*.??? ysection.*.???
