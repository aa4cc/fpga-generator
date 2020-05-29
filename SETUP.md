
# Setting up the generator

## Setting up a standalone generator (up to 64 outputs)

When only 64 outputs are needed, the setup is fairly straightforward:

1. Download the Quartus II project from folder [software](software).
2. Use Quartus II. to compile it and program it into your De0-Nano kit. In case of compatibility issues: Quartus II. version 13.0.1. was used to develop the generator.
3. Connect the two UART lines to the device. The generator receives data via pin A8 and transmits via pin D3.
4. Locate the dip switches on top of the board. Switch 0 is used to choose between standalone and synchronized modes of operation. Set it to the upper position. LED0 on top of the board will start blinking, signalizing that the device is in standalone mode.
5. The device is now set up, you may now set phases and duties of its output channels. See [communication](COMMUNICATION.md) for details.

## Setting up synchronized generators (up to 256 outputs, using provided PCB)

When more outputs are required, you will need to synchronize several generators. This section assumes that you will be using two to four DE0-Nano boards.

First, you will need to obtain and populate synchronization shield PCBs. Eagle design files for said PCB are available in folder [chaining_shield](chaining_shield). See readme within the folder for details on components.

Once you have the shields, perform steps 1 to 3 of the previous section for each of your DE0-Nano. Having done that, continue with following steps:

4. On each DE0-Nano, locate the DIP switches. Move switch 0 to the lower position to switch the device into synchronised mode. LED0 should not be blinking - if it is, it signifies that the device is in standalone mode.
5. Choose one generator to be the master. Dip switch 1 is used to switch between master and slave modes. Move it to the lower position. LED0 should now be ON, signalizing that the device is master.
6. For all devices apart from the master, move switch 1 to the upper position. Their LED0s should be OFF, signalizing that the devices are in slave mode.
7. Connect a synchronization shield to each device. Interconnect their coaxial connectors as described in [chaining_shield](chaining_shield) readme.
8. Connect the synchronization shields by a flat cable.
9. The devices are set up, you may now set phases and duties of their output channels. See [communication](COMMUNICATION.md) for details. 


## Going beyond 256 channels

If you need more than 256 channels, you will have to modify the synchronization shield PCB by adding more output connectors. 

It may be convenient to edit the quartus design files and add more clock output pins (in my desin, those are pins B16, D16, D14 and G16).


