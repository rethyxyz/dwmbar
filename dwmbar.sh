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
# I also recommend installing Noto Color Emoji to display emojis, as without,
# you will see squares in their place.
#

########
# TODO #
########

# Figure out the separator issues.



########################
# VARIABLE DEFINITIONS #
########################

# Primary network interface here.
PRIMARY_INTERFACE="wlp5s0"
# Secondary network interface here. This is used as backup in-case the first
# goes down, or if you want another one to be displayed.
SECONDARY_INTERFACE="enp2s0"
# Your device type (laptop or desktop) goes here (displays bat info if laptop,
# doesn't if desktop).
DEVICE="desktop"
# This can be any character, as long as your font supports it. Emojis should
# work, too.
SEPARATOR="|"



#############
# FUNCTIONS #
#############

get_time() { printf "⏰ $(date +'%r')"; }

get_date() { printf "📅 $(date +'%m-%d')"; }

get_mpd_track() {
    TRACK=$(mpc -p 6601 current)

    [ "$TRACK" ] && printf "🎵 $TRACK"
}

get_mpd_remaining() {
    STATE=$(mpc -p 6601 | sed -n 2p | awk '{print $1}')
    TIME_REMAINING=$(mpc -p 6601 | sed -n 2p | awk '{print $3}')

    if \
    [ ! "$TIME_REMAINING" = "to" ] \
    || [ ! "$TIME_REMAINING" = "repeat:" ]; then

        if [ "$STATE" = "[paused]" ]; then
            printf "⏸️ $SEPARATOR"
        elif [ ! "$STATE" ]; then
            printf ""
        else
            printf "%s" "⏯️ $TIME_REMAINING $SEPARATOR"
        fi
    fi
}

get_vol_perc() {
    VOL=$(pulsemixer --get-volume | awk '{print $2}')
    VOL_STATE=$(pulsemixer --get-mute)

    case "$VOL_STATE" in
        1) printf "🔇" ;;
        *)
            if [ "$VOL" -lt 25 ]; then
                printf "🔈 %s%%" "$VOL"
            elif [ "$VOL" -lt 50 ]; then
                printf "🔉 $VOL%%"
            else
                printf "🔊 $VOL%%"
            fi
        ;;
    esac
}

get_bat_perc() {
    BAT_LEVEL="$(awk '{ sum += $1 } END { print sum }' \
        /sys/class/power_supply/BAT*/capacity)"

    STATUS="$(cat /sys/class/power_supply/BAT*/status)"

    case "$STATUS" in
        Charging) printf "🔌 $BAT_LEVEL%%" ;;

        *)
            if [ ! "$BAT_LEVEL" ]; then
                printf ""
            elif [ "$BAT_LEVEL" -lt 25 ]; then
                printf "🔋 $BAT_LEVEL%%"
            elif [ "$BAT_LEVEL" -lt 50 ]; then
                printf "🔋 $BAT_LEVEL%%"
            else
                printf "🔋 $BAT_LEVEL%%"
            fi
        ;;
    esac
}

get_mem_free() {
    MEM_FREE=$(($(grep -m1 'MemAvailable:' /proc/meminfo \
        | awk '{print $2}') / 1024))

    if [ "$MEM_FREE" -gt 2500 ]; then
        printf "🗄️ $MEM_FREE"MB
    elif [ "$MEM_FREE" -gt 1500 ]; then
        printf "🗄️ $MEM_FREE""MB"
    else
        printf "🗄️ $MEM_FREE""MB"
    fi
}

get_temp() {
    TEMP=$(head -c 2 /sys/class/thermal/thermal_zone0/temp)

    if [ ! "$TEMP" ]; then
        printf ""
    elif [ "$TEMP" -gt 80 ]; then
        printf "🟥 $TEMP""C"
    elif [ "$TEMP" -gt 60 ]; then
        printf "🟨 $TEMP""C"
    else
        printf "🟩 $TEMP""C"
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
        printf "📶 $PRIMARY_INTERFACE_ADDR"
    elif [ "$SECONDARY_INTERFACE_ADDR" ]; then
        printf "📶 $SECONDARY_INTERFACE_ADDR"
    else
        printf "[OFFLINE]"
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

    *)
        printf ":: \"%s\" not a valid device\n" "$DEVICE"
        exit 1
    ;;
esac
