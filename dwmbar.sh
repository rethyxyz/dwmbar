#!/bin/bash
# dwmbar.sh

ptime() { printf "%s" "$(date +'%r')"; }
pdate() { printf "%s" "$(date +'%m-%d')"; }

mpdsong() {
    local song=$(mpc -p 6601 current)
    [[ "$song" ]] && printf "%s" "$song"
}

mpdremaining() {
    local state=$(mpc -p 6601 | sed -n 2p | awk '{print $1}')
    local remainder=$(mpc -p 6601 | sed -n 2p | awk '{print $3}')

    if [ ! "$remainder" = "to" ] || [ ! "$remainder" = "repeat:" ]; then
        if [[ "$state" = "[paused]" ]]; then
            printf "[X]" "$sep"
        elif [[ ! "$state" ]]; then
            printf ""
        else
            printf "%s" "$remainder"
        fi
    fi
}

volperc() {
    local vol=$(pulsemixer --get-volume | awk '{print $2}')
    local vol_state=$(pulsemixer --get-mute)

    case "$vol_state" in
        1) printf "[X]" ;;
        *)
            if [[ "$vol" -lt 25 ]]; then
                printf "%s%%" "$vol"
            elif [[ "$vol" -lt 50 ]]; then
                printf "%s%%" "$vol"
            else
                printf "%s%%" "$vol"
            fi
        ;;
    esac
}

batperc() {
    perc="$(awk '{ sum += $1 } END { print sum }' /sys/class/power_supply/BAT*/capacity)"
    state="$(cat /sys/class/power_supply/BAT*/status)"

    case "$state" in
        Charging) printf "[->] %s%%" "$perc" ;;
        *)
            if [[ ! "$perc" ]]; then
                printf ""
            elif [[ "$perc" -lt 25 ]]; then
                printf "%s%%" "$perc"
            elif [[ "$perc" -lt 50 ]]; then
                printf "%s%%" "$perc"
            else
                printf "%s%%" "$perc"
            fi
        ;;
    esac
}

freemem() {
    local mem=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024))
    if [[ "$mem" -gt 2500 ]]; then
        printf "%s"MB "$mem"
    elif [[ "$mem" -gt 1500 ]]; then
        printf "%s""MB" "$mem"
    else
        printf "%s""MB" "$mem"
    fi
}

cputemp() {
    local temp=$(head -c 2 /sys/class/thermal/thermal_zone0/temp)
    if [[ ! "$temp" ]]; then
        printf ""
    elif [[ "$temp" -gt 80 ]]; then
        printf "[!!!] %s""C" "$temp"
    elif [[ "$temp" -gt 60 ]]; then
        printf "%s""C" "$temp"
    else
        printf "%s""C" "$temp"
    fi
}

ipaddr() {
    local primary_interface_addr=$(\
		ip addr \
        | awk "/$PRIMARY_INTERFACE/ && /inet/" \
        | awk '{print $2}'\
	)
    local secondary_interface_addr=$(\
		ip addr \
        | awk "/$SECONDARY_INTERFACE/ && /inet/" \
        | awk '{print $2}'\
	)
    if [[ "$primary_interface_addr" ]]; then
        printf "%s" "$primary_interface_addr"
    elif [[ "$secondary_interface_addr" ]]; then
        printf "%s" "$secondary_interface_addr"
    else
        printf "[OFFLINE]"
    fi
}

main() {
	local COUNTER=1

	while true; do
		INTERFACE=$(\
			ip a \
			| grep "$COUNTER: " \
			| awk '{print $2}' \
			| sed "s/://g"
		)

		if [ "$INTERFACE" ]; then
			[ ! "$INTERFACE" = "lo" ] && INTERFACES+=("$INTERFACE")
		else
			break
		fi

		COUNTER=$((COUNTER+1))
	done

	# This can be any character, as long as your font supports it. Emojis should
	# work, too.
	sep="|"

	# If valid network interface not found, perma offline status is shown, which
	# should be obvious. Loopback address is skipped outright.
	PRIMARY_INTERFACE="${INTERFACES[0]}"
	SECONDARY_INTERFACE="${INTERFACES[1]}"

	# Your device type (laptop or desktop) goes here (displays bat info if
	# laptop, doesn't if desktop). I'm not sure if all devices have this file.
	# I'll check this in the future whenever I have access to a laptop of a
	# different make.
	[ -e "/sys/class/power_supply/BAT0/type" ] \
		&& DEVICE="laptop" \
		|| DEVICE="desktop"

	# How long the bar waits before re-running the functions.
	INTERVAL="0.2"

	case "$DEVICE" in
		laptop | Laptop)
			while true; do
				xsetroot -name "$(mpdremaining) $(mpdsong) $sep $(volperc) $sep $(freemem) $sep $(cputemp) $sep $(ipaddr) $sep $(batperc) $sep $(pdate) $(ptime)"
				sleep "$INTERVAL"
			done
		;;

		desktop | Desktop)
			while true; do
				xsetroot -name "$(mpdremaining) $(mpdsong) $sep $(volperc) $sep $(freemem) $sep $(ipaddr) $sep $(pdate) $(ptime)"
				sleep "$INTERVAL"
			done
		;;

		*)
			printf "\"%s\" not a valid device\n" "$DEVICE"
			exit 1
		;;
	esac
}

main
