# Demo for example usage of OpenWrt/LEDE BuildOverlay.
#
# Originally posted to lede-dev mailing list through a link to github gist:
# https://gist.github.com/yousong/1df4fcee324dd6b6095e6b551e2806a9
#
# The file needs to be named as $(PKG_DIR_NAME).mk and placed in a subdir of $(TOPDIR)/overlay/

# Place an empty line at the end of "pre" definition
define Package/hello/install/pre
	echo 'install/pre: $(1)'

endef

# Place an empty line at the begining of "post" definition
define Package/hello/install/post

	echo 'install/after: $(1)'
endef

# Store the original "install" definition to work around recursive expansion
# issue.  This is not necessary if only "post" hook is needed.
Package/hello/install/orig := $(Package/hello/install)

# backslash for line continuation won't work as it will prepend blank spaces
# to each line of recipes
#
#Package/hello/install=\
#	$(Package/hello/install/pre)\
#	$(Package/hello/install/orig)\
#	$(Package/hello/install/post)
#

Package/hello/install=$(Package/hello/install/pre)$(Package/hello/install/orig)$(Package/hello/install/post)
