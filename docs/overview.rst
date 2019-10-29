.. default-role:: literal

.. _overview:

Introduction and Overview
=========================

The `Colibri Arm Family`_ consists of a series of SODIMM sized System on
Modules.  The `Colibri VF50`_ provides a single core A5 ARM with 128MB of RAM
and FLASH and is used to provide the control system for the Diamond `Digital
Power Supply`_.

The `DPS Rootfs`_ builder (this project) is used to assemble the core OS
functions required to support the EPICS `DPS IOC`_ (a separate project).

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
