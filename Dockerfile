FROM alpine

RUN apk add --no-cache ppp pptpd iptables

COPY ./etc /etc/

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0700 /entrypoint.sh

# Default network settings
ENV IPFORWARDING=yes
ENV NETWORK=10.99.99.0/24
ENV LOCALIP=10.99.99.1
ENV IPRANGE=10.99.99.100-200
ENV DNS1=8.8.8.8
ENV DNS2=1.1.1.1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["pptpd", "--fg"]
