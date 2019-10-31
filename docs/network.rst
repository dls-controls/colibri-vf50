..  _network:

Network Configuration
=====================

Configuration Tool
------------------

A command line tool ``configure-network`` is included to manage the network
configuration.

..  program:: configure-network
..  option:: configure-network [options] network host-name [ip-address]

    To change the assigned IP address for the system it is necessary to specify
    which network the system is on and the host name to use.  if the specified
    host name is not in the selected network configuration file then the
    required IP address must also be specified.

    ..  option:: network

        This identifies which network to configure, and must be specified.  The
        network configuration is loaded from the file
        ``/opt/networks/network-``:option:`network`\ ``.config``.  The format of
        this file is documented below, but basically this file defines the core
        network and DNS settings and the ntp server, as well as a list of known
        hostname and IP address pairs.

    ..  option:: host-name

        This must be specified and selects the network hostname for the device.
        Note that this is also used as the EPICS name prefix for the IOC.

    ..  option:: ip-address

        If the specified host-name is present in the selected network
        configuration file then this parameter is optional and the IP address is
        assigned automatically.  Otherwise this parameter is checked for
        validity against the selected network settings and used to set the
        device IP address.

    ..  option:: -w

        If :option:`-w` is not specified the selected network configuration is
        printed out but is *not* applied.  Specify this option to update the
        configuration.

    ..  option:: -r

        This will trigger a call to ``/etc/init.d/network restart`` after
        configuration.  Note that network contact with the system may be lost.


Alternatively the following form can be used to enumerate the available
networks and machine names:

..  program:: configure-network-l
..  option:: configure-network -l [network]

    If *network* is not specified, prints a list of the available
    networks, otherwise prints a list of the known machine names and their IP
    addresses for the selected network.


Configuration File Format
-------------------------

Network configuration files are stored in ``/opt/network`` and have names of the
form ``network-``\ *network-name*\ ``.config``.  The standard installation
includes two network configurations:

======= ======================= =============== ================================
Network Config file             Addresses       Role
======= ======================= =============== ================================
dev     ``network-dev.config``  172.23.240.0/24 Development network
pri     ``network-pri.config``  172.23.192.0/24 Primary machine network
======= ======================= =============== ================================

The configuration file contains all the information required to configure the
Colibri system to operate on the selected network, and includes the following
entries:

=============== ================================================================
Section         Description
=============== ================================================================
[fstab]         Extra mount points for ``mount-extra`` service.
[ntp]           Server identification for NTP server.
[resolv]        DNS resolver information.
[network]       Network definition.
[valid-ips]     List of valid machine names and associated IP addresses.
=============== ================================================================


System Network Configuration
----------------------------

Because the root file system is read-only, the network configuration files need
to be managed as soft links to files which are managed by the
:option:`configure-network` tool.  The following linked files are managed.  Each
linked file links from ``/etc`` to ``/var/state/etc``, for example
``/etc/hostname`` is managed in ``/var/state/etc/hostname``.

``network/interfaces``
    Contains the complete network definition, specifying IP address, network
    addresses and netmask, and gateway address (if present in network config
    file).  Read during network startup.

``hostname``
    Contains the target host name, read during network startup.

``resolv.conf``
    Contains DNS resolver entries, read each time network name resolution is
    attempted.

``ntp.conf``
    Contains NTP configuration including NTP server address.  Read during NTP
    server startup.

``fstab.extra``
    Contains a list of mount points in ``/etc/fstab`` format.  Read when running
    ``mount-extra`` process.  Unlike the other files, this file is linked from
    ``/etc`` via an entry in ``/etc/mount-extra``.
