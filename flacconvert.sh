#!/bin/bash

#################################################################################
#                                                                               #
# Copyright (C) 2009-2010, FLAC-Convert team                                    #
#                                                                               #
# FLAC-Convert is free software: you can redistribute it and/or modify          #
# it under the terms of the GNU General Public License as published by          #
# the Free Software Foundation, either version 3 of the License, or             #
# (at your option) any later version.                                           #
#                                                                               #
# FLAC-Convert is distributed in the hope that it will be useful,               #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                  #
# GNU General Public License for more details.                                  #
#                                                                               #
# You should have received a copy of the GNU General Public License             #
# along with FLAC-Convert. If not, see <http://www.gnu.org/licenses/>.          #
#                                                                               #
#################################################################################


function usage
{
    echo "Usage: $0 [profile.prof]"
}


# source profile if specified, or default.prof
function source_profile
{
    if [ $# = 0 ]
    then
        profile="default.prof"
    elif [ $# = 1 ]
    then
        profile="$1"
    else
        usage
        return 1
    fi

    # if no slash, then path is relative
    if [ $(expr index / "$profile") = 0 ]
    then
        relative=1
    else
        relative=0
    fi

    # try to find profile in the script directory
    if [ ! -f "$profile" ]
    then
        if [ $relative = 1 ]
        then
            profile2="$(dirname "$0")/$profile"
            if [ -f "$profile2" ]
            then
                profile="$profile2"
                relative=0
            else
                echo "Neither $(pwd)/$profile, nor $profile2 exists"
                return 1
            fi
        else
            echo "File $profile doesn't exist"
            return 1
        fi
    fi

    # this should prevent bash searching profile in PATH
    if [ $relative = 1 ]
    then
        profile="$(pwd)/$profile"
        relative=0
    fi

    echo "Using $profile"

    source "$profile"
}


# enable ctrl-c abort
control_c()
{
    for f in `jobs -p`; do
        kill $f 2> /dev/null
    done
    wait
    exit $?
}
trap control_c SIGINT


function check_exit_codes
{
    local ps=${PIPESTATUS[*]}
    local args=( `echo $@` )
    local i=0
    for s in $ps
    do
        if [ $s -ne 0 ]
        then
            echo "WARNING: Return code of ${args[$i]} indicates failure"
            break
        fi
        let i=$i+1
    done
}

processes_arr[1]="lame"
processes_arr[2]="oggenc"
processes_arr[3]="faac"
processes_arr[4]="neroAacEnc"

function create_mp3
{
    flacfile="$1"
    opt="$2"
    outputfile="$3"

    # get the id tags... not all are supported by id3v2 for mp3s
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

    # sleep while max number of jobs are running
    until ((`jobs | wc -l` < maxnum)); do
        sleep 1
    done

    echo "Encoding `basename "$flacfile"` to $outputfile"
    nice flac -dcs "$flacfile" | lame $opt \
    --tt "$TITLE" \
        --tn "$TRACKNUMBER" \
        --tg "$GENRE" \
        --ty "$DATE" \
        --ta "$ARTIST" \
        --tl "$ALBUM" \
        - "$outputfile" &>/dev/null &
    check_exit_codes flac lame
}


function create_ogg
{
    flacfile="$1"
    opt="$2"
    outputfile="$3"

    # sleep while max number of jobs are running
    until ((`jobs | wc -l` < maxnum)); do
        sleep 1
    done

    echo "Encoding `basename "$flacfile"` to $outputfile"
    nice oggenc $opt "$flacfile" -o "$outputfile" &>/dev/null &
    check_exit_codes oggenc
}


function create_aac
{
    flacfile="$1"
    opt="$2"
    outputfile="$3"

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

    # sleep while max number of jobs are running
    until ((`jobs | wc -l` < maxnum)); do
        sleep 1
    done

    echo "Encoding `basename "$flacfile"` to $outputfile"
    nice flac -dcs "$flacfile" | faac $opt \
        --artist "$ARTIST" \
        --writer "$COMPOSER" \
        --title "$TITLE" \
        --genre "$GENRE" \
        --album "$ALBUM" \
        --track "$TRACKNUMBER/$TRACKTOTAL" \
        --disc "$DISCNUMBER" \
        --year "$DATE" \
        --comment "$COMMENT" \
        -o "$outputfile" \
        - &>/dev/null &
    check_exit_codes flac faac
}


function create_naac
{
    flacfile="$1"
    opt="$2"
    outputfile="$3"
 
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

    # sleep while max number of jobs are running
    until ((`jobs | wc -l` < maxnum)); do
        sleep 1
    done

    echo "Encoding `basename "$flacfile"` to $outputfile"
    nice flac -dcs "$flacfile" | neroAacEnc $opt -if - -of "$outputfile" &>/dev/null &&
    neroAacTag "$outputfile" \
        -meta:artist="$ARTIST" \
        -meta:composer="$COMPOSER" \
        -meta:title="$TITLE" \
        -meta:genre="$GENRE" \
        -meta:album="$ALBUM" \
        -meta:track="$TRACKNUMBER" \
        -meta:totaltracks="$TRACKTOTAL" \
        -meta:disc="$DISCNUMBER" \
        -meta:year="$DATE" \
        -meta:comment="$COMMENT" \
        &>/dev/null &
    check_exit_codes flac neroAacEnc neroAacTag
}


function convert_path
{
    local base="$1"             # with trailing slash
    local dest="$2"             # with trailing slash
    local file="$3"             # full path
    local convpath="$4"         # suffix
    local backwards="$5"        # whether file is a destination file,
                                # if so, convert it to the source file

    if [ ! "$backwards" = "1" ]
    then
        file=${file#"$base"}
        file_substring=${file%%/*}
        local replacement=$dest$file_substring$convpath
        file=${file/#"$file_substring"/"$replacement"}
    else
        file=${file#"$dest"}
        file_substring=${file%%/*}
        local replacement=$base$file_substring
        replacement=${replacement%"$convpath"}
        file=${file/#"$file_substring"/"$replacement"}
    fi
    echo "$file"
}


function convert_flacs
{
    # getting the parameters
    flacfile="$1"
    outputfile="$2"
    opt="$3"

    ext="${outputfile##*.}"
    outputfile="$(sed "s/\.m4aNero$/.m4a/" <<< "$outputfile")"

    # check if the encoded file is older than the original flac file; if so, encode it!
    if [ "$flacfile" -nt "$outputfile" ]
    then
        case "$ext" in
            mp3) create_mp3 "$flacfile" "$opt" "$outputfile";;
            ogg) create_ogg "$flacfile" "$opt" "$outputfile";;
            m4a) create_aac "$flacfile" "$opt" "$outputfile";;
            m4aNero) create_naac "$flacfile" "$opt" "$outputfile";;
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
    conv_create="$6"
    flac_type="$7"

    torrentname="${sourcefolder##*/}"

    # Create .torrent file name to be used. If the conversion type was added during transcoding already, don't readd it
    case "$conv_create" in
        1) convpath="";;
        *) convpath=" [$conv]";;
    esac
    # Check whether type should be added to the creation FLAC .torrents
    case "$flac_type" in
        2) convpath=" [$conv]";;
        *) convpath="";;
	esac
    outputfile="$sourcefolder$convpath.torrent"

    # create torrent
    if [ ! -f "$torrentpath$outputfile" ]
    then
        mkdir -p "$torrentpath"
        # sleep while max number of jobs are running
        until ((`jobs | wc -l` < maxnum)); do
            sleep 1
        done
        # start new job and add it to the background
        nice mktorrent -n "$torrentname$convpath" -p -a "$announce" -o "$torrentpath$outputfile" "$sourcefolder" &
    # if a .torrent already exists yet the folder has changed, create a new torrent in the new_torrent subfolder
    elif [ "$sourcefolder" -nt "$torrentpath$outputfile" ]
    then
        mkdir -p "$torrentpath$torrentfolder_new"
        # sleep while max number of jobs are running
        until ((`jobs | wc -l` < maxnum)); do
            sleep 1
        done
        # start new job and add it to the background
        nice mktorrent -n "$torrentname$convpath" -p -a "$announce" -o "$torrentpath$torrentfolder_new$outputfile" "$sourcefolder" &
    fi
}


# list all files with specified extensions in the specified directory
function find_exts
{
    local path="$1"
    shift
    local exts=$@
    [ $# -eq 0 ] && return 0

    for fileext in ${exts[@]}
    do
        expr="$expr -o -iname \"*.$fileext\""
    done
    expr=${expr# -o }
    eval "nice find $path -type f $expr"
}

# remove destination files and folders if corresponding files in flac folder
# don't exist anymore
function remove_obsolete_files
{
    local dest="$1"             # destination folder with trailing slash
    local src="$2"              # flac folder with trailing slash
    local convpath="$3"         # suffix
    local ext="$4"              # which extension have trancscoded files

    ext="$(sed "s/^m4aNero$/m4a/" <<< "$ext")"

    # remove folders
    find "$dest" -type d | while read folder
    do
        if [ -d "$folder" ]     # skip already removed folders
        then
            srcfolder=$(convert_path "$src" "$dest" "$folder" "$convpath" 1)
            if [ ! -d "$srcfolder" ]
            then
                rm -Rf "$folder"
            fi
        fi
    done

    # remove copied and linked files
    find_exts "$dest" ${copy_exts[@]} ${hard_link_exts[@]} \
        ${soft_link_exts[@]} | while read destfile
    do
        srcfile=$(convert_path "$src" "$dest" "$destfile" "$convpath" 1)
        if [ ! -e "$srcfile" ]
        then
            rm -f "$destfile"
        fi    
    done

    # remove transcoded files
    find "$dest" -type f -iname "*.$ext" | while read destfile
    do
        file=$(convert_path "$src" "$dest" "$destfile" "$convpath" 1)
        srcfile=${file%.*}.flac
        srcfile2=${file%.*}.FLAC
        if [ ! -e "$srcfile" -a ! -e "$srcfile2" ]
        then
            rm -f "$destfile"
        fi
    done
}



#################################################################################
#                                 SCRIPT CONTROL                                #
#                               do not edit below                               #
#################################################################################


source_profile "$@"
[ $? -eq 0 ] || exit $?

echo "Starting the flacconvert script."

# determine maximal number of parallel jobs and add 1
maxnum=`grep -c '^processor' /proc/cpuinfo`
maxnum=$(($maxnum+$coreaddition))

# convert flacs
# check if current run level is set to create only .torrent files; if not, do conversion
if [ "$run_level" != "1" ]
then
    echo "Starting conversion of flac files..."
    # if the flac folder does not exist, skip completely as nothing can be converted
    if [ -d "$flacfolder" ]
    then
        for I in ${!conv_arr[*]}
        do
            conv="${conv_arr[$I]}"
            dest="${dest_arr[$I]}"
            ext="${ext_arr[$I]}"
            opt="${opt_arr[$I]}"
            case "$conv_create" in
                1) convpath=" [$conv]";;
                *) convpath="";;
            esac
            destfolder="$basefolder$dest"

            echo "... removing obsolete files..."
            if [ "$mirror" = "1" ]
            then
                remove_obsolete_files "$destfolder" "$flacfolder" \
                                         "$convpath" "$ext"
            fi
            
            cd "$flacfolder"
            # create folder structure
            find "$flacfolder" -type d | grep -v '^\.$' | while read folder
            do
                folder="$(convert_path "$flacfolder" "$destfolder" \
                                       "$folder" "$convpath")"
                mkdir -p "$folder"
            done

            echo "... copying files..."
            find_exts "$flacfolder" ${copy_exts[@]} | while read extfile
            do
                file="$(convert_path "$flacfolder" "$destfolder" \
                                     "$extfile" "$convpath")"
                cp -a -u "$extfile" "$file"
            done

            echo "... hard linking files..."
            find_exts "$flacfolder" ${hard_link_exts[@]} | while read extfile
            do
                file="$(convert_path "$flacfolder" "$destfolder" \
                                     "$extfile" "$convpath")"
                [ -e "$file" ] || ln "$extfile" "$file"
            done

            echo "... soft linking files..."
            find_exts "$flacfolder" ${soft_link_exts[@]} | while read extfile
            do
                file="$(convert_path "$flacfolder" "$destfolder" \
                                     "$extfile" "$convpath")"
                [ -e "$file" ] || ln -s "$extfile" "$file"
            done

            echo "... converting flac files..."
            nice find "$flacfolder" -iname '*.flac' | while read flacfile
            do
                outputfile="$(convert_path "$flacfolder" "$destfolder" \
                                           "$flacfile" "$convpath")"
                outputfile="${outputfile%.*}.$ext"
                # run convert_flacs function
                convert_flacs "$flacfile" "$outputfile" "$opt"
            done
        done
        echo "... conversion of flac files finished."
    else
        echo "... no flac files found."
    fi
fi

# check if current run level is set to only convert music files; if not, create .torrents
if [ "$run_level" != "0" ]
then

	# make sure all conversion processes are finished
    for check_proc in ${processes_arr[@]}
    do
        echo "... waiting for $check_proc to be finished ..."
        check=`pgrep $check_proc | wc -l`
        while [ "$check" -gt "0" ]; do
            sleep 1
            echo "... waiting for $check_proc to be finished ..."
            check=`pgrep $check_proc | wc -l`
        done
        echo "... $test_proc finished ..."
    done

    # create .torrent files
    echo "Starting creation of .torrent files..."
    for I in ${!conv_arr[*]}
    do
        conv="${conv_arr[$I]}"
        dest="${dest_arr[$I]}"
        ext="${ext_arr[$I]}"
        opt="${opt_arr[$I]}"

        echo "... for $conv ..."

        # go to the right folder
        case "$torrentsubfolder" in
            1) torrentpath="$torrentfolder$dest";;
            *) torrentpath="$torrentfolder";;
        esac
        if [ -d "$basefolder$dest" ]
        then
            cd "$basefolder$dest"
            # run the create torrent script, skip top directory
            find . -maxdepth 1 -type d | grep -v '^\.$' | while read sourcefolder
            do
                # run create_torrents function
                # Last parameter "0" is for flagging that this is not flac_create
                create_torrents "$sourcefolder" "$announce_url" "$torrentpath" "$torrentfolder_new" "$conv" "$conv_create" "0"
            done
            echo "... creation of .torrent files for $conv finished."
        else
            echo "... no .torrent files for $conv created."
        fi
    done

    # create .torrent files for the flac files
    echo "Starting creation of .torrent files..."
    if [ "$flac_create" == "1" ]
    then

        echo "... for $flac_conv ..."

        # go to the right folder
        case "$torrentsubfolder" in
            1) torrentpath="$torrentfolder$flac_sub";;
            *) torrentpath="$torrentfolder";;
        esac
        if [ -d "$flacfolder" ]
        then
            cd "$flacfolder"
            # run the create torrent script, skip top directory
            find . -maxdepth 1 -type d |grep -v '^\.$' | while read sourcefolder
            do
                # run create_torrents function
                # Use flac_type=1 to alaways add the $flac_conv to the torrent path
                create_torrents "$sourcefolder" "$announce_url" "$torrentpath" "$torrentfolder_new" "$flac_conv"  "$conv_create" "$flac_type"
            done
            echo "... creation of .torrent files for $flac_conv finished."
        else
            echo "... no .torrent files created."
        fi
    fi
fi
