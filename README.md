This script opens a specified port per given ISP (all of its IPv4 addresses as sources) on your openwrt firewall.
Before use modify your ISP's AS number and the 'case' part of this script accordingly.

Prerequsites:
 - telnet client installed on your router

Not yet tested on v20

Usage:

./fw-acc-modify.sh [isp-name]
