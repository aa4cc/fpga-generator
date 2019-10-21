#!/usr/bin/env python3
from generator import Generator
from time import sleep
import serial

port = serial.Serial('/dev/ttyUSB0', 230400, parity= serial.PARITY_EVEN) #pozn.: paritu prvni verze generatoru v FPGA nekontroluje, paritni bit jen precte a zahodi (aktualni k 8.4.2018)

g = Generator(port);

f_phase_4seq = lambda i : 180 if i%14==0 else 0;

def print_4seq(phases, duty_cycles):
	print("Phases")
	[print([phases[i] for i in range(k*14,(k+1)*14)]) for k in range(4)];
	print("Duty cycles")
	[print([duty_cycles[i] for i in range(k*14,(k+1)*14)]) for k in range(4)];


g.set_frequency(300e3);

i = 0;
while True:
	phases 		= [f_phase_4seq(i+k) for k in range(4*14)];
	duty_cycles = [0.5]*4*14;

	print_4seq(phases, duty_cycles);

	g.set(phases, duty_cycles);

	i += 1;

	input("Press Enter to continue...")
	# sleep(0.02)