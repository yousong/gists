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
	mkfs.ext4 -m 0 -L cidata "$ncdisk"

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
	menulst="$(find "$rootdir" -maxdepth 3 -type f -iname menu.lst -type f | head -n1)"
	if [ -s "$menulst" ]; then
		if grep -m1 -q " LABEL=cirros-rootfs" "$menulst"; then
			distro="cirros"
			local initrd
			initrd="$(find "$rootdir" -maxdepth 1 -name initrd.img | head -n1)"
			distro_version_id="$(gunzip -c "$initrd" | cpio --to-stdout --quiet -i etc/cirros/version)"
			return
		fi
	fi
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

detect_distro_arch() {
	parse_elf distro_arch distro_arch_endian "$rootdir/bin/sh"
	if [ -n "$distro_arch" -a -n "$distro_arch_endian" ]; then
		update_config "distro_arch" "$distro_arch"
		update_config "distro_arch_endian" "$distro_arch_endian"
		return
	fi

	local efidir
	local pe
	efidir="$(find "$rootdir" -maxdepth 1 -type d -iname efi | head -n 1)"
	if [ -d "$efidir" ]; then
		pe="$(find "$efidir" -type f -iname "*.efi" | head -n 1)"
	fi
	if [ -z "$pe" ]; then
		pe="$(find "$rootdir" -maxdepth 2 -iname "*.exe" | head -n 1)"
	fi
	if [ -s "$pe" ]; then
		local sig off mach
		sig="$(hexdump -v -s 0 -n 2 -e '2/1 "%02x" "\n"' "$pe")"
		[ "$sig" = 4d5a ]

		off="$(hexdump -v -s 60 -n 4 -e '4/1 "%02x" "\n"' "$pe")"
		swap32 off "$off"
		sig="$(hexdump -v -s "$((0x$off))" -n 4 -e '4/1 "%02x" "\n"' "$pe")"
		[ "$sig" = 50450000 ]

		mach="$(hexdump -v -s "$((0x$off + 4))" -n 2 -e '2/1 "%02x" "\n"' "$pe")"
		swap16 mach "$mach"
		case "$mach" in
			8664) distro_arch_endian=le; distro_arch=x86_64 ;;
			014c) distro_arch_endian=le; distro_arch=i386 ;;
			aa64) distro_arch_endian=  ; distro_arch=aarch64 ;;
			*) false ;;
		esac
		update_config "distro_arch" "$distro_arch"
		update_config "distro_arch_endian" "$distro_arch_endian"
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

	nbd_connect dev1 "$disk1"
	local features
	if [ "$distro" = centos -a "$distro_version_id" -le 6 ]; then
		features="${features:+$features,}^metadata_csum,uninit_bg"
	fi
	mkfs.ext4 -vv -F -E 'lazy_itable_init=1,lazy_journal_init=1' -O "$features" "$dev1"
	local UUID TYPE
	eval "$(blkid -o export "$dev1" | grep -E "^(UUID|TYPE)")"
	poptrap

	if [ "$distro" = cirros ]; then
		mkds_nocloud

		poptrap
		touch "$peppered"
		return
	fi

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
			cat "$topdir/fedora.repo" >"$rootdir/etc/yum.repos.d/fedora.repo"
			cat "$topdir/fedora-updates.repo" >"$rootdir/etc/yum.repos.d/fedora-updates.repo"
			chown 0:0 "$rootdir/etc/yum.repos.d/fedora.repo"
			chown 0:0 "$rootdir/etc/yum.repos.d/fedora-updates.repo"
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
	mount "$basefileabs" "$rootdir"
	pushtrap "umount $rootdir/"

	detect_rootfs
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
	local helper
	local vhost=on

	parse_elf hostarch hostarch_endian /bin/bash
	if [ "$hostarch" = "$distro_arch" ]; then
		accel=(-accel kvm)
		cpu=(-cpu host)
	else
		accel=(-accel tcg,thread=multi)
		case "$distro_arch" in
			aarch64) cpu=(-cpu cortex-a57) ;;
			*) false ;;
		esac
		vhost=off
	fi
	case "${basefileabs##*.}" in
		iso)
			drives+=(
				-device virtio-scsi-pci,id=scsi0
				-drive file="$basefileabs,media=cdrom,if=none,id=scsi0cd0"
				-device scsi-cd,drive=scsi0cd0
			)
			boot=(-boot order=cd,menu=on)
			;;
		*) ;;
	esac
	if [ -s "$dir/nocloud.raw" ]; then
		drives+=( -drive "file=$dir/nocloud.raw,format=raw,if=virtio" )
	fi

	helper="$("$qemu" -help | grep -m1 -o '/.*qemu-bridge-helper')"
	[ -x "$helper" ]
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
		-device VGA \
		-display vnc="0.0.0.0:$((10000 + $i))" \
		-smp cpus=${ncpu} \
		-m "$memsize" \
		-drive "file=$disk0,format=qcow2,if=virtio" \
		-drive "file=$disk1,format=qcow2,if=virtio" \
		"${drives[@]}" \
		"${boot[@]}" \
		-device virtio-net-pci,mac="$mac",netdev=wan \
		-netdev tap,id=wan,br=br-wan,helper="$helper",vhost="$vhost" \
		-device virtio-rng-pci \
		"$@"

}

runarm64() {
	run \
		qemu-system-aarch64 \
		-M virt,gic-version=3,graphics=on,firmware=edk2-aarch64-code.fd \

}

runamd64() {
	run \
		qemu-system-x86_64 \
		-M q35 \

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

	local f
	for f in $(find "$dir" -maxdepth 2 -type f -name "??-config-*"); do
		source "$f"
	done
	case "$distro_arch" in
		x86_64) runamd64 ;;
		aarch64) runarm64 ;;
		*) false ;;
	esac
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

set -o xtrace
"$@"
