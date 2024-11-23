# Don't Wake Cthulhu!

This is a game for the [Micronique Hector](https://en.wikipedia.org/wiki/Hector_(microcomputer)) 2/HR micro computers.

## Introduction

The game is developed mostly in C for the game logic, with some Z80 assembly language for the display routines.

Python scripts are used to convert the graphics PNG files into C source files and bitmaps in the Hector frame buffer format. Some of the graphics are included in the C compilation commands, some others are compressed and included as binaries in the assembly source code.

To fit all the graphics in memory, the [ZX0](https://github.com/einar-saukas/ZX0) compression tool was used. It seems very efficient, and the "standard" decompression routine is tiny.

## How to build

Before you can build, you need these pre-requisites:

1. A copy of the [z88dk](https://github.com/z88dk/z88dk/wiki) development kit. Follow the instructions to install the SDK; the Makefile assumes that the z88dk tools are in the system path.
2. A copy of the [ZX0](https://github.com/einar-saukas/ZX0) data compression tools for the Z80. Adjust the path in the Makefile.
3. A working installation of Python.

Install the PIL library for Python:

```
pip install Pillow
```

You can then build the project:

```
make bitmaps; make compile; make k7
```

This will build two set of binaries in `build`; one for the Hector 2/HR line of computers, and one for the Hector HRX.

- The `.bin` file can be loaded directly into memory.
- The `.k7` file can be loaded like a cassette.

## How to run

The game was mostly tested with the [VBHector](http://hectorvictor.free.fr/index.php?page=8ALh79=UoEsI) emulator. To run the game, two possibilities:

- Start VBHector in HR or HRX mode, and load the `.k7` file.
- Use the VBHector option to load a binary file; load it at address `0x6000`, with SP address at `0xc000`.
