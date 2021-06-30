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
# Installing Noto Color Emoji (or any related font) to display emojis is
# recommended, as without, you will see squares in their place. Or, your dwm
# instance will crash.
#

#########################
# VARIABLE DECLARATIONS #
#########################

COUNTER=1

while true; do
    INTERFACE=$(ip a | grep "$COUNTER: " | awk '{print $2}' | sed "s/://g")

    if [ "$INTERFACE" ]; then
        [ ! "$INTERFACE" = "lo" ] && INTERFACES+=("$INTERFACE")
    else
        break
    fi

    COUNTER=$((COUNTER+1))
done

# This can be any character, as long as your font supports it. Emojis should
# work, too.
SEPARATOR="|"

# If valid network interface not found, perma offline status is shown, which
# should be obvious. Loopback address is skipped outright.
PRIMARY_INTERFACE="${INTERFACES[0]}"
SECONDARY_INTERFACE="${INTERFACES[1]}"

# Your device type (laptop or desktop) goes here (displays bat info if laptop,
# doesn't if desktop). I'm not sure if all devices have this file, so I'll
# check this in the future (whenever I have access to many laptops).
[ -e "/sys/class/power_supply/BAT0/type" ] \
&& DEVICE="laptop" \
|| DEVICE="desktop"



#############
# FUNCTIONS #
#############

get_time() { printf "⏰ %s" "$(date +'%r')"; }
get_date() { printf "📅 %s" "$(date +'%m-%d')"; }

get_mpd_track() {
    TRACK=$(mpc -p 6601 current)

    [ "$TRACK" ] && printf "🎵 %s" "$TRACK"
}

get_mpd_remaining() {
    STATE=$(mpc -p 6601 | sed -n 2p | awk '{print $1}')
    TIME_REMAINING=$(mpc -p 6601 | sed -n 2p | awk '{print $3}')

    if \
    [ ! "$TIME_REMAINING" = "to" ] \
    || [ ! "$TIME_REMAINING" = "repeat:" ]; then

        if [ "$STATE" = "[paused]" ]; then
            printf "⏸️ %s" "$SEPARATOR"
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
                printf "🔉 %s%%" "$VOL"
            else
                printf "🔊 %s%%" "$VOL"
            fi
        ;;
    esac
}

get_bat_perc() {
    BAT_LEVEL="$(awk '{ sum += $1 } END { print sum }' \
        /sys/class/power_supply/BAT*/capacity)"

    STATUS="$(cat /sys/class/power_supply/BAT*/status)"

    case "$STATUS" in
        Charging) printf "🔌 %s%%" "$BAT_LEVEL" ;;

        *)
            if [ ! "$BAT_LEVEL" ]; then
                printf ""
            elif [ "$BAT_LEVEL" -lt 25 ]; then
                printf "🔋 %s%%" "$BAT_LEVEL"
            elif [ "$BAT_LEVEL" -lt 50 ]; then
                printf "🔋 %s%%" "$BAT_LEVEL"
            else
                printf "🔋 %s%%" "$BAT_LEVEL"
            fi
        ;;
    esac
}

get_mem_free() {
    MEM_FREE=$(($(grep -m1 'MemAvailable:' /proc/meminfo \
        | awk '{print $2}') / 1024))

    if [ "$MEM_FREE" -gt 2500 ]; then
        printf "🗄️ %s"MB "$MEM_FREE"
    elif [ "$MEM_FREE" -gt 1500 ]; then
        printf "🗄️ %s""MB" "$MEM_FREE"
    else
        printf "🗄️ %s""MB" "$MEM_FREE"
    fi
}

get_temp() {
    TEMP=$(head -c 2 /sys/class/thermal/thermal_zone0/temp)

    if [ ! "$TEMP" ]; then
        printf ""
    elif [ "$TEMP" -gt 80 ]; then
        printf "🟥 %s""C" "$TEMP"
    elif [ "$TEMP" -gt 60 ]; then
        printf "🟨 %s""C" "$TEMP"
    else
        printf "🟩 %s""C" "$TEMP"
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
        printf "📶 %s" "$PRIMARY_INTERFACE_ADDR"
    elif [ "$SECONDARY_INTERFACE_ADDR" ]; then
        printf "📶 %s" "$SECONDARY_INTERFACE_ADDR"
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
