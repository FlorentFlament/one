#!/usr/bin/env python3
import math
import asmlib

RESOLUTION = 128

table = [int(round((math.sin(x/RESOLUTION*2*math.pi)+1)*29/2)) for x in range(RESOLUTION)]
print(asmlib.lst2asm(table))
