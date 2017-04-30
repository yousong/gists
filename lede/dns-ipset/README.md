Configure /etc/config/dhcp to let domains be resolved by specified servers and
to add the result to specified ipsets

To use it

	./do-dns-ipset.sh dns-ipset.txt

This will generate `/tmp/dnsmasq.d/dnsmasq.ipset` file to be included by the
`--conf-dir` option of dnsmasq.
