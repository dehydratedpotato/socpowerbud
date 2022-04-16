#!/bin/sh

# SFMRM service version 0.1.0
#
# MIT License
#
# Copyright (c) 2021-2022 BitesPotatoBacks
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

  #################################################
 ##### Function declarations and other crap #####
################################################


SYSTEM=`sysctl machdep.cpu.brand_string`
DATE=`date +'%A'`

FILE=""
ARCH=""
DIDWNLD=""

#CMDOPTS=$@


mkdir -p -- ".sfmrm-data" && cd -P -- ".sfmrm-data"

test -f "arch" || uname -m > "arch"
test -f "did_download" || echo "false" > "did_download"


ARCH=`cat arch`
FILE="${ARCH}-client"
DIDWNLD=`cat did_download`


function _checkInternet()
{
    PING=`ping -c 1 -q google.com >&/dev/null; echo $?`

    if [ $PING != 0 ]
    then
        printf "\e[1mSFMRM service:\033[0;35m warning:\033[0m\e[0m no internet connection, cannot fetch new binary version from Github\n"
        exit
    fi
}


function _pullLatestVersionBinary()
{
    _checkInternet

    printf "\e[1mSFMRM service:\033[0;32m alert:\033[0m\e[0m downloading latest binary version from Github...\n"
        
    LATEST=`curl --silent "https://api.github.com/repos/BitesPotatoBacks/SFMRM/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
        LATESTCUT=`curl --silent "https://api.github.com/repos/BitesPotatoBacks/SFMRM/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | tr -d 'a-z' | tr -d '-' | tr -d '_'`

    curl -Ls "https://github.com/BitesPotatoBacks/SFMRM/releases/download/${LATEST}/sfmrm-v${LATESTCUT}-${FILE}.zip" -O
    
    
    unzip -qq "sfmrm-v${LATESTCUT}-${FILE}.zip" -d "binary" &&
    mv "binary/sfmrm-${FILE}" "sfmrm-${FILE}"
    
    chmod 755 "./sfmrm-${FILE}" &&
    xattr -cr "./sfmrm-${FILE}"
    
    rm "sfmrm-v${LATESTCUT}-${FILE}.zip" &&
    rm -rf "binary"
}


  #################################################
 #####       Actually doing stuff here       #####
################################################

    
if [[ $SYSTEM == *"Pro"* ]] || [[ $SYSTEM == *"Max"* ]] || [[ $SYSTEM == *"Ultra"* ]] || [[ $SYSTEM == *"M2"* ]]
then
    printf "\e[1mSFMRM service:\033[0;35m warning:\033[0m\e[0m your CPU is not officially supported."
    printf "Please visit \e[1mgithub.com/BitesPotatoBacks/SFMRM/issues\e[0m to open a request of support.\n\n"
    
    read -n 1 -s -r -p "(If you want to continue anyway, press any key)"
    
    printf "\n"
fi


if [[ ! -f "./sfmrm-${FILE}" ]]
then
    _pullLatestVersionBinary
fi


if [[ $DATE == "Friday" ]]
then
    if [[ $DIDWNLD == "false" ]]
    then
        _pullLatestVersionBinary
        
        echo "true" > "did_download"
    fi

else
    echo "false" > "did_download"
fi



"./sfmrm-${FILE}" $@
