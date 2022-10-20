#!/bin/bash
################################################
# Date: 2020                                   #
# By  : yizhang2020@berkeley.edu               #
# File: adb.sh                                 #
#       the main script to extend adb function #
################################################
# ask script to give warning when a value is not defined
#set -u

# for debugging purpose, print the command before the output; usually turn it off
#set -x

# steop execution once error detected (exit value is 0)
#set -e

# to turn off 'set -e' do 'set +e' or use syntax: command || do_something

# this is specific for pipe command, stop pipe execution if '-o' is set
#set -o pipefail

###########################################################
# setup environment for cron job execution                #
###########################################################
export TERM=xterm
export SHELL=/bin/bash
if [ "$adbsh_home" = "" ];then
    _dir=$( cd "$( dirname "$0" )" && pwd )
    adbsh_home=$_dir
    export adbsh_home=$_dir
fi
export PATH=$PATH:$adbsh_home:/usr/local/bin/:/bin:/sbin:/usr/sbin:/usr/bin

# import shared libs
. $adbsh_home/adbsh.color.sh
. $adbsh_home/adbsh.util.sh

###########################################################
# core functioins                                         #
###########################################################

adbsh_init(){
    pkgs="adb android-tools-fastboot"
    for pkg in $pkgs
    do
        echo "Checking $pkg"
        apk_info=`apt list --installed 2>/dev/null | grep "^$pkg/"`
        if [ "$apk_info" = "" ];then
            echoYellow "Package [$pkg] not installed, install it now"
            sudo apt install $pkg
        else
            echoGreen " found"
        fi
    done
}

usage(){
    echo "Usage: adb.sh <commands>"
    echo "commands: "
    echo "        : init - install necessary ubuntu packages for adb.sh"
    echo "        : udev - check USB connected devices, parse idProduct and idVendor, add udev rulest"
    echo "        : devices     - list all adb/fastboot connnected devices"
    echo "        : screen_shot - take a screenshot and save it local filesystem"
    echo "        : secinfo     - list security related adb properties and SELinux info"
    echo "        : logs        - shortcut of 'adb -s <dsn> logcat'"
    echo "        : shell       - shortcut of 'adb -s <dsn> shell"
    echo "        : getprop     - shortcut of 'adb -s <dsn> shell getprop"
    echo "Example: adb.sh devices"
}
###########################################################
# global variables                                        #
###########################################################
adbsh_cmds="appinfo init devices getprop logs screen_shot shell secinfo udev"
device_history_profile="$adbsh_home/device.history.profile"
tmpdir="/tmp"

if [ $# -eq 0 ];then
    usage
    exit
fi

cmd=${1:=""}
shift
dsn=${1:-""}
shift
rest="$@"

case $cmd in
    pkginfo)
        exit_if_given_device_not_connected $dsn
        echo "collecting installed package informatio for device [$dsn]"
        collect_package_info $dsn
        ;;
    init)
        adbsh_init
        ;;
    devices)
        read_device_info $dsn
        ;;
    logs)
        adb -s $dsn logcat
        ;;
    screen_shot)
        echo "take a screen_shot $dsn"
        adb_screen_shot $dsn
        ;;
    shell)
        echo "get into [$dsn] shell"
        adb -s $dsn shell
        ;;
    getprop)
        exit_if_given_device_not_connected $dsn
        echo "run getprop in [$dsn] shell"
        getprop "$dsn"
        ;;
    secinfo)
        echo "run android device security information in [$dsn] shell"
        exit_if_given_device_not_connected $dsn
        secinfo "$dsn"
        ;;
    udev)
        $adbsh_home/udev.sh    
        ;;
   *)
        echo -n "Command ["; echoRedString "$cmd" ;echo "] does not supported"
        echo -n "Try one of ["; echoGreenString $adbsh_cmds; echo "]" 
        exit 1
        ;;
esac
