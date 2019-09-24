Generate dnsmasq config snippet to

 - resolve selected domains using desired dns server
 - add the resolved results to desired ipset

The genereated config file will be `/etc/dnsmasq.ipset` by default.  The output dir can be controlled by environment variable `o_confdir`, e.g.

	./do-dns-ipset.sh dns-ipset.txt
	o_confdir=/tmp/dnsmasq.d ./do-dns-ipset.sh dns-ipset.txt

To use the generated config file, add the following line to `/etc/dnsmasq.conf`

	conf-file=/etc/dnsmasq.ipset
