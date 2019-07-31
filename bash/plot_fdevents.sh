#!/bin/bash

ARGS=2
if [ $# -lt "$ARGS" ]
then
    echo "Usage: `basename $0` db subset"
    echo " Create map of events with error ellipse from fdloc"
    echo " need to run fdloc2db.pl first "
    echo " Example: `basename $0` loc2db \"depth<50\""
    exit
fi

dbo=$1
sub="$2"

db=/data/WF/Mongolia/dbmaster/XL/XL_masterdb
R=-R93/105/43/52.5
J=-JM6i
outps=events-fdloc.ps
faults=faults.txt

B="-Bf1a2/f1a2WSen"
parms="--FONT_ANNOT_PRIMARY=10p --FORMAT_GEO_MAP=dddF"

pscoast $J $R $B -Dh -S -C136/206/250 -Na/3,black -W1/3,black -K $parms -P > $outps

dbsubset $db.site 'sta=~/HD.*/' |\
dbselect - lon lat sta |\
psxy $J $R -St0.15 -Gblue -W1,white -O -K >> $outps

#dbsubset $db.site 'sta=~/HV.*/' |\
#dbselect - lon lat sta |\
# pstext $J $R -F+f8p,Helvetica+a0+jLM -D0.05/0 -O -K >> $outps

dbjoin $dbo.event :prefor#orid origin |\
 dbjoin - origerr |\
 dbsubset - "$sub" |\
 dbselect - lon lat depth smajax sminax > tmp.evts

awk '{print $1,$2}' tmp.evts |\
 psxy $J $R -Sc0.05 -Gblack  -O -K >> $outps

#awk '{print $1,$2,0,$4,$5}' tmp.evts |\
# psxy $J $R -SE -W1p,yellow -O -K >> $outps

psxy $J $R -T -O >> $outps
psconvert -A -Tf $outps
/bin/rm $outps tmp.evts

