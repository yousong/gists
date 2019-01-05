#!/usr/bin/env bash

set -o errexit
set -o pipefail

vs='
3.18.130
4.9.146
4.14.90
4.19.9
'

set -ex

dl_linux () {
        local ver="$1"
        local oIFS="$IFS"
        IFS="."
        set -- $ver
        IFS="$oIFS"
        local ver_maj="$1"
        local ver_min="$2"
        local subdir fn
        local u urls
        if [ -z "$ver_maj" -o -z "$ver_min" ]
        then
                __errmsg "dl_linux usage examples:"
                __errmsg "  dl_linux 1.0"
                __errmsg "  dl_linux 4.4.49"
                return 1
        fi
        if [ "$ver_maj" -ge 3 ]
        then
                subdir="v$ver_maj.x"
        else
                subdir="v$ver_maj.$ver_min"
        fi
        fn="linux-$ver.tar.xz"
        urls="
http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/$subdir/$fn
http://mirrors.aliyun.com/linux-kernel/$subdir/$fn
"
        for u in $urls
        do
                wget -O "$fn" -c "$u" && break
        done
}

p() {
	for v in $vs; do
		dl_linux $v
		if [ ! -d linux-$v ]; then
			tar xJf linux-$v.tar.xz
		fi
		(
			cd linux-$v
			make tinyconfig
			echo "CONFIG_MODULES=y" >>.config
			make olddefconfig
			make -j8
		)
	done
}

b() {
	for v in $vs; do
		make -C "$PWD/linux-$v" M=$PWD KBUILD_VERBOSE=1
	done
}

"$@"
