set -o errexit
set -o xtrace

# put me at root dir of openwrt source code
mydir="$(dirname "$(readlink -f "$0")")"

git checkout v17.01.7

# trim for size
f=target/linux/ar71xx/files/arch/mips/ath79/Makefile
sed -i -e 's!^obj-\$(CONFIG_ATH79_MACH_!#\0!' "$f"
sed -i -e 's!^#\(obj-\$(CONFIG_ATH79_MACH_TL_WR741ND)\)!\1!' "$f"

# trim for size
f=include/target.mk
sed -i -e 's!^\(DEFAULT_PACKAGES:=.*\) opkg \(.*\)!\1 \2!' "$f"

# use feeds from local cloned repo
cat feeds.conf.default \
	| grep -vE ' (routing|telephony) ' \
	| sed -r -e 's!https.*/([^.]+)\.git(\^.*)!file://'$mydir/..'/\1/.git\2!' \
	> feeds.conf
./scripts/feeds update -a
./scripts/feeds install -a

with_zerotier=false
if "$with_zerotier"; then
	# - zerotier 1.12 requires c++17
	# - zerotier 1.10.6 is too big for 4M devices, ca. 849KiB
	# - zerotier 1.1 seems deprecated and not working
	( set -ex; cd feeds/packages; git rm -rf net/zerotier; git checkout origin/openwrt-23.05 net/zerotier; )
	( set -ex; cd feeds/packages; git rm -f net/zerotier/patches/*remove-noexecstack.patch; )
	# sed -i -e 's/std::string_view/std::experimental::string_view/g' `rg -l std::string_view ext/inja```
	# sed -i -e 's!<string_view>!<experimental/string_view>!' `rg -l '<string_view>' ext/inja`
	cp zerotier.patch feeds/packages/net/zerotier/patches/9999.patch
	cat zerotier-makefile.patch | ( set -ex; cd feeds/packages; patch -p1; )
fi

cp ../defconfig/wr841v5-yy .config
make defconfig
