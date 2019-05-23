
### 360k floppy
# 512 b/s
# 2 heads
# 40 cylinders
# 9 sect/track
# 720 sectors

### 1.2Mb floppy
# 512 b/s
# 2 heads
# 80 cylinders
# 15 sect/track
# 2400 sectors

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

dpt_360:
    .byte   0xBF        # 0-3: head unload time, 4-7: step rate
    .byte   0x02        # 0: non-DMA mode, 1-7: head load time
    .byte   0x01        # motor timeout ticks
    .byte   0x02        # sector size, 0x02 == 512b
    .byte   0x09        # sectors per track (9, 0x09)
    .byte   0x1B        # r/w gap length
    .byte   0xFF        # special sectors (0xFF: N/A)
    .byte   0x6C        # format gap length
    .byte   0xFF        # fill byte
    .byte   0x01        # head settle time
    .byte   0x01        # motor start time

    .byte   0x28        # cylinders (40)
    .byte   0x02        # heads (2)

dpt_1200:
    .byte   0xBF        # 0-3: head unload time, 4-7: step rate
    .byte   0x02        # 0: non-DMA mode, 1-7: head load time
    .byte   0x01        # motor timeout ticks
    .byte   0x02        # sector size, 0x02 == 512b
    .byte   0x0F        # sectors per track (15, 0x0F)
    .byte   0x1B        # r/w gap length
    .byte   0xFF        # special sectors (0xFF: N/A)
    .byte   0x6C        # format gap length
    .byte   0xFF        # fill byte
    .byte   0x01        # head settle time
    .byte   0x01        # motor start time

    .byte   0x50        # cylinders (80)
    .byte   0x02        # heads (2)

dpt_1440:
    .byte   0xBF        # 0-3: head unload time, 4-7: step rate
    .byte   0x02        # 0: non-DMA mode, 1-7: head load time
    .byte   0x01        # motor timeout ticks
    .byte   0x02        # sector size, 0x02 == 512b
    .byte   0x12        # sectors per track (18, 0x12)
    .byte   0x1B        # r/w gap length
    .byte   0xFF        # special sectors (0xFF: N/A)
    .byte   0x6C        # format gap length
    .byte   0xFF        # fill byte
    .byte   0x01        # head settle time
    .byte   0x01        # motor start time

    .byte   0x50        # cylinders (80)
    .byte   0x02        # heads (2)

##################################################
# %si: DPT

disk_init:
        push    %ax
        push    %di
        push    %es             # save ES
# --- set up DPT in int 1Eh
        movw    $BOOTSEG, %di
        movw    %di, %es
        movw    $0x0078, %di    # int 0x1E vector, L
        movw    %si, %es:(%di)
        movw    $0x007A, %di    # int 0x1E vector, H
        movw    %cs, %es:(%di)
# --- set up our own params
        xor     %ax, %ax
        movb    %cs:0x0c(%si), %al      # heads
        movw    %ax, disk_heads
        movb    %cs:0x0b(%si), %al      # cylinders
        movw    %ax, disk_cylinders
        movb    %cs:0x04(%si), %al      # sectors
        movw    %ax, disk_sectors

        pop     %es             # restore ES
        pop     %di
        pop     %ax
        ret

##################################################
# ds must be set up
# cx: cylinder + sector  (in INT13h format)
# dh: head
# cx: result

disk_chs_to_lba:
        push    %ax
        mov     %cx, %ax
        and     $0x003F, %ax        # lowest 6 bits
        dec     %ax
        push    %ax                 # we have the sector - 1

        movb    %dh, %al
        push    %ax                 # we have the head

        movb    %cl, %ah
        rol     %ah
        rol     %ah
        movb    %ch, %al
        and     $0x03FF, %ax        # we have the cylinder

        mov     disk_heads, %cx     # nHeads
        mul     %cx                 # (Cyl × nHeads)

        pop     %cx                 # Head
        add     %cx, %ax            # ((Cyl × nHeads) + Head)
        
        mov     disk_sectors, %cx   # nSects
        mul     %cx                 # (((Cyl × nHeads) + Head) × nSects)

        pop     %cx                 # (Sect − 1)
        add     %cx, %ax            # (((Cyl × nHeads) + Head) × nSects) + (Sect − 1)

        mov     %ax, %cx

        pop     %ax
        ret


##################################################
# carry: error
# ax: error message

ipl:
        push    %cx
        push    %dx
        push    %es
        push    %di

        mov     $BOOTSEG, %cx
        mov     %cx, %es
        mov     $BOOTADDR, %di

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
# --- check partition size and select disk parameters
        movw    partition_total_sects_hi, %ax
        or      %ax, %ax
        movw    $text_ipl_parsize, %ax      # this is almost always 00
        stc
        jnz     9f

        movw    partition_total_sects_lo, %ax
        cmpw    $0x0B40, %ax                # 2880(0x0B40) x 512 = 1.44Mb
        jnz     1f
        mov     $dpt_1440, %si
        call    disk_init
        jmp     2f
1:
        movw    partition_total_sects_lo, %ax
        cmpw    $0x0960, %ax                # 2400(0x0960) x 512 = 1.2Mb
        jnz     1f
        mov     $dpt_1200, %si
        call    disk_init
        jmp     2f
1:
        movw    partition_total_sects_lo, %ax
        cmpw    $0x02D0, %ax                # 720(0x0@D0) x 512 = 360kb
        jnz     1f
        mov     $dpt_360, %si
        call    disk_init
        jmp     2f
1:
        movw    $text_ipl_parsize, %ax      # first partiton is not 1.44Mb
        stc
        jnz     9f
2:

# --- load the boot sector of the first partition to 7C00
        mov     $BOOTADDR, %di
        mov     partition_offset_lba_lo, %cx
        mov     partition_offset_lba_hi, %dx

        call    sd_read_block
        movw    $text_ipl_sdcard, %ax
        jc      9f
# --- check if partition is bootable
        movw    $0xAA55, %ax                # boot sector signature
        cmpw    %es:(BOOTADDR + 510), %ax
        movw    $text_ipl_bootsect, %ax     # boot sector signature mismatch
        stc
        jnz     9f

        clc
9:
        pop     %di
        pop     %es
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
