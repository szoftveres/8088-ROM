
### 1.44Mb floppy 
# 512 byte / sector
# 18 sector / track
# 2 heads
# 80 cylinders
# 2880 sectors

##################################################
.section .bss

# --- disk geometry parameters

.local disk_heads
.comm disk_heads, 2, 2
.local disk_cylinders
.comm disk_cylinders, 2, 2
.local disk_sectors
.comm disk_sectors, 2, 2


# --- Partition table, 16 bytes

.local partition_status
.comm partition_status, 1, 1
.local partition_hstart
.comm partition_hstart, 1, 1
.local partition_csstart
.comm partition_csstart, 2, 1
.local partition_type
.comm partition_type, 1, 1
.local partition_hend
.comm partition_hend, 1, 1
.local partition_csend
.comm partition_csend, 2, 1
.local partition_offset_lba_lo
.comm partition_offset_lba_lo, 2, 1
.local partition_offset_lba_hi
.comm partition_offset_lba_hi, 2, 1
.local partition_total_sects_lo
.comm partition_total_sects_lo, 2, 1
.local partition_total_sects_hi
.comm partition_total_sects_hi, 2, 1

##################################################

.section .text

##################################################
# carry: error
# ax: error message

ipl:
        push    %cx
        push    %dx
        push    %ds
        push    %es
        push    %di

        mov     $BOOTSEG, %cx
        mov     %cx, %es
        mov     $BOOTADDR, %di
        mov     $DSEG, %cx
        mov     %cx, %ds

        movw    sdcard_block_to_byte, %ax
        cmpw    $0x0009, %ax
        movw    $text_ipl_non512k, %ax      # SDcard block size is not 512
        stc
        jnz     9f

# --- load the MBR to 7C00
        mov     $BOOTADDR, %di
        mov     $0x0000, %cx
        mov     $0x0000, %dx
        call    sd_read_block
        movw    $text_ipl_sdcard, %ax
        jc      9f

        movw    $0xAA55, %ax                # MBR signature
        cmpw    %es:(BOOTADDR + 510), %ax
        movw    $text_ipl_mbr, %ax          # MBR signature mismatch
        stc
        jnz     9f
# --- extract the partiton table
        movw    $0x0010, %cx                # one partition entry, 16 bytes
        movw    $(BOOTADDR + 446), %si      # 7C00 + 446 bytes
        movw    $partition_status, %di
1:
        movb    %es:(%si), %al
        movb    %al, %ds:(%di)
        inc     %si
        inc     %di
        loop    1b
# --- check if partition is bootable
        movb    partition_status, %al
        cmpb    $0x80, %al
        movw    $text_ipl_activepar, %ax    # first partiton is not active
        stc
        jnz     9f
# --- check if partition size equals to 1.44Mb
        movw    partition_total_sects_hi, %ax
        or      %ax, %ax
        movw    $text_ipl_parsize, %ax      # first partiton is not 1.44Mb
        stc
        jnz     9f
        movw    partition_total_sects_lo, %ax
        cmpw    $0x0B40, %ax                # 2880(0x0B40) x 512 = 1.44Mb
        movw    $text_ipl_parsize, %ax      # first partiton is not 1.44Mb
        stc
        jnz     9f

# --- load the boot sector of the first partition to 7C00
        mov     $BOOTADDR, %di
        mov     partition_offset_lba_lo, %cx
        mov     partition_offset_lba_hi, %dx

        call    sd_read_block
        movw    $text_ipl_sdcard, %ax
        jc      9f
# --- check if partition is a bootable 1.44M one
        movw    $0xAA55, %ax                # boot sector signature
        cmpw    %es:(BOOTADDR + 510), %ax
        movw    $text_ipl_bootsect, %ax     # boot sector signature mismatch
        stc
        jnz     9f

        clc
9:
        pop     %di
        pop     %es
        pop     %ds
        pop     %dx
        pop     %cx
        ret

text_ipl_sdcard:
        .asciz   "SD card read error\n"
text_ipl_non512k:
        .asciz   "incompatible block size\n"
text_ipl_mbr:
        .asciz   "MBR not found\n"
text_ipl_activepar:
        .asciz   "active partition not found\n"
text_ipl_parsize:
        .asciz   "incompatible partition size\n"
text_ipl_bootsect:
        .asciz   "boot sector not found\n"

##################################################

