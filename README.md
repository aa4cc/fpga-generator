# fpga-generator

This repository contains a generator of phase-shifted square waves.
The generator built upon the De0-Nano developement board and implmeneted as a Quartus II. project.

It provides 64 output channels, each with configurable phase shift and duty cycle. The resolution of those parameters is 360 parts per period.
All outputs share a single frequency, which is also reconfigurable on the fly.

Communication to the device is realised via UART.

The design of the device is modular and allows for multiple devices of the same kind to be synchronised together, thus providing more outputs.
When devices are synchronised in this way, they need to be connected via a custom PCB shield designed for this purpose.
Design files for the shield are available in the chaining_shield folder.


WIP



