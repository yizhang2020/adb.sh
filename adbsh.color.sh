#!/bin/bash
# this is shared lib for color based terminal output
#
osplatform=`uname | tr '[:upper:]' '[:lower:]'`

# for more colors, check
# http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
if [ "$osplatform" = "linux" ]
then
    ############# color reference on Linux ###########
    Black='\e[0;30m'
    Blue='\e[0;34m'   ; LightBlue='\e[1;34m'
    Green='\e[0;32m'  ; LightGreen='\e[1;32m'
    Cyan='\e[0;36m'   ; LightCyan='\e[1;36m'
    Red='\e[0;31m'    ; LightRed='\e[1;31m'
    Purple='\e[0;35m' ; LightPurple='\e[1;35m'
    Brown='\e[0;33m'  ; 
    Yellow='\e[1;33m'
    Gray='\e[0;30m'   ;  LightGray='\e[0;37m'
    White='\e[1;37m'
    NC='\e[0m' # No Color

elif [ "$osplatform" = "darwin" ];then
    ########### color reference on Mac ###########
    Black='[30m'    ; DarkGray='[1;30m'
    Blue='[34m'     ; LightBlue='[1;34m'
    Green='[32m'    ; LightGreen='[1;32m'
    Cyan='[36m'     ; LightCyan='[1;36m'
    Red='[31m'      ; LightRed='[1;31m'
    Purple='[35m'   ; LightPurple='[1;35m'
    Brown='[33m'    
    Yellow='[1;33m'
    White='[1;37m'; LightGray='[37m';
    NC='[0m' # No Color
fi

#############################################
# Color utility functions                   #
#############################################

highlight(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 4)${msg}$(tput sgr 0)"
    # some ref here:
    # setaf: foreground color, setab background color
    # 0    black     COLOR_BLACK     0,0,0 
    # 1    red       COLOR_Red       max,0,0
    # 2    green     COLOR_Green     0,max,0
    # 3    yellow    COLOR_Yellow    max,max,0
    # 4    blue      COLOR_Blue      0,0,max
    # 5    magenta   COLOR_MAGENTA   max,0,max
    # 6    cyan      COLOR_Cyan      0,max,max
    # 7    white     COLOR_White     max,max,max
}

hlCyan(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 6) $msg $(tput sgr 0)"
}

hlMagenta(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 5) $msg $(tput sgr 0)"
}

hlBlue(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 4) $msg $(tput sgr 0)"
}

hlYellow(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 3) $msg $(tput sgr 0)"
}

hlGreen(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 2) $msg $(tput sgr 0)"
}

hlRed(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 1) $msg $(tput sgr 0)"
}

echoPass(){
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 2) PASS $(tput sgr 0)"
}

echoFail(){
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 1) FAIL $(tput sgr 0)"
}

echoBlock(){
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 1) BLOCK $(tput sgr 0)"
}
echoWarn(){
    local msg="$@"
    echo -en "$(tput bold)$(tput setaf 7)$(tput setab 5) ${msg} $(tput sgr 0)"
}

echoBlueString(){
    local msg="$@"
    echo -en "${Blue}$msg${NC}"
}

echoBlue(){
    echoBlueString "$@"
    echo ""
}

echoPurple(){
    echoPurpleString "$@"
    echo ""
}

echoPurpleString(){
    local msg="$@"
    echo -en "${Purple}$msg${NC}"
}

echoGreen(){
    local msg="$@"
    echo -en "${LightGreen}${msg}${NC}"
    echo ""
}

echoGreenString(){
    local msg="$@"
    echo -en "${LightGreen}${msg}${NC}"
}

echoYellow(){
    local msg="$@"
    echo -en "${Yellow}$msg${NC}"
    echo ""
}

echoYellowString(){
    local msg="$@"
    echo -en "${Yellow}$msg${NC}"
}

echoRed(){
    local msg="$@"
    echo -en "${Red}$msg${NC}"
    echo ""
}

echoRedString(){
    local msg="$@"
    echo -en "${Red}$msg${NC}"
}

good(){
    local msg="$@"
    echo -en "${LightGreen}[Success]: $msg${NC}"
    echo ""
}

err(){
    local msg="$@"
    echo -en "${Red}[Error]: $msg${NC}"
    echo ""
}

warn(){
    local msg="$@"
    echo -en "${Cyan}$msg${NC}"
    echo ""
}

echo_fancy_time_flies_dot_line(){
    local max_wait_time="$1"
    local interval="$2"
    if [ "$max_wait_time" = "" ];then
        max_wait_time=60
    fi
    if [ "$interval" = "" ];then
        interval=10
    fi
    local wait_so_far=0
    while [ $wait_so_far -lt $max_wait_time ];do
        echoGreenString "."; echoYellowString "."
        sleep $interval
        wait_so_far=$((wait_so_far + interval))
    done
}

