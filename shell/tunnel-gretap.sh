# Sample traffic
#
# 18:04:46.475157 00:22:a0:72:21:85 > 00:22:52:d9:69:78, ethertype IPv4 (0x0800), length 136: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto GRE (47), length 122)
#     172.26.3.206 > 172.26.2.210: GREv0, Flags [none], proto TEB (0x6558), length 102
#         56:85:40:5c:2f:b1 > 92:8b:c4:f9:6f:0c, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 0, offset 0, flags [DF], proto ICMP (1), length 84)
#     1.2.3.4 > 1.2.3.3: ICMP echo request, id 32280, seq 40, length 64
# 18:04:46.475312 00:22:52:d9:69:78 > 00:22:a0:72:21:85, ethertype IPv4 (0x0800), length 136: (tos 0x0, ttl 64, id 35347, offset 0, flags [DF], proto GRE (47), length 122)
#     172.26.2.210 > 172.26.3.206: GREv0, Flags [none], proto TEB (0x6558), length 102
#         92:8b:c4:f9:6f:0c > 56:85:40:5c:2f:b1, ethertype IPv4 (0x0800), length 98: (tos 0x0, ttl 64, id 10132, offset 0, flags [none], proto ICMP (1), length 84)
#     1.2.3.3 > 1.2.3.4: ICMP echo reply, id 32280, seq 40, length 64
#
link_gretap_setup() {
	local name="$1"
	local l="${2%%:*}"
	local r="${3%%:*}"
	local ipl="${2##*:}"
	local ipr="${3##*:}"
	local dev="$4"

	link_gretap_teardown "$name"
	sudo ip link add "$name" type gretap local "$l" remote "$r" dev "$dev"
	sudo ip addr add local "$ipl" peer "$ipr" dev "$name"
	sudo ip link set "$name" up 
}

link_gretap_teardown() {
	local name="$1"

	sudo ip link del "$name" 2>/dev/null
}

# value consists of 2 parts
# - ip address for link_gretap endpoint
# - ip address to be assigned for the link_gretap interface
endlocal="172.26.2.210:1.2.3.3"
endremote="172.26.3.206:1.2.3.4"

# viewpoint of local host: self
self="$(hostname)"
if [ "$self" = "titan" ]; then
	link_gretap_setup foo "$endlocal" "$endremote" eth0
else
	link_gretap_setup foo "$endremote" "$endlocal" eth0
fi

