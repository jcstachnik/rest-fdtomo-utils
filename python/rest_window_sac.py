from obspy import read,UTCDateTime,Stream
from obspy.io.sac.sactrace import SACTrace

import os,argparse

def getargs():
    parser = argparse.ArgumentParser(description=
    '''
    Window SAC files for REST. Faster version of Fortran 
    program window_sac.
    ''',
    epilog=
    '''
    Example: 
    python rest_window_sac.py -s window_sac.spec 

    TODO: 
    More checking on file/timeseries integrity, which will likely
    slow it down to the same speed as the Fortran.
    ''',
    formatter_class=argparse.RawTextHelpFormatter)
    helpmsg = "Name of spec file. "
    parser.add_argument("-s","--spec",required=True, type=str,
                        help=helpmsg)
    helpmsg = "Dry run, only parse detections, do not cut SAC files."
    parser.add_argument("-d","--dryrun",required=False, type=bool,
                        default=False, help=helpmsg)

    args = parser.parse_args()
    return args,parser

class Spec:
    def __init__(self, sfile="window_sac.spec"):
        with open(sfile) as fh:
            for line in fh:
                if not line.strip():
                    continue
                s = line.split()
                #print s[0], s[1]
                if s[0] == 'twinb' or s[0] == 'twine':
                    setattr(self,s[0],float(s[1]))
                else:
                    setattr(self,s[0],s[1])


def get_min_max_det(detections):
    nd = len(detections)
    #print('{} detections '.format(nd))
    mind = UTCDateTime("2599-12-31T00:00:00")
    maxd = UTCDateTime(0)
    for i,det in enumerate(detections):
        dd = det.split()
        y = int(dd[0])
        j = int(dd[1])
        h = int(dd[2])
        m = int(dd[3])
        s = float(dd[4])
        # this only takes care of secs = 60.
        if s == 60.:
            s = 0.
            m += 1
        ss = '{0:4d}-{1:03d}T{2:02d}:{3:02d}:{4}'.format(y, j, h, m, s)
        dtime = UTCDateTime(ss)
        if dtime < mind:
            mind = dtime
        elif dtime > maxd:
            maxd = dtime
    return mind, maxd
    
def write_pfile(detections, pfile):
    of = open(pfile, 'w')
    for item in detections:
        of.write("%s\n" % item)

def cutsac(storig, sacstrt, sacend, evdir, evstr):
    yr = sacstrt.year
    jd = sacstrt.julday
    hr = sacstrt.hour
    mn = sacstrt.minute
    sc = sacstrt.second
    sacprefix = '{0:4d}.{1:03d}.{2:02d}.{3:02d}.{4:02d}'.format(yr, jd, hr, mn, sc)
    stsli = storig.slice(starttime=sacstrt, endtime=sacend)
    for i,tr in enumerate(stsli):
        fnm = sacprefix + '.' + tr.stats.station + '.' + tr.stats.channel
        ofnm = evdir + '/' + fnm
        tr.trim(starttime=sacstrt, endtime=sacend)
        sac = SACTrace.from_obspy_trace(tr)
        sac.reftime = tr.stats.starttime
        #st.write(ofnm, format='SAC')
        sac.write(ofnm)

# -----------------------------------------
args,parser = getargs()
dryrun = args.dryrun
sfile = args.spec
specs = Spec(sfile=sfile)
filelist = specs.filelist
datalist = specs.datalist
windir = specs.windir
twinb = specs.twinb
twine = specs.twine
'''
# spec file
spec = "window_sac.spec"
# --- These need to be read in from above spec file
filelist = "filelist.SAC"
# input event file, from output of collect_events
datalist = "event.file" 
windir = "WINDOWS2"

twinb = -20.
twine = 40.
'''
# ---

if not os.path.exists(windir):
    print('Making windir {}'.format(windir))
    os.makedirs(windir)

print('Reading in event file {} ... '.format(datalist))
f = open(datalist, 'r')

print('Reading in SAC files from file {}'.format(filelist))
with open(filelist, 'r') as fl:
    fls = fl.read().splitlines()
storig = Stream()
for ff in fls:
    print('Reading file: {}'.format(ff))
    storig += read(ff)

print('{} SAC files read'.format(len(storig)))

detections = []
evstrs = []
irep = 1
iev = 0
for line in f:
    if not line.strip():
        #print('Found blank line')
        iev += 1
        print('Event {}: Finding min/max detection times ... '.format(iev))
        mindet, maxdet = get_min_max_det(detections)
        yr = mindet.year
        jd = mindet.julday
        hr = mindet.hour
        mn = mindet.minute # need to round up minutes here
        # 2012.277.22.23.01
        evstri = '{0:4d}.{1:03d}.{2:02d}.{3:02d}'.format(yr, jd, hr, mn)
        print('Processing {0} detections for min det {1}'.format(len(detections),evstri))
        # check if evstri exists in evstrs, if so increment irep
        if evstri in evstrs:
            irep += 1
        else:
            evstrs.append(evstri)
            irep = 1
        # 2012.277.22.23.01
        evstr = '{0:s}.{1:02d}'.format(evstri, irep)
        evdir = windir + '/' + evstr
        print evdir
        if not os.path.exists(evdir):
            os.makedirs(evdir)
        pfile = evdir + '/' + evstr + '.pickfile'
        write_pfile(detections, pfile)
        sacstrt = mindet + twinb # twinb is negative for before picktime
        sacend = maxdet + twine
        # WINDOWS/2012.277.22.23.01/2012.277.22.23.00.HD37.HHZ
        # WINDOWS/2012.280.12.17.01/2012.280.12.16.42.HD36.HHZ
        print('Cutting SAC files ...')
        cutsac(storig, sacstrt, sacend, evdir, evstr)
        detections = []
        continue
    detections.append(line.strip())

"""
input event.file has detection lines like this, events separated
by blank line

2012 277 22 23 20.5200 P   0.0100  0.0100  0  0  0 HD66   HHZ    /data2/WF/Mongolia/S 0.329812E+08 Detection            20180709 111
2012 277 22 23 27.5100 P   0.0100  0.0100  0  0  0 HD29   HHZ    /data2/WF/Mongolia/S 0.267385E+09 Detection            20180709 111
2012 277 22 23 28.2100 P   0.0100  0.0100  0  0  0 HD28   HHZ    /data2/WF/Mongolia/S 0.178827E+07 Detection            20180709 111
2012 277 22 23 28.2400 P   0.0100  0.0100  0  0  0 HD30   HHZ    /data2/WF/Mongolia/S 0.321042E+10 Detection            20180709 111
2012 277 22 23 28.5000 P   0.0100  0.0100  0  0  0 HD27   HHZ    /data2/WF/Mongolia/S 0.197364E+07 Detection            20180709 111
2012 277 22 23 28.7800 P   0.0100  0.0100  0  0  0 HD52   HHZ    /data2/WF/Mongolia/S 0.139207E+08 Detection            20180709 111
"""


