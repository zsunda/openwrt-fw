This script opens a specified port per given ISP (referring with its name; all of its IPv4 addresses as source prefixes) on your openwrt router's firewall.

Prerequsites:
 - telnet client installed on your router (as the tested OpenWRT version of 19.07.8 has a bug in busybox and whois, check this topic: https://forum.openwrt.org/t/whois-broken-for-ip-address-queries/45071)

Tested on v18, v19

Usage:

./fw-acc-modify.sh <isp-name>
