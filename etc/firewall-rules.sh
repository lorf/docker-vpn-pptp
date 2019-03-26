#!/bin/sh
#
# This file should be sourced by /entrypoint.sh
#

iptables -t nat -A VPN_PPTP_NAT_POST -s "$NETWORK" ! -d "$NETWORK" -j MASQUERADE
iptables -A VPN_PPTP_IN -j ACCEPT
iptables -A VPN_PPTP_OUT -j ACCEPT
iptables -A VPN_PPTP_FWD -s "$NETWORK" -p tcp -m tcp \
    --tcp-flags FIN,SYN,RST,ACK SYN -j TCPMSS --clamp-mss-to-pmtu
iptables -A VPN_PPTP_FWD -j ACCEPT
