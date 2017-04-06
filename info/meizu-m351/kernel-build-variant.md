`arch/arm/mach-exynos/Kconfig`

- `ENG_KERNEL`, the one in `mx3_defconfig`
- `DEV_KERNEL`
- `USER_KERNEL`, the one in official firmware (see `strings zImage | grep '3\.4'`)
- `UNICOM_KERNEL`, will set output china unicom logo at fb probe
- `OVERSEAS_KERNEL`
- `RECOVERY_KERNEL`, drivers for `sound`, `gps`, etc. will not be built

The variant info will also be available in `bootinfo.build_variant[]` passed from bootloader and this part will be available as `/proc/uboot_version` (see `fs/proc/uboot_version.c`).  The U-Boot version `bootinfo.uboot_version[]` will be available as `/proc/uboot_git_version`

`init/Kconfig`, it will show up in the following place.  `/proc/version` and output of command `uname -r`

	config LOCALVERSION
	        string
	        #"Local version - append to kernel release"
	        default "-eng"  if ENG_KERNEL
	        default "-dev" if DEV_KERNEL
	        default "-user" if USER_KERNEL
	        default "-overseas" if OVERSEAS_KERNEL
	        default "-unicom" if UNICOM_KERNEL
	        default "-recovery-release" if RELEASE_RECOVERY
	        default "-recovery" if RECOVERY_KERNEL

`drivers/video/Kconfig`

	config M6X_LOGO_UNICOM
		depends on UNICOM_KERNEL
		default y
		bool "MEIZU M6X Unicom Logo"
		
`drivers/video/s3c-fb.c`, see `s3c_fb_copy_logo_fb()`