# The problem

A dlna client requests url from xml document verbatimly without firstly
unquoting entities like `&amp;` etc, thus causing request failures

# The solution

iptables rule for DNAT

	iptables -t nat -A zone_lan_prerouting -p tcp -d d.pcs.baidu.com -j DNAT --to-destination 10.4.240.221:44406
	iptables -t nat -A OUTPUT -p tcp -d d.pcs.baidu.com -j DNAT --to-destination 10.4.240.221:44406

socat command for waiting connections

	socat tcp-listen:44406,fork,reuseaddr exec:$PWD/sed.amp.sh

`sed.amp.sh` for replacing `&amp;` with `&`

	#!/bin/sh
	if [ -z "$STDBUF_ON" ]; then
		export STDBUF_ON=1
		exec stdbuf -i0 -o0 -e0 "$0" "$@"
	fi
	
	sedfilter='/^GET / {
		s/&amp;/\&/g
		w/proc/self/fd/2
	}'
	
	# XXX: sed is not line-buffered causing it read past the request
	# header part
	#
	# NOTE: To work with also IPv6 address, we need to take into account square
	# brackets and colon characters in the host part
	req="$(sed -ur -e '/^\r?$/q')"
	hostport="$(echo "$req" | grep '^[Hh]ost:' | cut -f2 -d: | grep -oE '[^ ]+')"
	if [ "$hostport" = "${hostport%:*}" ]; then
		hostport="$hostport:80"
	fi
	
	# NOTE: the extra echo command is there to complement the newline at the end of
	# var stripped off by shell
	#
	# To force close (flush) then reopen, try the following
	#
	#	exec 9>&1; exec 1>/dev/null; exec 1>&9;
	#
	(echo "$req"; echo; cat ) \
	    | sed -u -e "$sedfilter" \
	    | socat stdio "tcp:$hostport"
