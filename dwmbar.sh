#!/bin/bash
#
# By: Brody Rethy
# Website: https://rethy.xyz
#
# Name: dwmbar.sh
#
# Summary:
# A modular status bar for dwm. Supports color using specific keycodes. See
# https://dwm.suckless.org/patches/statuscolors/ on how, or look at and study
# the code below.
#

# Your primary network interface goes here.
INTERFACE="enp2s0"
# Your device type (laptop or desktop) goes here (displays bat info if laptop).
DEVICE="desktop"
# This can be any character, as long as your font supports it.
SEPARATOR="╬"

get_time() { date +"%r"; }
get_date() { date +'%m-%d'; }
get_mpd_track() { /usr/bin/mpc -p 6601 current; }

get_mpd_remaining() {
    STATE=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $1}')
    TIME_REMAINING=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $3}')

    case "$STATE" in
        "[paused]") /usr/bin/echo -e "[PAUSED]" ;;
        *) /usr/bin/echo -e "$TIME_REMAINING" ;;
    esac
}

get_vol_perc() {
    VOL=$(pulsemixer --get-volume | awk '{print $2}')
    VOL_STATE=$(pulsemixer --get-mute)

    case "$VOL_STATE" in
        1) /usr/bin/echo -e "[MUTED]" ;;
        *)
            if [ "$VOL" -lt 25 ]; then
                /usr/bin/echo -e "$VOL%"
            elif [ "$VOL" -lt 50 ]; then
                /usr/bin/echo -e "$VOL%"
            else
                /usr/bin/echo -e "$VOL%"
            fi
            ;;
    esac
}

get_bat_perc() {
    BAT_LEVEL="$(awk '{ sum += $1 } END { print sum }' /sys/class/power_supply/BAT*/capacity)"
    STATUS="$(cat /sys/class/power_supply/BAT*/status)"

    case "$STATUS" in
        Charging) /usr/bin/echo "[C] $BAT_LEVEL%" ;;
        *)
            if [ "$BAT_LEVEL" -lt 25 ]; then
                /usr/bin/echo "$BAT_LEVEL%"
            elif [ "$BAT_LEVEL" -lt 50 ]; then
                /usr/bin/echo "$BAT_LEVEL%"
            else
                /usr/bin/echo "$BAT_LEVEL"%
            fi
            ;;
    esac
}

get_mem_free() {
    MEM_FREE=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024))

    if [ "$MEM_FREE" -gt 2500 ]; then
        /usr/bin/echo -e "$MEM_FREE"MB
    elif [ "$MEM_FREE" -gt 1500 ]; then
        /usr/bin/echo -e "$MEM_FREE""MB"
    else
        /usr/bin/echo -e "$MEM_FREE""MB"
    fi
}

get_temp() {
    TEMP=$(head -c 2 /sys/class/thermal/thermal_zone0/temp)

    if [ "$TEMP" -gt 80 ]; then
        /usr/bin/echo -e "$TEMP""C"
    elif [ "$TEMP" -gt 60 ]; then
        /usr/bin/echo -e "$TEMP""C"
    else
        /usr/bin/echo -e "$TEMP""C"
    fi
}

get_ip_addr() {
    IP_ADDR=$(ip addr | awk "/$INTERFACE/ && /inet/" | awk '{print $2}')

    if [ "$IP_ADDR" ]; then
        /usr/bin/echo -e "$IP_ADDR"
    else
        /usr/bin/echo -e "[OFFLINE]"
    fi
}

case $DEVICE in
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

    *) echo ":: Not a valid device" ;;
esac
