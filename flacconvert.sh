#!/bin/bash


#############################################################################
#                                                                           #
#    Copyright 2009, nijet99@gmail.com                                      #
#                                                                           #
#    This file is part of FLAC-Convert                                      #
#                                                                           #
#    Foobar is free software: you can redistribute it and/or modify         #
#    it under the terms of the GNU General Public License as published by   #
#    the Free Software Foundation, either version 3 of the License, or      #
#    (at your option) any later version.                                    #
#                                                                           #
#    Foobar is distributed in the hope that it will be useful,              #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of         #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
#    GNU General Public License for more details.                           #
#                                                                           #
#    You should have received a copy of the GNU General Public License      #
#    along with FLAC-Convert. If not, see <http://www.gnu.org/licenses/>.   #
#                                                                           #
#############################################################################


##############################################################################
#                             DEFINE VARIABLES                               #
##############################################################################

# Define announce url
announce_url="http://tracker.domain.com/announce"

# Define the base folder from where everything else is relativ. If you have no common basefolder leave this empty. Trailing slash required.
basefolder='/home/hyper/Desktop/test/'	

# Define the folder where the flac albums can be found. Trailing slash required. 
flacfolder=$basefolder'FLAC/'

# Define the folder where the .torrent files shall be stored. Trailing slash required.
torrentfolder=$basefolder'torrents/'

# If you want to have subfolders according to each conversion type (see below) set this value to 1
torrentsubfolder='0'

# Define a different folder for newly created torrents to be stored so that existing .torrent files won't be overwritten. Trailing slash required.
torrentfolder_new='torrents_new/'

# Define the conversion "type". This is a reference for the other arrays and only those types will be converted to that are enabled here.
# Also make sure that the array index number matches the one of the following arrays.
conv_arr[1]='320'
#conv_arr[2]='V0'
#conv_arr[3]='V2'
#conv_arr[4]='OGG'

# Define the destination folder for each type. Trailing slash required.
dest_arr[1]='What_320/'
dest_arr[2]='What_V0/'
dest_arr[3]='What_V2/'
dest_arr[4]='What_OGG/'

# Define the file extension for each type
ext_arr[1]='mp3'
ext_arr[2]='mp3'
ext_arr[3]='mp3'
ext_arr[4]='ogg'

# Define the conversion options for each type
opt_arr[1]='--vbr-new -b 320 --replaygain-accurate --id3v2-only'
opt_arr[2]='--vbr-new -V 0 --replaygain-accurate --id3v2-only'
opt_arr[3]='--vbr-new -V 2 --replaygain-accurate --id3v2-only'
opt_arr[4]='-q 8'



##############################################################################
#                            DEFINE USER FUNCTIONS                           #
#                             do not edit below                              #
##############################################################################




function create_mp3
{
    flacfile="$1"
    opt="$2"
    outputfile="$3"

    # get the id tags... not all are supported by idv3 for mp3s
    TITLE="`metaflac --show-tag=TITLE "$flacfile" | awk -F = '{ printf($2) }'`"
    ARTIST="`metaflac --show-tag=ARTIST "$flacfile" | awk -F = '{ printf($2) }'`"
    ALBUM="`metaflac --show-tag=ALBUM "$flacfile" | awk -F = '{ printf($2) }'`"
    DISCNUMBER="`metaflac --show-tag=DISCNUMBER "$flacfile" | awk -F = '{ printf($2) }'`"
    DATE="`metaflac --show-tag=DATE "$flacfile" | awk -F = '{ printf($2) }'`"
    TRACKNUMBER="`metaflac --show-tag=TRACKNUMBER "$flacfile" | awk -F = '{ printf($2) }'`"
    TRACKTOTAL="`metaflac --show-tag=TRACKTOTAL "$flacfile" | awk -F = '{ printf($2) }'`"
    GENRE="`metaflac --show-tag=GENRE "$flacfile" | awk -F = '{ printf($2) }'`"
    DESCRIPTION="`metaflac --show-tag=DESCRIPTION "$flacfile" | awk -F = '{ printf($2) }'`"
    COMMENT="`metaflac --show-tag=COMMENT "$flacfile" | awk -F = '{ printf($2) }'`"
    COMPOSER="`metaflac --show-tag=COMPOSER "$flacfile" | awk -F = '{ printf($2) }'`"
    PERFORMER="`metaflac --show-tag=PERFORMER "$flacfile" | awk -F = '{ printf($2) }'`"
    COPYRIGHT="`metaflac --show-tag=COPYRIGHT "$flacfile" | awk -F = '{ printf($2) }'`"
    LICENCE="`metaflac --show-tag=LICENCE "$flacfile" | awk -F = '{ printf($2) }'`"
    ENCODEDBY="`metaflac --show-tag=ENCODED-BY "$flacfile" | awk -F = '{ printf($2) }'`"
    REPLAYGAIN_REFERENCE_LOUDNESS="`metaflac --show-tag=REPLAYGAIN_REFERENCE_LOUDNESS "$flacfile" | awk -F = '{ printf($2) }'`"
    REPLAYGAIN_TRACK_GAIN="`metaflac --show-tag=REPLAYGAIN_TRACK_GAIN "$flacfile" | awk -F = '{ printf($2) }'`"
    REPLAYGAIN_TRACK_PEAK="`metaflac --show-tag=REPLAYGAIN_TRACK_PEAK "$flacfile" | awk -F = '{ printf($2) }'`"
    REPLAYGAIN_ALBUM_GAIN="`metaflac --show-tag=REPLAYGAIN_ALBUM_GAIN "$flacfile" | awk -F = '{ printf($2) }'`"
    REPLAYGAIN_ALBUM_PEAK="`metaflac --show-tag=REPLAYGAIN_ALBUM_PEAK "$flacfile" | awk -F = '{ printf($2) }'`"

    flac -dc "$flacfile" | lame $opt \
	--tt "$TITLE" \
	--tn "$TRACKNUMBER" \
	--tg "$GENRE" \
	--ty "$DATE" \
	--ta "$ARTIST" \
	--tl "$ALBUM" \
	- "$outputfile"
}



function create_ogg
{
    flacfile="$1"
    opt="$2"
    outputfile="$3"

    oggenc $opt "$flac" -o "$outputfile"
}



function convert_flacs
{
    # getting the parameters
    flacfile="$1"
    basefolder="$2"
    ext="$3"
    opt="$4"

    # set right filename for transcoded file
    outputfile="$basefolder$dest${flacfile%*.*}.$ext"

    # check if the encoded file is older than the original flac file; if so, encode it!
    if [ "$flacfile" -nt "$outputfile" ]
    then
	case "$ext" in
	    mp3)	create_mp3 "$flacfile" "$opt" "$outputfile";;
	    ogg)	create_ogg "$flacfile" "$opt" "$outputfile";;
	esac
	# find album path in order to touch the album dir to change last modified date
	album_tmp=$(dirname "$outputfile")
	album_dir="${album_tmp%/Disc [0-9]*}"
	touch "$album_dir"
    fi

}



function create_torrents 
{
   # getting the parameters
    sourcefolder="$1"
    announce="$2"
    torrentpath="$3"
    torrentfolder_new="$4"
    conv="$5"

    # Create .torrent file name to be used
    outputfile="$sourcefolder [$conv].torrent"

    # again timestamps for incremental running
    ts_folder=`stat -c %Y "$sourcefolder"`
    if [ -f "$torrentpath$outputfile" ]
    then
	ts_output=`stat -c %Y "$torrentpath$outputfile"`
    else
	ts_output=0
    fi

    # check if current folder "." is selected
    if [ "$sourcefolder" = "." ]
	then
	test=""
    # create torrent
    elif [ ! -f "$torrentpath$outputfile" ]
	then
	mkdir -p $torrentpath$torrentfolder_ne
	echo "mktorrent -p -a $announce -o $torrentpath$outputfile $sourcefolder"
	mktorrent -p -a "$announce" -o "$torrentpath$outputfile" "$sourcefolder"
    # if a .torrent already exists yet the folder has changed, create a new torrent in the new_torrent subfolder
    elif [ "$ts_output" -lt "$ts_folder" ]
	then
	mkdir -p $torrentpath$torrentfolder_new
	echo "mktorrent -p -a $announce -o $torrentpath$torrentfolder_new$outputfile $sourcefolder"
	mktorrent -p -a "$announce" -o "$torrentpath$torrentfolder_new$outputfile" "$sourcefolder"
    else
	test=""
    fi

}



##############################################################################
#                               SCRIPT CONTROL                               #
#                             do not edit below                              #
##############################################################################



# convert flacs
for I in ${!conv_arr[*]}
do
    dest="${dest_arr[$I]}"
    ext="${ext_arr[$I]}"
    opt="${opt_arr[$I]}"

    cd $flacfolder
    dest="${dest_arr[$I]}"
    # create folder structure
    find -type d -exec mkdir -p $basefolder$dest{} \;
    # copy desired non-flac files
    find . \( -iname '*.cue' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' \) -exec cp -u {} $basefolder$dest{} \;
    # find all flac files and pass them on to the actual convert script
    find . -iname '*.flac' | while read flacfile
    do
	# run convert_flacs function
	convert_flacs "$flacfile" "$basefolder" "$ext" "$opt"
    done
done



# create .torrent files
for I in ${!conv_arr[*]}
do
    conv="${conv_arr[$I]}"
    dest="${dest_arr[$I]}"
    ext="${ext_arr[$I]}"
    opt="${opt_arr[$I]}"

    # go to the right folder
    case "$torrentsubfolder" in
	1)	torrentpath="$torrentfolder$dest";;
	*)	torrentpath="$torrentfolder";;
    esac
    convertpath=$basefolder$dest
    cd $convertpath
    # run the create torrent script
    find . -maxdepth 1 -type d | while read sourcefolder
    do
	# run create_torrents function
	create_torrents "$sourcefolder" "$announce_url" "$torrentpath" "$torrentfolder_new" "$conv"
    done
done
