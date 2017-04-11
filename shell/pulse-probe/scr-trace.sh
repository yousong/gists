#!/bin/sh

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <ip>" >&2
	exit 1
fi

ip="$1"
while true; do
	echo -n '## '
	date +%s
	tracepath -l 64 -n "$ip"
	sleep 1
done >>"tracepath-$ip.txt"
