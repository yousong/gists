#!/bin/sh
#
# - two hosts: moon, sun
# - make two linux bridge br0 on each host
# - make 32 pairs of veth interfaces: vNNN-0, vNNN-1
# - connect vNNN-1 to br0
# - make 31 net namespaces: ns{002,032}
# - move v{002,0032}-0 to separate namespace
# - setup ip addresses and route
# - enable net.ipv4.ip_forward
#
#          10.1.1.2 \                             / 10.2.2.2
#             ...    --> moon <-- esp --> sun <--      ...
#         10.1.1.32 /    ^                   ^    \ 10.2.2.32
#                        |                   |
#                        |                   |
#                 10.1.1.1/24            10.2.2.1/24
#
#
N=32


cmd_netup='
sysctl -w net.ipv4.ip_forward=1

ip link add dev br0 type bridge
ip addr add dev br0 $net.1/24
ip link set br0 up
for i in $(seq 2 '$N'); do
    w="$(printf "%03d" $i)"
    w0=$w-0
    w1=$w-1
    ip link add v$w0 type veth peer name v$w-1
    ip link set v$w0 up
    ip link set v$w0 master br0
    ip netns add ns$w
    ip link set v$w1 netns ns$w
    ip netns exec ns$w ip addr add dev v$w1 $net.$i/24
    ip netns exec ns$w ip link set v$w1 up
    ip netns exec ns$w ip route add default dev v$w1
done
'
cmd_netdown='
ip link del br0
for i in $(seq 2 '$N'); do
    w="$(printf "%03d" $i)"
    w0=$w-0
    w1=$w-1
    ip link del v$w0
    ip netns del ns$w
done
'


cmd_netup_moon="
net=10.1.1
$cmd_netup
"
cmd_netup_sun="
net=10.2.2
$cmd_netup
"


cmd_netdown_moon="
net=10.1.1
$cmd_netdown
"
cmd_netdown_sun="
net=10.2.2
$cmd_netdown
"


_cmd() {
	local host="$1"; shift

    ssh "root@$host" "
$*
"
}

netup() {
    _cmd moon "$cmd_netup_moon"
    _cmd sun  "$cmd_netup_sun"
}

netdown() {
    _cmd moon "$cmd_netdown_moon"
    _cmd sun  "$cmd_netdown_sun"
}

"$@"
