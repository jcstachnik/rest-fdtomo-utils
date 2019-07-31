import numpy as np
from obspy import UTCDateTime
from obspy.core.event import Catalog, Event, Origin, Magnitude
from obspy.core.event import Pick, WaveformStreamID, Arrival, Amplitude
from obspy.core.event import Event, Origin, Magnitude
from obspy.core.event import EventDescription, CreationInfo
import argparse, logging

def getargs():
    parser = argparse.ArgumentParser(description=
    '''
    Convert FDLOC format file to Obspy Catalog
    ''',
    epilog=
'''
Some information below about these files:

FDLOC format
    2013  19 18 59  30.0461  -3.03001   35.86095  10.0000                
    MW36  2013  19 18 59  33.269 P           0.100           3.223
    MW36  2013  19 18 59  35.631 S           0.400           5.585
    MW43  2013  19 18 59  34.087 P           0.100           4.041


c   read in event header
1   read(lunleq,100,end=60) iyr, jday, ihr, imn, sec, xlat, xlon, dep,evid
100 format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,6x,a10)

2   read(lunleq,101) sta(nsta), iyr, jday, ihr, imn, sec, usemark,
     +      phs(nsta), rwt
     c101    format(a6,2i4,2i3,f8.3,1x,a1,8x,f8.3)
     101 format(a6,2i4,2i3,f8.3,a1,a1,8x,f8.3)

recent beta version seems to read unformatted lines:

1   read(lunleq,'(a132)',end=60) aline
c   write(*,*) aline
    evid = "          "
        call readheader(aline, iyr, jday, ihr, imn, sec, xlat8, xlon8, dep, evid, std, nfield, lunleq, ierr)

    call readphase (aline, sta(nsta), iyr, jday, ihr, imn, sec, usemark, phs(nsta), 
         +                rwt, phext, resmin, mark, tdelts, az1s, az2s, lunleq, ierr)

Also, there is a resetid parameter that can be set to disregard evid and 
set to NOEVID. ok.

OUTPUT:
        write(lunfdt,200) iyr,jday,ihr,imn,sec,xlat,xlon,ezm,evid,stdmin,avfac,
             +           delx, dely, delz, deld, npuse,nsuse,npuse+nsuse,bflag
             c200        format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,6x,a10,1x,2f10.3,3i4,1x,a6)
             200     format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,1x,a10,1x,2f10.3,4f6.1,3i4,1x,a6)

            write(lunfdt,201) sta(j), iyr, jday, ihr, imn, dsec, phs(j), rwts(j),
                 +         resmin(j)-avrmin
                 201        format(a6,2i4,2i3,f8.3,1x,a1,8x,f8.3,1x,f10.3)

''',
    formatter_class=argparse.RawTextHelpFormatter)
    helpmsg = "Name of fdloc format files. "
    parser.add_argument("-f","--fdfile",required=True, type=str,
                        help=helpmsg)
    args = parser.parse_args()
    return args,parser

def read_origin_fixed(line):
    """
    Read origin line based on fixed format
        write(lunfdt,200) iyr,jday,ihr,imn,sec,xlat,xlon,ezm,evid,stdmin,avfac,
             +           delx, dely, delz, deld, npuse,nsuse,npuse+nsuse,bflag
             c200        format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,6x,a10,1x,2f10.3,3i4,1x,a6)
             200     format(2i4,2i3,f9.4,f10.5,1x,f10.5,f9.4,1x,a10,1x,2f10.3,4f6.1,3i4,1x,a6)

    line = '2012 280 11  5  54.4318  46.89492   97.98225   0.0000 NOEVID          0.765     9.144   0.0   0.0   0.0   0.0  48  38  86'
    """
    #logger.debug('{}'.format(line))
    orig = {"yr" : int(line[0:4]),
            "jd" : int(line[5:8]),
            "hr" : int(line[9:11]),
            "mn" : int(line[12:14]),
            "sec" : float(line[15:24]),
            "lat" : float(line[25:35]),
            "lon" : float(line[36:44]),
            "dep" : float(line[45:53]),
            "noev" : line[54:64],
            "stdobs" : float(line[65:75]),
            "avwt" : float(line[75:85]),
            "late" : float(line[85:91]),
            "lone" : float(line[91:97]),
            "depe" : float(line[97:103]),
            "tote" : float(line[103:109]),
            "np" : int(line[110:113]),
            "ns" : int(line[114:117]),
            "nt" : int(line[118:121]),
            "mag" : -999
            }
    yr=int(line[0:4])
    jd=int(line[5:8])
    hr=int(line[9:11])
    mn=int(line[12:14])
    sec=float(line[15:24])
    lat=float(line[25:35])
    lon=float(line[36:44])
    dep=float(line[45:53])
    noev=line[54:64]
    stdobs=float(line[65:75])
    avwt=float(line[75:85])
    late=float(line[85:91])
    lone=float(line[91:97])
    depe=line[97:103]
    tote=line[103:109]
    np=int(line[110:113]) # num p
    ns=int(line[114:117]) # num s
    nt=int(line[118:121]) # nass
    mag = -999
    ostr = '{0}-{1:03d}T{2:02d}:{3:02d}:{4:06.4f}'.format(yr,jd,hr,mn,sec)
    ot = UTCDateTime(ostr)
    ote = ot.timestamp
    orig["ostr"] = ostr
    orig["ot"] = ot
    orig["ote"] = ote
    print('OT: {0} Lat {1} Lon {2} Dep {3}'.format(ostr,lat,lon,dep))
    #if args.loglevel == 'DEBUG':
    #    for key, value in orig.iteritems():
    #        print('{0} : {1}'.format(key, value))
    return orig

def read_arrival_line(line, fmt='fixed', dZch='HHZ', dHch='HHN'):
    """
    fmt = 'fixed' or 'free'
    """
    #logger.debug('{}'.format(line))
    if (fmt is 'fixed'):
        sta = line[0:5].strip()
        yr = int(line[6:10])
        jd = int(line[11:14])
        hr = int(line[15:17])
        mn = int(line[18:20])
        sec = float(line[22:28])
        if (sec == 60.000):
            sec = 0.0
            mn += 1
        yn = line[28:29]
        ph = line[29:30]
        deltim = float(line[39:46])
        tunc = float(line[40:45]) # arr time uncertainty
        astr = '{0}-{1:03d}T{2:02d}:{3:02d}:{4:06.4f}'.format(yr,jd,hr,mn,sec)
        at = UTCDateTime(astr)
        ate = at.timestamp
        if (ph is "P"):
            ch = dZch
        elif (ph is "S"):
            ch = dHch
        else:
            print('unkn phase {0} setting chan to {1}'.format(ph,dZch))
            ch = dZch
        arriv = { "sta" : sta,
                   "chan" : ch,
                   "yr" : yr,
                   "jd" : jd,
                   "hr" : hr,
                   "mn" : mn,
                   "sec" : sec,
                   "yn" : yn,
                   "ph" : ph,
                   "deltim" : deltim,
                   "tunc" : tunc,
                   "astr" : astr,
                   "at" : at,
                   "ate" : ate
                }
    else:
        print('only fixed implemented')
        arriv = {}
    #if args.loglevel == 'DEBUG':
    #    for k,v in arriv.iteritems():
    #        print('{0} : {1}'.format(k, v))
    return arriv

def read_sta_res():
    with open('path/to/input') as infile, open('path/to/output', 'w') as outfile:
        copy = False
        for line in infile:
            if line.strip() == "Start":
                copy = True
            elif line.strip() == "End":
                copy = False
            elif copy:
                outfile.write(line)

# awk ' /   No. Stn    Phs Average St.Dev. Nobs/ {flag=1;next} /  Normal termination of program /{flag=0} flag { print }' sphrayderv.log10


def mkevent(origlist, arrivallist):
    """
    Create an Obspy Event from an origin and arrivals

    """
    origdict = origlist[0]
    test_event = Event()
    test_event.origins.append(Origin())

    test_event.origins[0].time = origdict['ot']
    test_event.event_descriptions.append(EventDescription())
    test_event.event_descriptions[0].text = 'TEST'
    test_event.origins[0].latitude = origdict['lat']
    test_event.origins[0].longitude = origdict['lon']
    test_event.origins[0].depth = origdict['dep'] * 1000
    test_event.creation_info = CreationInfo(agency_id='TEST')
    test_event.origins[0].time_errors['Time_Residual_RMS'] = 0.01 # FIXME
    test_event.magnitudes.append(Magnitude())
    test_event.magnitudes[0].mag = 0.1 # FIXME
    test_event.magnitudes[0].magnitude_type = 'ML' # FIXME
    test_event.magnitudes[0].creation_info = CreationInfo('TES') # FIXME
    test_event.magnitudes[0].origin_id = test_event.origins[0].resource_id
    for i,arr in enumerate(arrivallist):
        _waveform_id = WaveformStreamID(station_code=arr['sta'], 
                                            channel_code=arr['chan'],
                                            network_code='XX')
        # can add onset='impulsive', polarity='positive',
        ipick = Pick(waveform_id=_waveform_id,
                                    phase_hint=arr['ph'],
                                    time=arr['at'],
                                    time_errors={"uncertainty":arr['tunc']},
                                    )
        test_event.picks.append(ipick)
        distdeg = 1
        azdeg = 1
        iarr = Arrival(pick_id=ipick.resource_id,
                            phase=ipick.phase_hint,
                            distance=distdeg,
                            azimuth=azdeg
                            )
        test_event.origins[0].arrivals.append(iarr)                        
    return test_event


def fdloc2catalog(fdfile):
    """
    Read in fdloc file and convert to Obspy Catalog
    """
    print('Reading in file: {}'.format(fdfile))
    cat = Catalog()
    cat.description = "FDLOC catalog"
    
    origins = []
    arrivals = []
    
    newblock=1
    doarr=0
    auth = "fdloc"
    
    f = open(fdfile,'r')
    for line in f:
        #print(line)
        if not line.strip():
            #print("Found blank line, eg new event")
            newblock = 1
            doarr = 0
            ev =mkevent(origins, arrivals)
            cat.append(ev)
            origins = []
            arrivals = []
            continue
        if (newblock == 1 and doarr == 0):
            orig = read_origin_fixed(line)
            origins.append(orig)
            #Check evid
            #Add to Catalog?
            doarr = 1
            continue
        if (newblock == 1 and doarr == 1):
            arriv = read_arrival_line(line, fmt='fixed')
            arrivals.append(arriv)
            # deal with arids
            # add to arrival, assoc tables

    f.close()
    return cat

"""
cat = Catalog()
cat.description = "FDLOC catalog"

origins = []
arrivals = []

newblock=1
doarr=0
auth = "fdloc"

fdfile='fdloc.final'
f = open(fdfile,'r')
for line in f:
    #print(line)
    if not line.strip():
        print("Found blank line, eg new event")
        newblock = 1
        doarr = 0
        ev =mkevent(origins, arrivals)
        cat.append(ev)
        origins = []
        arrivals = []
        continue
    if (newblock == 1 and doarr == 0):
        orig = read_origin_fixed(line)
        origins.append(orig)
        #Check evid
        #Add to Catalog?
        doarr = 1
        continue
    if (newblock == 1 and doarr == 1):
        arriv = read_arrival_line(line, fmt='fixed')
        arrivals.append(arriv)
        # deal with arids
        # add to arrival, assoc tables

"""
#ev = mkevent(origins, arrivals)
#line = '2012 280 11  5  54.4318  46.89492   97.98225   0.0000 NOEVID          0.765     9.144   0.0   0.0   0.0   0.0  48  38  86'

#orig = read_origin_fixed(line)
if __name__ == "__main__":
    args,parser = getargs()
    cat = fdloc2catalog(args.fdfile)
