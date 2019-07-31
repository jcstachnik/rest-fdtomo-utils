from obspy import read,Stream,UTCDateTime
from glob import glob
import matplotlib.pyplot as plt
import numpy as np
from fdtomo import fdloc2catalog
import argparse

def getargs():
    parser = argparse.ArgumentParser(description=
    '''
    Plot waveforms and estimation function 
    ''',
    epilog=
    '''
    Example: 
    python plot_rest_est.py -f fdloc.final -s "*HHZ" -P 1.0 -p 2.0

    TODO: 
    Plot pick uncertainty
    Show picks not used in location as different color
    Show Origin information
    Indicate time window
    Add filter band as command line args
    Add logging
    Add showfig as command line option
    ''',
    formatter_class=argparse.RawTextHelpFormatter)
    helpmsg = "Name of fdloc format file. "
    parser.add_argument("-f","--fdfile",required=True, type=str,
                        help=helpmsg)
    helpmsg = "Pretime before arrival in seconds [2]. "
    parser.add_argument("-P","--pre",required=False, type=float,
                        default=2.0,
                        help=helpmsg)
    helpmsg = "Post time after arrival in seconds [2]. "
    parser.add_argument("-p","--post",required=False, type=float,
                        default=2.0,
                        help=helpmsg)
    helpmsg = "Lower corner frequency [1.0 Hz]. "
    parser.add_argument("--fmin",required=False, type=float,
                        default=1.0,
                        help=helpmsg)
    helpmsg = "Upper corner frequency [15.0 Hz]. "
    parser.add_argument("--fmax",required=False, type=float,
                        default=15.0,
                        help=helpmsg)
    helpmsg = "Number of passes [2]. "
    parser.add_argument("--passes",required=False, type=int,
                        default=2,
                        help=helpmsg)
    helpmsg = "File Subset. Should be channel pattern [*HHZ]."
    parser.add_argument("-s","--sub",required=False, type=str,
                        default='*HHZ',
                        help=helpmsg)
    helpmsg = "Base name for saving files [Event]."
    parser.add_argument("-b","--base",required=False, type=str,
                        default='Event',
                        help=helpmsg)
    helpmsg = "Do Not show figures to screen."
    parser.add_argument("--noshow",required=False, type=bool,
                        default=False,
                        help=helpmsg)

    args = parser.parse_args()
    return args,parser

def get_at_from_event(ievent, sta, chan):
    picks = ievent.picks
    for i,pik in enumerate(picks):
        if str(pik.waveform_id.station_code) == str(sta) and \
            str(pik.waveform_id.channel_code) == str(chan):
            return pik.time,pik.time_errors
    return None,None

def plotwf(obs, est, showfig=True, block=False,
                pltname='Test', title='Example', savefig=False):
    """
    obs: Obspy Stream
    est: Obspy Stream

    """

    outdir = './'
    # copy the input Streams
    st = obs.copy()
    if est is not None:
        gr = est.copy()
    else:
        gr = None
    # number of stations
    #StazOb = getSTationslist(st)
    #StazOb = obs
    nsta = len(obs) # hack

    Xsize = 8.5
    Ysize = 11.0

    # number of figures
    nperpage = 30 # should be factor of 3
    F = int(nsta/nperpage) + 1
    i=0
    # loop over figures F
    for f in range(F):
        p = 3
        u = 12
        nrPage = 'Page ' + str(f+1) + '/' + str(F)
        page   = str(f+1) + '-' + str(F)
        name = pltname + page
        ofname = pltname + page
        # number of stations for each plot
        if((f+1) < F):
           nr = nperpage
        else:
           nr = nsta - (F-1)*nperpage
        nr *= 1
        #  Initialize figure
        ff = title+'_'+str(f)
        fig=plt.figure(ff,figsize=(Xsize,Ysize),facecolor='w')
        p=3
        tlen0 = 0
        newbox=False
        for k in range(0,nr):
             p=p+1
             d = "%s,%s,%s" % (u,3,p)
             ax1=fig.add_subplot(u,3,p)
             sttime = st[i].times()
             stdat = st[i].data / np.abs(st[i].data).max()
             #ax1=plt.plot(sttime,st[i].data,color='k',linewidth=2.0)
             ax1=plt.plot(sttime, stdat, color='k', linewidth=1.0)
             ax1=plt.axvspan(2-st[i].stats.arrival_time_error.uncertainty, 
                            2+st[i].stats.arrival_time_error.uncertainty, alpha=0.5, color='red')
             if gr is not None:
                grtime = gr[i].times()
                grdat = gr[i].data / gr[i].data.max()
                #ax1=plt.plot(grtime,gr[i].data,color='r', linewidth=0.75)
                ax1=plt.plot(grtime, grdat, color='r', linewidth=0.75)
                #ax1=plt.vlines(x=0, ymin=-1, ymax=1, color='b', linestyle=':')
                ax1=plt.vlines(x=2., ymin=-1, ymax=1, color='b', linestyle=':')

             info=st[i].stats.station+'_'+st[i].stats.channel 
             ax1=plt.title(info,fontsize=8,loc='left')
             ax1=plt.axis('off')
             i = i+1
        #fig.savefig(ofname, bbox_inches='tight')
        #fig.savefig(ofname+'.eps', format='eps', bbox_inches='tight')
        fig.savefig(ofname+'.pdf', format='pdf', bbox_inches='tight')
    if showfig:
        plt.show()

# -------------------------------------------------
if __name__ == "__main__":
    args,parser = getargs()
    cat = fdloc2catalog(args.fdfile)

    showfig = True 
    if args.noshow:
        showfig = False
    ievent = cat[0]
    iorigin = ievent.origins[0]
    ot = iorigin.time
    fmn=1.0
    fmx=15.0
    pre = args.pre
    post = args.post
    sub = args.sub
    stz = read(sub)
    stz.sort(keys=['station'])

"""
    if bessel:
        order = 3
        sps = 100
        nyq = sps/2
        Wn = [fmn/nyq, fmx/nyq]
        b, a = signal.bessel(order, Wn, 'bandpass')
        data_filt1 = signal.lfilter(b, a, data)
        data_filt2 = signal.filtfilt(b, a, data)
"""

    obsall = Stream()
    estall = Stream()
    for i,trz in enumerate(stz):
        tro = trz.copy()
        sta = trz.stats.station
        zchan = trz.stats.channel
        at,tres = get_at_from_event(ievent, sta, zchan)
        if at is None:
            continue
        #data_filt = signal.filtfilt(b, a, trz.data)
        #tro.data = data_filt
        trz.detrend(type='demean')
        #trz.filter(type='bandpass', freqmin=fmn, freqmax=fmx, corners=4, zerophase=True)
        trz.filter(type='bandpass', freqmin=fmn, freqmax=fmx, corners=4, zerophase=False)
        trz.detrend(type='demean')
        trz.trim(starttime=at-pre, endtime=at+post)
        trz.stats.arrival_time = at
        trz.stats.arrival_time_error = tres
    
        efil = glob('*{0}.{1}.est'.format(sta,zchan))
        if (len(efil) < 1):
            est = Stream()
        else:
            ez = read(efil[0])[0]
            ez.detrend(type='demean')
            ez.trim(starttime=at-pre, endtime=at+post)
            #edat = est.data / np.abs(est.data).max()
            obsall += trz
            estall += ez
    if len(estall)>0:
        plotwf(obsall, estall, pltname='Event_string', 
                title='Origin_Info_Here',
                showfig=showfig)
    else:
        plotwf(obsall, None, pltname='Event_string', 
                title='Origin_Info_Here',
                showfig=showfig)


"""
#at = HD39  2012 280 11  6  19.299 P           0.220     -0.445
at = UTCDateTime("2012-280T11:06:19.299")

sta = 'HD39'
obs = read('2012.280.11.05.15.{0}.HH?'.format(sta))
ests = read('2012.280.11.05.15.{0}.HH*.est'.format(sta))
obs.filter(type='bandpass', 
            freqmin=fmn, freqmax=fmx, 
            corners=4, zerophase=True)

trz = obs.select(channel='HHZ')[0].detrend(type='demean')
ez = ests.select(channel='HHZ')[0].detrend(type='demean')

trz.trim(starttime=at-pre, endtime=at+post)
ez.trim(starttime=at-pre, endtime=at+post)

#zdat = trz.data/np.abs(trz.data.max()).max()
zdat = trz.data/np.abs(trz.data).max()
edat = ez.data/ez.data.max()

rt = trz.times(reftime=at)

fig,ax = plt.subplots()
ax.plot(rt, zdat)
ax.plot(rt, edat)
ax.vlines(x=0, ymin=-1, ymax=1, color='k', linestyle=':')

#ax.plot(rt,zdat+1)
#ax.plot(rt,edat+1)

#plt.show()
plt.savefig('out.png', format='png')

stz=read('*HHZ')
plotwf(stz,None)

"""


