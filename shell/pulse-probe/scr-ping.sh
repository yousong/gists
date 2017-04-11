#!/bin/sh

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <ip>" >&2
	exit 1
fi

ip="$1"
while true; do
	date +%s | tr '\n' ' '
	# TODO: add -W for response deadline
	ping -c 1 "$ip" | grep 'bytes from'
	sleep 1
done >>"ping-$ip.txt"
