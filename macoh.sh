#!/bin/bash
#
# GitHub project: https://github.com/qnxor/macoh
# Bogdan Roman, University of Cambridge, 2014
# http://www.damtp.cam.ac.uk/research/afha/bogdan
#

set -e

# Default vars. DO NOT CHANGE THESE. Edit macoh.conf instead.

home=~/macoh
usercmd=''
waitstart=15
waitend=15
timeout=180
gputest=tess_x64
gpuwidth=1280
gpuheight=720
gpumsaa=2
p95minfft=8
p95maxfft=8
p95mem=8
p95timefft=5
p95nice=10
menuquit=0
mov=big_buck_bunny_1080p_h264.mov
# mkv=$home/big_buck_bunny_1080p_h264_transcoded.mkv
mkv=/dev/null
gputesttypes='fur, tess_x8, tess_x16, tess_x32, tess_x64, gi, pixmark_piano, pixmark_volplosion, plot3d, triangle'
testid=`date +%Y%m%d-%H%M%S`
url_ipg="https://software.intel.com/sites/default/files/IntelPowerGadget3.0.1.zip"
url_handbrake="http://heanet.dl.sourceforge.net/project/handbrake/0.9.9/HandBrake-0.9.9-MacOSX.6_CLI_x86_64.dmg"
url_gle="http://heanet.dl.sourceforge.net/project/glx/gle4%20(Current%20Active%20Version)/4.2.4c/gle-graphics-4.2.4c-exe-mac.dmg"
url_video="http://blender-mirror.kino3d.org/peach/bigbuckbunny_movies/big_buck_bunny_1080p_h264.mov"
url_prime95="ftp://mersenne.org/gimps/p95v285.MacOSX.zip"
url_gputest="http://www.ozone3d.net/gputest/dl/GpuTest_OSX_x64_0.7.0.zip"
url_gputest_referer="http://www.geeks3d.com/20140304/gputest-0-7-0-opengl-benchmark-win-linux-osx-new-fp64-opengl-4-test-and-online-gpu-database/"
url_gfx="https://github.com/qnxor/macoh/raw/master/gfxCardStatus.tgz"
url_im="http://www.imagemagick.org/download/binaries/ImageMagick-x86_64-apple-darwin13.1.0.tar.gz"


#------------------------------ Core functions ------------------------------#

die () {
	local code=$1; shift; echo "Error: $@." >&2; exit $code
}
err () {
	local code=$1; shift; echo "Error: $@." >&2; return $code
}
mnt () { 
	hdiutil attach "$1" >/dev/null
}
umnt () {
	diskutil unmount "$1" >/dev/null
}
wget () {
	curl -L -o "$@"
}
stddev () {
	# awk '{ delta = $1 - avg; avg += delta / NR; mean2 += delta * ($1 - avg); } END { print sqrt(mean2 / NR); }'
	awk '{sum+=$1; sumsq+=$1*$1} END {print sqrt(sumsq/NR - (sum/NR)**2)}'
}
mean () {
	awk '{ delta = $1 - avg; avg += delta / NR; } END { print avg; }'
}
humantime () {
	[[ $t -ge 86400 ]] && echo -n $(($1/86400))d
	[[ $1 -ge 3600  ]] && echo -n $((($1%86400)/3600))h
	# [[ $1 -ge 60    ]] && echo -n $((($1%3600)/60))m
	echo $((($1%3600)/60))m$(($1%60))s
}
editconf () {
	local val
	[[ $2 =~ ^[0-9]+$ ]] && val=$2 || val="'$2'"
	eval "$1=$val"
	cp -f "$conf" "$conf~"
	sed -E "s:^$1=.*:$1=${val//:/\\:}:" "$conf~" > "$conf"
}
silentkill () {
	# Die with dignity. Kill if stubborn.
	# Add brackets ( ) around bg processes so we suppress "stopped" messsages
	( { sleep 0.25; kill -TERM $* &>/dev/null; } & )
	( { sleep 3; kill -KILL $* &>/dev/null; } & )
	# The 'wait' trick only works for subprocess of the current shell, should be fine
	# It suppresses the "terminated" background messages.
	# "wait" returns 127 if process not found (thanks!). We return 0 always.
	wait $* &>/dev/null || return 0
}
set-imagick () {
	local im
	if [[ -d $bin/ImageMagick ]]; then
		export MAGICK_HOME="$bin/ImageMagick"
		export DYLD_LIBRARY_PATH="$MAGICK_HOME/lib/"
		[[ "$PATH" = *"$MAGICK_HOME/bin"* ]] || export PATH="$MAGICK_HOME/bin:$PATH"
	fi
}
anykey () {
	local msg="Press any key to continue ..."
	[[ -n $1 ]] && msg="$@"
	echo $msg
	read -s -n 1
}
# Fetch a list of functions prefixed by PREFIX. Outputs a list separated by SEP
# Usage: functionlist PREFIX SEP
functionlist () {
	local IFS=$'\n\t ' 
	local list=(`declare -f | grep -Eo "^$1[a-zA-Z0-9_\-]+ \(\)" | sed -E "s/^$1//;s/ \(\)//"`)
	list=${list[*]}
	echo ${list// /$2}
}
menu () {
	local i n ans map prompt=$1 default=$2
	local args=$@
	shift 2
	local opts=("$@")
	while [[ 1 ]]; do
		i=0
		n=0
		map=''
		while [[ $i -lt $# ]]; do
			if [[ -z ${opts[i]} ]]; then
				echo
			else
				let n=n+1
				printf "  %2d. %s\n" $n ${opts[i]}
				map=("${map[@]}" "${opts[i]}")
			fi
			let i=i+1
		done
		echo
		echo -n "$prompt"
		[[ -n $default ]] && echo -n " [$default] "
		read ans
		echo
		if [[ -z $ans ]]; then
			menuchoice="$default"
			break
		elif [[ $ans -ge 1 && $ans -le $n ]]; then
			menuchoice=${map[ans]}
			break
		else
			anykey "Invalid choice '$ans'. Press any key to try again ..."
			echo
		fi
	done
}

#------------------------------ GET functions ------------------------------#

moh-get-handbrake ()
{
	echo 
	local ans=y
	# md5=d426eae09825284c8a4b66d55cafeeb4
	[[ -x $bin/HandBrakeCLI && $1 != force ]] && \
		read -p "HandBrake CLI seems to exist in $bin. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $bin/done-handbrake
		echo Fetching HandBrake CLI into $bin ...
		wget $tmp/HandBrake-0.9.9-MacOSX.6_CLI_x86_64.dmg "$url_handbrake" -#
		mnt $tmp/HandBrake-0.9.9-MacOSX.6_CLI_x86_64.dmg
		cp -f /Volumes/HandBrake-0.9.9-MacOSX.6_CLI_x86_64/HandBrakeCLI $bin
		umnt /Volumes/HandBrake-0.9.9-MacOSX.6_CLI_x86_64
		> $bin/done-handbrake
	fi
}

moh-get-ipg ()
{
	echo 
	local ans=y
	# md5=5e3f984efdf04fa608ef1ba35d1309fe
	[[ -d /Applications/Intel\ Power\ Gadget && $1 != force ]] && read -p "Intel Power Gadget seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $bin/done-ipg
		echo "Fetching and installing Intel Power Gadget into /Applications ..."
		wget $tmp/ipg.zip "$url_ipg" -#
		unzip -q -o $tmp/ipg.zip -d $tmp
		mnt $tmp/Intel*.dmg
		echo "Installing Intel Power Gadget may ask you to enter your Mac password."
		sudo installer -pkg /Volumes/Intel*\ Power\ Gadget/Install\ Intel\ Power\ Gadget.pkg -target /
		umnt /Volumes/Intel*\ Power\ Gadget
		> $bin/done-ipg
	fi
}

moh-get-gle ()
{
	echo
	local ans=y
	# md5=021e612a678cce8f2f8b1425fec1d0b5
	[[ -d $bin/QGLE.app && $1 != force ]] && read -p "QGLE seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $bin/done-gle
		echo Fetching Graphics Layout Engine into $bin ...
		wget $tmp/gle.dmg "$url_gle" -#
		mnt $tmp/gle.dmg
		[[ -d $bin/QGLE.app ]] && rm -rf $bin/QGLE.app
		cp -r /Volumes/gle-graphics-*/QGLE.app $bin
		umnt /Volumes/gle-graphics-*
		> $bin/done-gle
	fi
}

moh-get-video ()
{
	echo
	local ans=y
	# md5=c23ab2ff12023c684f46fcc02c57b585
	[[ -r $home/$mov && $1 != force ]] && read -p "The video file seems exist in $home. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $home/done-video
		echo "Fetching The Big Buck Bunny movie (692 MB) into $home. This may take a while ..."
		wget $home/$mov "$url_video" -#
		> $home/done-video
	fi
}

moh-get-prime95 ()
{
	echo
	local ans=y
	# md5=0390ae2ff3d4a7082927482d82e62f59
	[[ -d $bin/Prime95.app && $1 != force ]] && \
		read -p "Prime95 seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $bin/done-prime95
		echo Fetching Prime95 into $bin ...
		wget $tmp/prime95.zip "$url_prime95" -#
		# zip file from mersenne.org causes unzip to exit with 1, even though it extracts ok
		if ! unzip -q -o $tmp/prime95.zip -d $tmp 2>$tmp/unziperr.log; then
			local e=$?
			sed -E '/ucsize [0-9]* <> csize|continuing with/d' $tmp/unziperr.log | \
				grep -qE '.' && cat $tmp/unziperr.log && die $e "unzip failed"
		fi
		[[ -d $bin/Prime95.app ]] && rm -rf $bin/Prime95.app
		cp -rf $tmp/Prime95.app $bin
		rm -rf $tmp/Prime95.app
		chmod 755 $bin/Prime95.app/Contents/MacOS/Prime95
		> $bin/done-prime95
	fi
}

moh-get-gputest ()
{
	echo
	local ans=y
	# md5=b3dbe739f64336b1f0752149c495dbf4
	[[ -d $bin/GpuTest.app && $1 != force ]] && \
		read -p "GpuTest seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $bin/done-gputest
		echo Fetching GpuTest into $bin ...
		wget $tmp/gputest.zip "$url_gputest" -# --referer "$url_gputest_referer"
		unzip -q -o $tmp/gputest.zip -d $tmp
		[[ -d $bin/GpuTest.app ]] && rm -rf $bin/GpuTest.app
		cp -rf $tmp/GpuTest.app $bin
		rm -rf $tmp/GpuTest.app
		chmod 755 $bin/GpuTest.app/Contents/MacOS/GpuTest
		> $bin/done-gputest
	fi
}

moh-get-gfx ()
{
	echo
	local ans=y
	# md5=1cecb1974a1d5c374dfd180a5e7b828e
	# [[ ( -d $bin/gfxCardStatus.app || -d /Applications/gfxCardStatus.app ) && $1 != force ]] && \
	[[ -d $bin/gfxCardStatus.app && $1 != force ]] && \
		read -p "gfxCardStatus seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $bin/done-gfx
		echo Fetching gfxCardStatus into $bin ...
		wget $tmp/gfxCardStatus.tgz "$url_gfx" -#
		[[ -d $bin/gfxCardStatus.app ]] && rm -rf $bin/gfxCardStatus.app
		tar -C $bin -zxf $tmp/gfxCardStatus.tgz
		> $bin/done-gfx
	fi
}

# Fetch and install a local copy of ImageMagick
moh-get-imagick ()
{
	echo
	local d ans=y
	# md5=1cecb1974a1d5c374dfd180a5e7b828e
	[[ -d $bin/ImageMagick-* && $1 != force ]] && \
		read -p "ImageMagick seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		set -e
		rm -f $bin/done-imagick
		echo Fetching ImageMagick into $bin ...
		wget $tmp/imagemagick.tgz "$url_im" -#
		tar -C $bin -zxf $tmp/imagemagick.tgz
		mv $bin/ImageMagick-* $bin/ImageMagick
		> $bin/done-imagick
	fi
	set-imagick
}

#---------------------------- DO/CHECK functions ----------------------------#

# Check mandatory packages
moh-check-common () {
	[[ -r $bin/done-ipg && -d /Applications/Intel\ Power\ Gadget ]] || moh-get-ipg force
	[[ -r $bin/done-gle && -d $bin/QGLE.app ]] || moh-get-gle force
	[[ -r $bin/done-imagick && -d $bin/ImageMagick ]] || moh-get-imagick force
}

# Check if all x264 test dependencies exist and download/install if not
moh-check-x264 ()
{
	moh-check-common
	[[ -r $bin/done-handbrake && -x $bin/HandBrakeCLI ]] || moh-get-handbrake force
	[[ -r $home/done-video && -r $home/$mov ]] || moh-get-video force
}

# Check if all Prime95 test dependencies exist and download/install if not
moh-check-prime95 ()
{
	moh-check-common
	[[ -r $bin/done-prime95 && -d $bin/Prime95.app ]] || moh-get-prime95 force
}

# Check if all Prime95 test dependencies exist and download/install if not
moh-check-gputest ()
{
	moh-check-common
	[[ -r $bin/done-gputest && -d $bin/GpuTest.app ]] || moh-get-gputest force
}

# Check packages for a user defined command
moh-check-usercmd ()
{
	moh-check-common
}

# Check packages for a user defined command
moh-check-gfx ()
{
	[[ -r $bin/done-gfx && -d $bin/gfxCardStatus.app ]] || moh-get-gfx force
}

## Start any user specified command and log it (it must terminate)
## TODO: add timer
moh-cmd ()
{
	do=usercmd
	moh-check-usercmd
	echo "$usercmd" | moh-wrapper UserCmd $timeout
}

# Run GpuTest
moh-do-gputest ()
{
	do=gputest
	moh-check-gputest
	moh-wrapper GpuTest <<-SH
		$bin/GpuTest.app/Contents/MacOS/GpuTest '/test=$gputest /width=$gpuwidth /height=$gpuheight /msaa=$gpumsaa /benchmark /benchmark_duration_ms=${timeout}000 /no_scorebox' &>/dev/null
	SH

}

# Run Prime95 ... currently buggy, torture test does not always start with -t
# http://www.mersenneforum.org/showthread.php?p=372979#post372918
moh-do-prime95 ()
{
	do=prime95
	moh-check-prime95

	local workdir=~/Prime95
	[[ -d $workdir ]] && rm -rf $workdir
	mkdir -p $workdir

	cat <<-STR

                              ---------------
                               W A R N I N G
                              ---------------

		There is a bug in Prime95, the torture test does not start automatically when the GUI opens. For now, do it manually once the GUI opens as follows:

		Options -> Torture Test -> Custom -> MinFFT=$p95minfft, MaxFFT=$p95maxfft, Memory=$p95mem, Time=$p95timefft -> Run.

		Press any key to start Prime95 ...
	
	STR
	read -s -n 1

	# 8k in-place FFTs (in-place when TortureMem <= 8) ... most stressful
	# For blend: Min=8, Max=1792, Mem=2048, Time=5
	# For small with some mem: Min=8, Max=16, Mem=512, Time=5
	cat > $workdir/prime.txt <<-TXT
		MinTortureFFT=$p95minfft
		MaxTortureFFT=$p95maxfft
		TortureMem=$p95mem
		TortureTime=$p95timefft
		V24OptionsConverted=1
		StressTester=1
		UsePrimenet=0
		Nice=$p95nice
		ManualComm=1
	TXT
	# SumInputsErrorCheck=0
	# ErrorCheck=0
	# StaggerStarts=1
	# WGUID_version=2
	# MergeWindows=12
	# NoMoreWork=0

	moh-wrapper Prime95 $timeout <<-SH
		$bin/Prime95.app/Contents/MacOS/Prime95 -t -W$workdir
	SH
}

## Start the normal x264 test
moh-do-x264 () {
	do=x264
	moh-check-x264
	moh-wrapper x264 <<-SH
		$bin/HandBrakeCLI -i $home/$mov -o $mkv -f mkv -4 -w 1280 -l 720 -e x264 -q 26 --vfr  -a 1 -E ffaac -B 128 -6 stereo -R Auto -D 0 --gain=0 --audio-copy-mask none --audio-fallback ffaac -x rc-lookahead=50:ref=8:bframes=16:me=umh:subme=9:merange=24 --verbose=1 2>$hblog
	SH
}

## Start the long x264 test
moh-do-x264-long () {
	do=x264-long
	moh-check-x264
	moh-wrapper x264-Long <<-SH
		# $bin/HandBrakeCLI -i $home/$mov -o $mkv -f mkv -4 -w 1280 -l 720 -e x264 -q 20 --vfr  -a 1 -E ffaac -B 128 -6 stereo -R Auto -D 0 --gain=0 --audio-copy-mask none --audio-fallback ffaac -x rc-lookahead=50:ref=16:bframes=16:b-adapt=2:direct=auto:me=tesa:subme=11:merange=48:analyse=all:trellis=2 --verbose=1 2>$hblog
		# $bin/HandBrakeCLI -i $home/$mov -o $mkv -f mkv -4 -w 1280 -l 720 -e x264 -q 20 --vfr  -a 1 -E ffaac -B 128 -6 stereo -R Auto -D 0 --gain=0 --audio-copy-mask none --audio-fallback ffaac --x264-preset=veryslow --verbose=1 2>$hblog
		$bin/HandBrakeCLI -i $home/$mov -o $mkv -f mkv -4 -w 1280 -l 720 -e x264 -q 26 --vfr  -a 1 -E ffaac -B 128 -6 stereo -R Auto -D 0 --gain=0 --audio-copy-mask none --audio-fallback ffaac -x rc-lookahead=200:ref=16:bframes=16:b-adapt=2:direct=auto:me=esa:subme=9:merange=24 --verbose=1 2>$hblog
	SH
}

moh-do-gfx () {
	do=gfx
	open "$bin/gfxCardStatus.app"
	echo "gfxCardStatus started, it should appear on the menu bar. Click it to select which GPU to use for 3D if you have both an integrated and discrete GPU."
}


#--------------------------- AUXILIARY functions ---------------------------#

moh-gpudetect () {
	moh-check-gfx
	local i j log pid
	$bin/gfxCardStatus.app/Contents/MacOS/gfxCardStatus &> $tmp/gfx.log &
	pid=$!
	echo Detecting GPUs ...
	for ((i=0;i<10;i++)); do
		sleep 1
		log=$(<$tmp/gfx.log)
		if [[ "$log" =~ GPUs\ present:\ \([^\)]+$'\n'\) ]]; then
			log=${log/*GPUs present: (/}
			log=${log/)*/}
			log=${log//[\",]/}
			local IFS=$'\n'
			log=($log)
			local IFS=$'\n\t '
			if [[ ${#log[*]} -lt 2 ]]; then
				silentkill $pid
				echo "Only one GPU detected. Nothing to switch. Exiting ..." >&2
				return 15
			else
				# for ((j=0;j<${#log[*]};j++)); do echo $((j+1)). ${log[j]}; done
				silentkill $pid
				return 0
			fi
		fi
	done
	silentkill $pid
	echo Timeout waiting for gfxCardStatus. >&2
	return 16
}

# moh-gpuswitch MODE, where MODE={1,2,3} for integrated, discrete, dynamic
moh-gpuswitch () {
	moh-check-gfx
	moh-gpudetect || return $?
	local i j log pid arg n=2 name=$1 line readouts finished size logfile=$logs/gfx.log
	arg=`echo $1 | tr '[:upper:]' '[:lower:]'`
	[[ $1 = 1 ]] && arg=integrated && name=Integrated
	[[ $1 = 2 ]] && arg=discrete && name=Discrete
	[[ $1 = 3 ]] && arg=dynamic && name=Dynamic
	[[ $arg =~ ^integrated|discrete|dynamic$ ]] \
		|| die $ERR_GPUSWITCH "Invalid GPU switch parameter '$arg'. GPU not switched."
	echo Switching GPU to $name ...
	# Need to attempt 2-3 times due to a bug
	# https://github.com/codykrieger/gfxCardStatus/issues/103
	for ((i=1;i<=n;i++)); do
		echo Pass $i/$n ...
		# It also doesn't exit, so we need to background it, monitor its log file, then kill it ... 
		> $logfile
		$bin/gfxCardStatus.app/Contents/MacOS/gfxCardStatus --$arg &> $logfile &
		pid=$!
		# stop when file size stops increasing
		for ((j=0;j<10;j++)); do
			[[ $j = 0 ]] && sleep 1 || sleep 1
			size[1]=`wc -c $logfile`
			[[ ${size[0]} = ${size[1]} ]] && break
			size[0]=${size[1]}
			# for ((j=0;j<readouts;j++)); do sleep 0.5; line[$j]=`tail -n 1 $logfile`; done
			# finished=1
			# for ((j=1;j<readouts;j++)); do
				# [[ -n ${line[j]} &&  -n ${line[j-1]} && "${line[j]}" = "${line[j-1]}" ]] \
					# || { finished=0; break; }
			# done
			# [[ $finished = 1 ]] && break
		done
		[[ $j = 10 ]] && Timeout waiting for gfxCardStatus. GPU possibly not switched. >&2 && return $ERR_GPUSWITCH
		# echo killing pid=$pid $i
		silentkill $pid
	done
	echo "Done. GPU should now be switched to $name. "
}

moh-gpuswitch-menu () {
	moh-check-gfx
	moh-gpudetect || return $?
	echo
	menu "Choose GPU:" Abort Integrated Discrete Dynamic "" Abort
	[[ $menuchoice = Abort ]] && return 0
	moh-gpuswitch $menuchoice
	anykey
}

## Parse HandBrake log and populate the global $duration, $mins, $secs, $perf
perf-handbrake () {
	[[ -r $hblog ]] || return 0
	local frames=(`grep -Eo 'got [0-9]+ frames' $hblog`)
	frames=${frames[1]}
	local fps=(`grep -Eo 'average encoding speed for job is [0-9.]+ fps' $hblog`)
	fps=${fps[6]}
	duration=`echo "$frames/$fps" | bc -l`
	duration=${duration/.*/}
	hduration=`humantime $duration`
	perf=`printf "%.2f fps" $fps`
}

## Parse GpuTest log and populate the global $duration, $mins, $secs, $perf
perf-gputest () {
	[[ -r $gpucsv ]] || return 0
	local IFS=$'\n\t,'
	local csv=($(<$gpucsv))
	local IFS=$'\n\t '
	local n=${#csv[*]}
	local frames=${csv[n-1]}
	duration=$((csv[n-3]/1000))
	hduration=`humantime $duration`
	local gpu=${csv[n-10]}
	gpu=${gpu/ OpenGL Engine/}
	gpu=${gpu/NVIDIA/Nvidia}
	gpu=${gpu/GeForce /}
	local fps=`echo "$frames/$duration" | bc -l`
	perf=`printf "%.2f fps, ${gpuwidth}x$gpuheight, ${gpumsaa}xAA, $gpu" $fps`
}

## Wrapper to start, monitor and log any job which is read from stdin
## usage wrapper NAME TIMEOUT
## - NAME is a short no-spaces name of the job, e.g. x264-long
## - TIMEOUT is a duration in seconds after which the test is forcefully killed
##   Use 0 to disable the timeout.
moh-wrapper ()
{
	echo

	# set test name (displayed in the graph title)
	local testname=$1
	#local sanename=`echo $1 | tr '[:upper:]' '[:lower:]' | tr '[:space:]' '-' | tr -dC '[a-z0-9\-]'`

	# Prepare script file to pass to Intel Power Gadget
	local cmdfile=$tmp/cmd-$do.sh

	local code=$(</dev/stdin) 	# Benchmark code passed via stdin
	local sudo 					# Code to deal with sudo
	local handbrake 			# Code to deal with HandBrake (cpu priority)
	local watchdog 				# Code to deal with max duration (timeout)

	# Does the code run HandBrakeCLI? It changes its nice level to 19 after it
	# starts so we can't start it with nice -n 0 HandBrakeCLI. Prepend a
	# background loop to poll for it and renice it once detected
	[[ $code =~ HandBrakeCLI ]] && handbrake='
	echo "CPU priority of HandBrake will be raised (sudo)."
	for ((i=0;i<120;i++)); do
		sleep 1
		pid=`pgrep HandBrakeCLI` && { sleep 2; sudo renice -10 -p $pid; break; }
	done &'

	# Timeout needed?
	# Add a pair of brackets ( ) around bg processes to suppress "terminated"
	# messages from the shell .. neat. Unforturnately, we can't suppress all of
	# them since the test is running in the fg and is killed by a bg process,
	# so the shell informs the user of the death of the fg process ... the bg
	# process can't prevent that. We could swap the fg and bg processes, but
	# then the test would run in bg which is more hassle to handle (though we
	# have bash's "wait" function)
	[[ $2 -gt 0 ]] && watchdog=$(declare -f silentkill)'
	echo "Waiting max '$(humantime $2)' to terminate."
	( sleep '$2'; pids=`pgrep -P $$` && { sleep 3 && kill -KILL $pids &>/dev/null & } && kill -TERM $pids; ) &>/dev/null &
	# { sleep '$2'; pids=`pgrep -P $$ 2>/dev/null` && silentkill $pids; } &
	'

	# Is the code using sudo? If so, ask for the password now to avoid the
	# password prompt being ocluded later by the wrapping scripts which may
	# redirect stdout/stderr.
	[[ -n $handbrake || $code =~ sudo[[:space:]] ]] \
		&& sudo='echo Sudo detected. It may ask you to enter your Mac password. && sudo echo'

	# Build script file to pass to Intel Power Gadget
	cat > $cmdfile <<-SH
		#!/bin/bash
		echo
		$handbrake
		$sudo
		echo Waiting $waitstart seconds to capture idle temperature ...
		sleep $waitstart
		echo Starting $testname benchmark. May take a while and fans may go berserk ...
		$watchdog
		$code
		echo Test finished. Cooling off for $waitend seconds ...
		sleep $waitend
	SH
	chmod 700 $cmdfile
	
	# Finally ... Go!
	local timestart=$(date +%s)
	/Applications/Intel\ Power\ Gadget/PowerLog -resolution 500 -file $ipgcsv -cmd $cmdfile
	local timeend=$(date +%s)
	# echo "Done."

	# Don't do these in $code because the user may press Ctrl-C
	[[ $do =~ gputest ]] && {
		[[ -r ~/_geeks3d_gputest_log.txt ]] && mv ~/_geeks3d_gputest_log.txt $gpulog
		[[ -r ~/_geeks3d_gputest_scores.csv ]] && mv ~/_geeks3d_gputest_scores.csv $gpucsv
	}

	# Populate the global $duration, $mins, $secs
	duration=$((timeend-timestart-waitstart-waitend))
	hduration=`humantime $duration`
	
	# Plot result
	moh-plot $testname
}

# Plot
moh-plot () {
	local testname=$1

	# Prepare to plot graph from the csv output of IPG
	cat >$tmp/ipg.gle <<-'GLE'
	papersize 20 10
	size 20 10
	!margins 2 2 2 2
	set font texcmr
	set titlescale 0.9
	begin graph
	   title arg$(2) dist 0.2
	   xtitle "Time (sec)"
	   ytitle "CPU Temperature (C)" color red
	   y2title "CPU Frequency (MHz)" color blue
	   data arg$(1) ignore 1 d1=c1,c9 d2=c1,c2
	   axis grid
	   subticks on
	   ticks color grey10
	   subticks lstyle 2
	   yaxis min 20 max 110 dticks 10 dsubticks 2.5
	   y2axis min 400 max 4000 dticks 200 dsubticks 100
	   !y2axis min 600 max 3300 nticks 9
	   !xnames from d1
	   key pos bl offset 1.25 0.25
	   d1 line color red key arg$(3)
	   d2 x2axis y2axis line color blue key arg$(4)
	end graph
	GLE

	# graph files
	local graph=$home/$testid-$do.png
	local graphgif=$home/$testid-$do.gif

	# Remove the trailing lines (Intel decided to add non-csv at athe end) 
	# and the first two columns (there's a bug in GLE: it can't properly read
	# the xnames from a column different than 1st column; 
	# "xnames from d1" reads the y values, instead of x values)
	local lines=(`wc -l "$ipgcsv"`)
	head -n $((${lines[0]}-11)) $ipgcsv | sed 's/^[^,]*,[^,]*,//' > $tmp/ipg.csv

	# Get max temp, max freq, duration and avg fps
	local maxtemp=`cut -f9 -d, $tmp/ipg.csv | sed 's/[[:space:]]//g' | sort -n | tail -1`
	local maxfreq=`cut -f2 -d, $tmp/ipg.csv | sed 's/[[:space:]]//g' | sort -n | tail -1`

	# Prepend to title
	local testtitle=$testname

	# Get performance details, if any
	[[ $do =~ x264 ]] && perf-handbrake
	[[ $do =~ gputest ]] && testtitle="$testtitle ($gputest)" && perf-gputest

	# CPU model
	local cpu=`sysctl -n machdep.cpu.brand_string`
	cpu=${cpu/ CPU/}
	cpu=${cpu/(TM)/}
	cpu=${cpu/(R)/}
	cpu=${cpu/Intel /}
	cpu=${cpu/AMD /}

	# Graph title
	local graphtitle="$testtitle - $cpu - $hduration"
	[[ -n $perf ]] && graphtitle="$graphtitle, $perf"

	# Plot graph, -resolution sets the DPI, note that the PNG driver is 
	# a rasterized and resampled version of the internal Postscript output, and
	# as such, the values sometimes may appear slightly off due to resampling
	$bin/QGLE.app/Contents/bin/gle -cairo -resolution 200 -d png -verbosity 0 \
		-output $graph \
		$tmp/ipg.gle \
		$tmp/ipg.csv \
		"$graphtitle" \
		"Temperature (max reached: $maxtemp C)" \
		"Frequency" \
	>/dev/null
	
	# Crop and make smaller, use sips if ImageMagick is not available
	set-imagick
	if which convert &>/dev/null; then
		mogrify -crop 1340x730+125+35 -quality 96 -colors 64 -write $graph-1 $graph \
			&& mv $graph-1 $graph
	elif which sips &>/dev/null; then
		sips -s format gif $graph --out $graphgif &>/dev/null
		graph=$graphgif
		rm $graph
	fi

    echo
    [[ -n $perf ]] && echo "Benchmark:        $perf"
    cat <<-STR
		Max temp reached: $maxtemp C
		Test duration:    $duration secs ($hduration)

		See $graph for the full graph.

	STR

	# open graph
	open $graph
}


#--------------------------------- SCRIPT ---------------------------------#

# Conf file
conf="$(dirname $0)/macoh.conf"

# Load conf. Overrides defaults, but not cmd line options.
[[ -r "$conf" ]] && source "$conf"

# Parse cmd line args (hack job, I know, will use getopts() later)
while [[ -n $@ ]]; do
	[[ $1 = -c || $1 = -cmd       ]] && shift && usercmd="$@" && break 	# -cmd must be the last option
	[[ $1 = -w || $1 = -wait      ]] && waitstart=$2 && waitend=$2 && shift 2 && continue
	[[ $1 = -t || $1 = -time      ]] && timeout=${2:-0} && shift 2 && continue
	[[ $1 = -do                   ]] && do=$2 && shift 2 && continue
	[[ $1 = -get                  ]] && get=$2 && shift 2 && continue
	[[ $1 = -r || $1 = -res       ]] && gpuwidth=${2/x*/} && gpuwidth=${2/*x/} && shift 2 && continue
	[[ $1 = -m || $1 = -msaa      ]] && gpumsaaa=$2 && shift 2 && continue
	[[ $1 = -s || $1 = -gpuswitch ]] && gpuswitch=$2 && shift 2 && continue
	[[ $1 = -g || $1 = -gputest   ]] && gputest=$2 && shift 2 && continue
	[[ $1 = -plot                 ]] && testid=$2 && do=moh-plot && shift 2 && continue
	[[ $1 = -name                 ]] && testname=$2 && shift 2 && continue
	die $ERR_CMDLINE "Unrecognized option '$1'"
done

# Internal vars
duration=0
hduration=0
code=''
tmp="$home/tmp"
bin="$home/bin"
logs="$home/logs"
ipgcsv="$logs/$testid-ipg.csv"
hblog="$logs/$testid-hb.log"
gpucsv="$logs/$testid-gputest.csv"
gpulog="$logs/$testid-gputest.log"

# Error codes
ERR_CMDLINE=11
ERR_KILL=13
ERR_GPUSWITCH=19

# Create needed dirs
mkdir -p "$home" "$logs" "$tmp" "$bin"

# Validate input
[[ $waitstart -gt 0 && $waitend -gt 0 ]] || die $ERR_CMDLINE "-w/-wait requires a positive integer"
[[ $gpuwidth -gt 0 && $gpuheight -gt 0 ]] || die $ERR_CMDLINE "-r/-res requires MxM, where M and N are positive integers"
[[ $gpumsaa = [0248] ]] || die $ERR_CMDLINE "-m/-msaa requires 0, 2, 4 or 8"
[[ $timeout -ge 0 ]] || die $ERR_CMDLINE "-t/-time requires a non-negative integer"
[[ ", $gputesttypes, " = *", $gputest, "*  ]] || die $ERR_CMDLINE "-g/-gputest requires one of: $gputesttypes"

# Cmd line GPU switch?
[[ -n $gpuswitch ]] && case $gpuswitch in
	integrated) moh-gpuswitch 1; ecode=$?;;
	discrete)   moh-gpuswitch 2; ecode=$?;;
	dynamic)    moh-gpuswitch 3; ecode=$?;;
	[012])      moh-gpuswitch $gpuswitch; ecode=$?;;
	*) die $ERR_CMDLINE "-s/-gpuswitch requires one of: integrated, discrete, dynamic or 0, 1, 2"
esac

# Cmd line predefined test?
[[ -n $do ]] && {
	dolist=$(functionlist "moh-do-" ", ")
	dore=$(functionlist "moh-do-" "|")
	[[ $do =~ ^$dore$ ]] || die $ERR_CMDLINE "-do requires one of: $dolist"
	moh-do-$do
	exit $?
}

# Cmd line fetch?
[[ -n $get ]] && {
	getlist=$(functionlist "moh-get-" ", ")
	getre=$(functionlist "moh-get-" "|")
	[[ $get =~ ^$re$ ]] || die $ERR_CMDLINE "-get requires one of: $getlist"
	moh-get-$get
	exit $?
}

# Cmd line user command?
[[ -n $usercmd ]] && {
	moh-cmd
	exit $?
}

# If only the -g/-gpuswitch was used, exit (allows scripting)
[[ -n $gpuswitch ]] && exit $ecode

# If not, show menu
while [[ 1 ]]; do
	echo -n "
------------------------------------------------------------------------
         MacOH 1.2.0-beta. Quit all other apps before launching.
------------------------------------------------------------------ Tests
 G. GpuTest (use gfxCardStatus to force the integrated GPU)
 P. Prime95 (in-place small FFTs, very stressful)
 X. x264 transcode
 Y. Longer x264 transcode (~4x longer)
--------------------------------------------------------------- Settings
 T. Change duration of GpuTest or Prime95 [$(humantime $timeout)]
 W. Change GpuTest type [$gputest]
 R. Change GpuTest resolution [${gpuwidth}x$gpuheight]
 M. Change GpuTest MSAA [$gpumsaa]
 S. Switch GPU to either Integrated or Discrete
--------------------------------------------------------------- Optional
 1. Fetch Intel Power Gadget (2.3 MB)
 2. Fetch Graphics Layout Engine (13.2 MB)
 3. Fetch Prime95 (3.3 MB)
 4. Fetch GpuTest (1.8 MB)
 5. Fetch HandBrakeCLI (6.9 MB)
 6. Fetch the movie Big Buck Bunny (692 MB)
 7. Fetch gfxCardStatus, can switch GPU for 3D (0.9 MB)
------------------------------------------------------------------------
Your choice: [Q=Quit] "
	read ans
	echo
	[[ -z $ans || $ans = q || $ans = Q ]] && exit 0

	set -e

	[[ $ans = 1 ]] && { moh-get-ipg; continue; }
	[[ $ans = 2 ]] && { moh-get-gle; continue; }
	[[ $ans = 3 ]] && { moh-get-prime95; continue; }
	[[ $ans = 4 ]] && { moh-get-gputest; continue; }
	[[ $ans = 5 ]] && { moh-get-handbrake; continue; }
	[[ $ans = 6 ]] && { moh-get-video; continue; }
	[[ $ans = 7 ]] && { moh-get-gfx; continue; }

	[[ $ans =~ ^[gG]$ ]] && { moh-do-gputest; [[ $menuquit = 1 ]] && exit || { anykey; continue; } }
	[[ $ans =~ ^[pP]$ ]] && { moh-do-prime95; [[ $menuquit = 1 ]] && exit || { anykey; continue; } }
	[[ $ans =~ ^[yY]$ ]] && { moh-do-x264-long;  [[ $menuquit = 1 ]] && exit || { anykey; continue; } }
	[[ $ans =~ ^[xX]$ ]] && { moh-do-x264;  [[ $menuquit = 1 ]] && exit || { anykey; continue; } }
	[[ $ans =~ ^[sS]$ ]] && { moh-gpuswitch-menu; continue; }

	[[ $ans =~ ^[wW]$ ]] && { 
		menu "Choose GpuTest benchmark:" "$gputest" ${gputesttypes//,/}
		[[ $menuchoice = $gputest ]] || editconf gputest $menuchoice
		continue
	}

	[[ $ans =~ ^[tT]$ ]] && { 
		read -p "New duration in seconds: [$timeout] " t;
		[[ $t -gt 0 ]] && editconf timeout $t && continue
		menuerr="Duration must be a number greater than 0"
	}

	[[ $ans =~ ^[rR]$ ]] && { 
		read -p "New resolution: [${gpuwidth}x$gpuheight] " r
		[[ $r =~ ^[0-9]+x[0-9]+$ ]] && editconf gpuwidth ${r/*x/} \
			&& editconf gpuheight ${r/x*/} && continue
		menuerr="Resolution must be MxN, where M and N are positive integers"
	}

	[[ $ans =~ ^[mM]$ ]] && { 
		read -p "New MSAA (0, 2, 4 or 8): [$gpumsaa] " m
		[[ $m =~ ^[0248]$ ]] && editconf gpumsaa $m && continue
		menuerr="MSAA value must be 0, 2, 4 or 8"
	}

	[[ -z $menuerr ]] && menuerr="Unknown option '$ans'"
	anykey "Error: $menuerr. Press any key to continue ..."
done 
