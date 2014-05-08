MacOH
=====

Small tool for Mac OS X that automatically downloads and installs tools and content to run CPU or GPU stress tests, monitoring CPU temperature and frequency which are plotted versus time. CPU throttling and/or overheating, if any, are easily spotted. See a [sample graph output](http://www.damtp.cam.ac.uk/research/afha/people/bogdan/macoh/graph.gif) (no throttling there).

For now, it automatically does the following as needed:

- Grabs needed free and open source tools: [Intel Power Gadget](https://software.intel.com/en-us/articles/intel-power-gadget-20) (measuring and logging), [HandBrake CLI](http://handbrake.fr) (x264 transcoding), [Prime95](http://mersenne.org) (CPU stress), [GpuTest](http://www.geeks3d.com/gputest/) (GPU stress), [gfxCardStatus](http://gfx.io) (GPU switching), [Ggraphics Layout Engine](http://glx.sourceforge.net) (graph plotting), [ImageMagick](http://www.imagemagick.org) (better image processing than sips)
- Grabs the free movie [Big Buck Bunny](http://www.bigbuckbunny.org) in 1080p (692 MB)
- Can run x264 transcodes, Prime95, GpuTest or a custom command of your choice
- Monitors and logs CPU temperature and frequency while the test is underway
- Plots a graph of CPU temperature and frequency vs. time
- Reports some metrics of the x264 and GpuTest benchmarks

**Stress:** The Prime95 test is bound to cause throttling on laptops. It uses small in-place FFTs in a loop which cause stress levels that are simply not found in practice. The x264 is more realistic. Still stressful, but closer to what you'd meet in demanding apps.

**Disclaimer:** As per the usual nitty gritty, I cannot be held responsible if your spouse leaves you as a result of running this tool, or worse: if your Mac gets damaged. Most likely you'll be just fine though.

Usage
-----

1. [Donwload](https://github.com/qnxor/macoh/archive/master.zip) the zip and extract somewhere
1. Open Terminal and do `bash macoh.sh`
1. Choose a command in the (old school) menu

### Command line alternative

If you prefer typing or scripting, some command line options are available. The syntax is:

`bash macoh.sh [OPTION VALUE [OPTION VALUE ...]]`

#### Options

- `-do` - launch a test, one of: *gputest*, *x264*, *x264-long*, *prime95*, *gpuswitch*
- `-get` - fetch one of: *ipg*, *gle*, *gfx*, *imagick*, *video*, *handbrake*, *gputest*, *prime95*. These are downloaded as necessary upon launching of a test but can be invoked separately. The script will prompt if it detects already downloaded/installed items. Downloads are placed in $HOME/macoh/tmp and installations in $HOME/macoh/bin.
- `-cmd` - A user defined command to execute and monitor. This must be the last option in the command line, everything after it is considered part of the user command. You can use this to launch your own stress test to be monitored and have the temp and freq vs time plotted. The command must not terminate immediately (e.g. do not use ''open MyBenchmark.app''). Also take note of the duration value (`-t`) below. The -cmd option needs more thorough testing, please report bugs.
- `-t,-time` - change the duration of GpuTest or Prime95 (default is 3 minutes). Use 0 to run indefinitely. If a positive integer is passed then the script will kill the test after the specified duration. This is also used for the user defined command (see `-cmd`), and is useful since some tests lack a stop condition (e.g. Prime95)
- `-w,-wait` - waiting time before the test, to get idle temperature (default is 15 seconds)
- `-g,-gputest` - change the GpuTest type to one of: *fur*, *tess_x8*, *tess_x16*, *tess_x32*, *tess_x64*, *gi*,*pixmark_piano*, *pixmark_volplosion*, *plot3d*, *triangle* (default is *fur*, the FurMark benchmark)
- `-r,-res` - change the resolution of GpuTest (default is 1280x720)
- `-m,-msaa` - change the MSAA level of GpuTest to 0, 2, 4, or 8 (default is 2). 0 disables MSAA.
- `-s,-gpuswitch` - force the GPU to either of: **integrated**, **discrete** or **dynamic**. You can also use **1**, **2** or **3** instead of literals. This setting only affects laptops with dual GPU (e.g. Intel Iris Pro and Nvidia). Note that this persists even after the script exits. The default setting is **dynamic** (unless you altrered it priorly) which means that the discrete GPU is in 3D.

#### Command line examples

`macoh.sh -do x264 -wait 30` will launch the x264 transcode test with 30 seconds wait time beforehand, downloading and installing the tools and the video as needed (skipping those already done), and generating `~/macoh/${DATE}-graph.gif`, `~/macoh/logs/${DATE}-ipg.csv` and `~/macoh/logs/${DATE}-hb.log`.

`macoh.sh -do gputest -wait 10 -res 1600x900 -msaa 0 -gputest tess_x32` will launch the TessMark test from GpuTest in a 1600x900 window with MSAA disabled and a wait time beforehand of 10 seconds.

`macoh.sh -time 120 -cmd /Applications/Heaven.app/Contents/MacOS/heaven` will launch the Unigine Heaven 3D benchmark if you have it installed and will kill it after 120 seconds. YOu will have to start the benchmark manually once the app opens.

**Conf file:** There is a `macoh.conf` configuration file which you can edit and which contains more options (e.g. Prime95 options). This is sourced directly by Bash in the main script so just make sure you use valid Bash syntax.

**Executable:** You can make it executable with `chmod u+x macoh.sh` if you wish, and then do `./macoh.sh`.

**Folders:** The script downloads and writes only to your home dir, in `$HOME/macoh` by default. The only exception is Intel Power Gadget which is installed in /Applications.

**Uninstall:** /Applications > Intel Power Gadget > Uninstaller, and also `rm -rf ~/macoh/*/` (wipe everything except the generated graphs and downloaded video).

Feedback
--------

There is a [thread on MacRumors](http://forums.macrumors.com/showthread.php?t=1731178) which started containing results of this script and discussions on findings. Your contribution there would be very welcome.

So far it seems to work fine on Mac OSX Mavericks and recent hardware (Ivy Bridge and Haswell). If it doesn't work for you, you find bugs or have suggestions then by all means please [drop a line on Github](https://github.com/qnxor/macoh/issues).

You can also reach me at http://www.damtp.cam.ac.uk/user/abr28

Known issues
------------

Prime95 v28.5-beta for Mac seems buggy, it doesn't always start the torture test as instructed when the GUI opens, but instead opens and sits idle. If that happens, once the GUI opens do it manually: `Options` > `Torture Test` > `Custom` > `MinFFT=8, MaxFFT=8, RunFFTsInPlace=Checked, TimeForEachFFT=5` > `Run`

Prime95 v27.9 doesn't play well with Haswell and the other v28 betas have the same issue.

Todo
----

- Fan speed monitoring +graph, anyone knows of a free tool to read RPM from command line?
- Avg and stddev between start+wait+5sec and end-wait-5sec
- GpuTest results
- Uninstall/clean option
- Auto-upload results and graph somewhere (with prompt)?
- Cross-platform version?

Changelog
---------

- 1.1.2-beta, 2014-05-08 - Added GPU switching to command line.
- 1.1.1-beta, 2014-05-07 - Bug fixing release. 
- 1.1.0-beta, 2014-05-06 - Added GpuTest, Prime95, gfxCardStatus, longer x264 test, more command line options.
- 1.0.1-alpha, 2014-05-03 - Added command line options to bypass menu
- 1.0.0-alpha, 2014-05-02 - First version
