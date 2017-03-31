#!/bin/sh

BASEURL="https://github.com/corbindavenport/nexus-tools/raw/master/bin"
PREFIX="$HOME/.usr"

BINDIR="$PREFIX/bin"

install_bin() {
	local f

	mkdir -p "$PREFIX/bin"
	for f in adb fastboot; do
		wget -O "$f" -c "$BASEURL/mac-$f"
		install -m 0755 "$f" "$BINDIR/$f"
	done
}

"$@"
