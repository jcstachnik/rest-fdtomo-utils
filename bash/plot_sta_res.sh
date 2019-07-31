#!/bin/bash

# This script parses the final iteration sphrayderv logfile
# to pull out the average station statistics.

it=10
ifil=sphrayderv.log${it}
ofil=stares.out
outps=stares.ps

echo "Creating figure called $outps but a pdf"

awk '/No. Stn    Phs Average St.Dev. Nobs/,/Normal termination of program/ {print $0}' $ifil |\
 awk 'NR>1 && NF>0' | grep -v "Normal" > $ofil

J=-JX6i/3i

nsta=`wc -l $ofil | awk '{print $1/2}'` # assume all have P&S
xmx=`echo "$nsta+1" | bc -lq`
ymx=1200
R=-R0/$xmx/0/$ymx
awk '$3==1' $ofil | awk '{print NR,$6}' |\
 psxy $J $R -Sb0.5u -Gblue \
 -Bpxf1g1 \
 -Bpyf100a500+l"N Obs" \
 -BWsn \
 -P -K > $outps

awk '$3==2' $ofil | awk '{print NR,$6}' |\
 psxy $J $R -Sb0.5u -Gred \
 -O -K >> $outps

awk '$3==1' $ofil | awk '{print NR,-20,$2}' |\
 pstext $J $R -F+f6p+a-90+jLM -N -O -K >> $outps

ymn=-0.3
ymx=0.3
R=-R0/$xmx/$ymn/$ymx
awk '$3==1' $ofil | awk '{print NR,$4}' |\
 psxy $J $R -Sc0.1i -Gblue \
 -Bpyf.05a0.1g1+l"Avg. Res. (s)" \
 -Bpxg1 \
 -BWs \
 -Y3i \
 -O -K >> $outps
awk '$3==1' $ofil | awk '{print NR,$4}' |\
 psxy $J $R -W1p,blue \
 -O -K >> $outps
awk '$3==2' $ofil | awk '{print NR,$4}' |\
 psxy $J $R -Sc0.1i -Gred \
 -O -K >> $outps
awk '$3==2' $ofil | awk '{print NR,$4}' |\
 psxy $J $R -W1p,red \
 -O -K >> $outps

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps
