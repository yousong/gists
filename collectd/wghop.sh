#!/bin/sh
hopchan=/tmp/wghop

prep() {
	if [ ! -p "$hopchan" ]; then
		rm -f "$hopchan"
		mkfifo "$hopchan"
		chmod a+w "$hopchan"
	fi
}

rand() {
	hexdump -n 2 -e '1/2 "%u\n"' /dev/urandom
}

hop() {
	while ! wg set wg0 listen-port $((20000+($(rand)%(65536-20000)))); do :; done
}

serv() {
	local x
	while true; do
		read x <"$hopchan"
		[ -n "$x" ] && hop
	done
}

notify() {
	echo -n hop >"$hopchan"
}

prep
[ -n "$serv" ] && serv || notify
