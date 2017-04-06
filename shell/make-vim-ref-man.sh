#
# A complete VIM REFERENCE MANUAL can be handy when we need to write new or edit existing vimscripts.
#
# If zsh complains "cat: xxx : File name too long", do the following
#
#     setopt sh_wordsplit
#
docdir="$HOME/.usr/share/vim/vim74/doc"
refman="vim-ref-man.txt"

rm -f "$refman"
awk -F '|' '
	/^REFERENCE MANUAL/ { p=1 }
	$2 ~ /\w+\.txt$/ { if (p) printf "%s\n", $2 }
' "$docdir/help.txt" \
	| while read f; do
		cat "$docdir/$f" >>"$refman"
	done
