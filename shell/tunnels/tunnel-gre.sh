tunnel_setup() {
	local name="$1"
	local l="${2%%:*}"
	local r="${3%%:*}"
	local ipl="${2##*:}"
	local ipr="${3##*:}"
	local dev="$4"

	# also works with ipip tunnel
	tunnel_teardown "$name"
	sudo ip tunnel add "$name" mode gre local "$l" remote "$r" dev "$dev"
	sudo ip addr add local "$ipl" peer "$ipr" dev "$name"
	sudo ip link set "$name" up 
}

tunnel_teardown() {
	local name="$1"

	sudo ip tunnel del "$name" 2>/dev/null
}

# value consists of 2 parts
# - ip address for tunnel endpoint
# - ip address to be assigned for the tunnel interface
endlocal="192.168.22.250:1.2.3.3"
endremote="192.168.3.198:1.2.3.4"

# viewpoint of local host: self
self="$(hostname)"
if [ "$self" = "debian" ]; then
	tunnel_setup foo "$endlocal" "$endremote" eth0
else
	tunnel_setup foo "$endremote" "$endlocal" eth0
fi
