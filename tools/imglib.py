class BadImageException(Exception):
    pass

def lbool2int(lst):
    """Converts a list of boolean to an integer.
    The list usually contains 8 items for a corresponding an 8 bits integer.
    """
    r = 0
    for b in lst:
        r <<= 1
        r |= b
    return r

def bool_array(im):
    """Converts an image to an array of booleans. The image is flattened,
    so each line succeeds the previous one.

    """
    return [v != 0 for v in im.getdata()]

def pack_bytes(arr):
    """Pack each 8 bools nibble into a byte.
    Return a list of int.

    """
    nibbles = [arr[i:i+8] for i in range(0, len(arr), 8)]
    return [lbool2int(n) for n in nibbles]

def flatten(l):
    return [item for sublist in l for item in sublist]
