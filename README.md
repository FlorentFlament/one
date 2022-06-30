# Rasfatari

## Prerequisite

* This code has been written in DASM. The assembler can be downloaded
  from [DASM project's page](http://dasm-dillon.sourceforge.net/)

* An Atari VCS emulator (though binaries can be tested on the real
  hardware instead). [Stella](https://stella-emu.github.io) is an
  excellent emulator and debugger for the Atari 2600.

* Make is needed to be able to use the Makefile. Though one can launch
  the commands of the Makefile without using make.


## Launching the intro

    $ make
    dasm main.asm -f3 -omain.bin -lmain.lst -smain.sym -d
    Debug trace OFF

    Complete.
    $ make run
    stella main.bin
