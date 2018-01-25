## refs

- intel haxm, https://software.intel.com/en-us/android/articles/intel-hardware-accelerated-execution-manager
- qemu 2.9 introduces haxm support, http://wiki.qemu.org/ChangeLog/2.9
- Setup NAT Network for QEMU in Mac OSX, https://blog.san-ss.com.ar/2016/04/setup-nat-network-for-qemu-macosx

## steps

install intel haxm

tuntap driver

	sudo port install tuntaposx
	sudo port load tuntaposx

create bridge and make it gateway

	sudo ./qemu-osx setup
	sudo ./qemu-osx run
	sudo ./qemu-osx run2

## todo

- investigate why "-drive if=virtio" does not work
