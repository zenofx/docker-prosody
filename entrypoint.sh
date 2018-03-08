#!/bin/bash
set -e

if [[ ! -e /usr/src/prosody/.hg ]]; then
	su-exec $UID:$GID hg clone https://hg.prosody.im/trunk /usr/src/prosody
else
	su-exec $UID:$GID hg pull -u -R /usr/src/prosody
fi

if [[ ! -e /usr/lib/prosody/modules/.hg ]]; then
	su-exec $UID:$GID hg clone https://hg.prosody.im/prosody-modules /usr/lib/prosody/modules
else
	su-exec $UID:$GID hg pull -u -R /usr/lib/prosody/modules
fi

cd /usr/src/prosody && su-exec $UID:$GID ./configure --prefix=/ \
	&& su-exec $UID:$GID make \
	&& make install \
	&& make clean \
	chown -vR $UID:$GID /etc/prosody/*

su-exec $UID:$GID "$@"
