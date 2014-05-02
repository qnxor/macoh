macoh
=====

Automated stress tests for measuring throttle and temperature on Macs

It automatically downloads and installs the needed tools and a video to run an x264 transcoding, monitoring CPU temperature and frequency which are then plotted versus time. For now, this automatically does the following:

- grabs a number of free and open source tools
  - [Intel Power Gadget](https://software.intel.com/en-us/articles/intel-power-gadget-20) for measuring and logging temp, freq and power
  - [HandBrake CLI](http://handbrake.fr) for x264 encoding
  - [QGLE](http://glx.sourceforge.net) for plotting the results
- grabs an open source movie
  - [Big Buck Bunny](http://www.bigbuckbunny.org) (691 MB, 1080p)
- performs an x264 transcoding of the movie into 720p using all CPU cores (about 8 minutes on a 2.3 GHz Core i7 Haswell)
- monitors and logs CPU temperature and frequency while transcoding
- plots a graph of temperature and frequency vs. time
- reports max reached temp, max reached freq, duration and average encoding performance (FPS)

The movie download may take a while depending on your connection. The other tools are much smaller.

## Usage

- Donwload and extract `macoh-x264.sh` somewhere in your home folder
- Do `chmod u+x ~/macoh-x264.sh`
- Then do `~/macoh-x264.sh`

That's about it. It will tell you what it does/needs. You can optionally do `~/macoh-x264.sh NAME` where `NAME` is some identifier for the test, by default `NAME` will be the current date and time in the format `yyyymmdd-HHMMSS`.

It's been tested only on Mavericks 10.9.2 but should work on most recent Mac OSX versions. Please do report if not (file an issue here on GitHub).

It writes only to your home folder, in `$HOME/Applications` (QGLE) and `$HOME/macoh` (everything else). The only exception is the Intel Power Gadget which is installed in /Applications. All tools can easily be uninstalled and erased.

## Todo

- Add uninstall option. For now, do it manually:
  - /Applications > Intel Power Gadget > Uninstall
  - ~/Applications > QGLE ... move to trash,
  - `rm -rf ~/macoh/*/` (this preserves the movie and plots)
- Add 3D benchmark for GPU stress testing
- Cross-platform or multi-platform versions?
- Linear regression between start+wait+5sec and end-cool-5sec to auto detect throttle
- Avg and stddev for freq between above bounds
- Same for temp between start+wait+60sec and end-cool-5sec
- Maybe also auto-upload the results and .png somewhere?
