#!/usr/bin/env bash
#
# Copyright 2018 (c) Yousong Zhou
#
# This script can be used to debug "no space left on device due to inotify
# "max_user_watches" limit".  It will output processes using inotify methods
# for watching file system activities, along with HOW MANY directories each
# inotify fd watches
#
# A temporary method of working around the said issue above, tune up the limit.
# It's a per-user limit
#
# 	sudo sysctl fs.inotify.max_user_watches=81920
#
# In case you also wonder why "sudo systemctl restart sshd" notifies inotify
# errors, it's from blue systemd-tty-ask-password-agent
#
#	execve("/usr/bin/systemd-tty-ask-password-agent", ["/usr/bin/systemd-tty-ask-passwor"..., "--watch"], [/* 16 vars */]) = 0
#	inotify_init1(O_CLOEXEC)                = 4
#	inotify_add_watch(4, "/run/systemd/ask-password", IN_CLOSE_WRITE|IN_MOVED_TO) = -1 ENOSPC (No space left on device)
#
# Sample output
#
#	[yunion@titan yousong]$ sudo bash a.sh  | column -t
#	systemd          /usr/lib/systemd/systemd          1      /proc/1/fdinfo/10     1
#	systemd          /usr/lib/systemd/systemd          1      /proc/1/fdinfo/14     4
#	systemd          /usr/lib/systemd/systemd          1      /proc/1/fdinfo/20     4
#	systemd-udevd    /usr/lib/systemd/systemd-udevd    689    /proc/689/fdinfo/7    4
#	NetworkManager   /usr/sbin/NetworkManager          914    /proc/914/fdinfo/10   5
#	NetworkManager   /usr/sbin/NetworkManager          914    /proc/914/fdinfo/11   4
#	crond            /usr/sbin/crond                   939    /proc/939/fdinfo/5    3
#	rsyslogd         /usr/sbin/rsyslogd                1212   /proc/1212/fdinfo/3   2
#	kube-controller  /usr/bin/kube-controller-manager  4934   /proc/4934/fdinfo/8   1
#	kubelet          /usr/bin/kubelet                  4955   /proc/4955/fdinfo/12  0
#	kubelet          /usr/bin/kubelet                  4955   /proc/4955/fdinfo/17  1
#	kubelet          /usr/bin/kubelet                  4955   /proc/4955/fdinfo/26  51494
#	journalctl       /usr/bin/journalctl               13151  /proc/13151/fdinfo/3  2
#	sdnagent         /opt/yunion/bin/sdnagent          20558  /proc/20558/fdinfo/7  90
#	systemd-udevd    /usr/lib/systemd/systemd-udevd    46019  /proc/46019/fdinfo/7  4
#	systemd-udevd    /usr/lib/systemd/systemd-udevd    46020  /proc/46020/fdinfo/7  4 
#
# The script is adapted from https://stackoverflow.com/questions/13758877/how-do-i-find-out-what-inotify-watches-have-been-registered/48938640#48938640
#
set -o errexit
set -o pipefail
lsof +c 0 -n -P -u root \
	| awk '/inotify$/ { gsub(/[urw]$/,"",$4); print $1" "$2" "$4 }' \
	| while read name pid fd; do \
		exe="$(readlink -f /proc/$pid/exe || echo n/a)"; \
		fdinfo="/proc/$pid/fdinfo/$fd"
		count="$(grep -c inotify "$fdinfo")"; \
		echo "$name $exe $pid $fdinfo $count"; \
	done
