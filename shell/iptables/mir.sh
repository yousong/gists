#!/bin/bash

mir_ports="${o_mir_ports:-65535,21841}"
mir_ip="${o_mir_ip:-1.1.1.1}"
mir_nets="${o_mir_nets}"

ipset create -! mirnet hash:net
for n in $mir_nets; do
	ipset add -! mirnet "$n"
done

while iptables -t nat -D PREROUTING  -j mirpre  2>/dev/null; do :; done
while iptables -t nat -D POSTROUTING -j mirpost 2>/dev/null; do :; done
iptables -t nat -F mirpre
iptables -t nat -F mirpost
iptables -t nat -X mirpre
iptables -t nat -X mirpost

iptables -t nat -N mirpre
iptables -t nat -A mirpre -m set ! --match-set mirnet src -j RETURN
iptables -t nat -A mirpre -p udp -m multiport --dports "$mir_ports" -j DNAT --to-destination "$mir_ip"
iptables -t nat -A mirpre -p tcp -m multiport --dports "$mir_ports" -j DNAT --to-destination "$mir_ip"
iptables -t nat -A PREROUTING -j mirpre

iptables -t nat -N mirpost
iptables -t nat -A mirpre -m set ! --match-set mirnet src -j RETURN
iptables -t nat -A mirpost -p udp -m multiport --dports "$mir_ports" -j MASQUERADE
iptables -t nat -A mirpost -p tcp -m multiport --dports "$mir_ports" -j MASQUERADE
iptables -t nat -A POSTROUTING -j mirpost
