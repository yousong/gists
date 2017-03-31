PREFIX="$HOME/.usr"
BINDIR="$PREFIX/bin"

# 1. Install jdk7
# 2. Install ia32-libs
# 3. Install apktool
wget -c https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
wget -c -O apktool.jar https://github.com/iBotPeaches/Apktool/releases/download/2.1.0/apktool_2.1.0.jar

for f in apktool apktool.jar; do
	install -m 0755 "$f" "$BINDIR/$f"
done