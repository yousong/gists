#!/bin/bash

# NOTE: keep this one empty in the repo
# NOTE: should we also override /etc/resolv.conf?
o_ifname_adm="${o_ifname_adm}"
o_ifname_vpc="${o_ifname_vpc}"
o_ifname_vpc_nets="${o_ifname_vpc_nets:-172.16.0.0/12 10.240.0.0/12}"
o_self="$0"

__errmsg() {
	echo "$o_self: $*" >&2
}

gendoc() {
	cat >&2 <<EOF

# $o_self

	Usage: $o_self gendoc
	       $o_self setup

## 概述

平台中对网络地址仅有内网、外网的区分，并依此通过dhcp提供地址、路由的配置

当一台虚机还同时绑定有管理网卡、vpc公共服务网卡时，通过dhcp取得的地址虽然正确，但是路由的配置却不一定符合期望

脚本尝试固化此类虚机的网络配置项，实现

 - 所有网卡地址配置正确
 - 默认路由走管理网卡
 - vpc公共服务相关子网路由设置正确
 - 基于网卡源地址的策略路由，例如，FullNAT环境中的NGINX机器，源地址为内网网卡地址、目的地址为公网IP的报文仍从内网网卡出去，而不是通过默认路由走管理网网卡
 - 重启机器配置能不变

## 原理

脚本通过环境变更接收配置项

 - o_ifname_adm, 管理网卡名，必选
 - o_ifname_vpc, vpc公共服务网卡名，可选
 - o_ifname_vpc_nets, 需要走vpc公共服务网卡网段，默认值为172.16.0.0/12, 10.240.0.0/12

脚本"setup"时会做以下操作

 1. 更新ifcfg-\$ifname，设定所有link/ether网卡的地址获取方式为dhcp
 2. 重启网络，使网卡获得地址
 3. 取网卡的inet地址，再次更新ifcfg-\$ifname
	- 地址获取方式为静态
	- 设定默认路由走\$o_ifname_adm
	- 设定route-\$ifname, rule-\$ifname，使流量进出的路径对称
	- 设定\$o_ifname_vpc_nets走\$o_ifname_vpc
 4. 再次重启网络
 5. 检查
	- 默认路由是否正确
	- \$o_ifname_vpc_nets路由是否正确
	- 策略路由是否正确

## 示例

	o_ifname_adm=eth2 o_ifname_vpc=eth1 $o_self setup

	# 执行单一步骤
	o_ifname_adm=eth2 o_ifname_vpc=eth1 $o_self check_pre
	o_ifname_adm=eth2 o_ifname_vpc=eth1 $o_self check_post
	o_ifname_adm=eth2 o_ifname_vpc=eth1 $o_self setup_conf_dhcp
	o_ifname_adm=eth2 o_ifname_vpc=eth1 $o_self restart_network
	o_ifname_adm=eth2 o_ifname_vpc=eth1 $o_self setup_conf_static
EOF
}

setup() {
	local func

	for func in \
			check_pre \
			setup_conf_dhcp \
			restart_network \
			setup_conf_static \
			flush_routes \
			restart_network \
			check_post \
			; do
		if $func; then
			__errmsg "-------- good: $func"
		else
			__errmsg "-------- bad : $func"
			return 1
		fi
	done
}

check_pre() {
	if [ -z "$o_ifname_adm" -o ! -d "/sys/class/net/$o_ifname_adm" ]; then
		__errmsg "wrong setting: o_ifname_adm is not set or does not exist: $o_ifname_adm"
		return 1
	fi

	if [ "$(id -u)" != 0 ]; then
		__errmsg "requires root privileges"
		return 1
	fi
}

ifnames_ether() {
	/sbin/ip -o address | grep link/ether | cut -d: -f2
}

ifname_ipmask() {
	local ifname="$1"

	/sbin/ip -oneline address show "$ifname" | grep -oE -m1 'inet [0-9./]+' | cut -d' ' -f2
}

ipmask_gateway() {
	local ipmask="$1"
	local network="$(ipcalc --network "$ipmask" | cut -d= -f2)"
	local gateway="${network%.*}.$((${network##*.} | 1))"
	echo "$gateway"
}

setup_conf_dhcp() {
	local ifname

	for ifname in $(ifnames_ether); do
		cat >"/etc/sysconfig/network-scripts/ifcfg-$ifname" <<-EOF
			DEVICE=$ifname
			ONBOOT=yes
			BOOTPROTO=dhcp
		EOF
	done
}

restart_network() {
	/etc/init.d/network restart
}

setup_conf_static() {
	local ifname
	local ipmask
	local GATEWAYDEV
	local i=2

	# make BOOTPROTO=static
	for ifname in $(ifnames_ether); do
		ipmask="$(ifname_ipmask "$ifname")"
		if [ -z "$ipmask" ]; then
			__errmsg "$ifname: failed find inet address"
			return 1
		fi
		# NOTE: disable 169.254.0.0 by setting NOZEROCONF=yes
		local BROADCAST NETWORK NETMASK
		eval "$(ipcalc --broadcast --network --netmask "$ipmask")"
		local gateway="$(ipmask_gateway "$ipmask")"
		cat >"/etc/sysconfig/network-scripts/ifcfg-$ifname" <<-EOF
			DEVICE=$ifname
			ONBOOT=yes
			BOOTPROTO=static
			IPADDR=${ipmask%%/*}
			BROADCAST=$BROADCAST
			NETWORK=$NETWORK
			NETMASK=$NETMASK
		EOF
		if [ "$ifname" = "$o_ifname_adm" ]; then
			cat >>"/etc/sysconfig/network-scripts/ifcfg-$ifname" <<-EOF
				DEFROUTE=yes
				GATEWAY=$gateway
			EOF
		else
			cat >>"/etc/sysconfig/network-scripts/ifcfg-$ifname" <<-EOF
				DEFROUTE=no
			EOF
		fi

		cat >/etc/sysconfig/network-scripts/route-$ifname <<-EOF
			$NETWORK/${ipmask#*/} dev $ifname table $i
			default via $gateway dev $ifname table $i
		EOF
		cat >/etc/sysconfig/network-scripts/rule-$ifname <<-EOF
			from ${ipmask%/*} lookup $i
		EOF
		i="$(($i+1))"
	done

	# $o_ifname_vpc_nets via gateway
	if [ -n "$o_ifname_vpc" -a -n "$o_ifname_vpc_nets" ]; then
		if [ ! -d "/sys/class/net/$o_ifname_vpc" ]; then
			__errmsg "cannot find o_ifname_vpc: $o_ifname_vpc"
			return 1
		fi
		local ipmask="$(ifname_ipmask "$o_ifname_vpc")"
		local gateway="$(ipmask_gateway "$ipmask")"
		local net
		for net in $o_ifname_vpc_nets; do
			echo "$net via $gateway dev $o_ifname_vpc" >>"/etc/sysconfig/network-scripts/route-$o_ifname_vpc"
		done
	fi

	# $o_ifname_adm as the default route
	if [ -f /etc/sysconfig/network ]; then
		GATEWAYDEV="$(source /etc/sysconfig/network; echo $GATEWAYDEV)"
	fi
	if [ "$GATEWAYDEV" != "$o_ifname_adm" ]; then
		echo "GATEWAYDEV=$o_ifname_adm" >>/etc/sysconfig/network
	fi
}

flush_routes() {
	local i=2
	local ifname

	# flush existing routes/rules to make the result more predicatable
	for ifname in $(ifnames_ether); do
		/sbin/ip route flush table $i
		while /sbin/ip rule delete lookup $i &>/dev/null; do true; done
		i="$(($i+1))"
	done
	/sbin/ip route flush table main
}

check_post() {
	if ! /sbin/ip route | grep default | grep "dev $o_ifname_adm" | grep -q 'via '; then
		__errmsg "default route should should go through $o_ifname_adm with gateway"
		return 1
	fi

	if [ -n "$o_ifname_vpc" -a -n "$o_ifname_vpc_nets" ]; then
		local net
		for net in $o_ifname_vpc_nets; do
			if ! /sbin/ip route | grep "$net" | grep -q "dev $o_ifname_vpc"; then
				__errmsg "route to $net should go through $o_ifname_vpc"
				return 1
			fi
		done
	fi

	local i=2
	local ifname
	local ipmask gateway
	local BROADCAST NETWORK NETMASK
	for ifname in $(ifnames_ether); do
		ipmask="$(ifname_ipmask "$ifname")"
		gateway="$(ipmask_gateway "$ipmask")"
		eval "$(ipcalc --broadcast --network --netmask "$ipmask")"
		if ! ip rule | grep "from ${ipmask%/*}" | grep -q "lookup $i"; then
			__errmsg "missing ip rule: from ${ipmask%/*} lookup $i"
			return 1
		fi
		if ! ip route show table "$i" | grep "$NETWORK/${ipmask#*/}" | grep -q "dev $ifname"; then
			__errmsg "missing ip route: $NETWORK/${ipmask#*/} dev $ifname table $i"
			return 1
		fi
		if ! ip route show table "$i" | grep "default" | grep "via $gateway" | grep -q "dev $ifname"; then
			__errmsg "missing ip route: default via $gateway dev $ifname table $i"
			return 1
		fi
		i="$(($i+1))"
	done
}

[ "$#" -gt 0 ] || set -- gendoc
"$@"
