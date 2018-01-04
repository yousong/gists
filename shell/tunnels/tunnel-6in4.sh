# Sample traffic
#
#	17:06:08.192104 00:22:1a:e8:f1:d7 > 00:00:5e:00:01:01, ethertype IPv4 (0x0800), length 138: (tos 0x0, ttl 64, id 12237, offset 0, flags [DF], proto IPv6 (41), length 124)
#	    101.236.62.248 > 104.238.138.31: (hlim 64, next-header ICMPv6 (58) payload length: 64) 2001:19f0:9002:b5a::3 > 2a02:c205:2012:6427::1: [icmp6 sum ok] ICMP6, echo request, seq 1
#	17:06:08.539147 08:e8:4f:6d:32:00 > 00:22:1a:e8:f1:d7, ethertype IPv4 (0x0800), length 138: (tos 0x0, ttl 42, id 15500, offset 0, flags [DF], proto IPv6 (41), length 124)
#	    104.238.138.31 > 101.236.62.248: (hlim 57, next-header ICMPv6 (58) payload length: 64) 2a02:c205:2012:6427::1 > 2001:19f0:9002:b5a::3: [icmp6 sum ok] ICMP6, echo reply, seq 1
#
link_6in4_setup() {
	local name="$1";		shift
	local left0="$1";		shift
	local left1="$1";		shift
	local right0="$1";		shift
	local dev="$1";			shift

	link_6in4_teardown "$name"
	sudo ip tunnel add "$name" mode sit local "$left0" remote "$right0" ${dev:+dev "$dev"}
	sudo ip addr add "$left1" dev "$name"
	sudo ip link set "$name" up 
}

link_6in4_teardown() {
	local name="$1"

	sudo ip tunnel del "$name" 2>/dev/null
}

setup() {
	if [ "$o_left" = "p0" ]; then
		link_6in4_setup "$o_dev" "$o_p0_addr0" "$o_p0_addr1" "$o_p1_addr0" "$o_p0_dev"
		sudo ip -6 route add ::/0 dev "$o_dev"
	else
		link_6in4_setup "$o_dev" "$o_p1_addr0" "$o_p1_addr1" "$o_p0_addr0" "$o_p1_dev"
		sudo /sbin/sysctl -w net.ipv6.conf.all.forwarding=1
		sudo /sbin/sysctl -w net.ipv6.conf.all.proxy_ndp=1
		sudo ip -6 route add "${o_p0_addr1%/*}" dev "$o_dev"
		sudo ip -6 neigh add proxy "${o_p0_addr1%/*}" dev "$o_p1_dev"
	fi
}

teardown() {
	link_6in4_teardown "$o_dev"
}

#
# The setup has the following assumptions
#
# - p0 is a host in ipv4 network.  That's why we add a default ipv6 route
#   through the tunnel device
# - p1 is a dual-stack host to whom traffics to a /64 network will be routed
#   and from whom p0 will have its ipv6 address assigned.
#
#   We also need to enable ndp proxy so that p1's gateway knows to send packets
#   with p0's ipv6 address to p1 which will forward through the tunnel to p0 at
#   last
#
# Option name
#
#	p{0,1}			role name
#	addr0			ipv4 addresses of endpoints
#	addr1			ipv6 addresses to be assigned to p0, p1, with prefix length
#	o_dev			name of the tunnel device to create
#	o_p{0,1}_dev 	where the encapsulated packets should be routed through
#	o_left			whoami, p0 or p1
#
o_dev=foo
o_p0_addr0="1.1.1.1"
o_p0_addr1="1:2:3::2/64"
o_p0_dev="eth1"
o_p2_addr0="2.2.2.2"
o_p1_addr1="1:2:3::3/64"
o_p1_dev="ens3"
#o_left

"$@"
