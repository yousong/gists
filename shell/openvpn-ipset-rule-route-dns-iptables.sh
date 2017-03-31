#
# Copyright 2017 (c) Yousong Zhou
#
# A memo for steps to
#
# 1. add dns resolve result to ipset
# 2. mark packets with src/dst being in that ipset
# 3. route marked packets through selected network interface
#
cat >$HOME/.usr/etc/dnsmasq.conf <<-EOF
	no-resolv
	server=172.26.0.253
	server=172.26.0.252
	interface=br-wan
	interface=lo
	dhcp-range=192.168.7.50,192.168.7.150,255.255.255.0,30m
	ipset=/amazonaws.com/setblocked
	ipset=/android.clients.google.com/setblocked
	ipset=/appspot.com/setblocked
	ipset=/awsstatic.com/setblocked
	ipset=/blogger.com/setblocked
	ipset=/blogspot.com/setblocked
	ipset=/blogspot.sg/setblocked
	ipset=/cloudfront.net/setblocked
	ipset=/duolingo.com/setblocked
	ipset=/ggpht.com/setblocked
	ipset=/golang.org/setblocked
	ipset=/googleapis.com/setblocked
	ipset=/google.com.hk/setblocked
	ipset=/google.com/setblocked
	ipset=/google.com.sg/setblocked
	ipset=/google.co.uk/setblocked
	ipset=/google.sg/setblocked
	ipset=/googlesource.com/setblocked
	ipset=/googleusercontent.com/setblocked
	ipset=/goo.gl/setblocked
	ipset=/gstatic.com/setblocked
	ipset=/linuxjournal.com/setblocked
	ipset=/openvpn.net/setblocked
	ipset=/pastebin.com/setblocked
	ipset=/pastie.org/setblocked
	ipset=/psiphon.ca/setblocked
	ipset=/slideshare.net/setblocked
	ipset=/sourceforge.net/setblocked
	ipset=/sprunge.us/setblocked
	ipset=/torproject.org/setblocked
	ipset=/wikipedia.org/setblocked
	server=/amazonaws.com/8.8.8.8
	server=/android.clients.google.com/8.8.8.8
	server=/appspot.com/8.8.8.8
	server=/awsstatic.com/8.8.8.8
	server=/blogger.com/8.8.8.8
	server=/blogspot.com/8.8.8.8
	server=/blogspot.sg/8.8.8.8
	server=/cloudfront.net/8.8.8.8
	server=/duolingo.com/8.8.8.8
	server=/ggpht.com/8.8.8.8
	server=/golang.org/8.8.8.8
	server=/goo.gl/8.8.8.8
	server=/googleapis.com/8.8.8.8
	server=/google.com/8.8.8.8
	server=/google.com.hk/8.8.8.8
	server=/google.com.sg/8.8.8.8
	server=/google.co.uk/8.8.8.8
	server=/google.sg/8.8.8.8
	server=/googlesource.com/8.8.8.8
	server=/googleusercontent.com/8.8.8.8
	server=/gstatic.com/8.8.8.8
	server=/linuxjournal.com/8.8.8.8
	server=/openvpn.net/8.8.8.8
	server=/pastebin.com/8.8.8.8
	server=/pastie.org/8.8.8.8
	server=/psiphon.ca/8.8.8.8
	server=/slideshare.net/8.8.8.8
	server=/sourceforge.net/8.8.8.8
	server=/sprunge.us/8.8.8.8
	server=/torproject.org/8.8.8.8
	server=/wikipedia.org/8.8.8.8
EOF

sudo `which dnsmasq` --no-daemon --no-resolv \
	--conf-file=$HOME/.usr/etc/dnsmasq.conf
	--dhcp-leasefile=$HOME/.usr/var/run/dnsmasq.leases

sudo "$HOME/.usr/sbin/openvpn" --config "$HOME/.usr.env/openvpn/titan.conf"

sudo ipset create setblocked
sudo ip rule add fwmark 2 lookup 2
sudo ip route flush 2
sudo ip route add default dev tun0 table 2

# better make these rules persistent
#
# Debian 7:
#
#	vi /etc/iptables/rules.v4
#	sudo service iptables-persistent restart
#
sudo iptables-restore --noflush <<-EOF
	*mangle
	-A OUTPUT -m set --match-set setblocked dst -j MARK --set-xmark 0x2/0xffffffff
	COMMIT
	*nat
	-A POSTROUTING -o eth1 -j MASQUERADE
	-A POSTROUTING -o tun0 -j MASQUERADE
	COMMIT
EOF
