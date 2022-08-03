# one

## Prerequisite

* This code has been written in DASM. The assembler can be downloaded
  from [DASM project's page](http://dasm-dillon.sourceforge.net/)

* An Atari VCS emulator (though binaries can be executed on the real
  hardware instead). The demo works well on
  [Stella](https://stella-emu.github.io) 6.7.

* Make is needed to be able to use the Makefile. Though one can launch
  the commands of the Makefile without using make.


## Launching the intro

```
dasm src/main.asm -omain.bin -lmain.lst -smain.sym -Iinc -Izik -Isrc -f3 -d
Debug trace OFF

 -RAM-
 Used RAM: 90 bytes

 -DATA-
 Track size:  $334

 -CODE-
 Music player size: 174 bytes
 Main size: 274 bytes (including music player)
 FX size: 1820 bytes (including fx data)

 -TOTAL-
 Used ROM: 2914 bytes
 Remaining ROM: 1178 bytes

Complete. (0)
$ make run
stella main.bin
```
