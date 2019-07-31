#!/bin/bash

ARGS=2

if [ $# -ne "$ARGS" ]
then
  echo "Usage: `basename $0` dbname site-subset"
  echo "Converts a css3.0 site table to station.list format"
  echo "for sphrayderv type codes.  Default output name is:"
  echo "station.list"
  echo " need to put subset in double quotes."
  echo " `basename $0` masterdb \"sta=~/AT.*/\" "
  exit 
fi


#db=/home/stach/Work/Databases/Mongolia/dbmaster/XL/XL_masterdb
db=$1
ofile=station.list
#sub='sta=~/AT.*/'
sub=$2

dbsubset ${db}.site $sub |\
dbsort - sta |\
 dbselect - elev sta lat lon |\
  awk '{printf "%12.2f%12.2f %6d %6s   %10.5f%12.6f\n", 0,0,$1*1000,$2,$3,$4}' > $ofile

