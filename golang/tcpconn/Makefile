export TOPDIR:=$(CURDIR)
export BUILDDIR:=$(TOPDIR)/build

empty:=
space:=$(empty) $(empty)
tab:=$(empty)	$(empty)
define newline


endef

SUPPORTED_PLATFORMS := \
	linux-amd64 \
	linux-arm64 \
	linux-mips \
	linux-mipsle \
	darwin-amd64 \

all: build
.PHONY: all
.PHONY: build

$(BUILDDIR):
	mkdir -p $(BUILDDIR)

define Build
$(eval goos   := $(word 1,$(subst -, ,$(1))))
$(eval goarch := $(word 2,$(subst -, ,$(1))))

build: build-$(goos)-$(goarch)

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
