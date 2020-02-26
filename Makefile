# Make file for building Colibri-VF50 u-boot, kernel, rootfs.

TOP := $(CURDIR)

# Build defaults that can be overwritten by the CONFIG file if present

BUILD_TOP = $(TOP)/build

U_BOOT_TAG = 2016.11-toradex
KERNEL_TAG = toradex_vf_4.4

TOOLCHAIN = $(TOP)/TOOLCHAIN

DEFAULT_TARGETS += boot


# The following symbols are not given defaults but must be specified in the
# CONFIG file.
REQUIRED_SYMBOLS += ROOTFS_TOP
REQUIRED_SYMBOLS += TAR_FILES
REQUIRED_SYMBOLS += UPGRADE_ROOT
# These must be defined in the TOOLCHAIN file.
REQUIRED_SYMBOLS += BINUTILS_DIR
REQUIRED_SYMBOLS += COMPILER_PREFIX
REQUIRED_SYMBOLS += SYSROOT

include CONFIG
include $(TOOLCHAIN)

ARCH = arm

# Both kernel and u-boot builds need CROSS_COMPILE and ARCH to be exported
EXPORTS = $(call EXPORT,CROSS_COMPILE ARCH)


BUILD_ROOT = $(BUILD_TOP)/build
SRC_ROOT = $(BUILD_TOP)/src
TOOLKIT_ROOT = $(BUILD_TOP)/toolkit
BOOT_ROOT = $(BUILD_TOP)/boot

export GIT_VERSION_SUFFIX = \
    $(shell git describe --abbrev=7 --dirty --always --tags)
export CROSS_COMPILE = $(COMPILER_PREFIX)-
export PATH := $(BINUTILS_DIR)/bin:$(TOOLKIT_ROOT)/bin:$(PATH)


# ------------------------------------------------------------------------------
# Source file definitions

# This file was generated by:
#  $ git clone git://git.kernel.org/pub/scm/utils/dtc/dtc.git
#  $ cd dtc
#  $ git archive v1.4.1 --prefix=dtc-1.4.1/ |
#    gzip - > dtc-1.4.1.tgz
# Note, it looks like we don't want to use 1.5 as this generates a lot of
# warnings about the device tree syntax, so presumably the syntax has changed.
MD5_SUM_dtc-1.4.1 = 9b7705a019efa74674b5cffb61b74145

# This file was generated by:
#  $ git clone git://git.toradex.com/u-boot-toradex.git
#  $ cd u-boot-toradex
#  $ git archive origin/2016.11-toradex --prefix=u-boot-2016.11-toradex/ |
#    gzip - > u-boot-2016.11-toradex.tgz
MD5_SUM_u-boot-2016.11-toradex = 04f26e0133da6ad8ab16acdd31af48d7

# This file was generated by:
#  $ git clone git://git.toradex.com/linux-toradex.git
#  $ cd linux-toradex
#  $ git archive origin/toradex_vf_4.4 --prefix=linux-toradex_vf_4.4/ |
#    gzip - > linux-toradex_vf_4.4.tgz
MD5_SUM_linux-toradex_vf_4.4 = 4130c62297b335159986ea258121794a

# This file was downloaded from:
#   ftp://ftp.infradead.org/pub/mtd-utils/mtd-utils-2.1.0.tar.bz2
MD5_SUM_mtd-utils-2.1.0 = 91e399e2f698caff01e9b0f4ca1b59cc


# ------------------------------------------------------------------------------
# Helper code lifted from rootfs and other miscellaneous functions

# Perform a sanity check: make sure the user has defined all the symbols that
# need to be defined.
define _CHECK_SYMBOL
    ifndef $1
        $1 = $$(error Must define symbol $1 in CONFIG)
    endif
endef
CHECK_SYMBOL = $(eval $(_CHECK_SYMBOL))
$(foreach sym,$(REQUIRED_SYMBOLS),$(call CHECK_SYMBOL,$(sym)))


# Function for safely quoting a string before exposing it to the shell.
# Wraps string in quotes, and escapes all internal quotes.  Invoke as
#
#   $(call SAFE_QUOTE,string to expand)
#
SAFE_QUOTE = '$(subst ','\'',$(1))'

# )' (Gets vim back in sync)

# Passing makefile exports through is a bit tiresome.  We could mark our
# symbols with export -- but that means *every* command gets them, and I
# don't like that.  This macro instead just exports the listed symbols into a
# called function, designed to be called like:
#
#       $(call EXPORT,$(EXPORTS)) script
#
EXPORT = $(foreach var,$(1),$(var)=$(call SAFE_QUOTE,$($(var))))

# Use the rootfs extraction tool to decompress our source trees.  We ensure that
# the source root is present.  Call thus:
#
#       $(call EXTRACT_FILE,target-name,extension)
#
define EXTRACT_FILE
mkdir -p $(SRC_ROOT)
$(ROOTFS_TOP)/scripts/extract-tar $(SRC_ROOT) $1.$2 $(MD5_SUM_$1) $(TAR_FILES)
endef


# ------------------------------------------------------------------------------
# Basic rules

default: $(DEFAULT_TARGETS)
.PHONY: default

clean:
	rm -rf $(BUILD_ROOT)
.PHONY: clean

clean-src:
	-chmod -R +w $(SRC_ROOT)
	rm -rf $(SRC_ROOT)
.PHONY: clean-src

clean-driver:
	$(EXPORTS) $(MAKE) -C $(KERNEL_BUILD) SUBDIRS=$(LOAD_FPGA_BUILD_DIR) \
            clean
	rm -rf $(DRIVERS_O)

clean-all: clean clean-src clean-driver
	rm -rf $(BUILD_TOP)
.PHONY: clean-all


# ------------------------------------------------------------------------------
# Building Device Tree Compiler
#
# This is a dependency of the u-boot build.

DTC = $(TOOLKIT_ROOT)/bin/dtc

DTC_NAME = dtc-1.4.1
DTC_SRC = $(SRC_ROOT)/$(DTC_NAME)
DTC_BUILD = $(BUILD_ROOT)/dtc


$(DTC):
	$(call EXTRACT_FILE,$(DTC_NAME),tgz)
	mkdir -p $(BUILD_ROOT)
	# Image the source into the build directory so we can build out of tree
	cp -Rs --no-preserve=mode $(DTC_SRC) $(DTC_BUILD)
	make -C $(DTC_BUILD)
	make -C $(DTC_BUILD) PREFIX=$(TOOLKIT_ROOT) install

dtc: $(DTC)
.PHONY: dtc


# ------------------------------------------------------------------------------
# Building u-boot
#

U_BOOT_NAME = u-boot-$(U_BOOT_TAG)
U_BOOT_SRC = $(SRC_ROOT)/$(U_BOOT_NAME)
U_BOOT_BUILD = $(BUILD_ROOT)/u-boot

U_BOOT_IMAGE = $(U_BOOT_BUILD)/u-boot-nand.imx
FW_PRINTENV = $(U_BOOT_BUILD)/tools/env/fw_printenv

MAKE_U_BOOT = $(EXPORTS) KBUILD_OUTPUT=$(U_BOOT_BUILD) $(MAKE) -C $(U_BOOT_SRC)


$(U_BOOT_SRC):
	$(call EXTRACT_FILE,$(U_BOOT_NAME),tgz)
	chmod -R a-w $(U_BOOT_SRC)

$(U_BOOT_IMAGE): $(DTC) $(U_BOOT_SRC)
	mkdir -p $(U_BOOT_BUILD)
	$(MAKE_U_BOOT) colibri_vf_defconfig
	$(MAKE_U_BOOT)
	mkdir -p $(TOOLKIT_ROOT)/bin
	cp $(U_BOOT_BUILD)/tools/mkimage $(TOOLKIT_ROOT)/bin

$(FW_PRINTENV): $(U_BOOT_SRC)
	$(MAKE_U_BOOT) env


u-boot: $(U_BOOT_IMAGE)
.PHONY: u-boot


# ------------------------------------------------------------------------------
# Kernel
#

KERNEL_NAME = linux-$(KERNEL_TAG)
KERNEL_SRC = $(SRC_ROOT)/$(KERNEL_NAME)
KERNEL_BUILD = $(BUILD_ROOT)/linux

ZIMAGE = $(KERNEL_BUILD)/arch/arm/boot/zImage
KERNEL_DTS_DIR = $(KERNEL_BUILD)/arch/arm/boot/dts/
KERNEL_DTB = $(KERNEL_DTS_DIR)/device-tree.dtb

MAKE_KERNEL = $(EXPORTS) KBUILD_OUTPUT=$(KERNEL_BUILD) $(MAKE) -C $(KERNEL_SRC)

$(KERNEL_SRC):
	$(call EXTRACT_FILE,$(KERNEL_NAME),tgz)
	chmod -R a-w $(KERNEL_SRC)

$(KERNEL_BUILD)/.config: kernel/dot.config $(KERNEL_SRC)
	mkdir -p $(KERNEL_BUILD)
	cp $< $@
	$(MAKE_KERNEL) -j4 oldconfig

$(ZIMAGE): $(KERNEL_BUILD)/.config
	$(MAKE_KERNEL) zImage
	touch $@

$(KERNEL_DTB): kernel/device-tree.dts kernel/dls-dps.dtsi
	mkdir -p $(KERNEL_DTS_DIR)
	cp $^ $(KERNEL_DTS_DIR)
	$(MAKE_KERNEL) device-tree.dtb

kernel-menuconfig: $(KERNEL_BUILD)/.config
	$(MAKE_KERNEL) menuconfig
	cp $< kernel/dot.config
.PHONY: kernel-menuconfig

kernel-src: $(KERNEL_SRC)
kernel: $(ZIMAGE)
dtb: $(KERNEL_DTB)
.PHONY: kernel-src kernel dtb


# ------------------------------------------------------------------------------
# MTD tools
#
# We need some mtd tools for UBI filesystem generation for initial installation.

MKFS_UBIFS = $(TOOLKIT_ROOT)/bin/mkfs.ubifs

MTD_UTILS_NAME = mtd-utils-2.1.0
MTD_UTILS_SRC = $(SRC_ROOT)/$(MTD_UTILS_NAME)
MTD_UTILS_PATCH = patches/mkfs.ubifs.symlink.patch

MTD_UTILS_CONFIG_OPTS += --without-tests
MTD_UTILS_CONFIG_OPTS += --without-lsmtd
MTD_UTILS_CONFIG_OPTS += --without-jffs
MTD_UTILS_CONFIG_OPTS += --without-lzo
MTD_UTILS_CONFIG_OPTS += --without-selinux
MTD_UTILS_CONFIG_OPTS += --without-openssl

MTD_UTILS_BUILD = $(BUILD_ROOT)/mtd-utils

$(MTD_UTILS_SRC):
	$(call EXTRACT_FILE,$(MTD_UTILS_NAME),tar.bz2)
	patch -d $(MTD_UTILS_SRC) -p1 < $(MTD_UTILS_PATCH)
	chmod -R a-w $(MTD_UTILS_SRC)

$(MKFS_UBIFS): $(MTD_UTILS_SRC)
	mkdir -p $(MTD_UTILS_BUILD)
	cd $(MTD_UTILS_BUILD)  &&  \
            PKG_CONFIG_PATH=$(shell pkg-config --variable pc_path pkg-config) \
            $(MTD_UTILS_SRC)/configure $(MTD_UTILS_CONFIG_OPTS)
	make -C $(MTD_UTILS_BUILD)
	install $(MTD_UTILS_BUILD)/mkfs.ubifs $@

mtd-utils: $(MKFS_UBIFS)
.PHONY: mtd-utils


# ------------------------------------------------------------------------------

DRIVERS_SRC := $(TOP)/drivers
LOAD_FPGA_SRC := $(DRIVERS_SRC)/dfl

DRIVERS_BUILD_DIR = $(BUILD_ROOT)/drivers
LOAD_FPGA_BUILD_DIR = $(DRIVERS_BUILD_DIR)/dfl
LOAD_FPGA = $(LOAD_FPGA_BUILD_DIR)/dls_fpga_loader.ko
DRIVERS_O := $(BUILD_TOP)/drivers


$(LOAD_FPGA_BUILD_DIR): $(LOAD_FPGA_SRC)
	mkdir -p "$(LOAD_FPGA_BUILD_DIR)"
	cp -s -r -f "$(LOAD_FPGA_SRC)" "$(DRIVERS_BUILD_DIR)"

$(LOAD_FPGA): $(ZIMAGE) $(LOAD_FPGA_BUILD_DIR)
	$(EXPORTS) $(MAKE) -C $(KERNEL_BUILD) M=$(LOAD_FPGA_BUILD_DIR) \
            modules

$(DRIVERS_O): $(LOAD_FPGA)
	mkdir -p $(DRIVERS_O)
	$(EXPORTS) $(MAKE) -C $(KERNEL_BUILD) M=$(LOAD_FPGA_BUILD_DIR) \
            modules_install INSTALL_MOD_PATH=$(DRIVERS_O)
	touch $@


# ------------------------------------------------------------------------------
# File system building
#
# This is the installed target file system

ROOTFS_O = $(BUILD_TOP)/targets/rootfs

# To handle make's requirement to have a single build target, we depend on the
# rootfs image directory.  This is rebuilt each time and contains all the target
# files we will want.
ROOTFS_IMAGE = $(ROOTFS_O)/image

# All these files are generated when we build the rootfs.
ROOTFS_FILES += $(ROOTFS_IMAGE)/imagefile.cpio.gz
ROOTFS_FILES += $(ROOTFS_IMAGE)/rootfs.img
ROOTFS_FILES += $(ROOTFS_IMAGE)/state.img
ROOTFS_FILES += $(ROOTFS_IMAGE)/initramfs-script.image
ROOTFS_FILES += $(ROOTFS_IMAGE)/install-script.image
ROOTFS_FILES += $(ROOTFS_IMAGE)/upgrade-script.image


# Command for building rootfs.  Need to specify both action and target name.
MAKE_ROOTFS = \
    $(call EXPORT,TOOLCHAIN FW_PRINTENV) $(ROOTFS_TOP)/rootfs \
        -f '$(TAR_FILES)' -r $(BUILD_TOP) -t $(CURDIR)/rootfs

ROOTFS_IMAGE_DEPENDS += $(MKFS_UBIFS)
ROOTFS_IMAGE_DEPENDS += $(U_BOOT_IMAGE)
ROOTFS_IMAGE_DEPENDS += $(FW_PRINTENV)
ROOTFS_IMAGE_DEPENDS += $(shell find rootfs -type f)
ROOTFS_IMAGE_DEPENDS += $(DRIVERS_O)

# We have a dependency on u-boot so that the mkimage command is available
$(ROOTFS_IMAGE): $(ROOTFS_IMAGE_DEPENDS)
	$(call MAKE_ROOTFS) make DRIVERS_O=$(DRIVERS_O)

$(ROOTFS_FILES): $(ROOTFS_IMAGE)

rootfs: $(ROOTFS_IMAGE)
.PHONY: rootfs


# The following targets are to make it easier to edit the busybox configuration.
#
busybox-menuconfig: $(ROOTFS_O)/build/busybox
	$(call MAKE_ROOTFS) package busybox menuconfig
.PHONY: busybox-menuconfig

$(ROOTFS_O)/build/busybox:
	$(call MAKE_ROOTFS) package busybox KEEP_BUILD=1

busybox-keep: $(ROOTFS_O)/build/busybox
.PHONY: busybox-keep


# ------------------------------------------------------------------------------
# Boot image
#
# Gathers together all the files needed to boot, install, or upgrade the target
# system.

BOOT_FILES += $(U_BOOT_IMAGE)
BOOT_FILES += $(ZIMAGE)
BOOT_FILES += $(KERNEL_DTB)
BOOT_FILES += $(ROOTFS_FILES)

boot: $(BOOT_FILES)
	rm -rf $(BOOT_ROOT)
	mkdir -p $(BOOT_ROOT)
	cp $^ $(BOOT_ROOT)
.PHONY: boot


# The upgrade target installs the files necessary for upgrading in the TFTP
# server.
UPGRADE_FILES += upgrade-script.image
UPGRADE_FILES += zImage
UPGRADE_FILES += device-tree.dtb
UPGRADE_FILES += rootfs.img
UPGRADE_FILES += state.img

upgrade: $(BOOT_FILES) boot
	for f in $(UPGRADE_FILES); do \
            cp $(BOOT_ROOT)/$$f $(UPGRADE_ROOT)/$(GIT_VERSION_SUFFIX)-$$f; \
        done
	@echo
	@echo Upgrade files are version: $(GIT_VERSION_SUFFIX)
	@echo
.PHONY: upgrade


# ------------------------------------------------------------------------------
# Documentation

docs:
	make -C docs
.PHONY: docs

clean-docs:
	make -C docs clean
.PHONY: clean-docs
