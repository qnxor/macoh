#!/bin/bash
#
# GitHub project: https://github.com/qnxor/macoh
# Bogdan Roman, University of Cambridge, 2014
# http://www.damtp.cam.ac.uk/research/afha/bogdan
#

set -e
home=~/macoh
tmp=$home/tmp
bin=$home/bin
logs=$home/logs
mov=big_buck_bunny_1080p_h264.mov
mkv=$home/big_buck_bunny_1080p_h264_transcoded.mkv
# Generate or read id to use for the log files
[[ -n $1 ]] && testid=$1 || testid=`date +%Y%m%d-%H%M%S`
ipglog=$logs/$testid-ipg.csv
hblog=$logs/$testid-hb.log
graph=$home/$testid-graph.png
graphgif=$home/$testid-graph.gif

mkdir -p $home $logs $tmp $bin

mnt () { 
	hdiutil attach "$1" >/dev/null
}
umnt () {
	diskutil unmount "$1" >/dev/null
}
wget () {
	#local ans=y
	#[[ -r "$1" ]] && read -p "File exists, redownload? [n] " ans
	#[[ $ans = y || $ans = Y ]] && \
		#curl -# -o "$1" "$2"
		curl -o "$@"
}

moh_get_handbrake () {
	echo 
	local ans=y
	[[ -x $bin/HandBrakeCLI && $1 != force ]] && read -p "HandBrake CLI seems to exist in $bin. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		rm -f $bin/done-handbrake
		echo Fetching HandBrake CLI into $bin ...
		wget $tmp/HandBrake-0.9.9-MacOSX.6_CLI_x86_64.dmg -# "http://heanet.dl.sourceforge.net/project/handbrake/0.9.9/HandBrake-0.9.9-MacOSX.6_CLI_x86_64.dmg"
		mnt $tmp/HandBrake-0.9.9-MacOSX.6_CLI_x86_64.dmg
		cp -f /Volumes/HandBrake-0.9.9-MacOSX.6_CLI_x86_64/HandBrakeCLI $bin
		umnt /Volumes/HandBrake-0.9.9-MacOSX.6_CLI_x86_64
		> $bin/done-handbrake
	fi
}

moh_get_ipg () {
	echo 
	local ans=y
	[[ -d /Applications/Intel\ Power\ Gadget && $1 != force ]] && read -p "Intel Power Gadget seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		rm -f $bin/done-ipg
		echo "Fetching and installing Intel Power Gadget into /Applications ..."
		wget $tmp/ipg.zip "https://software.intel.com/sites/default/files/IntelPowerGadget3.0.1.zip" -#
		unzip -q -o $tmp/ipg.zip -d $tmp
		mnt $tmp/Intel*.dmg
		echo "You need to provide your Mac system password to install Intel Power Gadget. "
		sudo installer -pkg /Volumes/Intel*\ Power\ Gadget/Install\ Intel\ Power\ Gadget.pkg -target /
		umnt /Volumes/Intel*\ Power\ Gadget
		> $bin/done-ipg
	fi
}

moh_get_gle () {
	echo
	local ans=y
	[[ -d ~/Applications/QGLE.app && $1 != force ]] && read -p "QGLE seems to be installed. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		rm -f $bin/done-gle
		echo "Fetching QGLE into ~/Applications ..."
		wget $tmp/gle.dmg "http://heanet.dl.sourceforge.net/project/glx/gle4%20(Current%20Active%20Version)/4.2.4c/gle-graphics-4.2.4c-exe-mac.dmg" -#
		mnt $tmp/gle.dmg
		cp -r /Volumes/gle-graphics-*/QGLE.app ~/Applications
		umnt /Volumes/gle-graphics-*
		> $bin/done-gle
	fi
}

moh_get_video () {
	echo
	local ans=y
	[[ -r $home/$mov && $1 != force ]] && read -p "The video file seems exist in $home. Redownload? [n] " ans
	if [[ $ans = y || $ans = Y ]]; then
		rm -f $home/done-video
		echo "Fetching The Big Buck Bunny movie (692 MB) into $home. This may take a while ..."
		wget $home/$mov "http://blender-mirror.kino3d.org/peach/bigbuckbunny_movies/$mov" -#
		> $home/done-video
	fi
}

moh_check_sane () {
	# check if all components are sane and redownload+reinstall if not
	# TODO: better method for detecting if sane
	[[ -r $bin/done-handbrake && -x $bin/HandBrakeCLI ]] || moh_get_handbrake force
	[[ -r $bin/done-ipg && -d /Applications/Intel\ Power\ Gadget ]] || moh_get_ipg force
	[[ -r $bin/done-gle && -d ~/Applications/QGLE.app ]] || moh_get_gle force
	[[ -r $home/done-video && -r $home/$mov ]] || moh_get_video force
}

moh_launch () {
	echo
	
	# Delete temp (downloaded) files? Nah ...
	#rm -rf $tmp/*

	# We need to pass a command to IPG's PowerLog.
	# Make it a file (had too much hassle passing it as string to PowerLog)
	echo "echo Waiting 15 seconds to capture idle temperature ...
sleep 15
$bin/HandBrakeCLI -i $home/$mov -o $mkv -f mkv -4 -w 1280 -l 694 -e x264 -q 20 --vfr  -a 1 -E ffaac -B 128 -6 stereo -R Auto -D 0 --gain=0 --audio-copy-mask none --audio-fallback ffaac -x rc-lookahead=50:ref=8:bframes=16:me=umh:subq=9:merange=24 --verbose=1 2>$hblog
echo Cooling off for 15 seconds ...
sleep 15" > $tmp/cmd-x264.sh

	# run the x264 encoding
	echo "Now executing the x264 transcode. This will take a while. Expect the fans to go berserk soon ..."
	/Applications/Intel\ Power\ Gadget/PowerLog -resolution 300 -file $ipglog -cmd bash $tmp/cmd-x264.sh
	echo "Done."

	# Prepare to plot graph from the csv output of IPG
	cat - >$tmp/ipg.gle <<'GLE'
papersize 20 10
size 20 10
!margins 2 2 2 2
set font texcmr
begin graph
   title arg$(2)
   xtitle "Time (sec)"
   ytitle "Temperature (C)" color red
   y2title "Frequency (MHz)" color blue
   data arg$(1) ignore 1 d1=c1,c9 d2=c1,c2
   axis grid
   subticks on
   ticks color grey40
   subticks lstyle 2
   yaxis min 0 max 110 dticks 10 dsubticks 5
   y2axis min 300 max 3600 dticks 300 dsubticks 150
   !xnames from d1
   key pos bl offset 0.25 0.25
   d1 line color red key arg$(3)
   d2 x2axis y2axis line color blue key arg$(4)
end graph
GLE

	# Remove the trailing lines (Intel decided to add non-csv at athe end) 
	# and the first two columns (there's a bug in GLE: it can't properly read
	# the xnames from a column different than 1st column; 
	# "xnames from d1" reads the y values, instead of x values)
	lines=(`wc -l $ipglog`)
	head -n $((lines[0]-11)) $logs/$testid-ipg.csv | sed 's/^[^,]*,[^,]*,//' > $tmp/ipg.csv

	# Get max temp, max freq, duration and avg fps
	maxtemp=`cut -f9 -d, $tmp/ipg.csv | sed 's/[[:space:]]//g' | sort -n | tail -1`
	maxfreq=`cut -f2 -d, $tmp/ipg.csv | sed 's/[[:space:]]//g' | sort -n | tail -1`
	avgfps=(`grep -Eo 'average encoding speed for job is [0-9.]+ fps' $hblog`)
	avgfps=${avgfps[6]}
	frames=(`grep -Eo 'got [0-9]+ frames' $hblog`)
	frames=${frames[1]}
	totsecs=`echo "$frames/$avgfps" | bc -l`
	totsecs=${totsecs/.*/}
	mins=$((totsecs/60))
	secs=$((totsecs-mins*60))

	# CPU model as graph title
	cpu=`sysctl -n machdep.cpu.brand_string`
	cpu=${cpu/ CPU/}
	cpu=${cpu/(TM)/}
	cpu=${cpu/(R)/}

	# Plot temp and freq graph
	~/Applications/QGLE.app/Contents/bin/gle -cairo -resolution 150 -d png -verbosity 0 \
		-output $graph \
		$tmp/ipg.gle \
		$tmp/ipg.csv \
		"$cpu   -   ${mins}m ${secs}s (${totsecs}s)   -   $avgfps avg fps" \
		"Temp (max reached: $maxtemp C)" "Freq" >/dev/null
	
	# convert to gif if sips exists (smaller)
	which sips >/dev/null && sips -s format gif $graph --out $graphgif && rm $graph && graph=$graphgif

	echo "
Max temp reached: $maxtemp C
Encode speed:     $avgfps fps (average)
Encode duration:  $totsecs secs (${mins}m ${secs}s)

See $graph for the full graph.
	"

	# read -p "
	# Do you want to view it with the associated graphics viewer? [y] " ans
	# [[ -z $ans || $ans = y || $ans = Y ]] && \
		open $graph
}

while [[ 1 ]]; do
	echo -n "
-----------------------------------------------------------------------
Automated x264 benchmark. Best to quit all other apps before launching.
-----------------------------------------------------------------------
  1. Fetch Handbrake (6.9 MB)
  2. Fetch Intel Power Gadget (2.3 MB)
  3. Fetch QGLE (13.2 MB)
  4. Fetch Big Buck Bunnie movie (692 MB)

  0. Launch x264 transcoding (does the above as needed)

  q. Quit
-----------------------------------------------------------------------
Your choice: [q] "
	read ans
	echo
	[[ -z $ans || $ans = q || $ans = Q ]] && exit 0
	[[ $ans = 1 ]] && moh_get_handbrake && continue
	[[ $ans = 2 ]] && moh_get_ipg && continue
	[[ $ans = 3 ]] && moh_get_gle && continue
	[[ $ans = 4 ]] && moh_get_video && continue
	[[ $ans = 0 ]] && moh_check_sane && moh_launch && exit
	#[[ $ans = a || $ans = A ]] && moh_get_handbrake && moh_get_ipg \
	#	&& moh_get_gle && moh_get_movie && moh_launch && exit
done 
