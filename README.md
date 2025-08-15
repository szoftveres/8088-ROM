# DIY x86 single-board computer and ROM BIOS
Designed to fulfill my desire to dig deep into low-level x86/PC/DOS, including hardware (8259 PIC, 16550 UART), BIOS and x86 assembly. Capable of running text-based DOS programs, including EDLIN, TASM and TCC.
 * CPU: 80C88-2,   5.5296 MHz
 * RAM: 896 kB
 * ROM: 128 kB
 * I/O: 16C550 UART
 * Storage: SD Card (1.44 Mb partition)
 * OS: [FreeDOS](https://www.freedos.org/)

## -> [Schematics (pdf)](schematics.pdf) <-

![image small x86](pcb.png)
![pcbd](pcbd.png)
![image board3](board3.jpg)

### Character I/O
The computer has no VGA adapter or keyboard interface, all interaction happens through the UART. In order to provide PC compatibility to text-based programs, INT 10h (VGA character out) and INT 16h (keyboard character in) BIOS calls are routed to the UART; this gives terminal-like access to text-based programs, like the FreeDOS shell.

### SD card interface, and storage device access through BIOS INT 13h calls:
The computer has a basic I/O port (4 bit in, 4 bit out), a virtual SPI interface is implemented on top of it through software (bit-banging). A daughter board with an SD card slot plugs directly into the I/O port socket and the BIOS implements SD card access routines on the virtual SPI interface.

On startup, the BIOS looks for an SD card on the SPI interface and searches for a valid MS-DOS partition on it. If a partition is found and has an exact size of 1.44MB, the computer can boot from it and the OS can read from and write to it via PC standard BIOS INT 13h calls, just as if it was an actual 1.44MB floppy disk.

![fddir1](fddir1.png)

The position-independent BIOS code can run from any 64k segment of the address space (even from RAM). Also, the BIOS provides routines for receiving 64k blocks via UART (e.g. a BIOS update), moving them around in the memory and burning them into the EEPROM - these features enable in-system EEPROM programming and development, without the need for an external EEPROM burner device.

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

