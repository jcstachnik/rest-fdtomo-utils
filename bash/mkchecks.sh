#!/bin/bash

nchk=8
ntot=160

nn=0
while [ $nn -lt "$ntot" ]
    do
for i in `seq 1 $nchk`; do 
    echo -n "0 " 
    nn=$[$nn+1]
done
for i in `seq 1 $nchk`; do 
    echo -n "1 " 
    nn=$[$nn+1]
done
for i in `seq 1 $nchk`; do 
    echo -n "0 " 
    nn=$[$nn+1]
done
for i in `seq 1 $nchk`; do 
    echo -n "-1 " 
    nn=$[$nn+1]
done

done

# spits out something like this, which is greater than ntot, but I 
# think that's okay
#0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 0 0 0 1 1 1 0 0 0 -1 -1 -1 [
