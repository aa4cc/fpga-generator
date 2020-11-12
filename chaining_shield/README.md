View this project on [CADLAB.io](https://cadlab.io/project/2149). 

# fpga_generator_chaining_shield

This is a synchronisation shield for interconnecting up to 4 generators. The coaxial cable connectors labeled M1 to M4 are used as clock outputs in the master device, while the connector labeled S is used as input in both master and slave devices.

When synchronizing multiple (N) devices, all of their boards should be interconnected via a flat cable connecting to the connector labeled SV1. Then, N coaxial cables should be connected to the M connectors of the master device. Connect the other end of each cable to the S input of one of the synchronized devices.

Yes, this includes the master - one of the cables will be connected to an output of the master device and loop back into the input of the master device. This is done to keep the transmission line lengths the same.

The board mates to the bottom (13x2) GPIO header of DE0-Nano. When determining the orientation, make use of the fact that the leftmost pin of the bottom row of header J0 mates to the ground pin of DE0-Nano.

# Notes on populating the board

Not all components shown in the schematic need to be populated. In particular:

* LED1 is optional (it has identical function to LED0 on top of the DE0-Nano kit. If your application lets you easily observe the top of the kit, feel free to skip it, otherwise, it is reccomended).
* Pins J1 and J2 are not used in the design and do not need to be populated.
* Resistor R1 is intended as termination resistor for impedance matching. When the device was tested at 40kHz, it functioned without it, so I left it unpopulated. 
* Coaxial connectors labeled M1 to M4 only need to be populated on the master board. The boards which will be used on slave devices only need their S connector populated. (The master board also needs its S connector populated).

**If you do decide to populate resistor R1**, make sure that you choose a suitably high value!  The pins feeding the clock outputs (labeled M1 to M4) have series 50 ohm resistors enabled in the Quartus project design files. Consult the cyclone IV datasheet to make sure that your chosen value will not decrease the amplitude of the signal below the logic level threshold. (The I/Os operate at 3,3V standard)



