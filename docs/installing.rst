.. _installing:

Fresh Installation
==================

For installation a Colibri development board is required together with an SD
card and a working RS232 connection.  Upgrading requires a network connection
and a tftp server, but can be done remotely.

Initial installation is a two step process.  Colibri cards come from the vendor
with Windows CE and its bootloader Eboot, which must first be replaced with
u-boot.  Once u-boot has been installed, the initial Linux system can be
installed and configured.

Note that this installation process should not normally be used for upgrading,
as installation will reset the NAND Flash erase counters maintained by UBI.

Requirements and Preparation
----------------------------

For installation the following is required:

1.  `Colibri Evaluation board`_ and power supply.
2.  PC with RS232 port and cabling.
3.  SD card.
4.  Built files for installation, see :ref:`building`.  For this document these
    will be assumed to be in a directory named ``$BOOT``.

Prepare the SD card as follows (this can be done using the ``gnome-disks``
tool):

1.  Ensure that the SD card is formatted with a single FAT32 partition.  It
    seems necessary to delete the factory default partition so that the card is
    readable by Eboot.
2.  Copy the following files from ``$BOOT`` to the SD card:

    * ``u-boot-nand.imx``
    * ``install-script.image``
    * ``zImage``
    * ``device-tree.dtb``
    * ``rootfs.img``
    * ``state.img``

Prepare the development board:

1.  Ensure the board is powered off.  Switch 7 adjacent to the power connector
    is used to toggle power to the board, and two green LEDs halfway along the
    same edge are illuminated when the board is powered on.

2.  Connect a "null modem" RS232 cable to the UART A connector.  This is the
    bottom male 9-pin connector closest to the pink 3mm audio socket.  Configure
    the PC serial port as 115200N8.

3.  Insert the SD card into the evaluation board.


Flashing a Factory Fresh Colibri
--------------------------------

Flashing and installing a factory fresh Colibri card is done by the following
procedure:

1.  Ensure the board, SD card, and serial connection are configured as described
    above.

2.  Insert the Colibri card into the development board.

3.  Turn on the power to the board (hold switch 7 for a second).

4.  Press space on the serial terminal immediately (you have 1 second to
    respond).  If successful the following will be shown::

        Toradex Bootloader 1.5 for Vybrid Built Dec 18 2017
        CPU  :  400 Mhz
        Flash:  128 MB
        RAM  :  128 MB
        Colibri VF50 module version 1.2B Serial No.: 6385035

        Press [SPACE] to enter Bootloader Menu

        Initiating image launch in 1 seconds.


        BootLoader Configuration:

        C) Clear Flash Registry
        X) Enter CommandPrompt Mode
        D) Download image to RAM now
        F) Download image to FLASH now
        L) Launch existing flash resident image now


        Enter your selection:

    If instead the text `Loading OS Image` is shown after `Initiating image
    launch` then turn the board off and on again (by pressing SW7 twice) and try
    again.

5.  Type `X` to enter command mode::

        Enter your selection: X

        >

6.  At the prompt type::

        flashloader u-boot-nand.imx

    This will replace WinCE with u-boot.  Wait until `Flashing complete` is
    reported and the prompt is returned::

        Flashing completed.

        >

7.  Reboot to boot into u-boot.  Type `reboot` at the prompt above and hit space
    immediately (again, you have 1 second to respond)::

        U-Boot 2016.11 (May 10 2019 - 10:55:05 +0100)

        CPU: Freescale Vybrid VF500 at 396 MHz
        Reset cause: POWER ON RESET
        DRAM:  128 MiB
        NAND:  128 MiB
        MMC:   FSL_SDHC: 0
        In:    serial
        Out:   serial
        Err:   serial
        Model: Toradex Colibri VF50 128MB V1.2B, Serial# 06317506
        Net:   FEC
        Hit any key to stop autoboot:  0
        Colibri VFxx #

8.  At the uboot prompt type the following::

        load mmc 0:1 $scriptaddr install-script.image && source $scriptaddr

    This will flash the initial version of the system and boot into it.

9.  Finally power off the development board (SW7), remove the Colibri module,
    and carefully peel off and discard the yellow Windows CE label.  This marks
    this module as flashed.


Configuring Network Assignment
------------------------------

A network address should be assigned using the :program:`configure-network`
tool.  This can be run immediately after booting into the initial system.  An
RS232 connection will be required until the network has been configured.

First let the system boot, and hit return for a prompt.  Then run::

    configure-network -w $network $hostname

where *$network* is ``dev`` or ``pri``, and *$hostname* is a supported host
name.  For more complex requirements, see :ref:`network`.

..  _Colibri Evaluation board:
    https://www.toradex.com/products/carrier-board/colibri-evaluation-board
