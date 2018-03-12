FROM debian:sid-slim
MAINTAINER Thorsten Schubert <tschubert@bafh.org>

ARG DEBIAN_FRONTEND="noninteractive"

ENV UNAME=prosody \
	UID=977 \
	GID=977 \
	TZ=Europe/Berlin \
	__FLUSH_LOG=yes

RUN \
	printf 'deb-src http://deb.debian.org/debian sid main' >> "/etc/apt/sources.list" \
	&& apt-get update \
    && apt-get install -y --no-install-recommends \
        lsb-base \
        libidn11 \
        libssl1.1 \
        lua-bitop \
        lua-dbi-mysql \
        lua-dbi-postgresql \
        lua-dbi-sqlite3 \
        lua-event \
        lua-expat \
        lua-filesystem \
        lua-sec \
        lua-socket \
        lua-zlib \
        lua5.1 \
        openssl \
        ca-certificates \
        ssl-cert \
        tzdata \
        mercurial \
        telnet \
    && apt-get build-dep -y prosody \
    && apt-get clean

COPY ./entrypoint.sh /entrypoint.sh
COPY ./su-exec-0.2/su-exec /usr/local/bin/

RUN \
	useradd -m -d /var/lib/prosody -r -U -u ${UID} -s /bin/false ${UNAME} \
	&& mkdir -p /run/prosody /etc/prosody /var/lib/prosody /var/log/prosody /usr/lib/prosody/modules /usr/src/prosody \
	&& chown -vR ${UID}:${GID} /run/prosody /etc/prosody /var/lib/prosody /var/log/prosody /usr/lib/prosody /usr/src/prosody \
    && chmod a+x /entrypoint.sh /usr/local/bin/su-exec \
    && rm -rf /var/lib/apt/lists/* /usr/share/man/* /tmp/*

# permissions should be retained
USER ${UNAME}
VOLUME [ "/etc/prosody", "/var/lib/prosody", "/usr/lib/prosody/modules", "/usr/src/prosody" ]
USER root

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "prosodyctl", "start" ]

EXPOSE 5222 5269 5347 5280 5281
