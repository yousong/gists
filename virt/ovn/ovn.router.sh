set -x

logdir=/home/yousong/.usr/var/log/openvswitch
rundir=/home/yousong/.usr/var/run/openvswitch

o_north_nb_ip=10.4.237.52
o_north_nb_port=6641
o_north_sb_ip=10.4.237.52
o_north_sb_port=6642

ovn_nbctl() {
	ovn-nbctl --db="tcp:$o_north_nb_ip:$o_north_nb_port" "$@"
}

ovn_sbctl() {
	ovn-sbctl --db="tcp:$o_north_sb_ip:$o_north_sb_port" "$@"
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

reset() {
	ovn-ctl stop_northd
	ovn-ctl stop_controller
	ovs-ctl stop
}

prep_logical() {
	# logical switch name does not need to be unique
	# logical switch port name needs to be unique: iface-id
	#
	# leaf records not referred to will be pruned automaticlaly
	ovn_nbctl \
		-- --all destroy DHCP_Options \
		-- --all destroy Logical_Switch \
		-- --all destroy Logical_Switch_Port \
		-- --all destroy Logical_Router \
		-- --all destroy Logical_Router_Port \
		-- --all destroy DNS \
		-- --all destroy Logical_Router_Static_Route \
		-- --all destroy NAT \
		-- --all destroy Load_Balancer \
		-- --all destroy ACL \

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

	# logical router only answers arp request for addresses bound on the inport
	# the mac address on router port is required to avoid implicit drop on ls_in_l2_lkup
	ovn_nbctl \
		-- lr-add lr0 \
		-- lrp-add lr0 lr0ls0 0a:00:00:00:00:01 192.168.2.1/24 \
		-- lrp-add lr0 lr0ls1 0a:00:00:00:01:01 192.168.3.1/24 \
		-- lsp-add ls0 ls0lr0 \
		-- lsp-set-type ls0lr0 router \
		-- lsp-set-addresses ls0lr0 0a:00:00:00:00:01 \
		-- lsp-set-options ls0lr0 router-port=lr0ls0 \
		-- lsp-add ls1 ls1lr0 \
		-- lsp-set-type ls1lr0 router \
		-- lsp-set-addresses ls1lr0 0a:00:00:00:01:01 \
		-- lsp-set-options ls1lr0 router-port=lr0ls1 \

	# "name" columne instead of "_uuid"
	# ping 192.168.4.1 will be tunnelled to the gateway chassis
	lg0chassis="$(ovn_sbctl --bare --columns=name find Chassis hostname=titan.office.mos)"
	ovn_nbctl \
		-- create Logical_Router name=lg0 options:chassis="$lg0chassis" \
		-- lrp-add lg0 lg0tp 0a:00:00:00:02:01 192.168.4.1/24 \
		-- ls-add lg0t \
		-- lsp-add lg0t tlg0p \
		-- lsp-set-type tlg0p router \
		-- lsp-set-addresses tlg0p 0a:00:00:00:02:01 \
		-- lsp-set-options tlg0p router-port=lg0tp \
		-- lrp-add lr0 lr0lg0t 0a:00:00:00:02:02 192.168.4.2/24 \
		-- lsp-add lg0t lg0tlr0 \
		-- lsp-set-type lg0tlr0 router \
		-- lsp-set-addresses lg0tlr0 0a:00:00:00:02:02 \
		-- lsp-set-options lg0tlr0 router-port=lr0lg0t \
		-- lr-route-add lr0 0.0.0.0/0 192.168.4.1 \
		-- lr-route-add lg0 192.168.2.0/24 192.168.4.2 \
		-- lr-route-add lg0 192.168.3.0/24 192.168.4.2 \

	# integration bridge and br-data-net will be connected by ovn-controller
	# with patch ports.  Ping from data-net to logical 192.168.5.3 will work
	#
	# why /16 not work
	ovn_nbctl \
		-- lrp-add lg0 lg0lp 0a:00:00:00:03:01 192.168.5.1/24 \
		-- ls-add lg0l \
		-- lsp-add lg0l llg0p \
		-- lsp-set-type llg0p router \
		-- lsp-set-addresses llg0p 0a:00:00:00:03:01 \
		-- lsp-set-options llg0p router-port=lg0lp \
		-- lsp-add lg0l lg0lnetp \
		-- lsp-set-type lg0lnetp localnet \
		-- lsp-set-addresses lg0lnetp unknown \
		-- lsp-set-options lg0lnetp network_name=data-net \

	# default route for gateway router
	ovn_nbctl \
		-- lr-route-add lg0 0.0.0.0/0 192.168.5.2 lg0lp \

	ovn_nbctl \
		-- --id=@nat2 create NAT type=snat logical_ip=192.168.2.0/24 external_ip=192.168.5.1 \
		-- --id=@nat3 create NAT type=snat logical_ip=192.168.3.0/24 external_ip=192.168.5.1 \
		-- add Logical_Router lg0 nat @nat2 \
		-- add Logical_Router lg0 nat @nat3 \

	# lb on ls resides on the client side; real server sees client's real ip
	# lb on lr; lr must be gateway router; real server cannot see client's real ip
	ovn_nbctl \
		-- --id=@lb0 create Load_Balancer name=lb0 vips:192.168.2.5="192.168.2.3,192.168.2.4" \
		-- --id=@lb1 create Load_Balancer name=lb1 vips:192.168.5.3="192.168.2.3,192.168.2.4" \
		-- add Logical_Switch ls1 load_balancer @lb0 \
		-- add Logical_Router lg0 load_balancer @lb1 \

	# allow only (from,to) (ping,http)
	ovn_nbctl \
		-- acl-add ls0 from-lport 1000 "tcp.dst == 80" allow-related \
		-- acl-add ls0   to-lport 1000 "tcp.dst == 80" allow-related \
		-- acl-add ls0 from-lport  999 "icmp4.type == 8 && icmp4.code == 0" allow-related \
		-- acl-add ls0   to-lport  999 "icmp4.type == 8 && icmp4.code == 0" allow-related \
		-- acl-add ls0 from-lport    0 "ip" drop \
		-- acl-add ls0   to-lport    0 "ip" drop \

	# it's port match
	ls0="$(ovn_nbctl --bare --columns=_uuid find Logical_Switch name=ls0)"
	ovn_nbctl \
		-- --id=@dns create DNS \
			records:a.com="1.1.1.1 1.1.1.2" \
			records:b.com="2.2.2.1 2.2.2.2" \
		-- add Logical_Switch "$ls0" dns_records @dns \

	dhcp2=$(get_dhcp_uuid 192.168.2.0/24)
	dhcp3=$(get_dhcp_uuid 192.168.3.0/24)
	add_logical_port ls0 ls0p0 0a:00:00:00:00:02 192.168.2.2 "$dhcp2"
	add_logical_port ls0 ls0p1 0a:00:00:00:00:03 192.168.2.3 "$dhcp2"
	add_logical_port ls0 ls0p2 0a:00:00:00:00:04 192.168.2.4 "$dhcp2"
	add_logical_port ls1 ls1p0 0a:00:00:00:01:02 192.168.3.2 "$dhcp3"
	add_logical_port ls1 ls1p1 0a:00:00:00:01:03 192.168.3.3 "$dhcp3"

	# works on tunnel_egress_iface: inter-chassis
	# interface line rate as the limit: virtio_net has no such feature and will default 100Mbps
	# queue_id will be allocated by northd and set on sb db;  correspond to class minor_id - 1
	# ovs set_queue action will be used to classify traffic: mapped to 0x10000 + queue_id
	ovn_nbctl \
		-- lsp-set-options ls1p0 qos_max_rate=30000000 \
		-- lsp-set-options ls0p0 qos_max_rate=20000000 \

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
	ip link del dev lg0lp0
	ip link add dev lg0lp0 type veth peer name lg0lp1
	ovs-vsctl \
		-- set Open_vSwitch . external_ids:ovn-bridge-mappings=data-net:br-data-net \
		-- --if-exists del-br br-data-net \
		-- --may-exist add-br br-data-net \
		-- --may-exist add-port br-data-net lg0lp1 \

	ip link set br-data-net up
	ip link set lg0lp1 up
	ip addr add 192.168.5.2/24 dev lg0lp0
	ip route add 192.168.2.0/24 via 192.168.5.1 dev lg0lp0
	ip route add 192.168.3.0/24 via 192.168.5.1 dev lg0lp0
	ip link set lg0lp0 up
	while iptables -t nat -D POSTROUTING -o eth0 -s 192.168.5.0/24 -j MASQUERADE; do true; done
	      iptables -t nat -A POSTROUTING -o eth0 -s 192.168.5.0/24 -j MASQUERADE

	add_host_port ls0p2 0a:00:00:00:00:04 192.168.2.4
	add_host_port ls1p1 0a:00:00:00:01:03 192.168.3.3
}

# prep_north
# prep_host
# prep_logical
# init_host0
# init_host1
"$@"
