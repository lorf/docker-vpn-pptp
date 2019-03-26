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
[ -f /config/firewall-rules.sh ] && \
    cp -p /config/firewall-rules.sh /etc/firewall-rules.sh

sed -i "s!%%LOCALIP%%!$LOCALIP!g; s!%%IPRANGE%%!$IPRANGE!g" \
    /etc/pptpd.conf

sed -i "s!%%DNS1%%!$DNS1!g" /etc/ppp/pptpd-options
if [ "$DNS2" ]; then
    sed -i "s!%%DNS2%%!$DNS2!g" /etc/ppp/pptpd-options
else
    sed -i '/%%DNS2%%/d' /etc/ppp/pptpd-options
fi

case "$IPFORWARDING" in
    ""|0|[Nn][Oo]|[Ff]*)
        ;;
    *)
        sysctl -w net.ipv4.ip_forward=1
        ;;
esac

# configure firewall
if [ -f /etc/firewall-rules.sh ]; then
    . /etc/firewall-rules.sh
fi

exec "$@"
