On target board

	gdbserver --attach 192.168.1.1:9000 $(pgrep xl2tpd)

On OpenWrt/LEDE dev host

	./scripts/remote-gdb 192.168.1.1:9000 ./staging_dir/target-mipsel_mips32_musl-1.1.10/root-malta/usr/sbin/xl2tpd
