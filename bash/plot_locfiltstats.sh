#!/bin/bash

ARGS=1

if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` maxit "
    echo " maxit = max number of iterations to plot"
    echo ""
    echo " This script parses the locfilt.log? files for pertinent"
    echo " information on the inversion at different iterations."
    echo " See the content of one of the locfilt.log files for "
    echo " more information"
    exit
fi


mit=$1 # max number of iterations
ofil=locfiltstats.out
outps=locfiltstats.ps
echo "Creating figure called $outps but a pdf"


echo "#     BODY             P              S" > $ofil
echo "#var std rms avres avwt c-sq nob neq " >> $ofil

# Parse the log files ---------
for it in `seq 1 $mit`
do
    locf=locfilt.log${it}
    v=`awk '/Number of events read in/,EOF {print $0}' $locf | awk 'NR>2 && NF>0' | awk -F: '{printf "%f ", $2}' `
    echo "$it ${v[@]}" >> $ofil
done

# Set up the Figure -----------
J=-JX3i/2i
# Set up the legend
fsz=6p
echo "# header for legend" > leg.out
echo "N 3 " >> leg.out
echo "L $fsz - L Stat" >> leg.out
echo "L $fsz - L Min" >> leg.out
echo "L $fsz - L Max" >> leg.out
echo "D 1p" >> leg.out
echo "V 1p" >> leg.out

# Process different columns
# iter bodyvar
c=2 # column number in file
cc=`echo "$c-1" | bc -lq` # subtract 1 bc gmt indices start at 0
R=`gmtinfo $ofil -i0,$cc -I- -hi2`
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -W1p,black -N \
 -Bpx1+l"Iteration" \
 -Bpy0.1 -BwS+glightgray \
 -P -K > $outps
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -Sc0.05i \
 -Gblack -N \
 -O -K >> $outps
mm=(`gmtinfo $ofil -i$cc -C -hi2`)
echo "C black" >> leg.out
echo "L $fsz - L BodyVar " >> leg.out
echo "L $fsz - L ${mm[0]} " >> leg.out
echo "L $fsz - L ${mm[1]} " >> leg.out

# iter BodyRMS
c=4
cc=`echo "$c-1" | bc -lq`
R=`gmtinfo $ofil -i0,$cc -I- -hi2`
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -W1p,blue -N \
 -O -K >> $outps
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -Sc0.05i \
 -Gblue -N \
 -O -K >> $outps
mm=(`gmtinfo $ofil -i$cc -C -hi2`)
echo "C blue" >> leg.out
echo "L $fsz - L BodyRMS" >> leg.out
echo "L $fsz - L ${mm[0]}" >> leg.out
echo "L $fsz - L ${mm[1]}" >> leg.out

# iter Pvar
c=10
cc=`echo "$c-1" | bc -lq`
R=`gmtinfo $ofil -i0,$cc -I- -hi2`
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -W1p,red -N \
 -O -K >> $outps
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -Sc0.05i \
 -Gred -N \
 -O -K >> $outps
mm=(`gmtinfo $ofil -i$cc -C -hi2`)
echo "C red" >> leg.out
echo "L $fsz - L Pvar" >> leg.out
echo "L $fsz - L ${mm[0]}" >> leg.out
echo "L $fsz - L ${mm[1]}" >> leg.out

# iter Pvar
c=13
cc=`echo "$c-1" | bc -lq`
R=`gmtinfo $ofil -i0,$cc -I- -hi2`
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -W1p,green -N \
 -O -K >> $outps
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -Sc0.05i \
 -Ggreen -N \
 -O -K >> $outps
mm=(`gmtinfo $ofil -i$cc -C -hi2`)
echo "C green" >> leg.out
echo "L $fsz - L Pavres" >> leg.out
echo "L $fsz - L ${mm[0]}" >> leg.out
echo "L $fsz - L ${mm[1]}" >> leg.out

# iter Svar
c=17
cc=`echo "$c-1" | bc -lq`
R=`gmtinfo $ofil -i0,$cc -I- -hi2`
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -W1p,yellow -N \
  -O -K >> $outps
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -Sc0.05i \
 -Gyellow -N \
 -O -K >> $outps
mm=(`gmtinfo $ofil -i$cc -C -hi2`)
echo "C yellow" >> leg.out
echo "L $fsz - L Svar" >> leg.out
echo "L $fsz - L ${mm[0]}" >> leg.out
echo "L $fsz - L ${mm[1]}" >> leg.out

# iter Pvar
c=20
cc=`echo "$c-1" | bc -lq`
R=`gmtinfo $ofil -i0,$cc -I- -hi2`
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -W1p,orange -N \
 -O -K >> $outps
gmtselect $ofil -i0,$cc -hi2 |\
 psxy $J $R -St0.05i \
 -Gorange -N \
 -O -K >> $outps
mm=(`gmtinfo $ofil -i$cc -C -hi2`)
echo "C orange" >> leg.out
echo "L $fsz - L Savres" >> leg.out
echo "L $fsz - L ${mm[0]}" >> leg.out
echo "L $fsz - L ${mm[1]}" >> leg.out

# ---------------------------------
echo "G 0.1i" >> leg.out
echo "C black" >> leg.out
echo "N 1 " >> leg.out
echo "L $fsz - C Final Values" >> leg.out
echo "D 1p" >> leg.out
echo "N 2 " >> leg.out
echo "L $fsz - R Num Eq:" >> leg.out
v=`tail -1 $ofil | awk '{printf "%d", $9}'`
echo "L $fsz - L $v" >> leg.out
echo "L $fsz - R Num P:" >> leg.out
v=`tail -1 $ofil | awk '{printf "%d", $16}'`
echo "L $fsz - L $v" >> leg.out
echo "L $fsz - R Num S:" >> leg.out
v=`tail -1 $ofil | awk '{printf "%d", $23}'`
echo "L $fsz - L $v" >> leg.out
# ---------------------------------
pslegend leg.out -D0/1/1.5i/2i/TL \
 -F+glightgray \
 -JX1i/2i -R0/1/0/1 \
 -X3.1i -O -K >> $outps

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps
