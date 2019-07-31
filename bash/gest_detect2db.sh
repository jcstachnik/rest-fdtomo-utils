#!/bin/bash

dfl=detect.list.sort

#2016 008 01 00 15.8400 P   0.0100  0.0100  0  0  0 IL02   HHZ    SAC/2016.008.01:00:0 0.147648E+05 Detection            20171221 155241
#2016 008 01 01 41.8500 P   0.0100  0.0100  0  0  0 IL02   HHZ    SAC/2016.008.01:00:0 0.289581E+05 Detection            20171221 155241
#2016 008 01 02 25.6500 P   0.0100  0.0100  0  0  0 IL02   HHZ    SAC/2016.008.01:00:0 0.240507E+04 Detection            20171221 155241
#2016 008 01 03 07.6600 P   0.0100  0.0100  0  0  0 IL02   HHZ    SAC/2016.008.01:00:0 0.153779E+04 Detection            20171221 155241
#2016 008 01 04 29.3900 P   0.0100  0.0100  0  0  0 IL02   HHZ    SAC/2016.008.01:00:0 0.136875E+03 Detection            20171221 155241


#awk '{printf "%d-%03d %02d:%02d:%.4f\n", $1, $2, $3, $4, $5}' detect.list | epoch | awk '{print $1}' > tmp.epochs


awk '{printf "dbaddv dbdet.arrival sta %s chan %s iphase %s time \"%d-%03d %02d:%02d:%.4f\"\n", $12, $13, $6, $1, $2, $3, $4, $5}' $dfl > tmp.dbaddv

sh tmp.dbaddv
/bin/rm tmp.dbaddv
