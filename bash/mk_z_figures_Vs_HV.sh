#!/bin/bash

# This script is an attempt to make a set of standard figures from
# running the P and S body wave tomography.  There are likely things
# are are unique to a given region that will need changing.
#
# This script is meant to be run from a main directory where the
# tomography was run.  This assumes you ran the runbwo_beta script
# with
# runbwo_beta.csh bwo hovsgol 1 10
# where bwo is the output directory that runbwo moves all the pertinent
# output files to.
# hovsgol is the project name and your main spec file is hovsgol0.spec
# 1 10, max 10 iterations, final model is bwo/lsqr_smooth.mod10
#

dohits=1
doz=0
outdir=Output-Vs
# Bounds on which sections to make.
# e.g. xsections (N-S) from longitude 98.5 to 101.5
# where the horizontal bounds of plot are from lat 44.5 to 50.0
xmn=98.5
xmx=101.5
xproj0=49.4
xproj1=52.5
# e.g. ysections (E-W) from latitude 50.0 to 52.0
ymn=50.0
ymx=52.0
yproj0=97.6
yproj1=102.0
# --------------------
# For the zsections
zmn=0
zmx=40
zR=-R$yproj0/$yproj1/$xproj0/$xproj1
zR=-JM4i
# --------------------
# Depth plot range
pymn=-2
pymx=60
# --------------------
# Lots of assumptions here...
proj=hovsgol
spec=${proj}0.spec
findat=${proj}_good.data
it=10 # max number of iterations
finmod=lsqr_smooth.mod${it}

# --------------------
tomodir=/data/SFW/share/Roecker_codes/joint_inversion/src/tomography/ 
tomobeta=/data/SFW/share/Roecker_codes/joint_inversion/src/tomography_beta/
plotbin=/data/SFW/share/Roecker_codes/scripts/
# --------------------
# --------------------
# --------------------
# --------------------
# --------------------

wdir=`pwd`


cd $outdir/

# ---------------------------
# --------------------------------------------
# make the parfile for creating Vsysections
Vszpar=${wdir}/$outdir/Vszsection.par
cat <<EOF > $Vszpar
# fdloc event file
evtfile=${wdir}/$outdir/$findat
wid=15 # event projection width
# Color scale bounds
vmin=3.2
vmax=4.8
vinc=0.02
vlab="km/s"
cont1=0.2
cont2=1.0
plotcont=1
plotscl=1
psa=1.0
psf=0.2
#
hitdir=${wdir}/$outdir/Vs-hits
#
topogrd=/data/TOPO/Projects/mongolia_large.grd
#
stafile=${wdir}/$outdir/station.list
R=$zR
J=$zJ
EOF

# S waves ------------------
# ---------------------------
if [ "$doz" -eq 1 ]; then

echo "Making the Vs-zsect ---------"
mkdir Vs-zsect
cd Vs-zsect
# Make the xsection files for all lines
${tomobeta}/section_beta <<EOF
../$finmod
1
n
3
0
EOF

${plotbin}/plot_many_z.sh $zmn $zmx $Vszpar

cd ../

fi
