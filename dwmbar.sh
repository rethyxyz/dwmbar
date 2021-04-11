#!/bin/bash

#
## By: Brody Rethy
## Website: https://rethy.xyz
#
## Name: dwmbar.sh
#
## Summary:
## An extensible status bar for dwm.
#

#
# TODO Get args in a loop
# TODO If needed ones empty (AKA not given) exit, or prompt again.
#

display_help() {
	/usr/bin/echo "dwmbar.sh [DEVICE]"
	/usr/bin/echo ""
	/usr/bin/echo "Takes one of two args: laptop, or desktop."
	/usr/bin/echo "To start this upon dwm launch, put this inside your ~/.xinitrc with the [DEVICE] arg (as shown above)."
}

DEVICE=$1

# DEFINE VARS FOR DEVICE
case $DEVICE in
	laptop | Laptop | e550 | E550) INTERFACE="wlp4s0" ;;
	desktop | Desktop) INTERFACE="enp2s0" ;;
	-h | --help) display_help; exit 0 ;;
	*)
		/usr/bin/echo ":: Not a valid device"
		/usr/bin/echo "::"
		/usr/bin/echo ":: Type dwmbar.sh -h for assistance"
		exit 1
		;;
esac

get_song_left() {
	STATE=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $1}')
	TIME_REMAINING=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $3}')

	## Theoretically faster than an if statement, though I haven't tested it yet.
	case $STATE in
		"[paused]") /usr/bin/echo -e "[PAUSED]" ;;
		*) /usr/bin/echo -e "$TIME_REMAINING" ;;
	esac

#	if i[ "$STATE" = "[paused]" ]]
#	then
#	else
#	fi
}

get_vol() {
   	VOL=$(pulsemixer --get-volume | awk '{print $2}')
	VOL_STATE=$(pulsemixer --get-mute)

	case $VOL_STATE in
		1) /usr/bin/echo -e "[MUTED]" ;;

		*)
			if [[ "$VOL" -lt 25 ]]
			then
				/usr/bin/echo -e "$VOL%"
			elif [[ "$VOL" -lt 50 ]]
			then
				/usr/bin/echo -e "$VOL%"
			else
				/usr/bin/echo -e "$VOL%"
			fi
			;;
	esac

#if [[ "$VOL_STATE" = 1 ]]
#then
#else
#fi
}

# TODO Check battery state
get_bat() {
	# Make charging green in the future
	BAT_LEVEL="$(awk '{ sum += $1 } END { print sum }' /sys/class/power_supply/BAT*/capacity)"
	STATUS="$(cat /sys/class/power_supply/BAT*/status)"

	case $STATUS in
		Charging)
			/usr/bin/echo "[C] $BAT_LEVEL%"
			;;
		*)
			if [[ $BAT_LEVEL -lt 25 ]]
			then
				/usr/bin/echo "$BAT_LEVEL%"
			elif [[ $BAT_LEVEL -lt 50 ]]
			then
				/usr/bin/echo "$BAT_LEVEL%"
			else
				/usr/bin/echo "$BAT_LEVEL"%
			fi
			;;
	esac

#if [[ "$STATUS" = "Charging" ]]
#then
#else
#fi
}

get_mem_free() {
	MEM_FREE=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024))

	if [[ $MEM_FREE -gt 2500 ]]
	then
		/usr/bin/echo -e "$MEM_FREE"MB
	elif [[ $MEM_FREE -gt 1500 ]]
	then
		/usr/bin/echo -e "$MEM_FREE""MB"
	else
		/usr/bin/echo -e "$MEM_FREE""MB"
	fi
}

get_temp() {
	TEMP=$(head -c 2 /sys/class/thermal/thermal_zone0/temp)

	if [[ "$TEMP" -gt 80 ]]
	then
		/usr/bin/echo -e "$TEMP""C"
	elif [[ "$TEMP" -gt 60 ]]
	then
		/usr/bin/echo -e "$TEMP""C"
	else
		/usr/bin/echo -e "$TEMP""C"
	fi
}

get_ip_addr() {
	IP_ADDR=$(ip addr | awk "/$INTERFACE/ && /inet/" | awk '{print $2}')

	if [[ "$IP_ADDR" ]]
	then
		/usr/bin/echo -e "$IP_ADDR"
	else
		/usr/bin/echo -e "[OFFLINE]"
	fi
}

get_song() {
	SONG_TITLE=$(/usr/bin/mpc -p 6601 current)
	/usr/bin/echo -e "$SONG_TITLE"
}

get_date() { date +'%m-%d'; }

get_time() { date +"%r"; }

SEPARATOR="╬"

case $DEVICE in
	laptop)
		while true
		do
			xsetroot -name "$(get_song_left) $(get_song) $SEPARATOR $(get_vol) $SEPARATOR $(get_mem_free) $SEPARATOR $(get_temp) $SEPARATOR $(get_ip_addr) $SEPARATOR $(get_bat) $SEPARATOR $(get_date) $SEPARATOR $(get_time)"
			sleep 0.2
		done
		;;

	desktop)
		while true
		do
			xsetroot -name "$(get_song_left) $(get_song) $SEPARATOR $(get_vol) $SEPARATOR $(get_mem_free) $SEPARATOR $(get_ip_addr) $SEPARATOR $(get_date) $SEPARATOR $(get_time)"
			sleep 0.2
		done
		;;
esac

#if [[ "$DEVICE" = "laptop" ]]
#then
#else
#fi
