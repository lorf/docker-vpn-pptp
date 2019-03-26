FROM alpine

RUN apk add --no-cache ppp pptpd iptables tini

COPY ./etc /etc/

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0700 /entrypoint.sh

ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
CMD ["pptpd", "--fg"]
