Content of `/proc/uboot_version`, compare and take index0

    eng       0
    oversea   1
    user      2

`property_get("ro.meizu.hardware.modem", buf_modem, "wcdma)`, take index1

    wcdma       index0
    td-scdma    index0+3

So

    eng,wcdma         0
    oversea,wcdma     1
    user,wcdma        2
    eng,td-scdma      3
    oversea,td-scdma  4
    user,td-scdma     5

This is also cross-confirmed by contents of bootloader.img
