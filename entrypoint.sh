#!/bin/bash
set -e

log()
{
    echo \[$(date +'%Y%m%d %H:%M:%S.%3N')\] \[${HOSTNAME}\] $*
}

echo ${TZ} > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
chown -R ${UID}:${GID} /run/prosody /etc/prosody /var/lib/prosody /var/log/prosody /usr/lib/prosody /usr/src/prosody

if [[ "${LUAJIT,,}" = "true" ]]; then
	log "installing luajit as default interpreter"
	update-alternatives --install /usr/bin/lua lua-interpreter /usr/bin/luajit 150 \
	&& update-alternatives --set lua-interpreter /usr/bin/luajit
fi

if [[ ! -e /usr/src/prosody/.hg ]]; then
	su-exec $UID:$GID hg clone https://hg.prosody.im/trunk /usr/src/prosody
else
	su-exec $UID:$GID /bin/bash -c 'hg pull -u -R /usr/src/prosody \
		&& hg update -C -R /usr/src/prosody'

	if [[ -v PROSODY_REVISION ]]; then
		log "checking out prosody revision: ${PROSODY_REVISION}"
		su-exec $UID:$GID hg update -C -r ${PROSODY_REVISION} -R /usr/src/prosody
	fi
fi

if [[ ! -e /usr/lib/prosody/modules-extra/.hg ]]; then
	su-exec $UID:$GID hg clone https://hg.prosody.im/prosody-modules /usr/lib/prosody/modules-extra
else
	su-exec $UID:$GID /bin/bash -c 'hg pull -u -R /usr/lib/prosody/modules-extra \
		&& hg update -C -R /usr/lib/prosody/modules-extra'

	if [[ -v MODULES_REVISION ]]; then
		log "checking out module revision: ${MODULES_REVISION}"
		su-exec $UID:$GID hg update -C -r ${MODULES_REVISION} -R /usr/lib/prosody/modules-extra
	fi
fi

# prosodyctl cert import complains if not owned by executing user (root)
# which it needs in order to read a mounted certificate volume
# e.g. /etc/letsencrypt/
cd /usr/src/prosody && su-exec $UID:$GID \
	./configure --prefix=/usr \
	&& su-exec $UID:$GID make \
	&& make install \
	&& make clean \
	&& chown -R $UID:$GID /etc/prosody/* \
	&& chown root /etc/prosody/certs

exec su-exec $UID:$GID "$@"
