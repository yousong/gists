Enum defs

	enum {
	    PART_KERNEL = 0,
	    PART_RAMDISK,
	    PART_RECOVERY,
	    PART_LOGO,
	    PART_PARAM,
	    PART_PRIVATE,
	    PART_BAT_MODEL,
	    /* recovery private data partition */
	    PART_REC_PRIV,
	    PART_RESERVED1,
	    PART_RESERVED2,
	    PART_MAX,
	};

Extracted from uboot2

	info_version: 1
	uboot_version: U-Boot 2012.07-ged6d281 (Apr 11 2014) for M35X-W release
	build_variant: user
	not_signed_check: 0
	board_version: 0
	part  0: start_sec:      1263 (     4ef), sec_count:     20480 (    5000)
	part  1: start_sec:     21743 (    54ef), sec_count:     20480 (    5000)
	part  2: start_sec:     42223 (    a4ef), sec_count:     40960 (    a000)
	part  3: start_sec:     83183 (   144ef), sec_count:     40960 (    a000)
	part  4: start_sec:    124143 (   1e4ef), sec_count:     40960 (    a000)
	part  5: start_sec:         1 (       1), sec_count:       256 (     100)
	part  6: start_sec:    165103 (   284ef), sec_count:        16 (      10)
	part  7: start_sec:       273 (     111), sec_count:         2 (       2)
	part  8: start_sec:    165119 (   284ff), sec_count:     40960 (    a000)
	part  9: start_sec:    206079 (   324ff), sec_count:     40960 (    a000)
	
	part  0: byte_offset:    646656 (   9de00), byte_count:  10485760 (  a00000)
	part  1: byte_offset:  11132416 (  a9de00), byte_count:  10485760 (  a00000)
	part  2: byte_offset:  21618176 ( 149de00), byte_count:  20971520 ( 1400000)
	part  3: byte_offset:  42589696 ( 289de00), byte_count:  20971520 ( 1400000)
	part  4: byte_offset:  63561216 ( 3c9de00), byte_count:  20971520 ( 1400000)
	part  5: byte_offset:       512 (     200), byte_count:    131072 (   20000)
	part  6: byte_offset:  84532736 ( 509de00), byte_count:      8192 (    2000)
	part  7: byte_offset:    139776 (   22200), byte_count:      1024 (     400)
	part  8: byte_offset:  84540928 ( 509fe00), byte_count:  20971520 ( 1400000)
	part  9: byte_offset: 105512448 ( 649fe00), byte_count:  20971520 ( 1400000)
	
Partition names `mmcblk0p[0-4]` are occupied by `/system`, `/cache`, `/userdata`, `/custom` respectively.  They are described by MSDOS partition table and parsed by `block/partitions/check.c:check_partition()`

	start_sec		sec_count		block_cnt
	60000			300000			1/2
	360000			100000
	560000			17fa000
	460000			100000

Partitions described by bootinfo are going to take indexes starting from 5.  If they are to be exported, `mmcblk0p5` will contain zImage.  See `drivers/mmc/card/block.c:init_extra_partition()` for details.