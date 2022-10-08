#!/bin/bash

dir=$( cd "$( dirname "$0" )" && pwd )
if [ "$adbsh_home" = "" ];then
    adbsh_home=$dir
    export adbsh_home=$dir
fi

# import color lib
. $adbsh_home/adbsh.color.sh

load_new_rules(){
    echo "reload Udev service"
    sudo service udev reload
    sudo service udev status
    echo "restart adb server"
    adb kill-server
    adb start-server
    echo "Done! "
    echo "In most case, you need unplug and replug usb cord to make it visiable and authorized under adb"
    echo "This script was designed to only work for Lab126 devices, if you want it work for other devices, you need modify source code"
    echo "Read the code for more info"
}

generate_and_append_new_rule(){
    new_rule="SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"${idVendor}\", ATTRS{idProduct}==\"${idProduct}\", MODE=\"0664\", GROUP=\"plugdev\""
    if cat $rule_file | grep "ATTRS{idVendor}==\"${idVendor}\", ATTRS{idProduct}==\"${idProduct}\"" 2>&1 >/dev/null
    then
        echo "Udev rule for $idVendor:$idProduct exists, doing nothing"
    else
        echoYellow "append new udev rule: $new_rule to [$rule_file]"
        echo $new_rule | sudo tee --append $rule_file
    fi
}
# Sample rule from /etc/udev/51-android.rules
#SUBSYSTEM=="usb", ATTRS{idVendor}=="1949", ATTRS{idProduct}=="0110", MODE="0664", GROUP="plugdev"

rule_file="/etc/udev/rules.d/51-android.rules"
#################################################################
# the next line means we grep everything other than hub
#lsusb | grep -v -i "hub" | while read line
#################################################################
# the next line is hard to customize. I test on my laptop and you might have
# diferent situation
lsusb | grep -v -i "hub\|Realtek\|Inel\|Logitech\|sensor\|Camera\|Apple\|Synaptics\|Smartcard\|Intel" | while read line
do
    echo "Check usb device: [$line]"
    idVendor=`echo $line | cut -d":" -f2,3 | cut -d" " -f3 | cut -d":" -f1`
    idProduct=`echo $line | cut -d":" -f2,3 | cut -d" " -f3 | cut -d":" -f2`
    echo "idVendor: ${idVendor} ; idProduct: ${idProduct}"
    generate_and_append_new_rule $idVendor $idProduct
done

load_new_rules

