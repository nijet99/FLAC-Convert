#!/bin/bash


#############################################################################
#                                                                           #
#    Copyright 2009, nijet99@gmail.com                                      #
#                                                                           #
#    This file is part of FLAC-Conver                                       #
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
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.        #
#                                                                           #
#############################################################################


# getting the parameters
dest=$1
basefolder=$2
folder=$3

# setting some vars
announce="http://tracker.domaion.com"			# your announce URL
new_folder=$basefolder"_new_torrents/"			# if a .torrent file already exists but the original source has changed it will create a new torrent file in that folder

opts="${dest%/*}"					# revmove trailing slash from the $dest var
outputfile="$folder [$opts].torrent"			# name the output .torrent file

currentpath="$basefolder$dest$folder"			# set current path

# again timestamps for incremental running
ts_folder=`stat -c %Y "$currentpath"`
ts_output=`stat -c %Y "$outputfile"`

echo "$folder -->  $ts_folder  &&  --$ts_output--"

# if torrent file does not exist yet, assign it a unix timestamp of "0"
if [ -z "$ts_output" ]
    then
    echo "outupt ist null"
    ts_output=0
fi


echo $folder
echo $ts_folder

echo "File: $outputfile"

# test whether it tries to create a torrent of the "." folder
testfile=". [$opts].torrent"

# test whether it tries to create a test of the "_new_torrents" folder; only necessary if you have the _new_torrent folder as subfolder of where it looks for files to create otrrents
newtorrents="./_new_torrents"
echo "folder: $folder ---- $newtorrents"

# running test above
if [ "$folder" = "$newtorrents" ]
    then
    echo "do nothing nothing nothing................................."
#running test above
elif [ "$outputfile" = "$testfile" ]
    then
    echo "do nothing................................................."
#create torrent
elif [ ! -f "$outputfile" ]
    then
    mktorrent -p -a "$announce" -o "$basefolder$dest$outputfile" "$currentpath"
elif [ "$ts_output" -lt "$ts_folder" ]
    then
    mkdir -p $new_folder
    mktorrent -p -a "$announce" -o "$new_folder$outputfile" "$currentpath"
else
    echo ""
fi

