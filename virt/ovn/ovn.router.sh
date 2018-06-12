set -x

logdir=/home/yousong/.usr/var/log/openvswitch
rundir=/home/yousong/.usr/var/run/openvswitch

o_north_sb_ip=10.4.237.52
o_north_sb_port=6642
o_north_nb_ip=10.4.237.52
o_north_nb_port=6641

ovn_nbctl() {
	ovn-nbctl --db="tcp:$o_north_nb_ip:$o_north_nb_port" "$@"
}

get_encap_ip() {
	ip -o addr show dev eth1 | grep -oE 'inet [^/ ]+' | cut -d' ' -f2
}

get_dhcp_uuid() {
	local cidr="$1"
	ovn_nbctl --bare --columns=_uuid find DHCP_Options cidr="$cidr"
}

prep_host() {
	local encap_ip="$(get_encap_ip)"

	ovs-ctl start --system-id=random
	ovn-ctl start_controller

	ovs-vsctl set Open_vSwitch . \
		external_ids:ovn-remote="tcp:$o_north_sb_ip:$o_north_sb_port" \
		external_ids:ovn-bridge=br0 \
		external_ids:ovn-encap-type=geneve \
		external_ids:ovn-encap-ip="$encap_ip" \

}

prep_north() {
	ovn-ctl start_northd \
		--db-nb-create-insecure-remote \
		--db-sb-create-insecure-remote

}

prep_logical() {
	# logical switch name does not need to be unique
	# logical switch port name needs to be unique: iface-id
	ovn_nbctl \
		-- --all destroy DHCP_Options \
		-- --all destroy Logical_Switch_Port \
		-- --all destroy Logical_Switch \
		-- --all destroy Logical_Router_Port \
		-- --all destroy Logical_Router \

	ovn_nbctl \
		-- create DHCP_Options \
				cidr=192.168.2.0/24 \
				options:server_id=192.168.2.1 \
				options:server_mac=0a:00:00:00:00:01 \
				options:lease_time=86400 \
				options:router=192.168.2.1 \
		-- create DHCP_Options \
				cidr=192.168.3.0/24 \
				options:server_id=192.168.3.1 \
				options:server_mac=0a:00:00:00:01:01 \
				options:lease_time=86400 \
				options:router=192.168.3.1 \

	ovn_nbctl \
		-- ls-add ls0 \
		-- ls-add ls1 \
		-- lr-add lr0 \
		-- lrp-add lr0 lr0ls0 0a:00:00:00:00:01 192.168.2.1/24 \
		-- lrp-add lr0 lr0ls1 0a:00:00:00:01:01 192.168.3.1/24 \
		-- lsp-add ls0 ls0lr0 \
		-- lsp-set-type ls0lr0 router \
		-- lsp-set-options ls0lr0 router-port=lr0ls0 \
		-- lsp-add ls1 ls1lr0 \
		-- lsp-set-type ls1lr0 router \
		-- lsp-set-options ls1lr0 router-port=lr0ls1 \

	dhcp2=$(get_dhcp_uuid 192.168.2.0/24)
	dhcp3=$(get_dhcp_uuid 192.168.3.0/24)
	add_logical_port ls0 ls0p0 0a:00:00:00:00:02 192.168.2.2 "$dhcp2"
	add_logical_port ls0 ls0p1 0a:00:00:00:00:03 192.168.2.3 "$dhcp2"
	add_logical_port ls0 ls0p2 0a:00:00:00:00:04 192.168.2.4 "$dhcp2"
	add_logical_port ls1 ls1p0 0a:00:00:00:01:02 192.168.3.2 "$dhcp3"
	add_logical_port ls1 ls1p1 0a:00:00:00:01:03 192.168.3.3 "$dhcp3"
}

add_logical_port() {
	local ls="$1"; shift
	local lsp="$1"; shift
	local mac="$1"; shift
	local ip="$1"; shift
	local dhcp="$1"; shift

	ovn_nbctl --may-exist lsp-add "$ls" "$lsp" \
		-- lsp-set-addresses "$lsp" "$mac $ip" \
		-- lsp-set-dhcpv4-options "$lsp" $dhcp \

}

add_host_port() {
	local name="$1"; shift
	local mac="$1"; shift
	local ip="$1"; shift
	local name0="${name}0"
	local name1="${name}1"

	# openvswitch internal type port may not work for it cannot be put to
	# ofport up state
	ip netns add "$name"
	ip link del dev "$name0"
	ip link add dev "$name0" type veth peer name "$name1"
	ip link set dev "$name0" up
	ip link set dev "$name1" netns "$name" address "$mac" mtu 1442 up

	ovs-vsctl --if-exists del-port "$name0"
	ovs-vsctl --may-exist add-port br0 "$name0" \
		-- set Interface "$name0" external_ids:iface-id="$name"

	ip netns exec "$name" timeout 3 dhclient -d "$name1"
}

init_host0() {
	add_host_port ls0p0 0a:00:00:00:00:02 192.168.2.2
	add_host_port ls0p1 0a:00:00:00:00:03 192.168.2.3
	add_host_port ls1p0 0a:00:00:00:01:02 192.168.3.2
}


init_host1() {
	add_host_port ls0p2 0a:00:00:00:00:04 192.168.2.4
	add_host_port ls1p1 0a:00:00:00:01:03 192.168.3.3
}

# prep_north
# prep_host
# prep_logical
# init_host0
# init_host1
"$@"
