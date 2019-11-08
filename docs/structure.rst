..  _structure:

Organisation of Sources
=======================

The sources are organised into the following sections:

`Makefile`_
    This coordinates the building of U-Boot, the kernel, and the rootfs, and
    assembling the final result into the ``$(BUILD_TOP)/boot`` directory.

``docs/``
    The documentation is built using ``sphinx-build``.

``kernel/``
    This directory contains the kernel configuration and the `device tree`_
    definition.

``patches/``
    One patch to the ``mkfs.ubifs`` tool build is needed.

`rootfs`_
    This defines the root file system, the detailed structure of this is defined
    below.


..  _Makefile:

``Makefile``
------------

The top level make file coordinates building all components.  The default target
``boot`` triggers assembly of the ``$(BUILD_TOP)/boot`` directory.  This file is
organised into the following sections:

Configuration
    Defaults are defined and the top level ``CONFIG`` and ``TOOLCHAIN`` files
    are loaded.

Special Sources
    Source file definitions for the device tree compiler (``dtc``), MTD
    utilities (for ``mkfs.ubifs``), and U-Boot and the kernel are defined here.
    All other source file definitions are part of the configured rootfs defined
    by ``$(ROOTFS_TOP)``.

Helper scripts and basic rules
    A number of special macros are lifted from rootfs here, and we define the
    basic targets.

Device Tree Compiler
    This is need for U-Boot and the kernel.  We need to use a particular version
    of the DTC to be compatible with our kernel.

U-Boot and Kernel
    Both U-Boot and the kernel are built from Toradex maintained versions with
    no patches.  The kernel configuration (stored in ``kernel/dot.config``) has
    been customised to our application.  A special make target ``make
    kernel-menuconfig`` supports editing the kernel configuration.

MTD tools
    These need to be built before the rootfs can be built.

Rootfs build
    Control is handed over to ``$(ROOTFS_TOP)/rootfs`` for this part of the
    build; see `rootfs`_ below for details.

Boot image and upgrade
    The default ``boot`` target assembles the boot files.  The special
    ``upgrade`` target pushes all files required for performing a system upgrade
    to the upgrade server.


..  _device tree:

Device Tree
-----------

The device tree configuration is complex and rather opaque.  Our device tree is
based on the Toradex configuration with local modifications to support the DPS
card.  The base kernel device tree definition files can be found in the
directory ``arch/arm/boot/dts`` under the linux kernel sources.

The base configuration is ``vf500-colibri.dtsi``, this defines a complete
configuration of the available IOs provided by the Colibri-VF50 module.  This is
then modified by our file ``dls-dps.dtsi`` which enables the standard components
and configures the non-default components.

=========== =============== ====================================================
Component   Role            Comments
=========== =============== ====================================================
uart0       Serial Console  Needs enabling.
fec1        Ethernet        Needs enabling and connecting to existing pins.
dspi0       SPI to DPS      Needs enabling, connecting to new pin configuration,
                            and specific enabling of CS3.  Also note that the
                            ``toradex,evalspi`` driver must be selected.
dspi1       SPI to SIC      Needs enabling and connecting to exisiting pins,
                            must use same driver as dspi0.
i2c0        I2C to sensor   Enabled, temperature sensor driver connected.
adc0, adc1  Internal ADCs   Needs enabling.
=========== =============== ====================================================

GPIO configuration is surprisingly complicated, see notes in :ref:`development`.


..  _rootfs:

Rootfs
------

The rootfs configuration is driven by the file ``rootfs/CONFIG``.  This defines
a list of ``PACKAGES`` to be installed in the rootfs together with a number of
``OPTIONS``.  Three of the options are local to ``rootfs`` and are described
further below.  Finally the ``BOOT`` definition is local and described below.

The following three local ``OPTIONS`` entries define customisations to the
installed rootfs.

``skeleton``
    This option manages changes to the core skeleton of the rootfs file system
    and also manages assembly of the separate ``state`` filesystem.

``network``
    All network configuration files are installed by this option.  Configuration
    is complicated by the fact that most of the rootfs is read-only, so further
    changes to the skeleton are implemented here.  This option also manages and
    installs the ``network-*.config`` files.

``upgrade``
    The ``upgrade-rootfs`` tool is installed by this option.

The following local ``BOOT`` definition manages the assembly of the final image
files.

``install``
    This stage of the build is run last after the complete rootfs has been
    assembled.  The main driving dependency here is ``$(O)/imagefile.cpio``,
    which is built last.

    This stage assembles the two UBIFS image files and the three U-Boot scripts
    needed to manage the system.  The scripts are as follows:

    ======================= ====================================================
    Script                  Description
    ======================= ====================================================
    ``install-script``      Reflashes target system and performs full install
    ``initramfs-script``    Used to load system into RAM and boot from SD card
    ``upgrade-script``      To be installed on tftp server for system upgrade
    ======================= ====================================================
