
#demonstration of Shifted Signal Generator communication
#Created 04.08.2018


import serial;
import time;
import crc8

#master 10
port = serial.Serial('COM10', 230400, parity= serial.PARITY_NONE) #pozn.: paritu prvni verze generatoru v FPGA nekontroluje, paritni bit jen precte a zahodi (aktualni k 8.4.2018)


#port.write(bytes([1]))
#input()



#port = serial.Serial('COM8', 115200, parity= serial.PARITY_EVEN) #pozn.: paritu prvni verze generatoru v FPGA nekontroluje, paritni bit jen precte a zahodi (aktualni k 8.4.2018)

dataArray = []
for i in range(64):
    dataArray.append(60);


#code taken from previous version of comm
dataStream = ""
for number in dataArray:
    ninebit = '{0:09b}'.format(number)      #generator uses 9 bit numbers to set phase and duty!!
    dataStream += ninebit
bytesArray = [dataStream[i:i+8] for i in range(0, len(dataStream), 8)]
last = bytesArray.pop()
while len(last)%8 != 0: #appended zeroes will be shifted out of the end of the settings register
    last += "0";
bytesArray.append(last)
#end of reused code


#!!!! 
#bytesArray = bytesArray[::-1]
#dont send in reverse order!! (change from last version)

intsArray = [int(i, 2) for i in bytesArray]


CODE_PHASES = [1]
CODE_DUTIES = [2]
CODE_PLL = [4] #not yet implemented
CODE_INQUIRE_MASTER = [8]
CODE_SYNCH = [16]
CODE_SET_MASTER = [32]
CODE_SET_SLAVE = [64]


code = CODE_PHASES   #edit this line

if code == CODE_PHASES or code == CODE_DUTIES:
    intsArray = code + intsArray
elif code == CODE_PLL:
    print("Not yet implemented");
    exit();
else:
    intsArray = code

print("Going to send ", intsArray)


#generate crc8 byte, using generating polynomial 0x07
hash = crc8.crc8()

hash.update(bytes(intsArray))
print("Calced crc is ", hash.hexdigest())

#break intsArray:
#intsArray[5] = intsArray[5] + 1
intsArray[0] = intsArray[0] 

port.write(bytes(intsArray) + hash.digest()) #send code, array of data bytes and crc byte

#port.write()


replyByte = port.read();
print("Reply is ", replyByte)
replyByte = replyByte[0] #convert to int
crcMask = 240
repMask = 15


crcR = replyByte & crcMask
if crcR == 240:
    print("Generator says: CRC was correct!")
elif crcR == 0:
    print("Generator says: CRC was incorrect!")
else:
    print("Unknown CRC reply nibble")


repR = replyByte & repMask

if repR == 1:
    print("Generator says: I received command to SET PHASES")
elif repR == 2:
    print("Generator says: I received command to SET DUTIES")
elif repR == 3:
    print("currently not implemented")
elif repR == 4:
   print("Generator says: I AM MASTER")
elif repR == 5:
    print("Generator says: I AM SLAVE")
elif repR == 6:
    print("Generator says: I received command to perform synch and I'm master.")
elif repR == 7:
    print("Generator says: I received command to perform synch but I'm ignoring it because I'm not master!")
elif repR == 8:
    print("Generator says: I received an invalid code (Please ignore previous nibble, I did not check CRC)")
elif repR == 9:
    print("Generator says: I received command to switch into master mode.")
elif repR == 10:
    print("Generator says: I received command to switch into slave mode.")
else:   
    print("Unknown data reply nibble")




while 1:
    b = port.read()
    print(b)














