#!python -B
#
# -B     Don't write .py[co] files on import. See also PYTHONDONTWRITEBYTECODE.
#
import imp
conf = imp.load_source('modname', '/etc/file.conf')
print conf.enable_xxx
