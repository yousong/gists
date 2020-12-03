#!/bin/sh

# Ref: https://www.kernel.org/doc/Documentation/networking/bonding.txt

set -o errexit
set -o pipefail

linkshow() {
	echo "MODE: $(</sys/class/net/bondtst/bonding/mode)"
	echo "bondtst: $(</sys/class/net/bondtst/address)"
	echo "    v00: $(</sys/class/net/v00/address)"
	echo "    v10: $(</sys/class/net/v10/address)"
}

setmode() {
	local num="$1"; shift
	local name="$1"; shift

	# otherwise "write error: Directory not empty"
	ip link set v00 nomaster
	ip link set v10 nomaster
	# otherwise "write error: Device or resource busy"
	ip link set bondtst down
	echo "$name" | tee /sys/class/net/bondtst/bonding/mode >/dev/null
	#echo "$num" | tee /sys/class/net/bondtst/bonding/mode >/dev/null
	# link down before set master otherwise will get "operation not permitted"
	ip link set v00 down
	ip link set v10 down
	ip link set v00 master bondtst
	ip link set v10 master bondtst
	ip link set bondtst up
	linkshow
}

down() {
	ip link del bondtst 2>/dev/null || true
	ip link del v00 2>/dev/null || true
	ip link del v10 2>/dev/null || true
	ip netns del ns0 2>/dev/null || true
	ip netns del ns1 2>/dev/null || true
}

up() {
	ip link add bondtst type bond
	ip link add v00 type veth peer name v01
	ip link add v10 type veth peer name v11

	ip netns add ns0
	ip netns add ns1
	ip link set v01 netns ns0
	ip link set v11 netns ns1
	ip netns exec ns0 bash -c '
		ip addr add 10.7.8.10/24 dev v01
		ip link set v01 up
	'
	ip netns exec ns1 bash -c '
		ip addr add 10.7.8.11/24 dev v11
		ip link set v11 up
	'
	ip addr add 10.7.8.1/24 dev bondtst
}

down
up

setmode 0 balance-rr
setmode 1 active-backup
setmode 2 balance-xor
setmode 3 broadcast
setmode 4 802.3ad
setmode 5 balance-tlb
setmode 6 balance-alb

ip netns exec ns1 bash
down
