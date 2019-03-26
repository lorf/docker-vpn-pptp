#!/bin/sh

set -ex

# Set defaults
: ${IPFORWARDING:=yes}
: ${NETWORK:=10.99.99.0/24}
: ${LOCALIP:=10.99.99.1}
: ${IPRANGE:=10.99.99.100-200}
: ${DNS1:=8.8.8.8}
: ${DNS2:=1.1.1.1}

iptables_startup_pre() {
    iptables_cleanup

    iptables -N VPN_PPTP_IN
    iptables -N VPN_PPTP_OUT
    iptables -N VPN_PPTP_FWD
    iptables -t nat -N VPN_PPTP_NAT_PRE
    iptables -t nat -N VPN_PPTP_NAT_POST
}

iptables_startup_post() {
    iptables -t nat -I PREROUTING -s "$NETWORK" -j VPN_PPTP_NAT_PRE
    iptables -t nat -I PREROUTING -d "$NETWORK" -j VPN_PPTP_NAT_PRE
    iptables -t nat -I POSTROUTING -s "$NETWORK" -j VPN_PPTP_NAT_POST
    iptables -t nat -I POSTROUTING -d "$NETWORK" -j VPN_PPTP_NAT_POST
    iptables -I INPUT -i ppp+ -j VPN_PPTP_IN
    iptables -I OUTPUT -o ppp+ -j VPN_PPTP_OUT
    iptables -I FORWARD -i ppp+ -j VPN_PPTP_FWD
    iptables -I FORWARD -o ppp+ -j VPN_PPTP_FWD
}

iptables_cleanup() {
    {
        set +e
        iptables -t nat -D PREROUTING -s "$NETWORK" -j VPN_PPTP_NAT_PRE 2>/dev/null
        iptables -t nat -D PREROUTING -d "$NETWORK" -j VPN_PPTP_NAT_PRE 2>/dev/null
        iptables -t nat -D POSTROUTING -s "$NETWORK" -j VPN_PPTP_NAT_POST 2>/dev/null
        iptables -t nat -D POSTROUTING -d "$NETWORK" -j VPN_PPTP_NAT_POST 2>/dev/null
        iptables -D INPUT -i ppp+ -j VPN_PPTP_IN 2>/dev/null
        iptables -D OUTPUT -o ppp+ -j VPN_PPTP_OUT 2>/dev/null
        iptables -D FORWARD -i ppp+ -j VPN_PPTP_FWD 2>/dev/null
        iptables -D FORWARD -o ppp+ -j VPN_PPTP_FWD 2>/dev/null
        iptables -F VPN_PPTP_IN 2>/dev/null
        iptables -F VPN_PPTP_OUT 2>/dev/null
        iptables -F VPN_PPTP_FWD 2>/dev/null
        iptables -t nat -F VPN_PPTP_NAT_PRE 2>/dev/null
        iptables -t nat -F VPN_PPTP_NAT_POST 2>/dev/null
        iptables -X VPN_PPTP_IN 2>/dev/null
        iptables -X VPN_PPTP_OUT 2>/dev/null
        iptables -X VPN_PPTP_FWD 2>/dev/null
        iptables -t nat -X VPN_PPTP_NAT_PRE 2>/dev/null
        iptables -t nat -X VPN_PPTP_NAT_POST 2>/dev/null
    } || true
}

trap 'rc=$?; iptables_cleanup; exit $rc' INT HUP TERM QUIT

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
iptables_startup_pre
if [ -f /etc/firewall-rules.sh ]; then
    . /etc/firewall-rules.sh
fi
iptables_startup_post

"$@"

iptables_cleanup
