#!/bin/sh
#
# This file should be sourced by /entrypoint.sh
#

iptables_add nat POSTROUTING -s "$NETWORK" ! -d "$NETWORK" -j MASQUERADE
iptables_add filter FORWARD -s "$NETWORK" -p tcp -m tcp \
    --tcp-flags FIN,SYN,RST,ACK SYN -j TCPMSS --set-mss 1356
iptables_add filter INPUT -i ppp+ -j ACCEPT
iptables_add filter OUTPUT -o ppp+ -j ACCEPT
iptables_add filter FORWARD -i ppp+ -j ACCEPT
iptables_add filter FORWARD -o ppp+ -j ACCEPT
