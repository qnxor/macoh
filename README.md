MacOH
=====

Small tool for Mac OS X that automatically downloads and installs the needed tools and a video, then transcodes (x264) the video using all cores, monitoring CPU temperature and frequency which are then plotted versus time. Overheating and/or throttling, if any, are easily spotted.

I use it, but help with testing will be appreciated. For now, this automatically does the following:

- Grabs a number of free and open source tools
  - [Intel Power Gadget](https://software.intel.com/en-us/articles/intel-power-gadget-20) for measuring and logging temp, freq and power
  - [HandBrake CLI](http://handbrake.fr) for x264 encoding
  - [QGLE](http://glx.sourceforge.net) for plotting the results
- Grabs an open source 1080p movie weighing 691 MB
  - [Big Buck Bunny](http://www.bigbuckbunny.org)
- Transcodes the movie via x264 into 720p using all CPU cores (about 8 minutes on a 2.3 GHz Core i7 Haswell)
- monitors and logs CPU temperature and frequency while transcoding
- plots a graph of temperature and frequency vs. time
- reports max reached temp, max reached freq, duration and average encoding performance (FPS)

**Stress:** This tool is not meant to stress the CPU to unrealistic levels (like, for example, Prime95) but it is still above what even many very demanding tasks will achieve. It does not yet stress test the GPU but that's planned for a next version.

**Disclaimer:** As per the usual nitty gritty, I cannot be held responsible if your spouse leaves you as a result of running this tool, or worse: if your Mac gets damaged. Most likely you'll be just fine though.

## Usage

- Donwload and extract `macoh-x264.sh` in your home folder
- Then in Terminal do `bash ~/macoh-x264.sh`

That's about it, it will report what it does/needs. You can make it executable with `chmod u+x macoh-x264.sh` if you wish and then do `./macoh-x264.sh`.

It accepts an argument, `./macoh-x264.sh NAME`, where `NAME` is an identifier appended to output files. Default `NAME` is the current date as `yyyymmdd-HHMMSS`.

It writes only to your home folder, in `$HOME/Applications` (QGLE) and `$HOME/macoh` (everything else). The only exception is the Intel Power Gadget which is installed in /Applications. All tools can be uninstalled easily (see Todo below).

## Feedback

Tested on a fresh Mavericks 10.9.2, Hasswell Core i7-4850HQ, but should work on most recent Mac OSX versions and CPUs. Let me know if it worked for you on a different CPU and/or Mac OS so I can update the compatibility list. 

If it didn't work for you, you find bugs or have suggestions to improve it then by all means please [drop a line](https://github.com/qnxor/macoh/issues) here on GitHub.

Otherwise you can reach me via my homepage: http://www.damtp.cam.ac.uk/research/afha/bogdan

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

## Changelog

- 1.0.0-alpha, 2014-05-02 - first version
