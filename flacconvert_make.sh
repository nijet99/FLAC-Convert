#!/bin/bash

# getting the parameters
dest=$1
basefolder=$2
flacfolder=$3
flac=$4

# set the according options for the conversion
mp_320_opts="--vbr-new -b 320 --replaygain-accurate"
mp_v0_opts="--vbr-new -V 0 --replaygain-accurate"
mp_v2_opts="--vbr-new -V 2 --replaygain-accurate"
ogg_opts="-q 8"

# get the id tags... only those that I use are here
TITLE="`metaflac --show-tag=TITLE "$flac" | awk -F = '{ printf($2) }'`"
ARTIST="`metaflac --show-tag=ARTIST "$flac" | awk -F = '{ printf($2) }'`"
ALBUM="`metaflac --show-tag=ALBUM "$flac" | awk -F = '{ printf($2) }'`"
DISCNUMBER="`metaflac --show-tag=DISCNUMBER "$flac" | awk -F = '{ printf($2) }'`"
DATE="`metaflac --show-tag=DATE "$flac" | awk -F = '{ printf($2) }'`"
TRACKNUMBER="`metaflac --show-tag=TRACKNUMBER "$flac" | awk -F = '{ printf($2) }'`"
TRACKTOTAL="`metaflac --show-tag=TRACKTOTAL "$flac" | awk -F = '{ printf($2) }'`"
GENRE="`metaflac --show-tag=GENRE "$flac" | awk -F = '{ printf($2) }'`"
COMPOSER="`metaflac --show-tag=COMPOSER "$flac" | awk -F = '{ printf($2) }'`"
# has no use this far....
REPLAYGAIN_REFERENCE_LOUDNESS="`metaflac --show-tag=REPLAYGAIN_REFERENCE_LOUDNESS "$flac" | awk -F = '{ printf($2) }'`"
REPLAYGAIN_TRACK_GAIN="`metaflac --show-tag=REPLAYGAIN_TRACK_GAIN "$flac" | awk -F = '{ printf($2) }'`"
REPLAYGAIN_ALBUM_GAIN="`metaflac --show-tag=REPLAYGAIN_ALBUM_GAIN "$flac" | awk -F = '{ printf($2) }'`"
REPLAYGAIN_ALBUM_PEAK="`metaflac --show-tag=REPLAYGAIN_ALBUM_PEAK "$flac" | awk -F = '{ printf($2) }'`"

#echo "$flacfolder --- $flac"
#echo "$1 - $TITLE - $ARTIST - $ALBUM - $DISCNUMBER - $DATE - $TRACKNUMBER - $TRACKTOTAL - $GENRE - $COMPOSER - $REPLAYGAIN_REFERENCE_LOUDNESS - $REPLAYGAIN_TRACK_GAIN - $REPLAYGAIN_ALBUM_GAIN - $REPLAYGAIN_ALBUM_PEAK"

# set right names for transcoded files (could be simple if all file extensions would be equal)
if [ $dest = "What_320/" ]
    then
    outputfile="$basefolder$dest${flac%*.*}.mp3"
elif [ $dest = "What_V0/" ]
    then
    outputfile="$basefolder$dest${flac%*.*}.mp3"
elif [ $dest = "What_V2/" ]
    then
    outputfile="$basefolder$dest${flac%*.*}.mp3"
elif [ $dest = "What_OGG/" ]
    then
    outputfile="$basefolder$dest${flac%*.*}.ogg"
else
    echo ""
fi

# get last modified info original and transcoded file in order to determine if the original has chnaged meanwhile (incremental update encodings)
ts_flac=`stat -c %Y "$flac"`
ts_output=`stat -c %Y "$outputfile"`

echo "$flac -->  $ts_flac  &&  --$ts_output--"

# in case encoded file does not exist yet, assign it a unix timestamp of "0"
if [ -z "$ts_output" ]
    then
    echo "outupt ist null"
    ts_output=0
fi

# check if the encoded file is smaller [older] than the original flac file; if so, encode it!
if [ "$ts_output" -lt "$ts_flac" ]
    then
    if [ $dest = "What_320/" ]
	then
	echo "$dest - 320"
	flac -dc "$flac" | lame $mp_320_opts \
	--tt "$TITLE" \
	--tn "$TRACKNUMBER" \
	--tg "$GENRE" \
	--ty "$DATE" \
	--ta "$ARTIST" \
	--tl "$ALBUM" \
	--add-id3v2 \
	- "$outputfile"
	album_tmp=$(dirname "$outputfile")
	album_dir="${album_tmp%/Disc [0-9]*}"
	touch "$album_dir"
    elif [ $dest = "What_V0/" ]
	then
	echo "$dest - V0"
	flac -dc "$flac" | lame $mp_v0_opts \
	--tt "$TITLE" \
	--tn "$TRACKNUMBER" \
	--tg "$GENRE" \
	--ty "$DATE" \
	--ta "$ARTIST" \
	--tl "$ALBUM" \
	--add-id3v2 \
	- "$outputfile"
	album_tmp=$(dirname "$outputfile")
	album_dir="${album_tmp%/Disc [0-9]*}"
	touch "$album_dir"
    elif [ $dest = "What_V2/" ]
	then
	echo "$dest - V2"
	flac -dc "$flac" | lame $mp_v2_opts \
	--tt "$TITLE" \
	--tn "$TRACKNUMBER" \
	--tg "$GENRE" \
	--ty "$DATE" \
	--ta "$ARTIST" \
	--tl "$ALBUM" \
	--add-id3v2 \
	- "$outputfile"
	album_tmp=$(dirname "$outputfile")
	album_dir="${album_tmp%/Disc [0-9]*}"
	touch "$album_dir"
    elif [ $dest = "What_OGG/" ]
	then
	echo "$dest - OGG"
	# oggenc will auto-use the idv3 tags from the .flac files
	oggenc $ogg_opts "$flac" -o "$outputfile"
	album_tmp=$(dirname "$outputfile")
	album_dir="${album_tmp%/Disc [0-9]*}"
	touch "$album_dir"
    else
	echo "$dest"
    fi
else
    echo ""
fi

