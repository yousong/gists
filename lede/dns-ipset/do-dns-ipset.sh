#!/bin/sh
#
# Copyright 2016-2017 (c) Yousong Zhou
#
#
o_confdir="${o_confdir:-/etc/}"

__errmsg() {
	echo "$1" >&2
}

update_dns_ipset() {
	local F="$1"
	local h ipset dns

	[ -r "$F" ] || {
		__errmsg "Abort: $F is not readable."
		return 1
	}

	mkdir -p "$o_confdir"
	sed -e '/^\s*#.*/d' -e '/^\s*$/d' "$F" \
		| while read -r h ; do
			if [ "${h#ipset=}" != "$h" ]; then
				ipset="${h#ipset=}"
			elif [ "${h#dns=}" != "$h" ]; then
				dns="${h#dns=}"
			else
				[ -n "$ipset" ] && echo "ipset=/$h/$ipset"
				[ -n "$dns" ] && echo "server=/$h/$dns"
			fi
		done >"$o_confdir/dnsmasq.ipset"

	/etc/init.d/dnsmasq restart
}

update_dns_ipset "$1"
