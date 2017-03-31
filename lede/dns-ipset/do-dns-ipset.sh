#!/bin/sh
#
# Copyright 2016 (c) Yousong Zhou
#
__errmsg() {
	echo "$1" >&2
}

update_dns_ipset() {
	local F="$1"
	local h ipset dns
	local lines

	[ -r "$F" ] || {
		__errmsg "Abort: $F is not readable."
		return 1
	}

	lines=$(sed -e '/^\s*#.*/d' -e '/^\s*$/d' "$F" | \
		while read -r h ; do
			if [ "${h#ipset=}" != "$h" ]; then
				ipset="${h#ipset=}"
			elif [ "${h#dns=}" != "$h" ]; then
				dns="${h#dns=}"
			else
				[ -n "$ipset" ] && echo "add_list dhcp.dns_ipset.ipset='/$h/$ipset'"
				[ -n "$dns" ] && echo "add_list dhcp.dns_ipset.server='/$h/$dns'"
			fi
		done)

	uci -q batch <<EOF
# reset dnsmasq section dns_ipset
delete dhcp.dns_ipset
set dhcp.dns_ipset=dnsmasq
$lines
commit dhcp
EOF
	/etc/init.d/dnsmasq reload
}

update_dns_ipset "$1"
