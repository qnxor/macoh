MacOH 1.3.1-beta
================

Small tool for Mac OS X that automatically downloads and installs tools and content and runs CPU or GPU stress tests, monitoring CPU temperature and frequency which are plotted versus time. The purpose is to evaluate CPU throttling and/or overheating (not performance).

Output examples: [x264](http://www.damtp.cam.ac.uk/research/afha/people/bogdan/macoh/x264.png) (no throttling), [Prime95](http://www.damtp.cam.ac.uk/research/afha/people/bogdan/macoh/prime95.png) (heavy throttling), [3D-Intel 5100](http://www.damtp.cam.ac.uk/research/afha/people/bogdan/macoh/gputest-irispro.png) (throttling), [3D-Nvidia 750M](http://www.damtp.cam.ac.uk/research/afha/people/bogdan/macoh/gputest-gt750m.png) (no throttling).

- Grabs free and open source tools as needed: [Intel Power Gadget](https://software.intel.com/en-us/articles/intel-power-gadget-20) (measuring and logging), [HandBrake CLI](http://handbrake.fr) (x264 transcoding), [Prime95](http://mersenne.org) (CPU stress), [GpuTest](http://www.geeks3d.com/gputest/) (GPU stress), [gfxCardStatus](http://gfx.io) (GPU switching), [Ggraphics Layout Engine](http://glx.sourceforge.net) (graph plotting), [ImageMagick](http://www.imagemagick.org) (better image processing than sips)
- Grabs the free movie [Big Buck Bunny](http://www.bigbuckbunny.org) in 1080p (692 MB) as needed
- Can run x264 transcodes, Prime95, GpuTest or a custom command/script of your choice
- Monitors and logs CPU temperature and frequency during the test
- Plots a graph of CPU temperature and frequency vs. time

Expect Prime95 to cause throttling on laptops. The x264 test is more realistic; still stressful, but closer to what you'd meet in demanding apps. The 3D GpuTest, when run on integrated GPU, can also cause CPU throttling.

Feedback
--------

The [dedicated thread on MacRumors forums](http://forums.macrumors.com/showthread.php?t=1731178) started containing results and discussions. Your contribution there would be very welcome. If it doesn't work for you, or if you find bugs, have suggestions, questions or comments then [drop a line on Github](https://github.com/qnxor/macoh/issues) or just [contact](http://www.damtp.cam.ac.uk/user/abr28) me.

**Disclaimer:** As per the usual nitty gritty, I cannot be held responsible if your spouse leaves you after running this tool, or worse: if your Mac gets damaged. Most likely you'll be just fine though.

Usage
-----

1. [Donwload](https://github.com/qnxor/macoh/archive/master.zip) the zip and extract somewhere
1. Open Terminal and do `bash macoh.sh`
1. Choose a command in the (old school) menu

#### Config file

There is a `macoh.conf` configuration file which you can edit it to set various options (defaults). It is sourced by Bash in the main script so make sure you use valid Bash syntax.

#### Command line alternative

`bash macoh.sh [-OPTION VALUE [-OPTION VALUE ...]]`

Where -OPTION VALUE can be:

- `-do` - launch a test, one of: *x264*, *x264-long*, *gputest*, *prime95*
- `-get` - fetch one of: *ipg*, *gle*, *gfx*, *imagick*, *video*, *handbrake*, *gputest*, *prime95*. These are downloaded as necessary upon launching of a test but can be invoked separately. The script will prompt if it detects already downloaded/installed items. Downloads are placed in $HOME/macoh/tmp and installations in $HOME/macoh/bin.
- `-cmd` - A user defined command to execute and monitor. This must be the last option in the command line, everything after it is considered part of the user command. You can use this to launch your own stress test to be monitored and have the temp and freq vs time plotted. The command must not terminate immediately (e.g. do not use ''open MyBenchmark.app''). Also take note of the duration value (`-t`) below. The -cmd option needs more thorough testing, please report bugs.
- `-t,-time` - duration of Prime95, GpuTest and user defined command in seconds, use 0 to run indefinitely (default is 600 for GpuTest and 300 for the rest, see macoh.conf). Prime95 and the user defined command are assumed to run indefintely by default, so this option is used to stop them, unless they exit or if you abort them early.
- `-w,-wait` - waiting time before the test, to get idle temperature (default is 15 seconds, see macoh.conf)
- `-g,-gputest` - change the GpuTest type to one of: *fur*, *tess_x8*, *tess_x16*, *tess_x32*, *tess_x64*, *gi*,*pixmark_piano*, *pixmark_volplosion*, *plot3d*, *triangle* (default is *tess_x64*, see macoh.conf)
- `-r,-res` - change the resolution of GpuTest (default is 1280x720, unless altered in macoh.conf)
- `-m,-msaa` - change the MSAA level of GpuTest to 0 (disabled), 2, 4, or 8 (default is 2, see macoh.conf).
- `-s,-gpuswitch` - force the GPU to either of: **integrated**, **discrete** or **dynamic**. You can also use **1**, **2** or **3** as synonyms. This setting only affects laptops with dual GPU (e.g. Intel Iris Pro and Nvidia). Note that this persists even after the script exits. The default setting is **dynamic** (unless you altrered it priorly) which means that the discrete GPU is in 3D. If you do not specify `-do` or `-cmd` then the script will exit after swicthing GPU (useful for scripting).

#### Command line examples

`macoh.sh -do x264 -wait 30` will launch the x264 transcode test with 30 seconds wait time beforehand and afterwards, downloading and installing the tools and the video as needed (skipping those already done), and generating `$HOME/macoh/${DATE}-x264.png`, `$HOME/macoh/logs/${DATE}-ipg.csv` and `$HOME/macoh/logs/${DATE}-hb.log`.

`macoh.sh -do gputest -wait 10 -res 1600x900 -msaa 0 -gputest tess_x64` will launch the TessMark test from GpuTest in a 1600x900 window with MSAA disabled and a wait time beforehand and afterwards of 10 seconds.

`macoh.sh -time 180 -cmd /Applications/Heaven.app/Contents/MacOS/heaven` will launch the Unigine Heaven 3D benchmark (installed separately) and will kill it after 180 seconds unless you quit it by then. You must start the Heaven benchmark manually once its app GUI opens since the script has no control over it.

#### Uninstall, Folders, etc.

To unistall, do: *(1)* /Applications > Intel Power Gadget > Uninstaller and *(2)* `rm -rf ~/macoh/*/*`. The latter wipes everything except generated graphs and downloaded video (note the `/*/*`).

The script writes only to your home dir in `$HOME/macoh`. The only exception is Intel Power Gadget which is installed in /Applications.

You can make it executable with `chmod u+x macoh.sh` and then do `./macoh.sh`.

Known issues
------------

gfxCardStatus has [a bug](https://github.com/codykrieger/gfxCardStatus/issues/103), it needs somes convincing to switch the GPU. The `macoh` script makes two attempts and normally gets it. Just in case it doesn't, you may need to insist or open the app normally (via Finder/Spotlight) and switch the GPU there.

Todo
----

- [ ] Fan speed monitoring +graph (any free tool?) [#2](//github.com/qnxor/macoh/issues/2)
- [ ] GPU freq and temp monitoring +graph (any free tool?) [#6](//github.com/qnxor/macoh/issues/6)
- [x] Add GPU testing
- [x] Add Prime95
- [ ] Avg and stddev between start+wait+5sec and end-wait-5sec [#3](//github.com/qnxor/macoh/issues/3)
- [x] GpuTest results
- [ ] Uninstall/clean option [#4](//github.com/qnxor/macoh/issues/4)
- [ ] Auto-upload results and graph somewhere (with prompt)?
- [ ] Cross-platform version?
