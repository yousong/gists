#!/usr/bin/env bash
#
# Copyright 2020 (c) Yousong Zhou
# 

set -o errexit
set -o pipefail

topdir="$(readlink -f "$(dirname "$0")")"
script="$(readlink -f "$0")"
prog="$(basename "$0")"

if [ -s "$topdir/config" ]; then
	source "$topdir/config"
fi
# 123 by default
passwd="${passwd:-"v7riKsA/UOR/g"}"
subnet="${subnet:-192.168.121}"
ncpu="${ncpu:-4}"
memsize="${memsize:-4G}"
rootdisksize="${rootdisksize:+$rootdisksize}"
datadisksize="${datadisksize:-2G}"

dnsmasqconf="/etc/dnsmasq.d/distro-on-qemu.conf"
traps=()

settrap_() {
	local i
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

findone() {
	local v
	find "$@" | while read v; do
		echo "$v"
		cat >/dev/null
	done
}

swap16() {
	local dstvar="$1"; shift
	local v="$1"; shift

	eval "$dstvar=${v#??}${v%??}"
}

swap32() {
	local dstvar="$1"; shift
	local v="$1"; shift
	local v0 v1

	swap16 v0 "${v#????}"
	swap16 v1 "${v%????}"
	eval "$dstvar=${v0}${v1}"
}

parse_elf() {
	local dstarch="$1"; shift
	local dstarch_endian="$1"; shift
	local elf="$1"; shift

	if [ -e "$elf" ]; then
		local sig endian arch
		sig="$(hexdump -v -s 0 -n 4 -e '4/1 "%02x" "\n"' "$elf")"
		[ "$sig" = "7f454c46" ]
		endian="$(hexdump -v -s 5 -n 1 -e '1/1 "%d\n"' "$elf")"
		arch="$(hexdump -v -s 18 -n 2 -e '2/1 "%02x" "\n"' "$elf")"
		case "$endian" in
			1) eval "$dstarch_endian=le"; swap16 arch "$arch" ;;
			2) eval "$dstarch_endian=be" ;;
			*) false ;;
		esac
		case "$arch" in
			003e) eval "$dstarch=x86_64" ;;
			00b7) eval "$dstarch=aarch64" ;;
			*) false ;;
		esac
	fi
}

nbd_connect() {
	local dstvar="$1"; shift
	local i dev

	for i in $(seq 0 15); do
		dev="/dev/nbd$i"
		if ! [ -b "$dev" ]; then
			continue
		fi
		if qemu-nbd -c "$dev" "$@" &>/dev/null; then
			pushtrap "qemu-nbd -d $dev"
			while ! lsblk --output name --raw --noheadings | grep -q "^nbd$i\$"; do sleep 0.3; done
			sleep 0.3
			eval "$dstvar=$dev"
			return
		fi
	done
	false
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


prep_default_cloudinit_disable() {
	if [ "$distro" = centos -a "$distro_version_id" -le 6 ]; then
		if [ -f "$rootdir/etc/cloud/cloud.cfg" ]; then
			mv "$rootdir/etc/cloud/cloud.cfg" "$rootdir/etc/cloud/cloud.cfg.disabled"
		fi
	fi
	[ ! -d "$rootdir/etc/cloud" ] || touch "$rootdir/etc/cloud/cloud-init.disabled"
}

prep_default_user_root() {
	if [ "$distro" = centos -a "$distro_version_id" -le 6 ]; then
		if [ -f "$rootdir/root/firstrun" ]; then
			rm -v "$rootdir/root/firstrun"
		fi
	fi
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
	if [ "$distro" = centos -a "$distro_version_id" -le 6 ]; then
		if [ -f "$rootdir/etc/sysconfig/network" ]; then
			sed -i -e "s/^HOSTNAME=.*/HOSTNAME=$name/" "$rootdir/etc/sysconfig/network"
		fi
		return
	fi
	echo "$name" >"$rootdir/etc/hostname"
}

prep_default_fstab() {
	if ! grep -q "$UUID" "$rootdir/etc/fstab"; then
		sed -i -e '/\s\+\/opt\s\+/d' "$rootdir/etc/fstab"
		echo "UUID=$UUID /opt $TYPE defaults 0 0" >>"$rootdir/etc/fstab"
	fi
}

prep_default_debian_sourceslist() {
	[ -n "$distro_version_codename" ]
	cat >"$rootdir/etc/apt/sources.list" <<-EOF
	deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $distro_version_codename main contrib non-free
	deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $distro_version_codename-updates main contrib non-free
	deb https://mirrors.tuna.tsinghua.edu.cn/debian/ $distro_version_codename-backports main contrib non-free
	deb https://mirrors.tuna.tsinghua.edu.cn/debian-security $distro_version_codename/updates main contrib non-free
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $distro_version_codename main contrib non-free
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $distro_version_codename-updates main contrib non-free
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ $distro_version_codename-backports main contrib non-free
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security $distro_version_codename/updates main contrib non-free
	EOF
	chown 0:0 "$rootdir/etc/apt/sources.list"
}
prep_default_ubuntu_sourceslist() {
	[ -n "$distro_version_codename" ]
	cat >"$rootdir/etc/apt/sources.list" <<-EOF
	deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename main restricted universe multiverse
	deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-updates main restricted universe multiverse
	deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-backports main restricted universe multiverse
	deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-security main restricted universe multiverse
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename main restricted universe multiverse
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-updates main restricted universe multiverse
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-backports main restricted universe multiverse
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-security main restricted universe multiverse

	# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-proposed main restricted universe multiverse
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $distro_version_codename-proposed main restricted universe multiverse
	EOF
	chown 0:0 "$rootdir/etc/apt/sources.list"
}

prep_default_centos_yumrepo() {
	[ -n "$distro_version_id" ]
	sed -e "s/distro_version_id/$distro_version_id/" <<-"EOF" >"$rootdir/etc/yum.repos.d/CentOS-Base.repo"
	# CentOS-Base.repo
	#
	# The mirror system uses the connecting IP address of the client and the
	# update status of each mirror to pick mirrors that are updated to and
	# geographically close to the client.  You should use this for CentOS updates
	# unless you are manually picking other mirrors.
	#
	# If the mirrorlist= does not work for you, as a fall back you can try the 
	# remarked out baseurl= line instead.
	#
	#
	 
	[base]
	name=CentOS-$releasever - Base - mirrors.aliyun.com
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
		http://mirrors.aliyuncs.com/centos/$releasever/os/$basearch/
		http://mirrors.cloud.aliyuncs.com/centos/$releasever/os/$basearch/
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-distro_version_id
	 
	#released updates 
	[updates]
	name=CentOS-$releasever - Updates - mirrors.aliyun.com
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
		http://mirrors.aliyuncs.com/centos/$releasever/updates/$basearch/
		http://mirrors.cloud.aliyuncs.com/centos/$releasever/updates/$basearch/
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-distro_version_id
	 
	#additional packages that may be useful
	[extras]
	name=CentOS-$releasever - Extras - mirrors.aliyun.com
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
		http://mirrors.aliyuncs.com/centos/$releasever/extras/$basearch/
		http://mirrors.cloud.aliyuncs.com/centos/$releasever/extras/$basearch/
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-distro_version_id
	 
	#additional packages that extend functionality of existing packages
	[centosplus]
	name=CentOS-$releasever - Plus - mirrors.aliyun.com
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/centos/$releasever/centosplus/$basearch/
		http://mirrors.aliyuncs.com/centos/$releasever/centosplus/$basearch/
		http://mirrors.cloud.aliyuncs.com/centos/$releasever/centosplus/$basearch/
	gpgcheck=1
	enabled=0
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-distro_version_id
	 
	#contrib - packages by Centos Users
	[contrib]
	name=CentOS-$releasever - Contrib - mirrors.aliyun.com
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/centos/$releasever/contrib/$basearch/
		http://mirrors.aliyuncs.com/centos/$releasever/contrib/$basearch/
		http://mirrors.cloud.aliyuncs.com/centos/$releasever/contrib/$basearch/
	gpgcheck=1
	enabled=0
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-distro_version_id
	EOF
	chown 0:0 "$rootdir/etc/yum.repos.d/CentOS-Base.repo"
}

prep_default_fedora_yumrepo() {
	cat >"$rootdir/etc/yum.repos.d/fedora.repo" <<-"EOF"
	[fedora]
	name=Fedora $releasever - $basearch - aliyun
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/fedora/releases/$releasever/Everything/$basearch/os/
	enabled=1
	metadata_expire=7d
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$basearch
	
	[fedora-debuginfo]
	name=Fedora $releasever - $basearch - Debug - aliyun
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/fedora/releases/$releasever/Everything/$basearch/debug/
	enabled=0
	metadata_expire=7d
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$basearch
	
	[fedora-source]
	name=Fedora $releasever - Source - aliyun
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/fedora/releases/$releasever/Everything/source/SRPMS/
	enabled=0
	metadata_expire=7d
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$basearch
	EOF
	cat >"$rootdir/etc/yum.repos.d/fedora-updates.repo" <<-"EOF"
	[updates]
	name=Fedora $releasever - $basearch - Updates - aliyun
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/fedora/updates/$releasever/Everything/$basearch/
	enabled=1
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$basearch
	
	[updates-debuginfo]
	name=Fedora $releasever - $basearch - Updates - Debug -aliyun
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/fedora/updates/$releasever/Everything/$basearch/debug/
	enabled=0
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$basearch
	
	[updates-source]
	name=Fedora $releasever - Updates Source - aliyun
	failovermethod=priority
	baseurl=http://mirrors.aliyun.com/fedora/updates/$releasever/Everything/SRPMS/
	enabled=0
	gpgcheck=1
	gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$basearch
	EOF
	chown 0:0 "$rootdir/etc/yum.repos.d/fedora.repo"
	chown 0:0 "$rootdir/etc/yum.repos.d/fedora-updates.repo"
}

prep_default_suse_zypprepo() {
	[ -n "$distro_version_id" ]
	cat >"$rootdir/etc/zypp/repos.d/zypp.repo" <<-EOF
	[update-oss]
	enabled=1
	autorefresh=1
	baseurl=http://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$distro_version_id/oss
	type=NONE

	[update-non-oss]
	enabled=1
	autorefresh=1
	baseurl=http://mirrors.tuna.tsinghua.edu.cn/opensuse/update/leap/$distro_version_id/non-oss
	type=NONE

	[dist-oss]
	enabled=1
	autorefresh=1
	baseurl=http://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$distro_version_id/repo/oss
	type=NONE

	[dist-non-oss]
	enabled=1
	autorefresh=1
	baseurl=http://mirrors.tuna.tsinghua.edu.cn/opensuse/distribution/leap/$distro_version_id/repo/non-oss
	type=NONE
	EOF
	chown 0:0 "$rootdir/etc/zypp/repos.d/zypp.repo"
}

mkds_nocloud() {
	local ncdisk="$dir/nocloud.raw"
	local ncdir="$dir/nocloud"

	dd if=/dev/zero of="$ncdisk" bs=1M count=2
	mkfs.fat -n cidata "$ncdisk"

	mkdir -p "$ncdir"
	mount "$ncdisk" "$ncdir"
	pushtrap "rmdir $ncdir"
	pushtrap "umount $ncdir"

	cat >"$ncdir/meta-data" <<-EOF
	{
		"instance-id": "$(uuidgen)",
		"name": "$name",
		"hostname": "$name",
		"public-keys": "$(cat $topdir/id_rsa.pub)"
	}
	EOF

	if [ "$distro" = cirros ]; then
		cat >"$ncdir/user-data" <<-EOF
		#!/bin/sh
		dev="\$(blkid -l -t UUID=$UUID -o device)"
		if [ -b "\$dev" ]; then
			echo "\$dev /opt $TYPE defaults 0 0" >>/etc/fstab
			mount /opt
		fi
		EOF
	fi

	poptrap
	poptrap
}

mkds_configdrive() {
	local ncdisk="$dir/configdrive.raw"
	local ncdir="$dir/configdrive"

	dd if=/dev/zero of="$ncdisk" bs=1M count=2
	mkfs.fat -n config-2 "$ncdisk"

	mkdir -p "$ncdir"
	mount "$ncdisk" "$ncdir"
	pushtrap "rmdir $ncdir"
	pushtrap "umount $ncdir"

	mkdir -p "$ncdir/openstack/latest"
	cat >"$ncdir/openstack/latest/meta_data.json" <<-EOF
	{
		"uuid": "$(uuidgen)",
		"name": "$name",
		"hostname": "$name",
		"public_keys": {
			"sysadmin": "$(cat $topdir/id_rsa.pub)"
		}
	}
	EOF

	poptrap
	poptrap
}

detect_rootfs() {
	local osrelf="$rootdir/etc/os-release"
	local NAME VERSION ID VERSION_ID VERSION_CODENAME

	if [ -f "$osrelf" ]; then
		eval "$(grep -E '^(NAME|VERSION|ID|VERSION_ID|VERSION_CODENAME)=' "$osrelf")"
		echo "detected: $NAME $VERSION"
		distro="$ID"
		distro_version_id="$VERSION_ID"
		distro_version_codename="$VERSION_CODENAME"
		return
	fi

	local cpef="$rootdir/etc/system-release-cpe"
	if [ -f "$cpef" ]; then
		local cpe="$(< "$cpef")"
		echo "cpe: $cpe"
		if [ "$(echo "$cpe" | cut -d/ -f1 )" = cpe: ]; then
			local hwpart ifs

			hwpart="$(echo "$cpe" | cut -d/ -f2)"
			ifs=$IFS; IFS=:; set -- $hwpart; IFS=$ifs
			if [ "$1" = o ]; then
				if [ "$3" = linux ]; then
					distro="$2"
				else
					distro="$3"
				fi
				distro_version_id="$4"
				return
			fi
		fi
	fi

	local menulst
	menulst="$(findone "$rootdir" -maxdepth 3 -type f -iname menu.lst -type f)"
	if [ -s "$menulst" ]; then
		if grep -m1 -q " LABEL=cirros-rootfs" "$menulst"; then
			distro="cirros"
			local initrd
			initrd="$(findone "$rootdir" -maxdepth 1 -name initrd.img)"
			distro_version_id="$(gunzip -c "$initrd" | cpio --to-stdout --quiet -i etc/cirros/version)"
			return
		fi
	fi
}

detect_rootfs_iso() {
	if [ -s "$rootdir/esx_ui.v00" ]; then
		distro="esx"
		if [ -s "$rootdir/efi/boot/boot.cfg" ]; then
			distro_version_id="$(grep -m1 "^build=" "$rootdir/efi/boot/boot.cfg" | cut -d= -f2 | cut -d. -f1)"
		fi
		update_config "distro" "$distro"
		update_config "distro_version_id" "$distro_version_id"
		return
	fi

	if [ -d "$rootdir/CentOS" ]; then
		distro=centos
		if [ "$(find "$rootdir/CentOS" -name "*.i386.rpm" | head -n 8 | wc -l)" = 8 ]; then
			distro_arch=i386
		fi
		update_config "distro" "$distro"
		update_config "distro_arch" "$distro_arch"
		return
	fi

	if [ -d "$rootdir/reactos" ]; then
		distro=reactos
		update_config "distro" "$distro"
		if [ -s "$rootdir/reactos/reactos.exe" ]; then
			if detect_set_distro_arch_pe "$rootdir/reactos/reactos.exe"; then
				return
			fi
		fi
	fi

	detect_rootfs
}

growpart() {
	local dev="$1"; shift
	local pi="$1"; shift
	local pb=${dev0}p$pi
	local PTTYPE

	eval "$(blkid -o export -p "$dev" | grep '^PTTYPE')"
	case "$PTTYPE" in
		gpt)
			local pinfo pcode pname
			pinfo="$(sgdisk --info="$pi" "$dev")"
			pcode="$(echo "$pinfo" | grep -oE '^Partition GUID code: [^ ]+' | cut -d: -f2 | tr -d ' ')"
			pname="$(echo "$pinfo" | grep -oE '^Partition name: '           | cut -d: -f2 | tr -d ' ')"
			if [ -z "$pcode" ]; then
				false
			fi
			if [ "$pname" = "''" ]; then
				pname=''
			fi
			sgdisk \
				--move-second-header \
				--delete="$pi" \
				--new="$pi:0:0" \
				${pcode:+--typecode="$pi:$pcode"} \
				${pname:+--change-name="$pi:$pname"} \
				"$dev"
			;;
		dos)
			local pid pboot
			pid="$(sfdisk --print-id "$dev" "$pi")"
			pboot="$(fdisk -l "$dev" | grep "^$pb[ ]" | grep -m1 -oF '*')"
			sfdisk \
				--force \
				-N "$pi" \
				"$dev" <<-EOF
			,+,$pid,$pboot
			EOF
			;;
		*)
			false
			;;
	esac

	local TYPE
	eval "$(blkid -o export "$pb" | grep '^TYPE')"
	case "$TYPE" in
		ext*)
			e2fsck -f "$pb"
			resize2fs "$pb"
			;;
		xfs)
			mount "$pb" "$rootdir"
			pushtrap "umount $rootdir"
			xfs_growfs "$rootdir"
			poptrap
			;;
		*)
			false
			;;
	esac
}

update_config() {
	local name="$1"; shift
	local value="$1"; shift

	if [ -s "$dir/00-config-init" ]; then
		sed -i -e "/^$name=/d" "$dir/00-config-init"
	fi
	echo "$name=$value" >>"$dir/00-config-init"
}

detect_set_distro_arch_elf() {
	local f="$1"; shift

	parse_elf distro_arch distro_arch_endian "$f"
	if [ -n "$distro_arch" -a -n "$distro_arch_endian" ]; then
		update_config "distro_arch" "$distro_arch"
		update_config "distro_arch_endian" "$distro_arch_endian"
		return 0
	fi
	return 1
}

detect_set_distro_arch_pe() {
	local pe="$1"; shift
	local sig off mach

	sig="$(hexdump -v -s 0 -n 2 -e '2/1 "%02x" "\n"' "$pe")"
	[ "$sig" = 4d5a ] || return 1

	off="$(hexdump -v -s 60 -n 4 -e '4/1 "%02x" "\n"' "$pe")"
	swap32 off "$off"
	sig="$(hexdump -v -s "$((0x$off))" -n 4 -e '4/1 "%02x" "\n"' "$pe")"
	[ "$sig" = 50450000 ] || return 1

	mach="$(hexdump -v -s "$((0x$off + 4))" -n 2 -e '2/1 "%02x" "\n"' "$pe")"
	swap16 mach "$mach"
	case "$mach" in
		8664) distro_arch_endian=le; distro_arch=x86_64 ;;
		014c) distro_arch_endian=le; distro_arch=i386 ;;
		aa64) distro_arch_endian=  ; distro_arch=aarch64 ;;
		*) return 1 ;;
	esac
	update_config "distro_arch" "$distro_arch"
	update_config "distro_arch_endian" "$distro_arch_endian"
	return 0
}

detect_distro_arch() {
	if detect_set_distro_arch_elf "$rootdir/bin/sh"; then
		return
	fi

	local efidir
	local pe
	efidir="$(findone "$rootdir" -maxdepth 1 -type d -iname efi)"
	if [ -d "$efidir" ]; then
		pe="$(findone "$efidir" -type f -iname "*.efi")"
	fi
	if [ -z "$pe" ]; then
		pe="$(findone "$rootdir" -maxdepth 2 -iname "*.exe")"
	fi
	if [ -s "$pe" ]; then
		if detect_set_distro_arch_pe "$pe"; then
			return
		fi
	fi

	local grubmoddir
	grubmoddir="$(findone "$rootdir" -maxdepth 2 -type d -iname grub)"
	if [ -n "$grubmoddir" ]; then
		local mod
		mod="$(findone "$grubmoddir" -maxdepth 2 -type f -iname '*.mod')"
		if detect_set_distro_arch_elf "$mod"; then
			return
		fi
	fi
}

preproot() {
	local peppered="$dir/peppered"
	local dev0 dev1
	local pi pb
	local rootdir

	if [ -f "$peppered" ]; then
		return
	fi

	nbd_connect dev0 "$disk0"
	rootdir="$topdir/m"
	mkdir -p "$rootdir"
	for pi in $(seq 16 -1 1); do
		pb=${dev0}p$pi
		if mount "$pb" "$rootdir/"; then
			pushtrap "umount $rootdir/"
			detect_rootfs
			detect_distro_arch
			poptrap
			if [ -n "$distro" -a -n "$distro_version_id" -a -n "$distro_arch" ]; then
				break
			fi
		fi
	done

	if ! [ -n "$distro" -a -n "$distro_version_id" ]; then
		poptrap
		touch "$peppered"
		return
	fi
	update_config distro "$distro"

	nbd_connect dev1 "$disk1"
	local features
	if [ "$distro" = centos -a "$distro_version_id" -le 6 ]; then
		features="${features:+$features,}^metadata_csum,uninit_bg"
	fi
	mkfs.ext4 -vv -F -E 'lazy_itable_init=1,lazy_journal_init=1' -O "$features" "$dev1"
	local UUID TYPE
	eval "$(blkid -o export "$dev1" | grep -E "^(UUID|TYPE)")"
	poptrap

	case "$distro" in
		clear-linux-os)
			mkds_configdrive

			poptrap
			touch "$peppered"
			return
			;;
		cirros)
			mkds_nocloud

			poptrap
			touch "$peppered"
			return
			;;
	esac

	if [ -n "$rootdisksize" ]; then
		growpart "$dev0" "$pi"
	fi

	mount "$pb" "$rootdir/"
	pushtrap "umount $rootdir/"

	prep_default_fstab
	prep_default_cloudinit_disable
	prep_default_user_root
	prep_default_sshd
	prep_default_hostname
	case "$distro" in
		debian|\
		ubuntu)
			case "$distro" in
				debian) prep_default_debian_sourceslist ;;
				ubuntu) prep_default_ubuntu_sourceslist ;;
				*) false ;;
			esac
			echo 'kernel.randomize_va_space=0' >"$rootdir/etc/sysctl.d/00-aslr.conf"
			if ! grep -q audit=0 "$rootdir/boot/grub/grub.cfg"; then
				sed -i -r -e 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 audit=0"/' "$rootdir/etc/default/grub"
				sed -i -r -e 's|linux\s+/boot/vmlinuz-.*|\0 audit=0|' "$rootdir/boot/grub/grub.cfg"
			fi
			if [ -d "$rootdir/etc/netplan" ]; then
				cat >"$rootdir/etc/netplan/00-networkd.yaml" <<-EOF
				network:
				  version: 2
				  renderer: networkd
				  ethernets:
				    id0:
				      match:
				        macaddress: $mac
				      dhcp4: true
				EOF
			fi
			;;
		centos)
			prep_default_centos_yumrepo
			touch "$rootdir/.autorelabel"
			;;
		fedora)
			prep_default_fedora_yumrepo
			touch "$rootdir/.autorelabel"
			;;
		sles)
			prep_default_suse_zypprepo
			cat >"$rootdir/etc/sysconfig/network/ifcfg-eth0" <<-EOF
			STARTMODE=auto
			BOOTPROTO=dhcp
			EOF
			chown 0:0 "$rootdir/etc/sysconfig/network/ifcfg-eth0"
			;;
		*)
			echo "unknown distro $distro" >&2
			bash -c "cd $rootdir; bash; exit 0"
			false
			;;
	esac

	poptrap
	poptrap

	touch "$peppered"
}

prepiso() {
	local peppered="$dir/prepiso"
	local rootdir

	if [ -f "$peppered" ]; then
		return
	fi

	rootdir="$topdir/m"
	mkdir -p "$rootdir"
	mount "$basefileabs" "$rootdir"
	pushtrap "umount $rootdir/"

	detect_rootfs_iso
	detect_distro_arch

	poptrap

	touch "$peppered"
}

the_arch() {
	local out="$1"; shift
	local in="$1"; shift

	case "$in" in
		x86_64|amd64)
			eval "$out=x86_64" ;;
		aarch64|arm64)
			eval "$out=aarch64" ;;
		*)
			false
	esac
}

run() {
	local qemu="$1"; shift
	local hostarch hostarch_endian
	local accel
	local cpu
	local drives=()
	local boot
	local vhost=on
	local netdev
	local use_ide
	local driveif=virtio
	local cidrive

	parse_elf hostarch hostarch_endian /bin/bash
	if [ "$hostarch" = "$distro_arch" ] || [ "$hostarch" = x86_64 -a "$distro_arch" = i386 ]; then
		accel=(-accel kvm)
		cpu=(-cpu host)
	else
		accel=(-accel tcg,thread=multi)
		case "$distro_arch" in
			aarch64) cpu=(-cpu cortex-a57) ;;
			*) cpu=(-cpu max) ;;
		esac
		vhost=off
	fi

	[ "$distro" != esx ] || use_ide=1
	[ "$distro_arch" != i386 ] || use_ide=1
	case "${basefileabs##*.}" in
		iso)
			if [ "$use_ide" = 1 ]; then
				drives+=(
					-drive file="$basefileabs,media=cdrom,if=none,id=ide0-cd0"
					-device ide-cd,drive=ide0-cd0
				)
			else
				drives+=(
					-device virtio-scsi-pci,id=scsi0
					-drive file="$basefileabs,media=cdrom,if=none,id=scsi0-cd0"
					-device scsi-cd,drive=scsi0-cd0
				)
			fi
			boot=(-boot order=cd,menu=on)
			;;
		*) ;;
	esac

	if [ "$use_ide" = 1 ]; then
		driveif=ide
	fi
	drives+=(
		-drive "file=$disk0,format=qcow2,if=$driveif"
		-drive "file=$disk1,format=qcow2,if=$driveif"
	)
	for cidrive in \
			"$dir/nocloud.raw" \
			"$dir/configdrive.raw" \
			; do
		if [ -s "$cidrive" ]; then
			drives+=( -drive "file=$cidrive,format=raw,if=$driveif,readonly" )
		fi
	done

	if [ "$distro" = esx ]; then
		netdev=(
			-device vmxnet3,mac="$mac",netdev=wan
			-netdev tap,id=wan,ifname="distro-vm$i",script="$topdir/qemu_ifup",downscript="$topdir/qemu_ifdown"
		)
	elif [ "$distro_arch" = i386 ]; then
		netdev=(
			-device e1000,mac="$mac",netdev=wan
			-netdev tap,id=wan,ifname="distro-vm$i",script="$topdir/qemu_ifup",downscript="$topdir/qemu_ifdown"
		)
	else
		netdev=(
			-device virtio-net-pci,mac="$mac",netdev=wan,mq=on
			-netdev tap,id=wan,ifname="distro-vm$i",script="$topdir/qemu_ifup",downscript="$topdir/qemu_ifdown",queues="$ncpu",vhost="$vhost"
		)
	fi

	"$qemu" \
		"${accel[@]}" \
		"${cpu[@]}" \
		-L "$topdir/qemu-firmware" \
		-name "$name" \
		-nographic \
		-nodefaults \
		-chardev stdio,mux=on,signal=off,id=chr0 \
		-serial chardev:chr0 \
		-mon chardev=chr0 \
		-device virtio-keyboard-pci \
		-device VGA,vgamem_mb=32 \
		-display vnc="0.0.0.0:$((10000 + $i))" \
		-smp cpus=${ncpu} \
		-m "$memsize" \
		"${drives[@]}" \
		"${boot[@]}" \
		"${netdev[@]}" \
		-device virtio-rng-pci \
		"$@"
}

runarm64() {
	run \
		qemu-system-aarch64 \
		-M virt,gic-version=3,graphics=on,firmware=edk2-aarch64-code.fd \

}

runamd64() {
	local mach=q35
	local args=()

	if [ "$distro_arch" = i386 ]; then
		mach=pc
	fi

	if [ "$distro" = "clear-linux-os" ]; then
		local romdirs="$(qemu-system-x86_64 -M "$mach" -L help)"
		local edk2code="edk2-x86_64-code.fd"
		local edk2vars="edk2-i386-vars.fd"
		local rom romdir
		local found
		for rom in "$edk2code" "$edk2vars"; do
			if [ -e "$dir/$rom" ]; then
				continue
			fi
			found=
			for romdir in $romdirs; do
				if [ -s "$romdir/$rom" ]; then
					cp "$romdir/$rom" "$dir/$rom"
					found=1
					break
				fi
			done
			[ -n "$found" ]
		done
		args+=(
			-drive file="$dir/$edk2code",if=pflash,format=raw,unit=0,readonly=on
			-drive file="$dir/$edk2vars",if=pflash,format=raw,unit=1
		)
	fi
	run \
		qemu-system-x86_64 \
		-M "$mach" \
		"${args[@]}" \

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
		case "${basefileabs##*.}" in
			iso)
				qemu-img create -f qcow2 "$disk0" "$rootdisksize"
				;;
			*)
				qemu-img create -f qcow2 -o backing_file="$(relpath_to "$(dirname "$disk0")" "$basefileabs")" "$disk0"
				if [ -n "$rootdisksize" ]; then
					qemu-img resize -f qcow2 "$disk0" "$rootdisksize"
				fi
				;;
		esac
	fi
	if ! [ -s "$disk1" ]; then
		qemu-img create -f qcow2 -o preallocation=falloc "$disk1" "$datadisksize"
	fi
}

open() {
	# centos8 rootfs xfs has features not supported by centos 7 xfs module
	local baseurl=https://cloud.centos.org/centos/8-stream/x86_64/images
	local baseurl=http://mirrors.ustc.edu.cn/centos-cloud/centos/8-stream/x86_64/images
	local basefile="CentOS-Stream-GenericCloud-8-20200113.0.x86_64.qcow2"

	local baseurl=http://mirrors.ustc.edu.cn/centos-cloud/centos/7/images
	local basefile="CentOS-6-x86_64-GenericCloud.qcow2"
	local basefile="CentOS-7-x86_64-GenericCloud.qcow2.xz"
	local basefile="CentOS-7-x86_64-GenericCloud.qcow2"
	local basefile="Fedora-Cloud-Base-32-1.6.x86_64.qcow2"
	local basefile="debian-10.5.0-openstack-amd64.qcow2"
	local basefile="debian-10.4.3-20200610-openstack-arm64.qcow2"
	local basefile="xenial-server-cloudimg-amd64-uefi1.img"
	local basefile="groovy-server-cloudimg-amd64.img"
	local basefile="alpine-virt-3.12.0-x86_64.iso"
	local basefile="alpine-virt-3.12.0-aarch64.iso"
	local basefile="SLES15-SP2-JeOS.x86_64-15.2-OpenStack-Cloud-GM.qcow2"
	local basefile="cirros-0.5.1-x86_64-disk.img"
	local basefile="cirros-0.5.1-aarch64-disk.img"
	local basefile="ubuntu-20.04.1-live-server-arm64.iso"
	local basefile="VMware-VMvisor-Installer-7.0b-16324942.x86_64.iso"
	local basefile="archlinux-2020.08.01-x86_64.iso"
	local basefile="android-x86_64-9.0-r2.iso"
	local basefile="cm-x86_64-14.1-r4-k419.iso"
	local basefile="FreeBSD-12.1-RELEASE-amd64.qcow2"
	local basefile="i386-disc1.iso" # centos 2.1
	local basefile="reactos-bootcd-0.4.15-dev-1397-g19779b3-x86-gcc-lin-rel.iso"
	local basefile="proxmox-ve_6.3-1.iso"
	local basefile="guix-system-vm-image-1.2.0.x86_64-linux.qcow2"
	local basefile="clear-34000-cloudguest.img"
	local basefile="void-live-x86_64-musl-20191109.iso"
	local basefile="pfSense-CE-2.4.5-RELEASE-p1-amd64.iso"

	local basefileabs="$topdir/$basefile"
	local url="$baseurl/$basefile"

	: wget -O "$basefileabs" -c "$url"

	local i="$1"
	local name="vm$i"
	local dir="$topdir/$name"
	local disk0="$dir/d0"
	local disk1="$dir/d1"
	local mac
	local distro
	local distro_version_id
	local distro_version_codename
	local distro_arch
	local distro_arch_endian

	mkdir -p "$dir"
	ensure_mac
	ensure_disk
	case "${basefileabs##*.}" in
		iso) prepiso ;;
		*) preproot ;;
	esac
	ensure_dhcp

	distro_arch=x86_64
	local f
	for f in $(find "$dir" -maxdepth 2 -type f -name "??-config-*"); do
		source "$f"
	done
	case "$distro_arch" in
		x86_64|i386) runamd64 ;;
		aarch64) runarm64 ;;
		*) false ;;
	esac
}

qemu_ifup() {
	local name="$1"; shift

	ip link set "$name" master br-wan up
	#ethtool -K "$name" tx off
}

qemu_ifdown() {
	local name="$1"; shift
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
	sysctl net.ipv4.ip_forward=1
	while iptables -t nat -D POSTROUTING -s "$subnet.0/24" '!' -d "$subnet.0/24" -j MASQUERADE; do :; done
	      iptables -t nat -A POSTROUTING -s "$subnet.0/24" '!' -d "$subnet.0/24" -j MASQUERADE;
	echo "interface=br-wan" >"$dnsmasqconf"
	echo "dhcp-range=$subnet.10,$subnet.150,2h" >>"$dnsmasqconf"
	systemctl restart dnsmasq
fi
if ! [ -s "$topdir/id_rsa" ]; then
	ssh-keygen -f "$topdir/id_rsa" -N ''
fi
if ! [ -d "$topdir/qemu-firmware" ]; then
	mkdir -p "$topdir/qemu-firmware"
	if [ -s /usr/share/qemu-efi-aarch64/QEMU_EFI.fd ]; then
		ln -sf /usr/share/qemu-efi-aarch64/QEMU_EFI.fd "$topdir/qemu-firmware/edk2-aarch64-code.fd"
	fi
	if [ -s /usr/lib/ipxe/qemu/efi-virtio.rom ]; then
		ln -sf /usr/lib/ipxe/qemu/efi-virtio.rom "$topdir/qemu-firmware/"
	fi
	if [ -s /usr/share/vgabios/vgabios-stdvga.bin ]; then
		ln -sf /usr/share/vgabios/vgabios-stdvga.bin "$topdir/qemu-firmware/"
	fi
fi
if ! [ -h "$topdir/qemu_ifdown" ]; then
	ln -sf "$(relpath_to "$topdir" "$script")"   "$topdir/qemu_ifup"
	ln -sf "$(relpath_to "$topdir" "$script")" "$topdir/qemu_ifdown"
fi

set -o xtrace
case "$prog" in
	qemu_ifup|qemu_ifdown) "$prog" "$@" ;;
	*) "$@" ;;
esac
