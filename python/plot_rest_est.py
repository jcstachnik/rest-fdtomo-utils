from obspy import read,Stream,UTCDateTime
from glob import glob
import matplotlib.pyplot as plt
import numpy as np
from fdtomo import fdloc2catalog
import argparse
from obspy.signal.util import smooth

def getargs():
    parser = argparse.ArgumentParser(description=
    '''
    Plot waveforms and estimation function 
    ''',
    epilog=
    '''
    Example: 
    python plot_rest_est.py -f fdloc.final -s "*HHZ" -P 1.0 -p 2.0
    plot_rest_est.py -f fdloc.final --fmin 10. --fmax 300. 
            -s "*.Z" -P 0.2 -p 0.2 -Z Z -H N
    plot_rest_est.py -f fdloc.final --fmin 10. --fmax 300. 
            -s "*.N" -P 0.2 -p 0.2 -Z Z -H N


    TODO: 
    Show Origin information
    Add logging
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
    helpmsg = "Channel name for P picks (Z channel) [HHZ]."
    parser.add_argument("-Z","--zchan",required=False, type=str,
                        default='HHZ',
                        help=helpmsg)
    helpmsg = "Channel name for S picks (Horiz channel) [HHN]."
    helpmsg += "Note: REST outputs estimation function on N only for S."
    parser.add_argument("-H","--hchan",required=False, type=str,
                        default='HHN',
                        help=helpmsg)
    helpmsg = "Base name for saving files [Event]."
    parser.add_argument("-b","--base",required=False, type=str,
                        default='Event_string',
                        help=helpmsg)
    helpmsg = "Do Not show figures to screen."
    parser.add_argument("--noshow",required=False, action='store_true',
                        default=False,
                        help=helpmsg)
    helpmsg = "Plot waveforms that do not have a pick. Default is to skip them."
    parser.add_argument("--plot_nopick",required=False, action='store_true',
                        default=False,
                        help=helpmsg)

    args = parser.parse_args()
    return args,parser

def get_at_from_event(ievent, sta, chan):
    picks = ievent.picks
    arrs = ievent.origins[0].arrivals # assume 1 orig
    for i,pik in enumerate(picks):
        if str(pik.waveform_id.station_code) == str(sta) and \
            str(pik.waveform_id.channel_code) == str(chan):
            for j,ar in enumerate(arrs):
                if pik.resource_id == ar.pick_id:
                    return pik.time, pik.time_errors, pik.evaluation_status, ar.time_residual
    return None,None,None,None

def plotwf(obs, est, showfig=True, block=False,
                pltname='Test', title='Example', savefig=False,
                pret=2., post=2.):
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
        print('{0} stas in plot {1}'.format(nr,f))
        ff = title+'_'+str(f)
        fig=plt.figure(ff,figsize=(Xsize,Ysize),facecolor='w')
        fig.suptitle(title, fontsize=8, y=0.91)
        p=0 # was 3 to have 1 row offset
        tlen0 = 0
        newbox=False
        for k in range(0,nr):
             p=p+1
             ax1=fig.add_subplot(u,3,p)
             ax1.set(xlim=(-pret, post), ylim=(-1, 1))
             #sttime = st[i].times()
             sttime = st[i].times(reftime=st[i].stats.arrival_time)
             stdat = st[i].data / np.abs(st[i].data).max()
             #ax0=plt.plot(sttime, stdat, color='k', linewidth=1.0)
             ax1.plot(sttime, stdat, color='k', linewidth=1.0)
             if st[i].stats.eval_status == 'confirmed':
                 boxcolor = 'lightskyblue'
             else:
                 boxcolor = 'tomato'
             #ax0=plt.axvspan(pret-st[i].stats.arrival_time_error.uncertainty, 
             #               pret+st[i].stats.arrival_time_error.uncertainty, alpha=0.5, color=boxcolor)
             ax1.axvspan(-st[i].stats.arrival_time_error.uncertainty, 
                            st[i].stats.arrival_time_error.uncertainty, alpha=0.5, color=boxcolor)
             ax1.vlines(x=0., ymin=-1, ymax=1, color='b', linestyle=':')
             if gr is not None:
                #grtime = gr[i].times()
                grtime = gr[i].times(reftime=st[i].stats.arrival_time)
                #grdat = gr[i].data / gr[i].data.max()
                gg = smooth(gr[i].data, 5)
                grdat = gg / gg.max()
                ax1.plot(grtime, grdat, color='r', linewidth=0.75)

             info=st[i].stats.station+'_'+st[i].stats.channel 
             info='{0}_{1} {2} {3:.3f}'.format(st[i].stats.station, st[i].stats.channel, 
                                        st[i].stats.arrival_time_error.uncertainty,
                                        st[i].stats.time_residual)
             #ax1=plt.title(info,fontsize=8,loc='left')
             plt.title(info,fontsize=6,loc='left')
             # only plot the bottom xaxis on last subplot of page
             if k==nr-1:
                #ax1=plt.axis('on')
                #ax1=plt.axes(frameon=False)
                #ax1.get_xaxis().tick_bottom()
                #ax1.axes.get_yaxis().set_visible(False)
                ax1.spines['right'].set_visible(False)
                ax1.spines['top'].set_visible(False)
                ax1.spines['left'].set_visible(False)
                #ax1.xaxis.set_ticks_position('bottom')
                ax1.tick_params(left=False)
                ax1.set_yticklabels([])
             else:
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
    cat = fdloc2catalog(args.fdfile, 
                        Zch=args.zchan, 
                        Hch=args.hchan)

    showfig = True 
    if args.noshow:
        showfig = False
    plot_nopick = False
    if args.plot_nopick:
        plot_nopick = True
        #print('plot_nopick=True, INCLUDING Waveforms w/o pick')
        print('plot_nopick=True, NOT IMPLEMENTED')
    ievent = cat[0]
    iorigin = ievent.origins[0]
    ot = iorigin.time
    fmn=args.fmin
    fmx=args.fmax
    pre = args.pre
    post = args.post
    sub = args.sub
    stz = read(sub)
    stz.sort(keys=['station'])
    pltbase = args.base
    ot = cat[0].origins[0].time.format_iris_web_service()
    la = cat[0].origins[0].latitude
    lo = cat[0].origins[0].longitude
    z = cat[0].origins[0].depth/1000
    origin_string = f'{ot} Lat: {la:.3f} Lon: {lo:.3f} Dep: {z:.3f} km'
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
        #at,aterr,evstat = get_at_from_event(ievent, sta, zchan)
        at,aterr,evstat,atres = get_at_from_event(ievent, sta, zchan)
        if at is None:
            if plot_nopick:
                continue
                #print('No arrival time for {}'.format(sta))
                #at = trz.stats.starttime
                #pre=0
                #post=trz.stats.endtime - trz.stats.starttime
                #aterr={'uncertainty':0}
                #evstat='confirmed'
                #atres=0
            else:
                print('No arrival time for {}, Skipping'.format(sta))
                continue
        #data_filt = signal.filtfilt(b, a, trz.data)
        #tro.data = data_filt
        trz.detrend(type='demean')
        #trz.filter(type='bandpass', freqmin=fmn, freqmax=fmx, corners=4, zerophase=True)
        trz.filter(type='bandpass', freqmin=fmn, freqmax=fmx, corners=4, zerophase=False)
        trz.detrend(type='demean')
        trz.trim(starttime=at-pre, endtime=at+post)
        trz.stats.arrival_time = at
        trz.stats.arrival_time_error = aterr
        trz.stats.eval_status = evstat # confirmed or rejected whether its used or not in rest,fdtomo
        trz.stats.time_residual = atres # travel time residual
    
        efil = glob('*.{0}.{1}.est'.format(sta,zchan))
        if (len(efil) < 1):
            est = Stream()
        else:
            ez = read(efil[0])[0]
            ez.detrend(type='demean')
            ez.trim(starttime=at-pre, endtime=at+post)
            #edat = est.data / np.abs(est.data).max()
            obsall += trz
            estall += ez
    print('Nobs {0} Nest {1}'.format(len(obsall), len(estall)))
    if len(estall)>0:
        plotwf(obsall, estall, pltname=pltbase, 
                title=origin_string,
                showfig=showfig, pret=pre, post=post)
    else:
        plotwf(obsall, None, pltname='Event_string', 
                title='Origin_Info_Here',
                showfig=showfig, pret=pre, post=post)


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


