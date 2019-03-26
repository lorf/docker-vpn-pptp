#!/bin/sh

set -ex

addrule() {
    local table="${1:-filter}"
    shift
    iptables -t "$table" -C "$@" || \
        iptables -t "$table" -A "$@"
}

# configure firewall
addrule nat POSTROUTING -s 10.99.99.0/24 ! -d 10.99.99.0/24 -j MASQUERADE
addrule filter FORWARD -s 10.99.99.0/24 -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j TCPMSS --set-mss 1356
addrule filter INPUT -i ppp+ -j ACCEPT
addrule filter OUTPUT -o ppp+ -j ACCEPT
addrule filter FORWARD -i ppp+ -j ACCEPT
addrule filter FORWARD -o ppp+ -j ACCEPT

exec "$@"
