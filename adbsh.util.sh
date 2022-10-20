#!/bin/bash
#set -x
dir=$( cd "$( dirname "$0" )" && pwd )
if [ "$adbsh_home" = "" ];then
    adbsh_home=$dir
    export adbsh_home=$dir
fi

# import color lib
. $adbsh_home/adbsh.color.sh

#####################################
# functions for adbsh               #
#####################################
adb_connected_devices(){
    adb devices | grep "^\([:0-9a-zA-Z]\)*.*device$" | sed -e "s/device$//g"
}

extract_single_device_info(){
    local device_dsn="$1"
    local output_file="$2"
    local device_info_tmp="$tmpdir/device.info.$device_dsn.$RANDOM.txt"
    local smartvolume=""
    adb -s $device_dsn shell getprop > $device_info_tmp

    local brand=`grep -i "\[ro.product.brand\]" $device_info_tmp | cut -d":" -f2 | tr -d "[]\r "`
    local sdk_version=`grep -i "\[ro.build.version.sdk\]" $device_info_tmp | cut -d":" -f2 | tr -d "[]\r "`
    local build_variant=`grep -i "\[ro.build.type\]" $device_info_tmp | cut -d":" -f2 | tr -d "[]\r "`
    local build_utc_time=`grep -i "\[ro.build.date.utc\]"  $device_info_tmp | cut -d":" -f2 | tr -d "[]\r "`
    local build_time_string=`perl -e "print scalar(localtime($build_utc_time))"`
    local security_patch=`grep -i "\[ro.build.version.security_patch\]" $device_info_tmp | cut -d":" -f2 | tr -d "[]\r "`
    local android_os_version=`grep -i "\[ro.build.version.release\]" $device_info_tmp | cut -d":" -f2 | tr -d "[]\r "`
    # the kernel version is part of /proc info, parse it from actual device
    local kernel_version=`adb -s $device_dsn shell cat /proc/version | cut -d" " -f3 | cut -d "-" -f1`
    # output a single device information to output file
    # the order of the fields can be found in read_device_info() : device_info_header 
    echo " $device_dsn | $brand | $android_os_version | $sdk_version | $kernel_version | $security_patch | $build_variant | $build_time_string " >> $output_file
    safe_rm $device_info_tmp
}

read_device_info(){
    device_info_header=" DSN | Brand | OS Ver | SDK Ver | Kernel | Security Patch | Variant | Build Time "
    local device_info_file="$tmpdir/adbsh.info.$RANDOM.txt"
    local device_info_file_final="$tmpdir/adbsh.info.$RANDOM.txt"
    local device_dsn="$1"
    local original_dsn="$device_dsn"
    if [ "$device_dsn" = "" ];then
        device_dsn="all"
    fi
    echo "" > $device_info_file
    local connected_devices=`adb_connected_devices`
    for dsn in $connected_devices
    do
        extract_single_device_info $dsn $device_info_file
    done
    if [ "$device_dsn" = "all" ];then
        show_adb_authorized_devices "$device_info_header" "$device_info_file"
        adb_show_unauthorized_device
        show_fastboot_usb_devices
    else
        local device_info_for_given_dsn="$tmpdir/device.info.$RANDOM.txt"
        cat $device_info_file | grep -i "$original_dsn" > $device_info_for_given_dsn
    fi
    safe_rm $device_info_file
}

show_adb_authorized_devices(){
    local device_info_header="$1"
    local device_info_file="$2"
    local device_info_file_tmp="$tmpdir/device.info.$RANDOM.txt"
    if [ -f $device_info_file ]
    then
        echo "$device_info_header" > $device_info_file_tmp
        cat $device_info_file | sort | grep -v -i "Unknown" >> $device_info_file_tmp
        local total_device=`cat $device_info_file | grep -v -i "Unknown" | grep -v "^\s*$" |wc -l | xargs echo | cut -d" " -f1`
        echoGreen "== List of adb connected and authorized devices (Total $total_device) =="
        perl $adbsh_home/table_beautifier.pl -i $device_info_file_tmp
    fi
    safe_rm $device_info_file_tmp
}

adb_show_unauthorized_device(){
    local not_authorized=`adb devices | grep -v "device$" | grep -v "List of devices attached" 2>&1`
    if [ "$not_authorized" != "" ]
    then
        echo -n "== List of adb connected but "; echoRedString "not authorized"; echo " device =="
        adb devices | grep -v "device$" | grep -v "List of devices attached" | sed -e "s/^/    /g"
    fi
    local unauthorized_devices=`adb devices | grep -v "device$" | grep -v "List of devices attached" | cut -f1 | tr -d "\r" | tr "\n" " "`
}

show_fastboot_usb_devices(){
    local fastboot_devices_usb=`fastboot devices | sed -e "s/fastboot$//g" | xargs echo`
    if [ "$fastboot_devices_usb" != "" ]
    then
        echo -n "== List of "; echoGreenString "attached but in fastboot USB mode"; echo " device =="
        # fastboot over usb
        fastboot devices| sed -e "s/^/    /g"
    fi
}

safe_rm(){
    local file_to_be_removed="$1"
    if [ "$file_to_be_removed" != "" ] 
    then
        if [ -f $file_to_be_removed ] 
        then
            rm -f $file_to_be_removed
        elif [ -d $file_to_be_removed ];then
            if [ "$file_to_be_removed" != "/" ];then
                rm -rf $file_to_be_removed
            fi
        fi
    fi
}

mktemp_file(){
    if [ "$tmpdir" = "" ];then
        if [ "$spa_home" = "" ]; then
            if [ -d /tmp ];then
                tmpdir = "/tmp"
            else
                tmpdir = "./tmp"
                mkdir "./tmp"
            fi
        else
            tmpdir="$spa_home/tmp"
            if [ ! -d $tmpdir ];then
                mkdir -p "$tmpdir"
            fi
        fi
    else
        if [ ! -d $tmpdir ];then
            mkdir -p "$tmpdir"
        fi
    fi
    local tmpfile="$tmpdir/spa.$RANDOM.$RANDOM.tmp"
    if [ -f $tmpfile ];then
        rm -f $tmpfile 
    fi
    touch $tmpfile
    echo $tmpfile
}


adb_screen_shot(){
    local device_dsn="$1"
    local timestamp=`date "+%F-%T" | sed -e "s/[-|:]/./g"`
    local fileName="screenshot.$timestamp.png"
    local screenShotDir="/tmp/screen_shots"
    if [ ! -d $screenShotDir ];then
        mkdir -p $screenShotDir
    fi
    exit_if_given_device_not_connected "$device_dsn"
    (
        adb -s $device_dsn shell screencap -p /sdcard/$fileName
        adb -s $device_dsn pull /sdcard/$fileName $screenShotDir/$fileName
        adb -s $device_dsn shell rm /sdcard/$fileName
    ) 2>&1 > /dev/null
    echo "screen shot has been saved as $screenShotDir/$fileName"
    if [ "$(uname)" = "Darwin" ];then
        open $screenShotDir/$fileName
    elif [ "$(uname)" = "Linux" ];then
        if [ -x /usr/bin/eog ];then
            /usr/bin/eog $screenShotDir/$fileName  2>/dev/null &
        else
            echo "No display command found"
        fi
    fi
}

exit_if_given_device_not_connected(){
    local device_dsn="$1"
    local connected_devices=`adb_connected_devices`
    if [ "$device_dsn" = "" ];then
        err "No device DSN number provided, exit"
        exit 1
    else
        if echo "$connected_devices" | grep -i -w "$device_dsn" 2>&1 > /dev/null
        then
            good "[$device_dsn] is connected"
        else
            err "[$device_dsn] is not connected, exit"
            exit 1
        fi
    fi
}

getprop(){
    local device_dsn="$1"
    local propf="$tmpdir/getprop.$device_dsn.txt"
    local tmpf="$tmpdir/getprop.$RANDOM.txt"
    adb -s $device_dsn shell getprop > $propf
    echo "  adb property | property value " > $tmpf
    cat $propf | sed -e "s/]: \[/ | /g" | tr '[' ' ' | tr -d ']'>> $tmpf

    perl $adbsh_home/table_beautifier.pl -i $tmpf
    echo "Device [$dsn] getprop saved in: $propf"
    safe_rm $tmpf
}

secinfo(){
    local device_dsn="$1"
    local propf="$tmpdir/getprop.$device_dsn.txt"
    local secf="$tmpdir/secinfo.$RANDOM.txt"
    adb -s $device_dsn shell getprop > $propf
    echo "  security configuration | value " > $secf
    cat $propf | sed -e "s/]: \[/ | /g" | tr '[' ' ' | tr -d ']' \
        | grep "ro.adb.secure\|ro.secure\|ro.vendor.build.security_patch\|ro.debuggable\|ro.crypt\|veri\|security.perf_harden\|ro.build.selinux" \
        >> $secf
    perl $adbsh_home/table_beautifier.pl -i $secf
    # knowledge in code
    # the expected value of system property and reference I found online
    expect_info "$secf" \
                "https://android.googlesource.com/platform/system/sepolicy/+/38ac77e4c2b3c3212446de2f5ccc42a4311e65fc" \
                "security.perf_harden" \
                "1"

    expect_info "$secf" \
                "https://android.googlesource.com/platform/system/core/+/refs/heads/oreo-mr1-iot-release/rootdir/adb_debug.prop" \
                "ro.secure" \
                "1"

    expect_info "$secf" \
                "https://android.googlesource.com/platform/system/core/+/6ac5d7d/adb/daemon/main.cpp#128" \
                "ro.adb.secure" \
                "1"

    expect_info "$secf" \
                "https://android.googlesource.com/platform/system/core/+/refs/heads/oreo-mr1-iot-release/rootdir/adb_debug.prop" \
                "ro.debuggable" \
                "0"

    # the following security property are different from above, the expected values
    # are vary, sometimes, as long as the property presents, it is secure"
    expect_info "$secf" \
                "https://source.android.com/docs/security/features/verifiedboot/dm-verity" \
                "ro.boot.veritymode" 

    expect_info "$secf" \
                "https://source.android.com/docs/security/bulletin" \
                "security_patch" 

    echo "Device [$dsn] security info saved in: $secf"

    echo "- system config -"
    selinux_val=`adb -s $device_dsn shell cat /sys/fs/selinux/enforce`
    if [ "$selinux_val" = "1" ];then
        echoGreen "SELinux status: enforcing mode"
    else
        echoRed "SELinux status: not enforced, check /sys/fs/selinux/enforce"
    fi
}

expect_info(){
    local dataf="$1"
    local comment="$2"
    local expect_str="$3"
    local expect_val="$4"
    if [ "$dataf" != "" ] && \
        [ -f "$dataf" ] && \
        [ "$expect_str" != "" ] && \
        [ "$comment" != "" ];then
        if ! grep "$expect_str" $dataf 2>&1>/dev/null; then
            echoRed "Expect  : [$expect_str]"
            echo    "Comment : $comment"
        else
            if [ "$expect_val" != "" ];then
                actual_val=`grep $expect_str $dataf | cut -d "|" -f2 |xargs echo`
                if [ "$expect_val" != "$actual_val" ];then
                    echoRed " - Warning, actual $expect_str = [$actual_val], expect [$expect_val]"
                    echo    " - Comment : $comment"
                fi
            fi
        fi
    fi
}


collect_package_info(){
    local device_dsn="$1"
    local packages=`adb -s $device_dsn shell pm list packages -f`
    local info_tmp="$tmpdir/package.info.$device_dsn.$RANDOM.txt"
    local info_tmp_2="$tmpdir/package.info.$device_dsn.$RANDOM.txt"
    echo "#package name | package install path" > $info_tmp
    echo "" > $info_tmp_2
    for package in $packages
    do
        pkg_path=`echo "$package" | sed -e "s/package://g" | rev | cut -d"=" -f1-| rev | xargs echo`
        pkg_name=`echo "$package" | sed -e "s/package://g" | rev | cut -d"=" -f1| rev |xargs echo`
        echo "$pkg_name | $pkg_path" >> $info_tmp_2
    done
    cat $info_tmp_2 | sort >> $info_tmp
    perl $adbsh_home/table_beautifier.pl -i $info_tmp
    safe_rm $info_tmp_2
    echoGreen "package info for device [$deice_dsn] saved as: $info_tmp"
}
