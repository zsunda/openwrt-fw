#!/bin/ash
#The goal of this script is to update an openwrt-based router's firewall which makes possible from a certain BGP AS
#to access to the device via SSH on a specified port
#
#It uses busybox's telnet which is not part of official openwrt-releases, therefore creating a custom firmware is a prerequisite
#
#basic checks
#

which telnet > /dev/null
RETVAL=$?

if [ $RETVAL -eq 1 ]
then
	echo
	echo "Telnet is not installed on this router. Compile a custom firmware and check telnet in busybox's network settings!"
	echo
	exit 1
fi	

if [ $# -eq 0 ]
then
	echo
	echo "Usage: $0 <isp>"
	echo "Currently ISP options are telekom, digi and vidanet."
	echo
	exit 2
fi

#
#defining variables
#

FILENAME=$1-ipv4-prefixes
ISP=$1
AS1=AS5483
AS2=AS20845
AS3=AS43529
PORT=1037
OPENWRT_VER=$(awk -F\' '{print $2}' /etc/openwrt_release | awk 'BEGIN {RS="\n"} FNR==2 {print}')

#
#defining functions
#

fw_proc() {
	local FW_CONF="${1}"
	local FW_NAME
	config_get FW_NAME "${FW_CONF}" name
	if [ "${FW_NAME}" = "ssh-$ISP" ]
		then uci -q delete firewall."${FW_CONF}"
	fi
}

#
# main routines
#

case $ISP in
	telekom)
	        { echo "-i or $AS1"; sleep 1; } | telnet whois.ripe.net 43 | awk '/^route:/ { ORS=" " ; print $2 }' > $FILENAME
		;;

	digi)
	        { echo "-i or $AS2"; sleep 1; } | telnet whois.ripe.net 43 | awk '/^route:/ { ORS=" " ; print $2 }' > $FILENAME
		;;
	
	vidanet)
	        { echo "-i or $AS3"; sleep 1; } | telnet whois.ripe.net 43 | awk '/^route:/ { ORS=" " ; print $2 }' > $FILENAME
		;;

	*)
		echo
		echo "Unknown ISP: \"$1\". Options are: telekom, digi or vidanet"
		echo
		exit 3
		;;

esac
	
if [ -s $FILENAME ]
then	

	IP_ADD=$(cat $FILENAME)
	#
	#deleting existing rules with same name avoiding duplicates   
	#
	. /lib/functions.sh
	config_load firewall
	config_foreach fw_proc rule
	uci commit firewall

	#
	# creating rules
	#
	case $OPENWRT_VER in

	        19*)
			rule_name=$(uci add firewall rule)
			uci batch <<- EOI
			set firewall.$rule_name.src='wan'
			set firewall.$rule_name.name='ssh-$ISP'
			add_list firewall.$rule_name.src_ip='$IP_ADD'
			set firewall.$rule_name.family='ipv4'
			set firewall.$rule_name.target='ACCEPT'
			add_list firewall.$rule_name.proto='tcp'
			set firewall.$rule_name.dest_port='$PORT'
			EOI
			uci commit firewall
			/etc/init.d/firewall restart
			exit 0
		        ;;
		
	        18*)
			rule_name=$(uci add firewall rule)
			uci batch <<- EOI
			set firewall.$rule_name.enabled='1'
			set firewall.$rule_name.target='ACCEPT'
			set firewall.$rule_name.src='wan'
			set firewall.$rule_name.proto='tcp'
			set firewall.$rule_name.dest_port='$PORT'
			set firewall.$rule_name.name='ssh-$ISP'
			set firewall.$rule_name.family='ipv4'
			set firewall.$rule_name.src_ip='$IP_ADD'
			EOI
			uci commit firewall
			/etc/init.d/firewall restart
			exit 0
			;;

	        *)
			echo
			echo "This is not a known version of Openwrt"
			echo
			exit 4
			;;
	esac
else
	echo
	echo "File "$FILENAME" not exists. Check permission and/or your internet connection!"
	echo
fi
