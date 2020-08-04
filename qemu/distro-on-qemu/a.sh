#!/usr/bin/env bash
#
# Copyright 2020 (c) Yousong Zhou
# 

set -o errexit
set -o pipefail

topdir="$(readlink -f "$(dirname "$0")")"

if [ -s "$topdir/config" ]; then
	source "$topdir/config"
fi
# 123 by default
passwd="${passwd:-"v7riKsA/UOR/g"}"
subnet="${subnet:-192.168.121}"
memsize="${memsize:-4G}"
datadisksize="${datadisksize:-2G}"

dnsmasqconf="/etc/dnsmasq.d/distro-on-qemu.conf"
traps=()

settrap_() {
	local n

	n="${#traps[@]}"
	n="$(($n - 1))"
	local f
	if [ "$n" -ge 0 ]; then
		for i in `seq 0 $n`; do
			f="${traps[i]}; $f"
		done
		f="set +e; $f"
	fi
	trap "$f" EXIT
}

pushtrap() {
	traps+=("$*")
	settrap_
}

poptrap() {
	local n

	n="${#traps[@]}"
	n="$(($n - 1))"
	set +e; ${traps[$n]}; set -e
	unset traps[$n]
	settrap_
}

preproot() {
	local peppered="$dir/peppered"
	local rootdir

	if [ -f "$peppered" ]; then
		return
	fi

	qemu-nbd -c /dev/nbd0 "$disk0"
	qemu-nbd -c /dev/nbd1 "$disk1"
	while ! [ -b /dev/nbd0p2 ]; do sleep 0.1; done
	while ! lsblk -r | grep ^nbd1; do sleep 0.1; done
	pushtrap "qemu-nbd -d /dev/nbd0; qemu-nbd -d /dev/nbd1"

	mkfs.ext4 -O '^has_journal' /dev/nbd1
	local UUID TYPE
	eval "$(blkid -o export /dev/nbd1 | grep -E "^(UUID|TYPE)")"

	rootdir="$topdir/m"
	mkdir -p "$rootdir"
	mount /dev/nbd0p2 "$rootdir/"
	pushtrap "umount $rootdir/"

	if ! grep -q "$UUID" "$rootdir/etc/fstab"; then
		sed -i -e '/\s\+\/opt\s\+/d' "$rootdir/etc/fstab"
		echo "UUID=$UUID /opt $TYPE defaults 0 0" >>"$rootdir/etc/fstab"
	fi
	prep_default_cloudinit_disable
	prep_default_user_root
	prep_default_sshd
	prep_default_hostname
	echo 'kernel.randomize_va_space=0' >"$rootdir/etc/sysctl.d/00-aslr.conf"
	cat "$topdir/sources.list" >"$rootdir/etc/apt/sources.list"
	chown 0:0 "$rootdir/etc/apt/sources.list"
	if ! grep -q audit=0 "$rootdir/boot/grub/grub.cfg"; then
		sed -i -r -e 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 audit=0"/' "$rootdir/etc/default/grub"
		sed -i -r -e 's|linux\s+/boot/vmlinuz-.*|\0 audit=0|' "$rootdir/boot/grub/grub.cfg"
	fi

	umount "$topdir/m/"
	poptrap

	qemu-nbd -d /dev/nbd1
	qemu-nbd -d /dev/nbd0
	poptrap

	touch "$peppered"
}

prep_default_cloudinit_disable() {
	[ ! -d "$rootdir/etc/cloud" ] || touch "$rootdir/etc/cloud/cloud-init.disabled"
}

prep_default_user_root() {
	sed -i -e "s#^root:[^:]*:#root:$passwd:#" "$rootdir/etc/shadow"
	sed -i -e "s/^#\?PermitRootLogin.*/PermitRootLogin yes/" "$rootdir/etc/ssh/sshd_config"
	if ! [ -s "$rootdir/root/.ssh/authorized_keys" ]; then
		mkdir -p "$rootdir/root/.ssh"
		cat "$topdir/id_rsa.pub" >"$rootdir/root/.ssh/authorized_keys"
		chown -R 0:0 "$rootdir/root/.ssh"
		chmod -R 0600 "$rootdir/root/.ssh"
	fi
}

prep_default_sshd() {
	[ -f "$rootdir/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -N '' -t rsa -f "$rootdir/etc/ssh/ssh_host_rsa_key"
	[ -f "$rootdir/etc/ssh/ssh_host_ecdsa_key" ] || ssh-keygen -N '' -t ecdsa -f "$rootdir/etc/ssh/ssh_host_ecdsa_key"
	[ -f "$rootdir/etc/ssh/ssh_host_ed25519_key" ] || ssh-keygen -N '' -t ed25519 -f "$rootdir/etc/ssh/ssh_host_ed25519_key"
}

prep_default_hostname() {
	echo "$name" >"$rootdir/etc/hostname"
}

detect_rootfs() {
	local osrelf="$rootdir/etc/os-release"
	local NAME VERSION ID VERSION_ID

	if [ -f "$osrelf" ]; then
		eval "$(grep -E '^(NAME|VERSION|ID|VERSION_ID)=' "$osrelf")"
		echo "detected: $NAME $VERSION"
		distro="$ID"
		distro_version_id="$VERSION_ID"
	fi
}

preproot_centos7() {
	local peppered="$dir/peppered"
	local dev0 dev1
	local pi pb
	local rootdir

	if [ -f "$peppered" ]; then
		return
	fi

	nbd_connect dev1 "$disk1"
	mkfs.ext4 -O '^has_journal' /dev/nbd1
	local UUID TYPE
	eval "$(blkid -o export /dev/nbd1 | grep -E "^(UUID|TYPE)")"
	poptrap

	nbd_connect dev0 "$disk0"
	rootdir="$topdir/m"
	mkdir -p "$rootdir"
	for pi in $(seq 0 15); do
		pb=${dev0}p$pi
		if ! [ -b "$pb" ]; then
			pi=$(( $pi - 1 ))
		fi
	done
	if [ "$pi" -lt 0 ]; the
		false
	fi
	for pi in $(seq $pi -1 0); do
		pb=${dev0}p$pi
		mount "$pb" "$rootdir/"
		pushtrap "umount $rootdir/"
		detect_rootfs
		if [ -n "$distro" -a -n "$distro_version_id" ]; then
			break
		fi
		poptrap
	done

	if ! grep -q "$UUID" "$rootdir/etc/fstab"; then
		sed -i -e '/\s\+\/opt\s\+/d' "$rootdir/etc/fstab"
		echo "UUID=$UUID /opt $TYPE defaults 0 0" >>"$rootdir/etc/fstab"
	fi
	prep_default_cloudinit_disable
	prep_default_user_root
	prep_default_sshd
	prep_default_hostname
	cat "$topdir/Centos-7.repo" >"$rootdir/etc/yum.repos.d/CentOS-Base.repo"
	chown 0:0 "$rootdir/etc/yum.repos.d/CentOS-Base.repo"
	touch "$rootdir/.autorelabel"

	poptrap
	poptrap

	touch "$peppered"
}

run() {
	local qemu="$1"; shift
	"$qemu" \
		-name "$name" \
		-nographic \
		-device virtio-keyboard-pci \
		-device VGA \
		-display vnc="0.0.0.0:$((10000 + $i))" \
		-m "$memsize" \
		-drive "file=$disk0,format=qcow2,if=virtio" \
		-drive "file=$disk1,format=qcow2,if=virtio" \
		-device virtio-net-pci,mac="$mac",netdev=wan \
		-netdev bridge,id=wan,br=br-wan \
		-device virtio-rng-pci \
		"$@"

}

runarm64() {
	run \
		qemu-system-aarch64 \
		-M virt,gic-version=3,graphics=on,firmware=edk2-aarch64-code.fd \
		-accel tcg,thread=multi \
		-cpu cortex-a57 \
		-smp cpus=4 \

}

runamd64() {
	run \
		qemu-system-x86_64 \
		-M pc \
		-accel kvm \
		-cpu host \
		-smp cpus=4 \

}

ensure_mac() {
	if ! [ "$i" -ge 10 -a "$i" -lt 256 ]; then
		echo "arg 0 should be an integer in range [0,255]" >&2
		return 1
	fi
	mac="62:64:00:12:34:$(printf "%02x" "$i")"
}

ensure_dhcp() {
	if ! grep -q "$mac" "$dnsmasqconf"; then
		echo "dhcp-host=$mac,$subnet.$i" >>"$dnsmasqconf"
		systemctl restart dnsmasq
	fi
}

ensure_disk() {
	if ! [ -s "$disk0" ]; then
		qemu-img create -f qcow2 -o backing_file="$(relpath_to "$(dirname "$disk0")" "$basefileabs")" "$disk0"
	fi
	if ! [ -s "$disk1" ]; then
		qemu-img create -f qcow2 -o preallocation=falloc "$disk1" "$datadisksize"
	fi
}

relpath_to() {
	local path0="$1"; shift
	local path1="$1"; shift
	local dir0

	set +x
	if [ -d $path0 ] || ! [ -e "$path0" ]; then
		dir0="$path0"
	else
		dir0="$(dirname "$path0")"
	fi
	local d="$dir0"
	local up
	while true; do
		local p="$path1/"
		if [ "${p#$d/}" != "$p" ]; then
			break
		fi
		if [ "$d" = "/" ]; then
			break
		fi
		d="$(dirname "$d")"
		up="${up:+$up/}.."
	done
	local r="${path1#$d}"
	if [ "${r:0:1}" = / ]; then
		r="${r:1}"
	fi
	echo "${up:+$up/}$r"
	set -x
}

test_relpath_to() {
	relpath_to "/a/b/c" "/a/b"
	relpath_to "/a/b/c" "/a/bb"
	relpath_to "/a/b/c" "/a/c/d"
	relpath_to "/a/b/c" "/c/c/d"
}

openarm64() {
	local baseurl=https://cdimage.debian.org/cdimage/openstack/current
	local basefile="debian-10.4.3-20200610-openstack-arm64.qcow2"
	local basefileabs="$topdir/$basefile"
	local url="$baseurl/$basefile"

	: wget -O "$basefileabs" -c "$url"

	local i="$1"
	local name="arm64n$i"
	local dir="$topdir/$name"
	local disk0="$dir/d0"
	local disk1="$dir/d1"
	local mac


	mkdir -p "$dir"
	ensure_mac
	ensure_disk
	preproot
	ensure_dhcp

	runarm64
}

openamd64() {
	# centos8 rootfs xfs has features not supported by centos 7 xfs module
	local baseurl=https://cloud.centos.org/centos/8-stream/x86_64/images
	local baseurl=http://mirrors.ustc.edu.cn/centos-cloud/centos/8-stream/x86_64/images
	local basefile="CentOS-Stream-GenericCloud-8-20200113.0.x86_64.qcow2"

	local baseurl=http://mirrors.ustc.edu.cn/centos-cloud/centos/7/images
	local basefile="CentOS-7-x86_64-GenericCloud.qcow2.xz"
	local basefile="CentOS-7-x86_64-GenericCloud.qcow2"

	local basefileabs="$topdir/$basefile"
	local url="$baseurl/$basefile"

	: wget -O "$basefileabs" -c "$url"

	local i="$1"
	local name="amd64n$i"
	local dir="$topdir/$name"
	local disk0="$dir/d0"
	local disk1="$dir/d1"
	local mac
	local distro
	local distro_version_id

	mkdir -p "$dir"
	ensure_mac
	ensure_disk
	preproot_centos7
	ensure_dhcp

	runamd64
}

cd "$topdir"

if [ -d "$HOME/.usr/bin" ]; then
	if echo "$PATH" | grep -q "$HOME/.usr/bin"; then
		export PATH="$HOME/.usr/bin:$PATH"
		export PATH="$HOME/.usr/sbin:$PATH"
	fi
fi
if ! ip link show br-wan &>/dev/null; then
	ip link add br-wan type bridge
	ip link set br-wan up
	ip addr add "$subnet.1/24" dev br-wan
	while iptables -t nat -D POSTROUTING -s "$subnet.0/24" -j MASQUERADE; do :; done
	      iptables -t nat -A POSTROUTING -s "$subnet.0/24" -j MASQUERADE;
	echo "interface=br-wan" >"$dnsmasqconf"
	echo "dhcp-range=$subnet.10,$subnet.150,2h" >>"$dnsmasqconf"
	systemctl restart dnsmasq
fi
if ! [ -s "$topdir/id_rsa" ]; then
	ssh-keygen -f "$topdir/id_rsa" -N ''
fi

set -o xtrace
"$@"
