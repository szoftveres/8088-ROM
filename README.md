# DIY x86 single-board computer and ROM BIOS.
The computer is built around the 80C88 (or compatible) CPU and is capable of booting into [FreeDOS](https://www.freedos.org/) and running text-based DOS programs.
It has 1MB RAM, 128kB in-system programmable BIOS EEPROM, an 82C59A programmable interrupt controller, an RS232 compatible serial port built around a 16C550, two fixed time interval sources and an I/O port (which can be configured as SPI and SD-card interface).

![image small x86](pcb.png)
## [Schematics (pdf)](schematics.pdf) <--
![pcbd](pcbd.png)
![image board3](board3.jpg)

### Character I/O
The computer has no VGA display- or keyboard interface, all interaction happens through the UART. In order to maintain text-based PC compatibility, the BIOS implements INT 10h (VGA character out) and INT 16h (keyboard character in) calls as UART character transfer; this gives terminal-like access to text-based programs, like the FreeDOS shell.

### SD card interface, and storage device access through BIOS INT 13h calls:
A software-defined (bit-banged) SPI interface is implemented on top of the I/O port with all the necessary BIOS routines to read and write an SD card. On startup, the BIOS looks for an SD card on the SPI interface and searches for a valid MS-DOS partition on it. If a partition is found and has an exact size of 1.44MB, the BIOS can boot from it as if it was an actual 1.44MB floppy disk and gives read and write access to it via standard INT 13h calls.

![fddir1](fddir1.png)

Some features enable in-system EEPROM programming and development, like position-independent BIOS ROM code that can be copied to and executed from RAM, the ability to download 64k binary blocks via the serial interface, and EEPROM writing routines.

## Memory Map

|Range             |    Area Description   |   Size    |     Limitis  |
|------------------|-----------------------|-----------|--------------|
|0x00000-0x003FF   |     Interrupt vectors |   1k      | 0 - 1k       |
|0x00400-0x004FF   |     BIOS data area    |   256b    | 1k - 1.25k   |
|0x00500-0xDF000   |     free RAM area     | 890.75k   | 1.25k - 892k |
|0xDF000-0xDFFFF   |     BIOS BSS RAM      |     4k    | 892k - 896k  |
|0xE0000-0xEFFFF   |     BIOS ROM L        |    64k    | 896k - 960k  |
|0xF0000-0xFFFFF   |     BIOS ROM H        |    64k    | 960k - 1024k |

## BIOS cpu configuration:

|Register|Value      |
|--------|-----------|
|DS      |0xDF00     |
|SP      |0xDF00:1000|

## Toolchain
https://sourcery.mentor.com/GNUToolchain/release3298

minipro -p SST39SF010A -w ./minipro.bin

