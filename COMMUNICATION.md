
# Communication

The generator communicates over UART, at BAUD 230400. The communication is two-way - the user sends multibyte commands to the generator and the generator replies with a single byte.

Communication software examples are provided in [software/py](software/py), and more will be added in the future.

# User to generator communication

Each command that the user sends to the generator consists of 3 parts, in this order:
* Code - one byte, identifies the type of command
* Data - zero or more bytes, depending on command type
* CRC - one byte, calculated as CRC8 with generating polynomial 0x07 from Code and Data.

A list of commands follows.

## Set phases

This command is used to configure the phase shifts of channels of the generator. The default value on generator power-up is 0 for all channels.

Code: 0x01
Data: The data is 72 bytes long and consists of concatenated 9-bit unsigned integers. Each integer should have a value of 0 to 360, denoting the phase shift in degrees.

## Set duties

This command is used to configure the duty cycles of channels of the generator. The default value on powerup is 0. To obtain a square wave with 50% duty cycle, it should be set to 180.

Code: 0x02
Data: The data is 72 bytes long and consists of concatenated 9-bit unsigned integers. Each integer should have a value of 0 to 360, denoting the duty cycle width in degrees. Value of zero will result in that output being kept in logical low, while value of 360 will be 100% duty cycle, representing an output stuck in logical high.

## PLL reconfig

This command is used to reconfigure the PLL used within the generator. This PLL generates the signal responsible for clocking the logic that generates output signals. As a result, the output frequency of the generator is dependant on the frequency of this signal - it is always 360 times lower than it.

So, if one wants the output of the generator to run at 40 kHz, they need to configure the PLL so that it outputs a clock of frequency 14.4 MHz. The PLL uses the onboard 50 MHz clock as its source.

The default PLL frequency at generator powerup is 14.4 MHz.

Code: 0x04
Data: An 18 byte long PLL scanchain. See [cyclone IV handbook](https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/hb/cyclone-iv/cyclone4-handbook.pdf), page 99.

## Inquire master

This command is used to request that the device includes in its reply information as to whether it is in master or in slave mode.

Code: 0x08
Data: This command has no data.

## Synchronize dividers

This command is used to synchronize multiple devices. It should always be sent to the master device. The synchronization process should take about one milisecond.

I reccomend that this command be always sent to the master device after all slaves have been connected. If this is not done, their internal clock dividers will not be synchronized and the phase shifts of different devices will float (signal with 0 phase from device A will be shifted in regards to a signal with 0 phase from device B).

It should also be sent after any manipulation with the hardware connecting the devices or after any switching of modes of synchronized devices, as those actions may also cause the clock dividers to desynchronize.

I have also, albeit very rarely, observed the clock dividers becoming desynchronized slightly (and outputs drifting by one degree) during normal operation - possibly due to interference causing one device to miss a rising edge of the shared clock. It might thus be advisable to send this signal every once in a while (e.g. once per 15 minutes).

Code: 0x10
Data: This command has no data.


# Generator to user communication

The generator sends a byte as a reply to each command received from the user (and also when it expects a code byte but receives one that does not match any of the codes listed in the previous section).

The reply byte consists of two parts:

## Low nibble

This nibble carries in it identification of the type of command that the generator is replying to, and, in some cases, additional information as well. Its possible values are:

* 0x1 - reply to set phases command.
* 0x2 - reply to set duties command.
* 0x3 - reply to pll reconfig command.
* 0x4 - reply to inquire master command. It also says that the device is master.
* 0x5 - reply to inquire master command. It also says that the device is slave.
* 0x6 - reply to synchronize dividers command.
* 0x7 - reply to synchronize dividers command. It also says that the device ignored the command because it is not master.
* 0x8 - this means that an invalid code byte was received.

## High nibble

This nibble tells the user whether the CRC they sent matches the CRC the generator has calculated internally.
When its value is 0xF, it signifies a match, while value of 0x0 means that the CRC was incorrect. If the CRC is incorrect, the generator does not act upon the command (meaning that no duties, phases or pll is reconfigured and no synchronization is done).

When the low nibble is 0x8, the high nibble should be disregarded. The generator does not check the CRC in this case.

## Pitfall with invalid code reply

When the generator receives an invalid code, it will send a reply with low nibble of 0x8 straight away, before accepting any further bytes. This has the side effect that the following data bytes (if any) and the CRC byte, will be interpreted as new code bytes (and will, most of the time, produce a new invalid code reply).

This needs to be kept in mind when communicating to the device.


# Communicating to synchronized generators

When you are using multiple generators, there are a couple differences:

Firstly, when you wish to change the output frequency of all synchronized generators, you only need to send the PLL reconfig command to the master device. Sending it to slave devices has no effect.

Secondly, when you send a Set Phases or Set Duties command, the outputs of a device that is not in standalone mode are not updated immediately. To cause the outputs of a device to update, the user needs to drive the TRIGGER EXTERNAL (mapped to pin G15 of DE0-Nano) low (the pin has a pull-up resistor enabled). This is done to make the update to new settings synchronous across all devices.

On the [chaining_shield](chaining_shield), this pin is routed to one of the outputs of the flat cable connector SV1, specifically, to the right pin of the middle row. 

















