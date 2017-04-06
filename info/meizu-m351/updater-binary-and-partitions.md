`META-INF/com/mx3/android/updater-script`

Partition and content

	mmcblk0p7		recovery-uboot.img
	mmcblk0p6		ramdisk-uboot.img
	mmcblk0p5		zImage
	mmcblk0boot0	bootloader.img or boot.img
	mmcblk0p1		/system
	mmcblk0p4		/custom, may delete `/custom/meizu/` if `/custom/simlock.key` does not exist

See `drivers/mmc/card/block.c:init_extra_partition()` for details.

Part info from `bootinfo` are added with index 5 as base.  That means `PART_REC_PRIV` will be available as `mmcblk0p[5 + PART_KERNEL]`, i.e. `mmcblk0p12`

In normal mode, `PART_REC_PRIV` is the only partition exported in kernel.

- bootable/recovery, https://android.googlesource.com/platform/bootable/recovery
- Android notes on OTA, http://www.efalk.org/Docs/Android/ota.html#Edify
- (possibly outdated), https://source.android.com/devices/tech/ota/inside_packages.html