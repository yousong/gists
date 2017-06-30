#!/bin/sh

# get gw from net/masklen (first address as the gw)
net_gw() {
	local net="$1"
	local a b

	net="${net%/*}"
	a="${net%.*}"
	b="${net##*.}"
	b="$(($b | 1))"
	echo "$a.$b"
}

# get net/masklen by masking @ip with @masklen
ip_masklen_net() {
	local ip="$1"
	local masklen="$2"
	local a b c

	if [ "$masklen" -ge 32 ]; then
		echo "$ip/$masklen"
	elif [ "$masklen" -ge 24 ]; then
		a="$(echo "$ip" | cut -d . -f 1-3)"
		b="$(echo "$ip" | cut -d . -f 4)"
		c="$(((1<<($masklen-24)) - 1))"
		c="$(($c << (32 - $masklen)))"
		c="$(($b & $c))"
		echo "$a.$c/$masklen"
	elif [ "$masklen" -ge 16 ]; then
		a="$(echo "$ip" | cut -d . -f 1-2)"
		b="$(echo "$ip" | cut -d . -f 3)"
		c="$(((1<<($masklen-16)) - 1))"
		c="$(($c << (24 - $masklen)))"
		c="$(($b & $c))"
		echo "$a.$c.0/$masklen"
	elif [ "$masklen" -ge 8 ]; then
		a="$(echo "$ip" | cut -d . -f 1)"
		b="$(echo "$ip" | cut -d . -f 2)"
		c="$(((1<<($masklen-8)) - 1))"
		c="$(($c << (16 - $masklen)))"
		c="$(($b & $c))"
		echo "$a.$c.0.0/$masklen"
	else
		a=
		b="$(echo "$ip" | cut -d . -f 1)"
		c="$(((1<<($masklen-0)) - 1))"
		c="$(($c << (8 - $masklen)))"
		c="$(($b & $c))"
		echo "$c.0.0.0/$masklen"
	fi
}

ip_masklen_net_test() {
	local ip masklen
	local i j k l

	for i in \
			192.168.33.129/0:0.0.0.0/0 \
			192.168.33.129/1:128.0.0.0/1 \
			192.168.33.129/24:192.168.33.0/24 \
			192.168.33.129/25:192.168.33.128/25 \
			192.168.33.129/32:192.168.33.129/32 \
			; do
		j="${i#*:}"
		i="${i%:*}"
		ip="${i%/*}"
		masklen="${i#*/}"
		k="$(ip_masklen_net "$ip" "$masklen")"
		[ "$j" = "$k" ] && l=ok || l=bad
		echo "$l $i -> $k"
	done
}

_do() {
	sh -xc "$1"
}

symroute() {
	local ipmasklen dev
	local ipaddress masklen netmasklen netgw
	local idx=2

	#
	#	127.0.0.1/8 lo
	#	10.76.67.57/24 eth0
	#	172.16.0.125/16 eth1
	ip address show \
			| grep -E '\s+\<inet [0-9./]+' \
			| awk ' { print $2" "$NF } ' \
			| while read ipmasklen dev; do
		ipaddress="${ipmasklen%/*}"
		masklen="${ipmasklen#*/}"

		if [ "${ipaddress#127.0}" != "$ipaddress" ]; then
			continue
		fi

		ipaddress="${ipmasklen%/*}"
		netmasklen="$(ip_masklen_net "$ipaddress" "$masklen")"
		netgw="$(net_gw "$netmasklen")"
		_do "
while ip rule delete lookup $idx; do true; done
ip route flush table $idx
ip route add table $idx dev $dev $netmasklen
ip route add table $idx dev $dev default via $netgw
ip rule add from $ipaddress lookup $idx
"
		idx="$(($idx + 1))"
	done
}

usage() {
	local arg0="$1"

	cat <<-EOF
		usage: $arg0 symroute
EOF
}

[ "$#" -gt 0 ] || set -- usage $0

"$@"
