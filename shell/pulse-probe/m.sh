. $PWD/env.sh

#
# Fetch from $iplist ping results of $pingips.  The file will be available
# as $sip-ping-$ip.txt
#
fetch() {
	local ip

	for ip in $pingips; do
		./msh.sh m_get "$workdir/ping-$ip.txt"
	done
	#./msh.sh m_get "$workdir/tracepath-1.2.3.4.txt"
}

#
# Preprocessing lines in ping result from
#
#	1463118053 64 bytes from 4.3.2.1: icmp_seq=1 ttl=253 time=1.11 ms
#
# to
#
#	1463118053 1.11
#
fmt_ping() {
	local tip="$1"
	local fin fout

	for ip in $iplist; do
		fin="data/$ip-ping-$tip.txt"
		fout="data/$ip-ping-$tip.out"
		sed -n -e 's/^\([0-9]\{10,\}\).*time=\([0-9.]\+\) ms$/\1 \2/p' "$fin" | sort -n -u -k1 >"$fout"
	done
}

fmt() {
	local ip

	for ip in $pingips; do
		fmt_ping "$ip"
	done
}

fetch_fmt() {
	fetch
	fmt
}

plot_ping() {
	gnuplot ping.gnuplot
}

cmds() {
	local ip

	for ip in $pingips; do
		echo ./msh.sh m_ping $ip
	done
	echo ./msh.sh m_trace 1.2.3.4
}

"$@"
