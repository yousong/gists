#!/bin/sh
#
# Poor man's sshpass.  Taken from comments of
# http://andre.frimberger.de/index.php/linux/reading-ssh-password-from-stdin-the-openssh-5-6p1-compatible-way/
#
# Usage example
#
#   echo 'pass' | ./spas.sh ssh -vvNT -D 7001 -p 22 -o 'UserKnownHostsFile /dev/null' -o 'PubkeyAuthentication no' -o 'StrictHostKeyChecking no' -o 'PreferredAuthentications password'-o "NumberOfPasswordPrompts 1" user@host
#
# - Implementation details can be found in read_passphrase()@readpass.c of openssh source code.
# - The first argument to SSH_ASKPASS will be a prompt string.
#
# Limitations
#
#  - Not suitable for interactive use for lack of controlling terminal
#  - Requires setsid, or similar tools
#
if [ -n "$SSH_ASKPASS_PASSWORD" ]; then
	echo "$SSH_ASKPASS_PASSWORD"
elif [ $# -lt 1 ]; then
	echo "Usage: echo password | $0 <ssh command line options>" >&2
	exit 1
else
	read SSH_ASKPASS_PASSWORD

	export SSH_ASKPASS=$(readlink -f $0)
	export SSH_ASKPASS_PASSWORD

	[ -z "$DISPLAY" ] || export DISPLAY=dummydisplay:0

	# use setsid to detach from current tty by opening a new session.  The
	# problem is that the new session has no controlling terminal which is
	# required by the ssh read_passphrase method
	#
	# setsid is available in util-linux package.
	exec setsid "$@"
	#exec setsid script -c "$*" /dev/null
fi
