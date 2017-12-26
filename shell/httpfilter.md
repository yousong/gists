# The problem

A dlna client requests url from xml document verbatimly without firstly
unquoting entities like `&amp;` etc.  Thus causing request failures

# The solution

iptables rule for DNAT

	iptables -t nat -A zone_lan_prerouting -p tcp -d d.pcs.baidu.com -j DNAT --to-destination 10.4.240.221:44406
	iptables -t nat -A OUTPUT -p tcp -d d.pcs.baidu.com -j DNAT --to-destination 10.4.240.221:44406

socat command for waiting connections

	socat tcp-listen:44406,fork,reuseaddr exec:$PWD/sed.amp.sh

sed.amp.sh for replacing `&amp;` with `&`.  `-u` for unbuffered to buffer less and flush more

	exec sed -u -e '/^GET /s/&amp;/\&/g' \
		| socat stdio tcp:d.pcs.baidu.com:80
