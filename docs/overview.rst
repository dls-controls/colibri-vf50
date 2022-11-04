.. _overview:

Introduction and Overview
=========================

The `Colibri Arm Family`_ consists of a series of SODIMM sized System on
Modules.  The `Colibri VF50`_ provides a single core A5 ARM with 128MB of RAM
and FLASH and is used to provide the control system for the Diamond `Digital
Power Supply`_.

The `DPS Rootfs`_ builder (this project) is used to assemble the core OS
functions required to support the EPICS `DPS IOC`_ (a separate project).

See :ref:`release_process` for the software release process, see
:ref:`upgrade-u-boot` for upgrading older versions of U-Boot.

Interfaces
----------

The Colibri module is fitted to the `SIC card`_ and communicates with the
hardware resources and external systems through the interfaces described below.

Serial Port
    The default serial port UART0 is used for configuration and logging.  This
    port is configured to run at 115200 baud and is connected to J4 (a Micro USB
    type B connector) on the front panel of the SIC card.  During normal
    operation this port will need to be connected to a terminal server with an
    attached conserver session for logging and access management.

Ethernet Port
    The ethernet port supports 10/100 Mb/s transfers and is used as the control
    system interface.  Both EPICS and ssh communication are supported on this
    interface.

SPI
    Two separate SPI interfaces are supported.  One connects to the on-board
    FPGA on the SIC card, the other to the FPGA on the DPS card.  The SPI
    interface to the SIC FPGA is on SPI0 channel 3 (device ``/dev/spidev0.3``)
    and the DPS FPGA is on SPI1 channel 0 (device ``/dev/spidev1.0``).

FPGA programming
    Both the SIC and DPS FPGAs can be programmed through dedicated GPIOs using
    the Xilinx configuration interface documented in `UG470`_.

I2C
    There is an I2C interface to an on-board temperature sensor, an `AD7414`_.
    This appears in the sysfs tree as a node under
    ``/sys/bus/i2c/devices/0-0048`` and the relevant sensor can be read from
    ``hwmon/hwmon0/temp1_input``.

ADC inputs
    The Colibri provides an integrated ADC.  Four voltage inputs are connected
    to the four available analogue inputs.  The ADC devices appear to be
    available under ``/sys/bus/iio/devices``, this needs a little more work.

Switch Sensors
    Four input switches are connected to four GPIOs.  These are read by the IOC
    during startup.


Software Architecture
---------------------

As supplied by the vendor (`Toradex`_) the Colibri modules come with Windows CE
installed.  This software is replaced by our own software stack, by the process
described here: :ref:`installing`.  The software installation consists of the
following components:

U-Boot
    This is the first software executed by the ARM processor after system reset,
    and is used for system installation and management as well as bringing up
    the Linux kernel.  The U-Boot image we install is as supported by Toradex
    and we use the default configuration.

    The Toradex branch of U-Boot is maintained here: `U-Boot-Toradex`_, and we
    use commit ``83a53c1c0c6`` with tag
    ``Colibri-VF_LXDE-Image_2.8b6.183-20190331`` dated 21 Feb 2019.

Linux
    Control is handed over to the Linux kernel by U-Boot, and this then runs the
    rest of our system.  The kernel version we use is supported by Toradex, and
    the configuration we use is stored under ``kernel/dot.config`` in this
    project.

    The Toradex branch of Linux is maintained here: `Linux-Toradex`_, and we use
    commit ``6f01eb5bf8e`` with tag ``Colibri-VF_LXDE-Image_2.8b6.183-20190331``
    dated 28 Mar 2019.

Root File System
    The file system managed by the kernel is installed on the Colibri FLASH and
    is managed as a number of `UBIFS`_ partitions.  The utilities on the rootfs
    are assembled from `busybox`_ (core utilities), `dropbear`_ (lightweight ssh
    server), `ntp`_ (time synchronisation), and a handful of other utilities.


Structure of Stored Data
~~~~~~~~~~~~~~~~~~~~~~~~

The 128MB of FLASH is first partitioned into the following `MTD`_ partitions
(partition sizes in hex, 126MB assigned to ``ubi``):

======= ======== ========== ====================================================
Device  Size     Name       Description
======= ======== ========== ====================================================
mtd0    00020000 vf-bcb     This appears to be part of the initial boot
mtd1    00160000 u-boot     U-Boot executable
mtd2    00080000 u-boot-env Environment for U-Boot
mtd3    07e00000 ubi        `UBIFS`_ partition containing rest of system
======= ======== ========== ====================================================

The ``ubi`` partition is subdivided into the following four volumes (sizes again
in hex):

======= ======== ========== ====================================================
Volume  Size     Name       Description
======= ======== ========== ====================================================
0       00400000 kernel     Kernel image loaded by U-Boot
1       00020000 dtb        Device tree used by kernel to identify hardware
2       00A00000 rootfs     Image of fixed root file system
3       -        state      Writeable file system state
======= ======== ========== ====================================================

The ``state`` volume is configured to occupy the rest of the partition and this
volume can be freely modified.  Only U-Boot is able to modify the ``rootfs``
partition.

The distribution of writeable or dynamic filesystems across the mounted root
filesystem is somewhat complex, and is summarised in the table below:

=========== =============== ====================================================
Mount       File system     Description
=========== =============== ====================================================
/dev        tmpfs           Device nodes managed by `mdev` and kernel hotplug
/dev/pts    devpts          Pseudoterminal multiplexor system, see `devpts`_
/dev/shm    tmpfs           Shared memory area for applications, see `SHM`_
/opt        ubi0:state      EPICS IOC and other applications are installed here
/proc       proc            Kernel managed files including process state files
/root       ubi0:state      Root login home directory
/sys        sysfs           Kernel managed device interface files
/tmp        tmpfs           Common temporary file storage
/var/lock   tmpfs           Run time lock files go here
/var/log    tmpfs           Some log files can go here
/var/run    tmpfs           Run time identification files go here
/var/state  ubi0:state      Persistent state files
=========== =============== ====================================================

..  note::

    Some discrepancies appear from the list above.

    1.  I'm not sure that ``/dev/shm`` is used or needed
    2.  There is no need for a separate ``/var/state``, can store all the state
        in the ``/opt`` directory tree.
    3.  Does ``/var`` need multiple separately mounted sub directories?  Why not
        make the entire directory in a tmpfs?


Boot Process and Startup
------------------------

Normal booting can be thought of as a four stage process:

1.  U-Boot loads the kernel and device tree and configures the kernel command
    line before handing control to the kernel.

2.  The Linux kernel initialises all hardware, mounts the root file system, and
    hands control over to the ``init`` process (while retaining overall control
    of the system).

3.  The ``init`` process executes a number of startup scripts for system
    configuration.

4.  The system application is finally ready to run.

U-Boot
~~~~~~

Booting is mediated by U-Boot which is the first program executed after reset or
power up.  By default U-Boot will then load and execute the kernel from the
appropriate UBIFS volumes, but booting can be manually interrupted, or U-Boot
can be configured for upgrading.  So at this stage there are four possible
options:

1.  By default U-Boot loads the kernel from ``ubi0:kernel`` and the device
    tree from ``ubi0:dtb`` and configures the kernel to load its root file
    system from ``ubi0:rootfs``.  This is done by setting the kernel command
    line to::

        ubi.mtd=ubi ubiargs=ubi.mtd=ubi root=ubi0:rootfs rootfstype=ubifs ro

2.  During development U-Boot can be interrupted and commanded to load the
    entire root file system (apart from the ``ubi0:state`` partitions) from an
    SD card by running the command ``run sdboot``.  This requires the use of a
    development board for access to the SD card.  In this case the kernel,
    device tree, and root file system are all loaded into memory from the SD
    card, and the kernel command line is set to::

        ubi.mtd=ubi rdinit=/sbin/init root=/dev/ram initrd=0x82100000,...

    where the last ``...`` is replaced with the computed size of the rootfs
    image file in memory.

3.  During upgrade U-Boot is reconfigured to load a complete system (kernel,
    device tree, rootfs, state files) from a tftp server.  During the upgrade
    process U-Boot rewrites the flash memory before finally triggering a normal
    boot into the upgraded system.

4.  During initial installation U-Boot can be interrupted and commanded to
    reformat the flash memory and to copy the complete system from the SD card
    onto flash.  This is a more invasive process, as the UBIFS is completely
    erased which resets the erase counters used for wear levelling; therefore a
    normal upgrade is preferable.

Kernel
~~~~~~

The kernel loads the device tree and initialises all the hardware drivers which
have been configured and which have entries in the device tree.  All relevant
logging is sent to the serial console and is cached in memory for access via the
``dmesg`` command line tool.  Control is then handed over to ``/sbin/init``
which will run as process 1, the `init`_ process.

Rootfs Startup
~~~~~~~~~~~~~~

The Busybox init process is configured by the file ``/etc/inittab``.  In our
system there are three lines of interest:

``::sysinit:/etc/init.d/rcS``
    This is run immediately on startup before running anything else.  The
    ``/etc/init.d/rcS`` script ensures that ``/dev`` is populated and all the
    mount points are set up.

``::once:/etc/init.d/rc``
    This is run once on startup after ``rcS`` and starts up the user services of
    interest by executing all the links in ``/etc/rc.d/`` starting with ``S``.
    These are all links to simple startup and shutdown scripts in
    ``/etc/init.d``, the specific scripts are listed below.

``ttyLP0::askfirst:/bin/sh -l``
    This is a login shell available on the serial console.  If necessary this
    shell is available during the executing of the ``rc`` script.

The following system level services are started by ``/etc/init.d/rc``:

``network``
    The network configuration is defined in ``/etc/network/interfaces`` and is
    managed elsewhere, see :ref:`network`.  This script configures the machine
    host name and starts networking.

``inetd``
    This is a lightweight ethernet enabled application launcher.  In our
    application ``inetd`` is configured to launch the ssh service when required.

``ntpd``
    Neither the Colibri module nor the SIC carrier board have a real time clock
    with persistent state.  Therefore for any kind of reliable timestamping
    (definitely required for an EPICS IOC) a connection to an `ntp`_ server is
    required.  This service is configured in ``/etc/ntp.conf``, see
    :ref:`network`.

``opt-etc``
    After all other services have been started, the ``opt-etc`` launcher service
    looks in ``/opt/etc/rc.d`` for startup scripts (which should themselves be
    links to scripts in ``/opt/etc/init.d``) to launch.

Each of these four services can be started, stopped, or restarted with the
command (``$SERVICE`` is the service name)::

    /etc/init.d/$SERVICE {start|stop|restart}

There is one further service installed in ``/etc/init.d`` which is not
configured for automatic startup:

``mount-extra``
    Mount points ``/mnt``, ``/dls_sw/work``, ``/dls_sw/prod`` are present but
    unmounted.  The file ``/var/state/etc/fstab.extra`` can be configured with a
    list of NFS mounts to be mounted when this service is started.  It is likely
    that the ``/dls_sw`` mount points will be removed in a future release of the
    rootfs.


Applications
~~~~~~~~~~~~

The Colibri system is designed to support one application, an EPICS IOC.  This
is intended to be installed in ``/opt/ioc`` and it should maintain its
persistent state in files under ``/opt/state``.  A startup and shutdown script
should be installed in ``/opt/etc/init.d`` and linked to from ``/opt/etc/rc.d``
so that it can be picked up by the ``opt-etc`` launcher.

There are a number of applications and facilities currently built into the
rootfs for possible use by applications:

``procServ``
    This provides a virtual terminal with a configurable telnet interface to a
    guest application.  When running the EPICS IOC as a service it should be
    wrapped by this application.

``screen``
    This is an alternative virtual terminal service, but this is not really
    suitable for wrapping an IOC.  This may be removed from a future version of
    the rootfs.

``conserver``
    `conserver`_ is an application for multiplexing access to a serial console
    and logging.  This should almost certainly be run elsewhere, and may be
    removed from a future version of the rootfs.

User ``epics_user``, group ``dcs``
    These are available for a mode of operation where the IOC does not run as
    root.  These may be removed from a future version of the rootfs.

Mount points ``/dls_sw/prod`` and ``/dls_sw/work``.
    These are for use by the ``mount-extra`` service, but are unlikely to be
    useful except for limited development applications.  These may be removed
    from a future version of the rootfs.

``nano``
    This is a lightweight editor, simpler to use than ``vi``, but only useful
    for occasional debug or administration use.

``strace``, ``lsof``, ``ethtool``, ``iperf``
    These are all debugging tools that have limited application and may be
    removed from a future version of the rootfs.


..  note::

    The following may be removed from a future version of the rootfs:

    ``screen``, ``conserver``, ``strace``, ``lsof``, ``ethtool``, ``iperf``,
    ``nano``, user ``epics_user``, group ``dcs``, mount points under
    ``/dls_sw``.

..  _Toradex:
    https://www.toradex.com

..  _Colibri Arm Family:
    https://www.toradex.com/computer-on-modules/colibri-arm-family

..  _Colibri VF50:
    https://www.toradex.com/computer-on-modules/colibri-arm-family/\
    nxp-freescale-vybrid-vf5xx

..  _Digital Power Supply:
    https://confluence.diamond.ac.uk/x/Z1xRBQ

..  _SIC card:
    https://confluence.diamond.ac.uk/x/5ZfhBQ

..  _DPS card:
    https://confluence.diamond.ac.uk/x/alxRBQ

..  _DPS Rootfs:
    https://gitlab.diamond.ac.uk/controls/targetOS/colibri-vf50

..  _DPS IOC:
    https://gitlab.diamond.ac.uk/controls/ioc/dps

..  _DLS rootfs:
    https://gitlab.diamond.ac.uk/controls/targetOS/rootfs

..  _UG470:
    https://www.xilinx.com/support/documentation/user_guides/\
    ug470_7Series_Config.pdf

..  _AD7414:
    https://www.analog.com/media/en/technical-documentation/data-sheets/\
    AD7414_7415.pdf

..  _U-Boot-Toradex:
    git://git.toradex.com/u-boot-toradex.git

..  _Linux-Toradex:
    git://git.toradex.com/linux-toradex.git

..  _UBIFS:
    https://en.wikipedia.org/wiki/UBIFS

..  _busybox:
    https://busybox.net/

..  _dropbear:
    https://matt.ucc.asn.au/dropbear/dropbear.html

..  _ntp:
    http://www.ntp.org/

..  _MTD:
    https://en.wikipedia.org/wiki/Memory_Technology_Device

..  _devpts:
    https://en.wikipedia.org/wiki/Devpts

..  _SHM:
    https://gerardnico.com/os/linux/shared_memory

..  _init:
    https://en.wikipedia.org/wiki/Init

..  _conserver:
    https://www.conserver.com/
