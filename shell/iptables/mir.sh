#!/bin/bash

mir_ports="${o_mir_ports:-65535,21841}"
mir_ip="${o_mir_ip:-1.1.1.1}"
mir_nets="${o_mir_nets}"

ipset create -! mirnet hash:net
for n in $mir_nets; do
	ipset add -! mirnet "$n"
done

sysctl -w net.ipv4.ip_forward=1

iptables-save --counters \
	| grep -vE '(mirpre|mirpost)' \
	| iptables-restore --counters

iptables-restore --noflush <<-"EOF"
	*nat
	:mirpre -
	:mirpost -
	-A mirpre -p udp -m multiport --dports 65534,65535,21841 -j DNAT --to-destination 104.238.138.31
	-A mirpre -p tcp -m multiport --dports 65534,65535,21841 -j DNAT --to-destination 104.238.138.31
	-A mirpost -p udp -m multiport --dports 65534,65535,21841 -j MASQUERADE
	-A mirpost -p tcp -m multiport --dports 65534,65535,21841 -j MASQUERADE
	-A PREROUTING -m set --match-set mirnet src -m addrtype ! --src-type LOCAL -j mirpre
	-A POSTROUTING -m set --match-set mirnet src -m addrtype ! --src-type LOCAL -j mirpost
	COMMIT
EOF
