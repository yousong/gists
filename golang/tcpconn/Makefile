export TOPDIR:=$(CURDIR)
export BUILDDIR:=$(TOPDIR)/build

empty:=
space:=$(empty) $(empty)
tab:=$(empty)	$(empty)
define newline


endef

GOOS:=$(shell go env GOOS)
GOARCH:=$(shell go env GOARCH)
SUPPORTED_PLATFORMS := \
	linux-amd64 \
	linux-arm64 \
	linux-mips \
	linux-mipsle \
	darwin-amd64 \

all: build-native
build-all:
.PHONY: all
.PHONY: build-all

build-native: $(BUILDDIR)/tcpconn
$(BUILDDIR)/tcpconn: build-$(GOOS)-$(GOARCH)
	ln -sf tcpconn.$(GOOS)-$(GOARCH) $(BUILDDIR)/tcpconn
.PHONY: build-native

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

define Build
$(eval goos   := $(word 1,$(subst -, ,$(1))))
$(eval goarch := $(word 2,$(subst -, ,$(1))))

build-all: build-$(goos)-$(goarch)

build-$(goos)-$(goarch): | $(BUILDDIR)
build-$(goos)-$(goarch):
	GOOS=$(goos) GOARCH=$(goarch) go build -o $(BUILDDIR)/tcpconn.$(goos)-$(goarch) .
.PHONY: build-$(goos)-$(goarch)

build-$(goos): build-$(goos)-$(goarch)
build-$(goarch): build-$(goos)-$(goarch)
.PHONY: build-$(goos)
.PHONY: build-$(goarch)

MAKE_TARGETS_build-os-arch += build-$(goos)-$(goarch)
MAKE_TARGETS_build-os += build-$(goos)
MAKE_TARGETS_build-arch += build-$(goarch)

endef

$(eval $(foreach plat,$(SUPPORTED_PLATFORMS),$(call Build,$(plat))))
MAKE_TARGETS := \
	build-all \
	$(sort $(MAKE_TARGETS_build-arch)) \
	$(sort $(MAKE_TARGETS_build-os)) \
	$(sort $(MAKE_TARGETS_build-os-arch)) \


help:
	@echo Supported targets
	@echo ""
	@$(foreach t,$(MAKE_TARGETS),echo "$(tab)$(t)";)
.PHONY: help

%:
	@echo Unknown target: $*
	@$(MAKE) -s help
	@false

clean:
	rm -rv $(BUILDDIR)
.PHONY: clean
