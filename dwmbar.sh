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
	echo "Takes one of two args: laptop, or desktop. To start this upon dwm launch, put this inside your ~/.xinitrc."
	exit 0
}

DEVICE=$1

# DEFINE VARS FOR DEVICE
case $DEVICE in
	laptop | Laptop | e550 | E550) INTERFACE="wlp4s0" ;;
	desktop | Desktop) INTERFACE="enp2s0" ;;
	-h | --help) display_help ;;
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
		echo "[PAUSED]"
	else
		echo "$TIME_REMAINING"
	fi
}

get_vol() {
   	VOL=$(pulsemixer --get-volume | awk '{print $2}')
	VOL_STATE=$(pulsemixer --get-mute)

	if [[ "$VOL_STATE" = 1 ]]
	then
		echo "[MUTED]"
	else
		echo "$VOL"%
	fi
}

# TODO Check battery state
get_bat() {
	BAT="$(awk '{ sum += $1 } END { print sum }' /sys/class/power_supply/BAT*/capacity)"
	STATUS="$(cat /sys/class/power_supply/BAT*/status)"

	if [[ "$STATUS" = "Charging" ]]
	then
		echo [C] "$BAT"%
	else
		echo "$BAT"%
	fi
}
get_date() { date +'%m-%d'; }
get_mem_free() { MEM_FREE=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024)); echo "$MEM_FREE"MB; }
get_net_info() { ip addr | awk "/$INTERFACE/ && /inet/" | awk '{print $2}'; }
get_song() { /usr/bin/mpc -p 6601 current; }
get_temp() { echo "$(head -c 2 /sys/class/thermal/thermal_zone0/temp)C"; }
get_time() { date +"%r"; }

SEPARATOR="╬"

if [[ "$DEVICE" = laptop ]]
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
