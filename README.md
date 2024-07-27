# 8088-ROM
8088 single-board computer and ROM BIOS

![image small x86](pcb.png)
![pcbd](pcbd.png)
![image board3](board3.jpg)


* ![Schematics](schematics.pdf)


This is a hobby i8088 single board computer and ROM BIOS, capable of booting into FreeDOS.
The board features a 16550 UART (IRQ7), two periodical time sources: 32kHz (IRQ5) and 2Hz (IRQ4), a 4-bit I/O port, 1Mb SRAM, 128k EEPROM, SPI and SD-card interfaces.

Standard I/O calls (INT 10h and INT 16h) are re-routed to the UART, which is the default I/O device for this system.

The board supports **SD card** as a storage media:
A software SPI bus is implemented on top of the I/O port and the ROM has all the routines to access the SD card through SPI bus. On startup, the BIOS checks for the presence of an SD card and tries to find a valid MS-DOS partition on it. Once it finds a valid partition that has the exact size of 1.44Mb, it gives access to it via the IBM PC standard INT 13h calls, just as if the 1.44Mb partition on the SD card was an actual 1.44Mb floppy disk. An OS can then be booted, just like on normal PCs.

![fddir1](fddir1.png)

BIOS features include the ability to move the contents of the BIOS ROM to RAM and restart the execution from RAM, the ability to receive 64k binary blocks via the UART, place them into RAM and execute them, as well as burn the contents of a RAM segment into the EEPROM. These features together enable the development of the software wihtout the need of any external EEPROM burner device.

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

