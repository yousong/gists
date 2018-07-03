o_grepo=$HOME/git-repo
o_ignor="lede-project/ ghtar/ gcc/"
o_repos=
for r0 in $(find $o_grepo -maxdepth 3 -name .git -type d); do
	r="${r0#$o_grepo/}"
	no=0
	for r1 in $o_ignor; do
		if [ "$r" != "${r#$r1}" ]; then
			no=1
			break
		fi
	done
	[ "$no" -eq 0 ] && o_repos="$o_repos $r0"
done
o_repod=$(for d in $o_repos; do echo ${d%/.git}; done)
o_packd=$HOME/packed

st() {
	for d in $o_repod; do
		echo "### $d"
		(cd $d; git status -s --porcelain)
	done
}

cl() {
	for d in $o_repod; do
		echo "### $d"
		(cd $d; git clean -fdx)
	done
}

pl() {
	for d in $o_repod; do
		echo "### $d"
		(cd $d; git checkout master; git pull)
	done
}

gc() {
	for d in $o_repod; do
		echo "### $d"
		(cd $d; git gc --prune=all)
	done
}

pk() {
	mkdir -p $o_packd
	for d in $o_repod; do
		echo "### $d"
		n=$(basename $d).$(cd $d; git rev-list --oneline --pretty='%cd.%h' --date=short  -1 HEAD | tail -n1).tar.xz
		f="$o_packd/$n"
		[ -s "$f" ] && continue
		rm -vf "$f.t"
		XZ_OPT=-T0 tar -cJf "$f.t" "${d#$PWD/}/.git"
		mv "$f.t" "$f"
	done
}

rs() {
	[ -d "$o_packd" ] || return 1
	mkdir -p "$o_grepo"
	for f in "$o_packd"/*; do
		echo "### $f"
		tar -C "$o_grepo" -xJf "$f"
	done
}

_() {
	for i in "$@"; do
		"$i"
	done
}

"$@"
