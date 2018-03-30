FROM debian:sid-slim
LABEL maintainer="Thorsten Schubert <tschubert@bafh.org>"

ARG DEBIAN_FRONTEND="noninteractive"
ARG UNAME="prosody"
ARG TZ="Europe/Berlin"
ARG UID="977"
ARG GID="977"
ARG LUAJIT="false"
ARG PROSODY_REVISION="tip"
ARG MODULES_REVISION="tip"

ENV UNAME=${UNAME} \
	TZ=${TZ} \
	UID=${UID} \
	GID=${GID} \
	LUAJIT=${LUAJIT} \
	PROSODY_REVISION=${PROSODY_REVISION} \
	MODULES_REVISION=${MODULES_REVISION} \
	__FLUSH_LOG="yes"

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"

RUN \
	set -x \
	&& printf 'deb-src http://deb.debian.org/debian sid main' >> "/etc/apt/sources.list" \
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
        luajit \
        openssl \
        ca-certificates \
        ssl-cert \
        tzdata \
        mercurial \
        busybox \
    && apt-get build-dep -y prosody \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /usr/share/man/* /tmp/* /var/tmp/*

COPY ./entrypoint.sh /entrypoint.sh
COPY ./su-exec-0.2/su-exec /usr/local/bin/

RUN \
	set -x \
	&& echo ${TZ} > /etc/timezone \
	&& dpkg-reconfigure -f noninteractive tzdata 2>&1 \
	&& mkdir -p /run/prosody /etc/prosody /var/lib/prosody /var/log/prosody /usr/lib/prosody/modules-extra /usr/src/prosody \
	&& groupadd -r -g ${GID} ${UNAME} \
	&& useradd -M -d /var/lib/prosody -r -u ${UID} -g ${GID} -s /bin/false ${UNAME} \
	&& chown -vR ${UID}:${GID} /run/prosody /etc/prosody /var/lib/prosody /var/log/prosody /usr/lib/prosody /usr/src/prosody \
    && chmod a+x /entrypoint.sh /usr/local/bin/su-exec

# permissions should be retained
USER ${UNAME}
VOLUME [ "/etc/prosody", "/var/lib/prosody", "/usr/lib/prosody/modules-extra", "/usr/src/prosody" ]
USER root

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "prosodyctl", "start" ]

EXPOSE 5222 5223 5269 5347 5280 5281
