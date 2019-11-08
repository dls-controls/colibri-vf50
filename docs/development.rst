.. _development:

Software Development Notes
==========================

The following U-Boot command will boot from SD card::

    load mmc 0:1 $scriptaddr boot-script.image && source $scriptaddr

Once an initial image has been installed following the instructions in
:ref:`installing` the following command is an alias for the above::

    run sdboot

Table of pin assignments
------------------------

The table below shows all of the configured GPIOs and other pin assignments.
The columns are labelled as follows:

J3
    This is the pin number on the SODIMM connector labelled J3 on the SIC board.
Function
    This is the pin description on the SIC circuit diagram.
SOC
    This is the pin number on the Vybrid VF5XX device.  This is used in the
    device tree specification to identify the particular pin.
Assignment
    This column shows the corresponding function assignment for this pin.  If
    blank then the default assignment is correct, otherwise an appropriate GPIO
    mux assignment is needed in the device tree.

All of the pins listed here are documented in the Colibri VFxx family datasheet
linked from the `DPS Colibri Documents`_ page, in particular see pages 21--25.

=== =========== =========== =========== ========================================
J3  Function    SOC         Assignment  Notes
=== =========== =========== =========== ========================================
33  UART RXD    PTB11                   Assigned to UART by default, needed for
                                        system serial console
35  UART TXD    PTB10                   "
86  SPI1 CS     PTD5                    SPI1 to DPS FPGA, configured by default
88  SPI1 CLK    PTD8                    "
90  SPI1 RXD    PTD6                    "
92  SPI1 TXD    PTD7                    "
194 SDA         PTB15                   I2C, configured by default
196 SCL         PTB14                   "
71  SPI0 CS     PTC0        DSPI0_CS3   SPI0 to SIC FPGA
73  SPI0 TXD    PTB21       DSPI0_SOUT  "
77  SPI0 CLK    PTB22       DSPI0_SCK   "
43  SPI0 RXD    PTB20       DSPI0_SIN   "
127 SW1-8       PTD26       GPIO_68     Bank of four switches read at startup
129 SW1-4       PTD4        GPIO_83     "
131 SW1-2       PTE3        GPIO_108    "
133 SW1-1       PTD9        GPIO_88     "
8   VCC1V8      ADC0_SE8                ADC0 channel 8
4   VCC5V0      ADC0_SE9                ADC0 channel 9
6   VCC3V3      ADC1_SE8                ADC1 channel 8
2   VCC1V0      ADC1_SE9                ADC1 channel 9
59  VCC1V2      PTB0        ADC0_SE2    ADC0 channel 2
98  A INIT B    PTC1        GPIO_46     Pins for programming DPS FPGA
100 A DONE      PTD13       GPIO_92     "
102 A PROG B    PTA12       GPIO_5      "
104 A DSO       PTD28       GPIO_66     "
106 A CLK       PTD31       GPIO_63     "
134 INIT B M1   PTA17       GPIO_7      Programming on-board SIC FPGA
136 DONE M1     PTE21       GPIO_126    "
138 PROG B M1   PTE22       GPIO_127    "
140 DSO M1      PTE13       GPIO_118    "
142 CLK M1      PTE14       GPIO_119    "
188 ALERT       PTD11       GPIO_90     Temperature alert from I2C sensor
55  XL TRIG     PTB17       GPIO_39     All these pins are spare and should be
                                        left tri-state.
135 SPARE 1     PTD10       GPIO_89     "
137 SPARE 2     PTC29       GPIO_102    "
89  SPARE 3     PTA9        GPIO_2      "
93  SPARE 4     PTB28       GPIO_98     "
95  SPARE 5     PTC30       GPIO_103    "
99  SPARE 6     PTD29       GPIO_65     "
144 SPARE 7     PTE5        GPIO_110    "
146 SPARE 8     PTE6        GPIO_111    "
184 SPARE 9     PTD25       GPIO_69     "
=== =========== =========== =========== ========================================

Configuring GPIOs
-----------------

The entries in the ``iomuxc`` section of the device tree consist of two parts
for each pin: a word specifying the port and its mapping, and a constant value
specifying the pin configuration.

The port name and its mapping is a word of the form:

    ``VF610_PAD_``\ *pin-name*\ ``__``\ *function*

where *pin-name* is the Vybrid pin name (third column in the table above) and
*function* is the selected function (fourth column).

The pin configuration is a 16-bit number with the following fields
(documentation taken from pages 241 and 256--257 of the VFxxx Controller
Reference manual on `DPS Colibri Documents`_.

======= ======= ======= ========================================================
Bits    Mask    Name    Function
======= ======= ======= ========================================================
0       0x0001  IBE     Set to 1 to enable input buffer
1       0x0002  OBE     Set to 1 to enable output buffer
2       0x0004  PUE     Set to 1 for output pull-up/down, 0 for keeper if
                        enabled in PKE
3       0x0008  PKE     Set to 1 to enable pull-up/down or keeper
5:4     0x0030  PUS     Pull up or down and strength if enabled in PKE.  0 =>
                        100 kOhm pull-down, 1 => 47 kOhm pull-up, 2 => 100 kOhm
                        pull-up, 3 => 22 kOhm pull-up.
8:6     0x01C0  DSE     Drive strength field.  0 => output disabled, 1 => 150
                        Ohm, 2 => 75 Ohm, 3 => 50 Ohm, 4 => 37 Ohm, 5 => 30 Ohm,
                        6 => 25 Ohm, 7 => 20 Ohm.
9       0x0200  HYS     Set to 1 for Schmitt trigger input, 0 for CMOS
10      0x0400  ODE     Set to 1 for open drain output
11      0x0800  SRE     Set to 1 for fast slew rate
13:12   0x3000  SPEED   Speed selection.  0 => 50 MHz, 1, 2 => 100 MHz, 3 => 200
                        MHz.
======= ======= ======= ========================================================

The "Mask" column is provided for convenience when reading and writing values in
hex.


ADC channels
------------

The ADC channels are accessed by reading the following nodes under
``/sys/bus/iio/devices``.

=================================== =================== ========================
Device node                         ADC channel         SIC board input
=================================== =================== ========================
``iio:device0/in_voltage2_raw``     ADC0 channel 2      VCC1V2
``iio:device0/in_voltage8_raw``     ADC0 channel 8      VCC1V8
``iio:device0/in_voltage9_raw``     ADC0 channel 9      VCC5V0
``iio:device1/in_voltage8_raw``     ADC1 channel 8      VCC3V3
``iio:device1/in_voltage9_raw``     ADC1 channel 9      VCC1V0
``iio:device0/in_temp_input``       Sensor temperature
``iio:device1/in_temp_input``       Sensor temperature
=================================== =================== ========================

Note that there is a *lot* of noise in these readings.  However, it seems that
writing 7541 to the ``in_voltage_sampling_frequency`` node of each device should
reduce the noise somewhat.  Note also that ``in_voltage_scale`` is around 0.8,
so presumably represents a scaling correction that will need to be applied.


GPIO Access
-----------

At present the EPICS driver is configured to use the GPIO sysfs interface, but
according to `<https://developer.toradex.com/knowledge-base/libgpiod>`_ this is
now an obsolete interface.  Unfortunately we don't appear to have any
``/dev/gpiochip*`` devices, am not sure if this is a kernel configuration or age
issue; it seems that the VF50 kernel is rather old (4.4).


..  _DPS Colibri Documents:
    https://confluence.diamond.ac.uk/x/fVxRBQ
