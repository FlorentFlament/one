#!/usr/bin/env python3
# Based on m/tools/png2logo.py
from os.path import basename
import sys

from PIL import Image

import asmlib
from imglib import *

def sanity_check(im):
    """Checks that the image has the appropriate format:
    * width is 16

    """
    w,h = im.size
    if w != 16:
        msg = "Image width is not 16: {}".format(w)
        raise BadImageException(msg)

def display_sprites(pfname, packed):
    for i in range(2): # 6 bytes per line
        print("sp_{}_{}:".format(pfname, i))
        print(asmlib.lst2asm(reversed(packed[i::2])))
    print("sp_{}_ptr:".format(pfname))
    for i  in range(2):
        print("\tdc.w sp_{}_{}".format(pfname, i))

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
    lines = [arr[i:i+16] for i in range(0, len(arr), 16)]
    pack  = pack_bytes(flatten(lines))
    #rev   = [~v & 0xff for v in pack]
    display_sprites(basename(fname).split(".")[0].replace("-","_"), pack)

main()
