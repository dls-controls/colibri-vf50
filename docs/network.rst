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
`[fstab]`_      Extra mount points for ``mount-extra`` service.
`[ntp]`_        Server identification for NTP server.
`[resolv]`_     DNS resolver information.
`[network]`_    Network definition.
`[valid-ips]`_  List of valid machine names and associated IP addresses.
=============== ================================================================

[fstab]
~~~~~~~

This contains a list of mount points in ``/etc/fstab`` format, of the form::

    172.23.100.71:/exports/dls_sw/work  /dls_sw/work   nfs nolock,intr

The first word is the NFS export, the second is the local mount point (which
must already exist), the third word must be the string ``nfs``, and the fourth
word is a list of nfs mount options.  The only sensible mount points available
are ``/mnt``, ``/dls_sw/work``, ``/dls_sw/prod``, though in practice none of
these are automatically mounted, and this functionality may be removed in a
future version of the rootfs.

[ntp]
~~~~~

This section is just a list of NTP server definitions of the form::

    server 172.23.24.2

where the first word must be the string ``server`` and the second word is the
IP address of a reachable NTP server.  A number of servers can be specified.

[resolv]
~~~~~~~~

This section contains lines in ``/etc/resolv.conf`` format.  Typically there is
a ``search`` line followed by a number of ``nameserver`` lines.

[network]
~~~~~~~~~

This section defines the network by specifying the following two or three
values:

=========== ====================================================================
Key         Description
=========== ====================================================================
``network`` IP address of network after masking with netmask.
``netmask`` Netmask of network, typically 255.255.240.0 for a /24 network.
``gateway`` Optionally, the address of the network gateway.  If this is not
            specified then addresses outside of the network are not reachable.
=========== ====================================================================

[valid-ips]
~~~~~~~~~~~

This is a list of valid machine names and IP addresses in the specified network.
This is used to help with managing valid machine name assignments, but a name
and IP pair can be manually assigned if necessary.


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
