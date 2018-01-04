link_6to4_setup() {
	local name="$1";		shift
	local left0="$1";		shift
	local right0="$1";		shift
	local dev="$1";			shift
	local left1 left1prefix

	left1prefix="$(printf "2002:%02x%02x:%02x%02x" ${left0//./ })"
	left1="$left1prefix::1/16"

	link_6to4_teardown "$name"
	sudo ip tunnel add "$name" mode sit local "$left0" remote "$right0" ${dev:+dev "$dev"}
	sudo ip addr add "$left1" dev "$name"
	sudo ip link set "$name" up
}

link_6to4_teardown() {
	local name="$1"

	sudo ip tunnel del "$name" 2>/dev/null
}

setup() {
	link_6to4_setup "$o_dev" "$o_p0_addr0" "$o_p1_addr0" "$o_p0_dev"
	sudo ip -6 route add ::/0 dev "$o_dev"
}

teardown() {
	link_6to4_teardown "$o_dev"
}

#
# Option name
#
#	p0				role name
#	addr0			ipv4 addresses of endpoints
#	o_dev			name of the tunnel device to create
#	o_p0_dev		where the encapsulated packets should be routed through
#
# 6to4 is almost the same as 6in4.  They use the same encapsulation method,
# i.e. proto-41.  6to4 is different in that
#
#  - the remote endpoint ipv4 address is 192.88.99.1, an anycast address
#  - the local ipv6 address is derived from local endpoint ipv4 address and has
#    prefix 2002::/16, the concatenated address will form a 2002:xxyy:zzaa::/48
#    network
#
# On Linux, we can omit the "remote 192.88.99.1" part and add default route
# with "::192.88.99.1" as the gateway to instruct the kernel to use it as the
# remote endpoint
#
o_dev=foo
o_p0_addr0="1.1.1.1"
o_p0_dev="eth1"
o_p1_addr0=192.88.99.1

"$@"
