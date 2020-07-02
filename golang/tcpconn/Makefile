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

MAKE_TARGETS:=

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

MAKE_TARGETS += build-$(goos)-$(goarch)
MAKE_TARGETS += build-$(goos)
MAKE_TARGETS += build-$(goarch)

endef

$(eval $(foreach plat,$(SUPPORTED_PLATFORMS),$(call Build,$(plat))))

help:
	@echo Supported targets
	@echo ""
	@$(foreach t,$(sort $(MAKE_TARGETS)),echo "$(tab)$(t)";)
.PHONY: help

%:
	@echo Unknown target: $*
	@$(MAKE) -s help

clean:
	rm -rv $(BUILDDIR)
.PHONY: clean
