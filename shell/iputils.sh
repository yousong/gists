#
# Copyright 2017 (c) Yousong Zhou
#

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

# longest binary prefix between two integers
topmask_int() {
	local sint="$1"
	local eint="$2"
	local i=128
	local bs be
	local maskint=0
	local masklen=0

	while [ "$i" != 0 ]; do
		bs="$(($sint & $i))"
		be="$(($eint & $i))"
		if [ "$bs" = "$be" ]; then
			masklen="$(($masklen + 1))"
			maskint="$(($maskint + $bs))"
			i="$(($i >> 1))"
		else
			break
		fi
	done
	echo "$maskint/$masklen"
}

# produce a net/masklen from start ip and end ip
ip_range_net() {
	local sip="$1"
	local eip="$2"
	local s3 s2 s1 s0
	local e3 d2 e1 e0
	local topmask
	local net masklen

	s3="${sip%%.*}"
	s2="${sip#*.}"
	s2="${s2%%.*}"
	s1="${sip%.*}"
	s1="${s1##*.}"
	s0="${sip##*.}"

	e3="${eip%%.*}"
	e2="${eip#*.}"
	e2="${e2%%.*}"
	e1="${eip%.*}"
	e1="${e1##*.}"
	e0="${eip##*.}"

	if [ "$s3" != "$e3" ]; then
		topmask="$(topmask_int "$s3" "$e3")"
		net="${topmask%/*}.0.0.0"
		masklen="${topmask#*/}"
	elif [ "$s2" != "$e2" ]; then
		topmask="$(topmask_int "$s2" "$e2")"
		net="$s3.${topmask%/*}.0.0"
		masklen="${topmask#*/}"
		masklen="$(($masklen + 8))"
	elif [ "$s1" != "$e1" ]; then
		topmask="$(topmask_int "$s1" "$e1")"
		net="$s3.$s2.${topmask%/*}.0"
		masklen="${topmask#*/}"
		masklen="$(($masklen + 16))"
	elif [ "$s0" != "$e0" ]; then
		topmask="$(topmask_int "$s0" "$e0")"
		net="$s3.$s2.$s1.${topmask%/*}.0"
		masklen="${topmask#*/}"
		masklen="$(($masklen + 16))"
	else
		net="$s3.$s2.$s1.$s0"
		masklen=32
	fi
	echo "$net/$masklen"
}

# ipadd:
#
# 1. Add <ip/preflen> to <ifname>
# 2. Add link route to the net with src ip being <ip>
# 3. Change/add default route with gw being the first address in specific net
# 4. Send unsolicitous arp requests to update neighbors' cache
ipadd() {
	local ip="$1"
	local masklen="$2"
	local ifname="$3"
	local ipnet net gw

	if [ "$(id -u)" != 0 ]; then
		echo "$0 requires root privileges" >&2
		exit 1
	fi

	ipnet="$ip/$masklen"
	net="$(ip_masklen_net "$ipnet")"
	gw="$(net_gw "$net")"

	ip addr add "$ipnet" dev "$ifname"
	ip route add "$net" dev "$ifname" src "$ip" &>/dev/null || \
		ip route change "$net" dev "$ifname" src "$ip"
	ip route change default via "$gw" dev "$ifname" src "$ip" &>/dev/null || \
		ip route add default via "$gw" dev "$ifname" src "$ip"
	arping -c 3 -U -I "$ifname" "$ip"
}

# ipdel:
#
# 1. Del <ip/preflen> from <ifname>
# 2. Del exactly the link route added by "ipadd" command
# 3. If there is remaining address in <ifname>
#    1. Try adding link route to its net
#    2. Change default route by using gw inferred from that address
ipdel() {
	local ip="$1"
	local masklen="$2"
	local ifname="$3"
	local ipnet net gw

	if [ "$(id -u)" != 0 ]; then
		echo "$0 requires root privileges" >&2
		exit 1
	fi

	ipnet="$ip/$masklen"
	net="$(ip_masklen_net "$ip" "$masklen")"
	gw="$(net_gw "$net")"

	ip addr del "$ipnet" dev "$ifname"
	ip route del "$net" dev "$ifname" src "$ip" &>/dev/null

	# get remaining address from ifname
	ipnet="$(ip addr show "$ifname" | awk '/^[ ]+inet ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/ { print $2; exit 0; }' )"
	if [ -n "$ipnet" ]; then
		ip="${ipnet%/*}"
		net="$(ip_masklen_net "$ipnet")"
		gw="$(net_gw "$net")"
		ip route change "$net" dev "$ifname" src "$ip" &>/dev/null || \
			ip route add "$net" dev "$ifname" src "$ip" &>/dev/null
		ip route change default via "$gw" dev "$ifname" src "$ip" &>/dev/null || \
			ip route add default via "$gw" dev "$ifname" src "$ip" &>/dev/null
	fi
}

"$@"
