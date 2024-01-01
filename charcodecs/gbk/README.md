This program tries to convert dir/file names from being gb18030-encoded to
utf8-encoded.

This is mostly needed after files were transfered from an old Windows host to
Linux systems.

The program accepts a single argument, either it be a directory or regular
file.  It will recursively operate on all entries in that directory (including
the directory itself) in a depth-first way
