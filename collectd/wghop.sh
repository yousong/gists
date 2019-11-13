#!/bin/sh
hopchan=/tmp/wghop

prep() {
	if [ ! -p "$hopchan" ]; then
		rm -f "$hopchan"
		mkfifo "$hopchan"
		chmod a+w "$hopchan"
	fi
}

rand() {
	local n=$1
	local expr="1/$n"' "%u\n"'
	hexdump -n "$n" -e "$expr" /dev/urandom
}

rand_range() {
	local n="$1"; shift
	local s="$1"; shift
	local e="$1"; shift
	local r

	r="$(rand "$n")"
	echo "$(($s + $r % ($e - $s + 1)))"
}

peer=""
endpoint_host0=
endpoint_host1=
endpoint_host=$endpoint_host0
endpoint_port=21841

rand_src_port=1
rand_dst_port=1

hop() {
	local srcport dstport
	local args

	if [ -z "$endpoint" -o -z "$peer" ]; then
		return
	fi
	if [ -n "$rand_src_port" ]; then
		srcport="$(rand_range 2 20000 65536)"
		args="$args listen-port $srcport"
	fi
	if [ -n "$rand_dst_port" ]; then
		dstport="$(rand_range 2 21841 41841)"
	else
		dstport="$endpoint_port"
	fi
	endpoint="$endpoint_host:$dstport"
	args="$args peer $peer endpoint $endpoint"

	set -x
	wg set wg0 $args
	: /etc/init.d/collectd restart
	set +x
}

serv() {
	local x
	while true; do
		read x <"$hopchan"
		[ -n "$x" ] && hop
	done
}

notify() {
	echo -n hop >"$hopchan"
}

prep
[ -n "$serv" ] && serv || notify
