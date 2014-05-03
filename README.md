MacOH
=====

Small tool for Mac OS X that automatically downloads and installs the needed tools and a video, then transcodes (x264) the video using all cores, monitoring CPU temperature and frequency which are then plotted versus time. CPU throttling and/or overheating, if any, are easily spotted. See a [sample graph output](http://www.damtp.cam.ac.uk/research/afha/people/bogdan/macoh/graph.gif) (no throttling there).

For now, it automatically does all of the following:

- Grabs needed free and open source tools: [Intel Power Gadget](https://software.intel.com/en-us/articles/intel-power-gadget-20) (measuring and logging), [HandBrake CLI](http://handbrake.fr) (x264 transcoding), [GLE](http://glx.sourceforge.net) (plotting)
- Grabs the free movie [Big Buck Bunny](http://www.bigbuckbunny.org) in 1080p (692 MB)
- Transcodes the movie using all CPU cores (5+ minutes depending on CPU type and speed)
- Monitors and logs CPU temperature and frequency while transcoding
- Plots a graph of temperature and frequency vs. time
- Reports max reached temp, duration and encoding performance (FPS)

**Stress:** It's not meant to put unrealistically high stress on the CPU (like, for example, Prime95) but it does stress it more than most demanding tasks. GPU stress is planned for the next version (see [Todo](#todo)).

**Disclaimer:** As per the usual nitty gritty, I cannot be held responsible if your spouse leaves you as a result of running this tool, or worse: if your Mac gets damaged. Most likely you'll be just fine though.

## Usage

Simple:

1. Donwload and extract `macoh-x264.sh` somewhere
1. Open Terminal and do `bash macoh-x264.sh`
1. Choose 0 from the (old school) command menu

It accepts optional arguments: `macoh-x264.sh [-ACTION] [NAME]`, where `NAME` is an identifier prepended to output files which must not start with a dash `-`; default is the current date as `yyyymmdd-HHMMSS`. You can skip the menu by specifying `-ACTION` as either `-start`, `-get-handbrake`, `-get-ipg`, `-get-video` or `-get-gle`. 

For example, `macoh-x264.sh -start run1` will launch the process, downloading and installing as needed (skipping if it had already done those steps), and generating `~/macoh/run1-graph.gif`, `~/macoh/logs/run1-ipg.csv` and `~/macoh/logs/run1-hb.log`.

You can make it executable with `chmod u+x macoh-x264.sh` if you wish, and then do `./macoh-x264.sh`.

It downloads and writes only to your home dir, in `$HOME/Applications` (GLE) and `$HOME/macoh` (everything else). The only exception is Intel Power Gadget which is installed in /Applications. See [Todo](#todo) for uninstall.

## Feedback

Tested on Mavericks 10.9.2, Core i7-4850HQ (rMBP Late 2013). Should work on most recent Macs. Let me know if it worked for you on a different CPU and/or Mac OSX. If it didn't work for you, you find bugs or have suggestions to improve it then by all means please [drop a line on Github](https://github.com/qnxor/macoh/issues).

You can also reach me at http://www.damtp.cam.ac.uk/research/afha/bogdan

## Todo

- Add uninstall option. For now, do it manually in 3 steps:
  - /Applications > Intel Power Gadget > Uninstaller
  - ~/Applications > QGLE ... move to trash,
  - `rm -rf ~/macoh/*/` (this preserves the movie and plots)
- Regression between start+wait+5sec and end-cool-5sec to auto detect throttle
- Avg and stddev for freq between above bounds
- Same for temp between start+wait+60sec and end-cool-5sec
- Add fan speed monitoring and logging (+graph)
- Add 3D benchmark for GPU stress testing
- Cross-platform or multi-platform versions?
- Maybe also auto-upload the results and .png somewhere?

## Changelog

- 1.0.1-alpha, 2014-05-03 - added command line options to bypass menu
- 1.0.0-alpha, 2014-05-02 - first version
