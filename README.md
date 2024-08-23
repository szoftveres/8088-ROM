# 8088-ROM

This is a DIY x86 single-board computer and ROM BIOS that is capable of booting into [FreeDOS](https://www.freedos.org/) and running text-based DOS programs.
The system is equipped with an 80C88 (or compatible) CPU running at 5.5296MHz, 1MB SRAM, 128kB in-system programmable BIOS EEPROM, an RS232 compatible 16C550 serial port (IRQ7), two fixed time interval sources: 32kHz (IRQ5) and 2Hz (IRQ4), a 4-bit I/O port, SPI and SD-card interfaces and an 82C59A programmable interrupt controller.

![image small x86](pcb.png)
## [Schematics (pdf)](schematics.pdf) <--
![pcbd](pcbd.png)
![image board3](board3.jpg)



BIOS INT 10h and INT 16h calls are re-routed to the (non- PC-standard address and IRQ) UART, which is the default character I/O device for this system.

### SD card interface:
A software-defined (bit-banged) SPI interface is implemented on top of the I/O port with all the necessary BIOS routines to read and write an SD card. On startup, the BIOS looks for an SD card on the SPI interface and searches for a valid MS-DOS partition on it. If a partition is found and has an exact size of 1.44MB, the BIOS gives access to it via standard BIOS INT 13h calls, as if it was an actual 1.44MB floppy disk. Subsequently, a standard IBM PC compatible OS boot process can take place.

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

