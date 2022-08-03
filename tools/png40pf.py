#!/usr/bin/env python3
# Based on m/tools/png2logo.py
from os.path import basename
import sys

from PIL import Image

import asmlib
from imglib import *

def sanity_check(im):
    """Checks that the image has the appropriate format:
    * width is 40

    """
    w,h = im.size
    if w != 40:
        msg = "Image width is not 40: {}".format(w)
        raise BadImageException(msg)

def playfields(l):
    pfs = []
    pfs.append(list(reversed(l[0:4])) + 4*[False])
    pfs.append(l[4:12])
    pfs.append(list(reversed(l[12:20])))
    pfs.append(list(reversed(l[20:24])) + 4*[False])
    pfs.append(l[24:32])
    pfs.append(list(reversed(l[32:40])))
    return flatten(pfs)

def display_pfs(pfname, packed):
    for i in range(6): # 6 bytes per line
        print("pf_{}_{}:".format(pfname, i))
        print(asmlib.lst2asm(reversed(packed[i::6])))
    print("pf_{}_ptr:".format(pfname))
    for i  in range(6):
        print("\tdc.w pf_{}_{}".format(pfname, i))

def main():
    fname = sys.argv[1]
    # Convert to 1 byte in {0,255} per pixel
    im   = Image.open(fname)

    # Beware im.convert('1') seems to introduce bugs !
    # To be troubleshooted and fixed upstream !
    # In the mean time using im.convert('L') instead
    grey = im.convert('L')
    sanity_check(grey)
    arr   = bool_array(grey)
    lines = [arr[i:i+40] for i in range(0, len(arr), 40)]
    pfs   = [playfields(l) for l in lines]
    pack  = pack_bytes(flatten(pfs))
    #rev   = [~v & 0xff for v in pack]
    display_pfs(basename(fname).split(".")[0].replace("-","_"), pack)

main()
