topdir=$PWD

containerd_configdir=$topdir/etc/containerd
containerd_config=$containerd_configdir/config.toml
containerd_libdir=$topdir/var/lib/containerd
containerd_rundir=$topdir/var/run/containerd
containerd_address=$topdir/var/run/containerd/containerd.sock


download() {
	wget -c https://github.com/kata-containers/kata-containers/releases/download/2.1.1/kata-static-2.1.1-x86_64.tar.xz
	wget -c https://github.com/containerd/containerd/releases/download/v1.5.5/containerd-1.5.5-linux-amd64.tar.gz
}

unpack() {
	tar xJf kata-static-2.1.1-x86_64.tar.xz
	tar xzf containerd-1.5.5-linux-amd64.tar.gz
}

config_containerd() {
	mkdir -p "$containerd_libdir"
	mkdir -p "$containerd_rundir"
	mkdir -p "$containerd_configdir"

	# edit output of "containerd config default"
	cat >"$containerd_config" <<EOF
root = "$containerd_libdir"
state = "$containerd_rundir"

[debug]
  level = "debug"

[grpc]
  address = "$containerd_address"

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "kata"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
          runtime_type = "io.containerd.kata.v2"
EOF
}

config_kata() {
	if [ -e /opt/kata ]; then
		if ! [ -h /opt/kata ]; then
			echo "/opt/kata exists and is not symlink" >&2
			return 1
		fi
	else
		# containerd-shim-kata-v2 as of 2.1 does not support specifying
		# arbitary path to configuration file.  It has its own list of
		# paths to try.  Additionally, default configuration files also
		# refer to files with /opt/kata prefix
		ln -sf $topdir/opt/kata /opt/kata
	fi

	# fc, clh has virtio-fs support
	ln -sf configuration-fc.toml $topdir/opt/kata/share/defaults/kata-containers/configuration.toml
	ln -sf configuration-clh.toml $topdir/opt/kata/share/defaults/kata-containers/configuration.toml
	ln -sf configuration-qemu.toml $topdir/opt/kata/share/defaults/kata-containers/configuration.toml
}

init_environ() {
	export PATH=$topdir/bin:$PATH
	export PATH=$topdir/opt/kata/bin:$PATH
}

case "$1" in
	containerd)
		config_containerd
		init_environ
		"$@" --config "$containerd_config"
		;;
	ctr)
		init_environ
		shift
		ctr --address "$containerd_address" "$@"
		;;
	.|source)
		# run as ". $0 ."
		alias containerd="bash $topdir/a.sh containerd"
		alias ctr="bash $topdir/a.sh ctr"
		;;
	*)
		"$@"
		;;
esac
