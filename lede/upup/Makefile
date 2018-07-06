#
# Copyright (C) 2017 Yousong Zhou <yszhou4tech@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=upup
PKG_RELEASE:=6

include $(INCLUDE_DIR)/package.mk

define Package/upup
  SECTION:=net
  CATEGORY:=Network
  TITLE:=upup managing the bridge link
  MAINTAINER:=Yousong Zhou <yszhou4tech@gmail.com>
endef

define Build/Compile
endef

define Package/upup/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/upup $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/upup.init $(1)/etc/init.d/upup
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/upup.config $(1)/etc/config/upup
endef

$(eval $(call BuildPackage,upup))
