#!/bin/bash

mod=../bwo/lsqr_smooth.mod10

# this converts the 3D binary file to ascii
/data/SFW/share/Roecker_codes/joint_inversion/src/tomography/sph2asc <<EOF > f
$mod
0
n
EOF


# grab the coordinates of the grid at 0 depth
awk '($3==0) {print $2,$1}' ascii.out > lon_lat.txt

# grab the first lat in the file
lat1=`head -1 ascii.out | awk '{print $1}'`
# grab the first lon in the file
lon1=`head -1 ascii.out | awk '{print $2}'`

# grab the lon,z coords at a given latitude
awk '($1==la) {print $2,$3}' la=$lat1 ascii.out > grid_lat_${lat1}.txt
# grab the lat,z coords at a given longitude
awk '($2==lo) {print $1,$3}' lo=$lon1 ascii.out > grid_lon_${lon1}.txt

outps=grid.ps
R=-R92/105/44/48
J=-JM4i
psxy $J $R lon_lat.txt -B1/1 -S+0.1i -P -K -Y3i > $outps

R=-R92/105/0/70
J=-JX4i/-2i
psxy $J $R grid_lat_${lat1}.txt -Bpxf1a2 -Bpy10 -BWsen -S+0.1i -O -K -Y-3.0i >> $outps
# flip the x and y to plot on the side
R=-R0/70/44/48
J=-JX2i/4i
psxy $J $R grid_lon_${lon1}.txt -B10/1 -S+0.1i -O -X4.5i -Y2i -: >> $outps

/bin/rm ascii.out lon_lat.txt grid_lat_${lat1}.txt grid_lon_${lon1}.txt

