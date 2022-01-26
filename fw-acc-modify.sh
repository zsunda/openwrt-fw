#!/bin/ash

#defining variables

filename=$1-ipv4-prefixes
isp=$1
port=1111
#BGP AS numbers, check bgp.he.net
as1=AS5483
as2=AS20845
as3=AS43529

case $isp in
	
	telekom)
        { echo "-i or $as1"; sleep 1; } | telnet whois.ripe.net 43 | awk '/^route:/ { ORS=" " ; print $2 }' > $filename
	;;
	
	digi)
        { echo "-i or $as2"; sleep 1; } | telnet whois.ripe.net 43 | awk '/^route:/ { ORS=" " ; print $2 }' > $filename
	;;
	
	vidanet)
        { echo "-i or $as3"; sleep 1; } | telnet whois.ripe.net 43 | awk '/^route:/ { ORS=" " ; print $2 }' > $filename
	;;

	*)
	echo "unknown provider"
	exit 1
	;;
esac

if [ -s $filename ]
then

      ip=`cat $filename`
   
      #deleting existing isp rules

      fw_proc() {
         local FW_CONF="${1}"
         local FW_NAME
         config_get FW_NAME "${FW_CONF}" name
         if [ "${FW_NAME}" = "ssh-$isp" ]
              then uci -q delete firewall."${FW_CONF}"
         fi
      }
      . /lib/functions.sh
      config_load firewall
      config_foreach fw_proc rule
      uci commit firewall

      #'add_list' is for Openwrt v19, older version uses 'set' instead of 'add_lists'
      #adding isp rules

      rule_name=$(uci add firewall rule)
      uci batch << EOI
      set firewall.$rule_name.enabled='1'
      set firewall.$rule_name.dest_port='$port'
      set firewall.$rule_name.src='wan'
      set firewall.$rule_name.name='ssh-$isp'
      add_list firewall.$rule_name.src_ip='$ip'
      set firewall.$rule_name.family='ipv4'
      set firewall.$rule_name.target='ACCEPT'
      add_list firewall.$rule_name.proto='tcp'
EOI
      uci commit firewall

      exit 0
else
      exit 2
fi
