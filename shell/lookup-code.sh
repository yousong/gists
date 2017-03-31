# lc for lookup-code, a poor man's searcher (see the_silver_searcher (ag) as one for millionaires').
#
#  ag will use VCS ignore file by default (-U to ignore VCS ignore file).
#
function lc () {
  # Note that this is intended for OpenWrt, directories like ./bin will not be searched by default.
  pattern="$1"
  search_root="${2:-$(pwd)}"

  # Tricks on the `find` command.
  #
  #  - `-P`, do not follow symlink
  #  - `find` evaluates its verdicts, which are combined together by default
  #     with `-and`, from left to right, until false or the end should be
  #     encountered.
  #  - That's why when the first `\( ... \)` is false, the
  #     following `-prune` will be skipped while verdicts after `-o` will be
  #     used.
  #  - The final `-print0` is for directories like `./.svn`, which would be
  #    `-print`-ed if there is only `-prune` present as actions on the command
  #    line.
  #  - That operator `-and` has higher precedence over `-o` is also part of
  #    the reason why directories like `./.svn` won't be scanned.
  #  - `-o` instead of `-or` is for POSIX compatibility
  #
  # Tricks on the `grep` command
  #  - `-n`, displaying line numbers.
  #  - `-e`, is for patterns that start with dash character.
  #
  # `-print0` of `find` and `-0` of `xargs` are for resilient against wobbled binary chars in filenames.
  find -P "$search_root" \( \
			-path "$(pwd)/build_dir" \
			-o -path "$(pwd)/bin" \
			-o -path "$(pwd)/dl" \
			-o -path "$(pwd)/tmp" \
			-o -path "$(pwd)/staging_dir" \
			-o -path "$(pwd)/feeds" \
			-o -path "$(pwd)/docs" \
			-o \( -type d -and -path "$(pwd)/.*/.*" \) \
		\) -prune \
		-o \( \
			-type f \
		\) -print0 \
  | xargs -0 grep --color=auto -n -e "$pattern"
}
