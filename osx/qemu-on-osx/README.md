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

	sudo ifconfig bridge1 create 192.168.7.1/24
	sudo ifconfig bridge1 destroy

enable ip forwarding

	sudo sysctl -w net.inet.ip.forwarding=1
	sudo sysctl net.inet.ip.forwarding

enable nat on en0 for traffics from networks of bridge1

	# nat rule in /etc/pf.conf
	#
	#	nat on en0 from bridge1:network to any -> (en0)
	#
	# -F nat, flush all nat rules
	# -N -f xxx, load only nat rules from file xxx
	# -s nat, show nat rules
	#
	# see pfctl(8) for details
	#
	sudo pfctl -F nat
	sudo pfctl -N -f /etc/pf.conf
	sudo pfctl -s nat

enable dhcp server

	# see bootpd(8) for details
	sudo cp bootpd.plist /etc/bootpd.plist
	sudo /usr/libexec/bootpd -d

qemu command, see `b`.  qemu requires requires root privileges to run

## todo

- make a bridge helper for qemu on osx
- investigate why "-drive if=virtio" does not work
