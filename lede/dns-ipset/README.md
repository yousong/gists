Configure /etc/config/dhcp to let domains be resolved by specified servers and
to add the result to specified ipsets

To use it

	./do-dns-ipset.sh dns-ipset.txt

This will reset `dns_ipset` section of `/etc/config/dhcp` according to content
of file `dns-ipset.txt`
