.. _building:

Building Colibri Base System
============================

Configuring Build
-----------------

Building the Colibri base system requires the preparation of a number of
prerequisites, which are then located via keys in the ``CONFIG`` and
``TOOLCHAIN`` files.

The following keys must be set in ``CONFIG``:

``ROOTFS_TOP``
    This must point to a copy of the DLS `rootfs`_.  At the time of writing
    release 1.12 is the correct version to use.

``BUILD_TOP``
    This must point to a workspace with around 2GB of free space.  The build
    will occur under this directory.

``TAR_FILES``
    This must point to one or more directories containing the source tar files
    used to build the base system.  The required tar files are listed below.

The following keys must be set in ``TOOLCHAIN``:

``BINUTILS_DIR``
    This must point to the base directory of the compiler toolchain.  We use the
    Toradex recommended toolchain which is downloaded from `gcc-linaro`_.  This
    is gcc 6.2.1 targetting the ARMv7 (suitable for A5).

``COMPILER_PREFIX``
    This defines the architecture target and must be the compiler prefix defined
    by the toolchain.  In our application this should be set to
    ``arm-linux-gnueabihf``.

``SYSROOT``
    This defines the location of the system root defined by the compiler
    toolchain, and should be set to::

        $(BINUTILS_DIR)/$(COMPILER_PREFIX)/libc

Required Source Files
---------------------

The following files must be present in the ``TAR_FILES`` directory with the
corresponding matching MD5 sum values.

=================================== ============================================
Compressed Source File              MD5 Checksum
=================================== ============================================
busybox-1.31.0.tar.bz2              ``cdba5d4458f944ceec5cdcf7c4914b69``
conserver-8.2.0.tar.gz              ``bb13834970c468f73415618437f3feac``
dropbear-2015.67.tar.bz2            ``e967e320344cd4bfebe321e3ab8514d6``
dtc-1.4.1.tgz                       ``9b7705a019efa74674b5cffb61b74145``
ethtool-2.6.36.tar.gz               ``3b2322695e9ee7bf447ebcdb85f93e83``
iperf-3.0.2.tar.gz                  ``5154c00201d599acc00194c6c278ca23``
linux-toradex_vf_4.4.tgz            ``4130c62297b335159986ea258121794a``
lsof_4.88.tar.bz2                   ``1b29c10db4aa88afcaeeaabeef6790db``
mtd-utils-2.1.0.tar.bz2             ``91e399e2f698caff01e9b0f4ca1b59cc``
nano-2.4.1.tar.gz                   ``1c612b478f976abf8ef926480c7a3684``
ncurses-5.9.tar.gz                  ``8cb9c412e5f2d96bc6f459aa8c6282a1``
ntp-4.2.8p2.tar.gz                  ``fa37049383316322d060ec9061ac23a9``
procServ-2.6.0.tar.gz               ``bbf052e7fcc6fa403d2514219346da04``
readline-6.3.tar.gz                 ``33c8fb279e981274f485fd91da77e94a``
screen-4.2.1.tar.gz                 ``419a0594e2b25039239af8b90eda7d92``
strace-4.10.tar.xz                  ``107a5be455493861189e9b57a3a51912``
u-boot-2016.11-toradex.tgz          ``04f26e0133da6ad8ab16acdd31af48d7``
zlib-1.2.8.tar.gz                   ``44d667c142d7cda120332623eab69f40``
=================================== ============================================

..  note::

    As noted in :ref:`overview`, some of these components may be dropped from
    the rootfs in the future.


Building
--------

Run ``make`` in the top level directory and the completely system will be built
and assembled into ``$(BUILD_TOP)/boot``.  This directory contains the following
files:

=========================== ====================================================
File                        Description
=========================== ====================================================
``device-tree.dtb``         Device tree for kernel, needed for booting, install,
                            and upgrade.
``imagefile.cpio.gz``       Rootfs file system in format for booting from SD
                            card.
``initramfs-script.image``  U-Boot script for booting from SD card..
``install-script.image``    U-Boot script for initial install.
``rootfs.img``              Rootfs image for initial install or upgrade.
``state.img``               State file system image for install or upgrade.
``u-boot-nand.imx``         U-Boot image for initial reflash from WinCE.
``upgrade-script.image``    U-Boot script for upgrade.
``zImage``                  Kernel image, needed for booting, install, and
                            upgrade.
=========================== ====================================================

For simplicity all these files should be copied to an SD card for initial
installation or booting from the SD card (during development only).  For
upgrades of a live system see :ref:`upgrading`.

The following further directories are created under ``$(BUILD_TOP)``:

``boot``
    Final build files, described above.

``build``
    Working build directories.  The rootfs build automatically deletes the build
    directories of its components, but other builds generated directly by the
    top level make file remain here.

``src``
    All the source files are extracted here and are marked read-only to prevent
    accidential overwriting during the build process.  To remove this directory
    run the ``make clean-src`` target.

``toolkit``
    A number of utilities (``mkimage``, ``dtc``, ``mkfs.ubifs``) are built and
    installed here.  If a pre-built rootfs is not used then it will build and
    install a number of further utilities (tar files for these will also be
    required, and are not listed above).

``targets/rootfs``
    The entire rootfs is assembled here.  This directory contains the following
    further directories of interest:

    ``roofs``
        The entire target root filesystem is assembled here, with any special
        permission overrided recorded in ``fakeroot.env``.

    ``state``
        The initial version of the state filesystem is assembled here.
        Initially this contains the ``network-*.config`` files and
        ``upgrade.config``.

    ``staging``
        Installable components are placed here and installed into the target
        ``rootfs`` directory as appropriate.


..  _rootfs:
    https://github.com/Araneidae/rootfs

..  _gcc-linaro:
     https://releases.linaro.org/components/toolchain/binaries/\
         6.2-2016.11/arm-linux-gnueabihf/
