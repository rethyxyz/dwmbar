#!/bin/bash
#
# By: Brody Rethy
# Website: https://rethy.xyz
#
# Name: dwmbar.sh
#
# Summary:
# A modular status bar for dwm. Displays color using specific key codes. See
# https://dwm.suckless.org/patches/statuscolors/ on how, or look at and study
# the code below.
#
# Without statuscolors patch, useless symbols are displayed in their place.
# It's recommended to install the statuscolors patch prior to using this
# script.
#

########################
# VARIABLE DEFINITIONS #
########################

# Primary network interface here.
PRIMARY_INTERFACE="wlp4s0"
# Secondary network interface here. This is used as backup in-case the first
# goes down, or if you want another one to be displayed.
SECONDARY_INTERFACE="enp0s25"
# Your device type (laptop or desktop) goes here (displays bat info if laptop,
# doesn't if desktop).
DEVICE="laptop"
# This can be any character, as long as your font supports it. Emojis should
# work, too.
SEPARATOR="╬"



#############
# FUNCTIONS #
#############

get_time() { date +"%r"; }

get_date() { date +'%m-%d'; }

get_mpd_track() { /usr/bin/mpc -p 6601 current; }

get_mpd_remaining() {
    STATE=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $1}')
    TIME_REMAINING=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $3}')

    if [ "$TIME_REMAINING" = "to" ] || [ "$TIME_REMAINING" = "repeat:" ]; then
        /usr/bin/printf ""
    else
        case "$STATE" in
            "[paused]") /usr/bin/printf "[PAUSED]" ;;
            *) /usr/bin/printf "%s" "$TIME_REMAINING" ;;
        esac
    fi
}

get_vol_perc() {
    VOL=$(pulsemixer --get-volume | awk '{print $2}')
    VOL_STATE=$(pulsemixer --get-mute)

    case "$VOL_STATE" in
        1) /usr/bin/printf "[MUTED]" ;;
        *)
            if [ "$VOL" -lt 25 ]; then
                /usr/bin/printf "%s%%" "$VOL"
            elif [ "$VOL" -lt 50 ]; then
                /usr/bin/printf "$VOL%%"
            else
                /usr/bin/printf "$VOL%%"
            fi
        ;;
    esac
}

get_bat_perc() {
    BAT_LEVEL="$(awk '{ sum += $1 } END { print sum }' \
        /sys/class/power_supply/BAT*/capacity)"
    STATUS="$(cat /sys/class/power_supply/BAT*/status)"

    case "$STATUS" in
        Charging) /usr/bin/printf "[C] $BAT_LEVEL%%" ;;
        *)
            if [ "$BAT_LEVEL" -lt 25 ]; then
                /usr/bin/printf "$BAT_LEVEL%%"
            elif [ "$BAT_LEVEL" -lt 50 ]; then
                /usr/bin/printf "$BAT_LEVEL%%"
            else
                /usr/bin/printf "$BAT_LEVEL%%"
            fi
        ;;
    esac
}

get_mem_free() {
    MEM_FREE=$(($(grep -m1 'MemAvailable:' /proc/meminfo \
        | awk '{print $2}') / 1024))

    if [ "$MEM_FREE" -gt 2500 ]; then
        /usr/bin/printf "$MEM_FREE"MB
    elif [ "$MEM_FREE" -gt 1500 ]; then
        /usr/bin/printf "$MEM_FREE""MB"
    else
        /usr/bin/printf "$MEM_FREE""MB"
    fi
}

get_temp() {
    TEMP=$(head -c 2 /sys/class/thermal/thermal_zone0/temp)

    if [ "$TEMP" -gt 80 ]; then
        /usr/bin/printf "$TEMP""C"
    elif [ "$TEMP" -gt 60 ]; then
        /usr/bin/printf "$TEMP""C"
    else
        /usr/bin/printf "$TEMP""C"
    fi
}

get_ip_addr() {
    PRIMARY_INTERFACE_ADDR=$(ip addr \
        | awk "/$PRIMARY_INTERFACE/ && /inet/" \
        | awk '{print $2}')

    SECONDARY_INTERFACE_ADDR=$(ip addr \
        | awk "/$SECONDARY_INTERFACE/ && /inet/" \
        | awk '{print $2}')

    if [ "$PRIMARY_INTERFACE_ADDR" ]; then
        /usr/bin/printf "$PRIMARY_INTERFACE_ADDR"
    elif [ "$SECONDARY_INTERFACE_ADDR" ]; then
        /usr/bin/printf "$SECONDARY_INTERFACE_ADDR"
    else
        /usr/bin/printf "[OFFLINE]"
    fi
}



########
# MAIN #
########

case "$DEVICE" in
    laptop | Laptop)
        while true; do
            xsetroot -name "$(get_mpd_remaining) $(get_mpd_track) $SEPARATOR $(get_vol_perc) $SEPARATOR $(get_mem_free) $SEPARATOR $(get_temp) $SEPARATOR $(get_ip_addr) $SEPARATOR $(get_bat_perc) $SEPARATOR $(get_date) $SEPARATOR $(get_time)"
            sleep 0.2
        done
    ;;

    desktop | Desktop)
        while true; do
            xsetroot -name "$(get_mpd_remaining) $(get_mpd_track) $SEPARATOR $(get_vol_perc) $SEPARATOR $(get_mem_free) $SEPARATOR $(get_ip_addr) $SEPARATOR $(get_date) $SEPARATOR $(get_time)"
            sleep 0.2
        done
    ;;

    *) printf ":: \"%s\" not a valid device\n" "$DEVICE"; exit 1 ;;
esac
