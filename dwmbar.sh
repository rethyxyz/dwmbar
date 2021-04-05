#!/bin/bash

#
#	By: Brody Rethy
#	Website: https://rethy.xyz
#
#	Name: dwmbar.sh
#
#	Summary:
#	An extensible status bar for dwm.
#

#
# TODO Get args in a loop
# TODO If needed ones empty (AKA not given) exit, or prompt again.
#

display_help() {
	echo "dwmbar.sh [DEVICE]"
	echo ""
	echo "Takes one of two args: laptop, or desktop."
	echo "To start this upon dwm launch, put this inside your ~/.xinitrc with the [DEVICE] arg (as shown above)."
}

DEVICE=$1

# DEFINE VARS FOR DEVICE
case $DEVICE in
	laptop | Laptop | e550 | E550) INTERFACE="wlp4s0" ;;
	desktop | Desktop) INTERFACE="enp2s0" ;;
	-h | --help) display_help; exit 0 ;;
	*)
		echo ":: Not a valid device"
		echo ""
		echo "Type dwmbar.sh -h for assistance"
		exit 1
		;;
esac

get_song_left() {
	STATE=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $1}')
	TIME_REMAINING=$(/usr/bin/mpc -p 6601 | sed -n 2p | awk '{print $3}')

	if [[ "$STATE" = "[paused]" ]]
	then
		echo -e "[PAUSED]"
	else
		echo -e "$TIME_REMAINING"
	fi
}

get_vol() {
	# I can cut down on redundancy here by doing this:
	# status=""
	# status+="\x03 BAT: $batperc"
	# status+="\x04 BAT: $batperc"
	# status+="\x01| "+$(date)
	# echo -e $status

   	VOL=$(pulsemixer --get-volume | awk '{print $2}')
	VOL_STATE=$(pulsemixer --get-mute)

	if [[ "$VOL_STATE" = 1 ]]
	then
		echo -e "[MUTED]"
	else
		if [[ "$VOL" -lt 25 ]]
		then
			echo -e "$VOL%"
		elif [[ "$VOL" -lt 50 ]]
		then
			echo -e "$VOL%"
		else
			echo -e "$VOL%"
		fi
	fi
}

# TODO Check battery state
get_bat() {
	# Make charging green in the future
	BAT_LEVEL="$(awk '{ sum += $1 } END { print sum }' /sys/class/power_supply/BAT*/capacity)"
	STATUS="$(cat /sys/class/power_supply/BAT*/status)"

	if [[ "$STATUS" = "Charging" ]]
	then
		echo "[C] $BAT_LEVEL%"
	else
		if [[ $BAT_LEVEL -lt 25 ]]
		then
			echo "$BAT_LEVEL%"
		elif [[ $BAT_LEVEL -lt 50 ]]
		then
			echo "$BAT_LEVEL%"
		else
			echo "$BAT_LEVEL"%
		fi
	fi
}

get_mem_free() {
	MEM_FREE=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024))

	if [[ "$MEM_FREE" -lt 2500 ]]
	then
		echo -e "$MEM_FREE""MB"
	elif [[ "$MEM_FREE" -lt 1500 ]]
	then
		echo -e "$MEM_FREE""MB"
	else
		echo -e "$MEM_FREE"MB
	fi
}

get_temp() {
	TEMP=$(head -c 2 /sys/class/thermal/thermal_zone0/temp)

	if [[ "$TEMP" -gt 80 ]]
	then
		echo -e "$TEMP""C"
	elif [[ "$TEMP" -gt 60 ]]
	then
		echo -e "$TEMP""C"
	else
		echo -e "$TEMP"C
	fi
}

get_date() { date +'%m-%d'; }
get_net_info() { ip addr | awk "/$INTERFACE/ && /inet/" | awk '{print $2}'; }
get_song() { /usr/bin/mpc -p 6601 current; }
get_time() { date +"%r"; }

SEPARATOR="╬"

if [[ "$DEVICE" = "laptop" ]]
then
	while true
	do
		xsetroot -name "$(get_song_left) $(get_song) $SEPARATOR $(get_vol) $SEPARATOR $(get_mem_free) $SEPARATOR $(get_temp) $SEPARATOR $(get_net_info) $SEPARATOR $(get_bat) $SEPARATOR $(get_date) $SEPARATOR $(get_time)"
		sleep 0.2
	done
else
	while true
	do
		xsetroot -name "$(get_song_left) $(get_song) $SEPARATOR $(get_vol) $SEPARATOR $(get_mem_free) $SEPARATOR $(get_net_info) $SEPARATOR $(get_date) $SEPARATOR $(get_time)"
		sleep 0.2
	done
fi
