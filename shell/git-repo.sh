o_grepo=$HOME/git-repo
o_repos=$(find $o_grepo -maxdepth 3 -name .git -type d)
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
	mkdir -p $o_packed
	for d in $o_repod; do
		echo "### $d"
		n=$(basename $d).$(cd $d; git rev-list --oneline --pretty='%cd.%h' --date=short  -1 HEAD | tail -n1).tar.xz
		f="$o_packed/$n"
		[ -s "$f" ] && continue
		rm -vf "$f.t"
		XZ_OPT=-T0 tar -cJf "$f.t" "${d#$PWD/}/.git"
		mv "$f.t" "$f"
	done
}

rs() {
	[ -d "$o_packed" ] || return 1
	mkdir -p "$o_grepo"
	for f in "$o_packed"/*; do
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
