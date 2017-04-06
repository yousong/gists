ARM TAGS, a way for bootloader passing info to kernel.  See [Booting ARM Linux](http://www.simtec.co.uk/products/SWLINUX/files/booting_article.html) for a good introduction to this.

m35x has a device-specific (possibly vendor-specific) `ATAG_BOOTINFO`

`arch/arm/include/asm/setup.h`, contains type declaration for

		#ifdef CONFIG_MACH_M6X
		/* board bootinfo */
		#define ATAG_BOOTINFO   0x5441000A
		
		#include <linux/bootinfo.h>
		
		struct tag_bootinfo {
		                struct bootinfo b;
		};
		#endif

`include/linux/bootinfo.h`, this file is for meizu devices only.	

- help functions for getting uboot info from `bootinfo`
- enum definication for part order

An excerpt

	 11 enum {
	 12         PART_KERNEL = 0,
	 13         PART_RAMDISK,
	 14         PART_RECOVERY,
	 15         PART_LOGO,
	 16         PART_PARAM,
	 17         PART_PRIVATE,
	 18         PART_BAT_MODEL,
	 19         /* recovery private data partition */
	 20         PART_REC_PRIV,
	 21         PART_RESERVED1,
	 22         PART_RESERVED2,
	 23         PART_MAX,
	 24 };

	 33 struct bootinfo {
	 34         u32             info_version;                   // 1/2/3/4/..
	 35         struct          part_info part[32];             // partition layout, null terminal
	 36         char            uboot_version[64];              // uboot string version
	 37         char            build_variant[16];              // eng/user/oversea/..
	 38         u8              not_signed_check;               // signed check, 0 means check the signature
	 39         u8              board_version;                  // defined by ID1-3 GPIO pin
	 40 };

`PART_PRIVATE` has device serial number, public key for signature verification, mac address

1. m35x kernel will get S/N and mac address at `drivers/mmc/card/block.c` with `meizu_device_info_init()` which is defined in `arch/arm/mach-exynos/meizu_security.c`.
2. Contents in `PART_PRIVATE` are organized as blocks (slots) of 1024 bytes
3. slot0 is for s/n
4. slot1 is for mac addresses
5. slot4 is for camera module

There are two public keys in `include/linux/rsa_pubkey.h`

- `factory_rsa_pk`, for data in `PART_PRIVATE` parts
- `remote_rsa_pk`, *not sure what's this for*

Prerequisites: we can root the device and these partitions are writable.

- Disassemble u-boot and see how it works