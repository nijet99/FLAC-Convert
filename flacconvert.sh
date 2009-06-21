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
#    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.        #
#                                                                           #
#############################################################################


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
