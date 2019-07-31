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
dox=0
doy=0
doz=0
outdir=Output-Vp2
# Bounds on which sections to make.
# e.g. xsections (N-S) from longitude 98.5 to 101.5
# where the horizontal bounds of plot are from lat 44.5 to 50.0
xmn=96.0
xmx=102.0
xproj0=44.5
xproj1=50.0
# e.g. ysections (E-W) from latitude 50.0 to 52.0
ymn=45.0
ymx=50.0
yproj0=96.0
yproj1=104.0
# --------------------
# For the zsections
zmn=0
zmx=40
zR=-R$yproj0/$yproj1/$xproj0/$xproj1
zJ=-JM4i
# --------------------
# Depth plot range
pymn=-2
pymx=110
# --------------------
# Lots of assumptions here...
proj=hangay
spec=${proj}0.spec
findat=${proj}_good.data
it=15 # max number of iterations
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

# Make a separate dir for output
if [ -d $outdir ]; then
    echo "Directory $outdir exists, remove and start again..."
    exit 0
fi

mkdir $outdir

cd $outdir/
#Copy the final model
cp ../bwo/$finmod ./
#Copy the final event locations
cp ../bwo/$findat ./
#Copy the final ray hits, assumes rayderv.hit is set in spec file
cp ../rayderv.hit ./
#copy the spec0 file
cp ../bwo/$spec ./
#copy the station
cp ../station.list ./

# ---------------------------
# make the parfile for creating Vpxsections
Vpxpar=${wdir}/$outdir/Vpxsection.par
cat <<EOF > $Vpxpar
# fdloc event file
evtfile=${wdir}/$outdir/$findat
wid=15 # event projection width
# Color scale bounds
vmin=5.4
vmax=8.4
vinc=0.05
vlab="km/s"
cont1=0.2
cont2=1.0
plotcont=1
plotscl=0
psa=1.0
psf=0.2
# 
hitdir=${wdir}/$outdir/Vp-hits
# 
topogrd=/data/TOPO/Projects/mongolia_large.grd
# 
stafile=${wdir}/$outdir/station.list
#  X or Y section
xy="X"
# Since this is a cross section, these are depth plot bounds
pymn=$pymn
pymx=$pymx
# The bounds of the entire model are likely larger than
# the desired plotting area. For xsection, these will be
# Lat bounds, ysection Lon bounds
# Starting point of projection:
proj0=${xproj0}
# End point of projection:
proj1=${xproj1}
EOF

# ---------------------------
# make the parfile for creating Vpysections
Vpypar=${wdir}/$outdir/Vpysection.par
cat <<EOF > $Vpypar
# fdloc event file
evtfile=${wdir}/$outdir/$findat
wid=15 # event projection width
# Color scale bounds
vmin=5.4
vmax=8.4
vinc=0.05
vlab="km/s"
cont1=0.2
cont2=1.0
plotcont=1
plotscl=0
psa=1.0
psf=0.2
# 
hitdir=${wdir}/$outdir/Vp-hits
# 
topogrd=/data/TOPO/Projects/mongolia_large.grd
# 
stafile=${wdir}/$outdir/station.list
#  X or Y section
xy="Y"
# Since this is a cross section, these are depth plot bounds
pymn=$pymn
pymx=$pymx
# The bounds of the entire model are likely larger than
# the desired plotting area. For xsection, these will be
# Lat bounds, ysection Lon bounds
# Starting point of projection:
proj0=${yproj0}
# End point of projection:
proj1=${yproj1}
EOF

# --------------------------------------------
# make the parfile for creating Vpysections
Vpzpar=${wdir}/$outdir/Vpzsection.par
cat <<EOF > $Vpzpar
# fdloc event file
evtfile=${wdir}/$outdir/$findat
wid=15 # event projection width
# Color scale bounds
vmin=5.4
vmax=8.4
vinc=0.05
vlab="km/s"
cont1=0.2
cont2=1.0
plotcont=1
plotscl=0
psa=1.0
psf=0.2
#
hitdir=${wdir}/$outdir/Vp-hits
#
topogrd=/data/TOPO/Projects/mongolia_large.grd
#
stafile=${wdir}/$outdir/station.list
R=$zR
J=$zJ
EOF


# --------------------------------------------
#Create a database of the events (origin, origerr, event, arrival, assoc):
#echo "Making db of final events"
#mkdir Events
#cd Events/
#perl ${plotbin}/fdloc2css.pl -i ../$findat -d fdlocdb
#cd ../

# P waves ------------------
if [ "$dohits" -eq 1 ]; then

echo " Creating the Vp hit count files ... "
mkdir Vp-hits
cd Vp-hits
cp ../$spec ./
cp ../rayderv.hit ./
# convert hits file to vel format,
# this outputs hits.vfile
${tomodir}/hit2vel <<EOF
$spec
EOF
# Make the xsections
${tomobeta}/section_beta <<EOF
hits.vfile
0
n
1
0
EOF
# Make the ysections
${tomobeta}/section_beta <<EOF
hits.vfile
0
n
2
0
EOF
# Make the zsections
${tomobeta}/section_beta <<EOF
hits.vfile
0
n
3
0
EOF
# This converts the xsection, ysection files to be used w/GMT
${plotbin}/convert_sect.sh

cd ../

fi
# -----------------------------------
if [ "$dox" -eq 1 ]; then
echo "Making the Vp-xsect ---------"
mkdir Vp-xsect
cd Vp-xsect
# Make the xsection files for all lines
${tomobeta}/section_beta <<EOF
../$finmod
0
n
1
0
EOF

${plotbin}/plot_many_x_2.sh $xmn $xmx $Vpxpar

cd ../

fi
# -----------------------------------
if [ "$doy" -eq 1 ]; then
echo "Making the Vp-ysect ---------"
mkdir Vp-ysect
cd Vp-ysect
# Make the xsection files for all lines
${tomobeta}/section_beta <<EOF
../$finmod
0
n
2
0
EOF

${plotbin}/plot_many_y_2.sh $ymn $ymx $Vpypar

cd ../

fi
# ---------------------------
if [ "$doz" -eq 1 ]; then

echo "Making the Vp-zsect ---------"
mkdir Vp-zsect
cd Vp-zsect
# Make the xsection files for all lines
${tomobeta}/section_beta <<EOF
../$finmod
0
n
3
0
EOF

${plotbin}/plot_many_z.sh $zmn $zmx $Vpzpar

cd ../

fi
