mydir="$(dirname "$(readlink -f "$0")")"

# run container for openwrt build
runob() {
	# Put openwrt source code under $work
	local workdir="$mydir/work"
	local defcfgdir="$mydir/defconfig"

	local dockerimg="yousong/test:openwrt"

	local uid
	local gid
	local user

	uid="$(id -u)"
	gid="$(id -g)"
	user="$(id -un)"

	docker run \
		--rm \
		-it \
		--name ob \
		-v "$workdir:/work" \
		-v "$defcfgdir:/work/defconfig" \
		-w "/work" \
		--user "$uid:$gid" \
		"$dockerimg" \
		bash
}

"$@"
