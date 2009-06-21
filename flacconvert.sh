#!/bin/bash

basefolder='/home/user/rtorrent/'
flacfolder=$basefolder'/Downloads'	#where to start looking for .flac files
dest[1]='What_320/'			#still hardcoded - serves as indication what to do with the files
dest[2]='What_V0/'			#   "
dest[3]='What_V2/'			#   "
dest[4]='What_OGG/'			#   "

cd $flacfolder

# convert flacs
for item in ${dest[*]}
do
    printf "   %s\n" $item
    # create folder structure
    find -type d -exec mkdir -p $basefolder$item{} \;
    # copy desired non-flac files
    find . \( -name '*.cue' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.gif' -o -name '*.png' \) -exec cp -u {} $basefolder$item{} \;
    # find all flac files and pass them on to the actual convert script
    find -name '*.flac' -exec /home/user/scripts/flacconvert_make.sh $item $basefolder $flacfolder '{}' \;

done

# create torrent files
for item in ${dest[*]}
do
    # go to the right folder
    torrentpath=$basefolder$item
    cd $torrentpath
    # run the create torrent script for each folder --> I assume everything is in a subfolder!!!
    find -maxdepth 1 -type d -exec /home/user/scripts/flacconvert_torrent.sh $item $basefolder '{}' \;
done
