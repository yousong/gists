#!/bin/sh

if test -f "$RUN_CRONTAB"; then
	crontab "$RUN_CRONTAB"
	exec /sbin/tini -- /usr/sbin/crond -f -L /dev/stderr "$@"
else
	exec bypy "$@"
fi
