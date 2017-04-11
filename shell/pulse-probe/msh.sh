. $PWD/env.sh

remotecmd() {
	local ip="$1"
	local cmd="$2"

	ssh -nT -i "$idrsa" "$user@$ip" "$cmd"
}

copyfile() {
	local ip="$1"
	local local="$2"
	local remote="$3"

	scp -i "$idrsa" "$local" "$user@$ip:$remote"
}

m_mkdir() {
	for ip in $ipsshlist; do
		remotecmd "$ip" "mkdir -p $workdir"
	done
}

m_cp_scr_ping() {
	for ip in $ipsshlist; do
		copyfile "$ip" scr-ping.sh "$workdir"
	done
}

m_cp_scr_trace() {
	for ip in $ipsshlist; do
		copyfile "$ip" scr-trace.sh "$workdir"
	done
}

m_ping() {
	local tip="$1"
	local ip

	for ip in $ipsshlist; do
		remotecmd "$ip" "cd $workdir; ./scr-ping.sh $tip" &
	done
}

m_trace() {
	local tip="$1"
	local ip

	for ip in $ipsshlist; do
		remotecmd "$ip" "cd $workdir; ./scr-trace.sh $tip" &
	done
}

m_reset() {
	local ip

	for ip in $ipsshlist; do
		remotecmd "$ip" "rm -rf $workdir"
	done
	m_mkdir
	m_cp_scr_ping
	m_cp_scr_trace
}

m_get_intip() {
	local ip

	for ip in $iplist; do
		remotecmd "$ip" "ip addr show dev eth0 | grep 'inet ' | grep -o '[0-9.]\\+' | head -n1"
	done
}

m_get() {
	local remote="$1"
	local f="$(basename "$remote")"
	local intip ip
	local i=1

	mkdir -p data
	for ip in $iplist; do
		intip="$(sed -n "${i}p" ip.int.list)"
		i="$(($i + 1))"
		scp -i "$idrsa" "root@$intip:$remote" "data/$ip-$f"
	done
}

_kill() {
	local ip="$1"

	remotecmd "$ip" 'kill `pgrep -f "^/bin/sh ./scr"`'
}

m_kill() {
	for ip in $ipsshlist; do
		_kill "$ip"
	done
}

m_gettime() {
        for ip in $ipsshlist; do
                echo -n "$ip "
                remotecmd "$ip" date
        done
}

m_synctime() {
        for ip in $ipsshlist; do
                echo -n "$ip "
                remotecmd "$ip" 'ntpdate -u 0.europe.pool.ntp.org'
        done
}

trap 'm_kill' "INT"
echo "doing $@"
"$@"
wait
echo "done $@"
#
# ./msh.sh m_reset
#
# ./msh.sh m_mkdir
# ./msh.sh m_cp_scr_ping
# ./msh.sh m_cp_scr_trace
#
# ./msh.sh m_kill
# ./msh.sh m_ping 1.2.3.4
# ./msh.sh m_ping 1.2.3.5
# ./msh.sh m_trace 1.2.3.5
#
