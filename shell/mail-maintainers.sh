#!/bin/sh

# Make --to xx --cc arguments for git-send-email from output of
# get_maintainer.pl script.
#
#   send_to_maintainer 133-MIPS-UAPI-Fix-unrecognized-opcode-WSBH-DSBH-DSHD-whe.patch
to_maintainers() {
	local f="$1"
	local get_maintainer="./scripts/get_maintainer.pl"
	local raw
	local to cc

	[ -x "$get_maintainer" ] || {
		echo "Cannot find executable $get_maintainer" >&2
		return 1
	}

	raw="$("$get_maintainer" "$f")"
	raw="$(echo "$raw" | cut -f1 -d'(')"
	to="$(echo "$raw" | head -n  1 | sed 's/^\(.*\)\s\+/--to "\1" /' | tr -d '\n')"
	cc="$(echo "$raw" | tail -n +2 | sed 's/^\(.*\)\s\+/--cc "\1" /' | tr -d '\n')"

	echo "$to $cc"
}

to_maintainers "$@"
