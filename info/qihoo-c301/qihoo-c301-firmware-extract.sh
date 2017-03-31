#!/bin/sh
#
# This script tries to decrypt and extract from OEM firmwares distributed by
# Qihoo factory and sysupgrade firmwares usable for OpenWrt.
#
# Prerequisites
#
#  - openssl enc command with aes-128-ecb support
#  - tail :)
#
# Original OEM firmwares can be found at http://luyou.360.cn/rom.html
#
in="$1"
[ -f "$in" ] || {
	echo "No such file: $in" >&2
	exit 1
}
out="$in.plain"
out_factory="$out.seama.factory"
out_sysupgrade="$out.seama.sysupgrade"


# Decrypt with AES-128-ECB
openssl enc -d -aes-128-ecb -K 95B8724B0763DF53469EE79B367F4599 -in "$in" -out "$out"


# OEM firmwares distributed by Qihoo have the following structure.
#
#	- 0x80 bytes of RSA-1024 signature
#	- 0x01 byte for denoting the filename size size_fn
#	- size_fn bytes for the filename
#	- Sealed seama image header
#	- Seama image header
#	- Image content
#
siz_rsa=0x80
siz_fn=0x$(hexdump -s "$siz_rsa" -n 1 -e '/1 "%02x"' "$out")


## Extract factory image.
offset_sealed_seama=$(($siz_rsa + 1 + $siz_fn))
tail_offset=$(($offset_sealed_seama + 1))
tail -c +"$tail_offset" "$out" >"$out_factory"


## Extract sysupgrade image.
siz_meta=0x$(hexdump -s 6 -n 2 -e '/1 "%02x"' "$out_factory")
tail_offset=$((12 + $siz_meta + 1))
tail -c +"$tail_offset" "$out_factory" > "$out_sysupgrade"
