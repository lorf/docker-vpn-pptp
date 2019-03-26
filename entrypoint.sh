#!/bin/sh

set -ex

iptables_add() {
    local table="${1:-filter}"
    shift
    iptables -t "$table" -C "$@" 2>/dev/null || \
        iptables -t "$table" -A "$@"
}

[ -f /config/pptpd-options ] && \
    cp -p /config/pptpd-options /etc/ppp/pptpd-options
[ -f /config/pptpd.conf ] && \
    cp -p /config/pptpd.conf /etc/pptpd.conf
[ -f /config/chap-secrets ] && \
    cp -p /config/chap-secrets /etc/ppp/chap-secrets

sed -i "s!%%LOCALIP%%!$LOCALIP!g; s!%%IPRANGE%%!$IPRANGE!g" \
    /etc/pptpd.conf

sed -i "s!%%DNS1%%!$DNS1!g" /etc/ppp/pptpd-options
if [ "$DNS2" ]; then
    sed -i "s!%%DNS2%%!$DNS2!g" /etc/ppp/pptpd-options
else
    sed -i '/%%DNS2%%/d' /etc/ppp/pptpd-options
fi

sysctl -w net.ipv4.ip_forward=1

# configure firewall
if [ -f /config/firewall-rules.sh ]; then
    . /config/firewall-rules.sh
else
    iptables_add nat POSTROUTING -s "$NETWORK" ! -d "$NETWORK" -j MASQUERADE
    iptables_add filter FORWARD -s "$NETWORK" -p tcp -m tcp \
        --tcp-flags FIN,SYN,RST,ACK SYN -j TCPMSS --set-mss 1356
    iptables_add filter INPUT -i ppp+ -j ACCEPT
    iptables_add filter OUTPUT -o ppp+ -j ACCEPT
    iptables_add filter FORWARD -i ppp+ -j ACCEPT
    iptables_add filter FORWARD -o ppp+ -j ACCEPT
fi

exec "$@"
