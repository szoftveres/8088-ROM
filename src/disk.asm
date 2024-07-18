
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




.global last_read_sector
.comm last_read_sector, 2, 2
.global disk_buffer
.comm disk_buffer, 512, 2

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
# ds must be set up to point to the variables
# %si: DPT

disk_init:
        push    %ax
        push    %di
        push    %es             # save ES
# --- set up DPT in int 1Eh
        movw    $ZEROSEG, %di
        movw    %di, %es
        movw    $0x0078, %di    # int 0x1E vector, L
        movw    %si, %es:(%di)
        movw    $0x007A, %di    # int 0x1E vector, H
        movw    %cs, %es:(%di)
# --- set up our own params
        xor     %ax, %ax
        movb    %cs:0x0c(%si), %al      # heads
        movw    %ax, %ds:disk_heads
        movb    %cs:0x0b(%si), %al      # cylinders
        movw    %ax, %ds:disk_cylinders
        movb    %cs:0x04(%si), %al      # sectors
        movw    %ax, %ds:disk_sectors

        pop     %es             # restore ES
        pop     %di
        pop     %ax
        ret

##################################################
# ds must be set up to point to the variables
# cx: cylinder + sector  (in INT13h format)
# dh: head
# cx: result

disk_chs_to_lba:
        push    %ax
        mov     %cx, %ax
        andw    $0x003F, %ax        # lowest 6 bits
        dec     %ax
        push    %ax                 # we have the sector - 1

        movb    %dh, %al
        xor     %ah,%ah
        push    %ax                 # we have the head

        movb    %cl, %ah
        rol     %ah
        rol     %ah
        and     $0x03, %ah
        movb    %ch, %al            # we have the cylinder

        mov     %ds:disk_heads, %cx     # nHeads
        mul     %cx                 # (Cyl × nHeads)

        pop     %cx                 # Head
        add     %cx, %ax            # ((Cyl × nHeads) + Head)
        
        mov     %ds:disk_sectors, %cx   # nSects
        mul     %cx                 # (((Cyl × nHeads) + Head) × nSects)

        pop     %cx                 # (Sect − 1)
        add     %cx, %ax            # (((Cyl × nHeads) + Head) × nSects) + (Sect − 1)

        mov     %ax, %cx

        pop     %ax
        ret


##################################################
# int 13h 02 handler
# ds must be set up to point to the variables (IRQ_DISPATCH does that)

disk_read_chs:
        push    %ax
        push    %bx
        push    %cx
        push    %dx
        push    %di

# -- debug --
#        push    %ax         # int_dbg alters %al, hence saving it
#        push    %bp
#        mov     $0x0013, %bp
#        push    %bp
#        call    int_dbg
#        pop     %bp
#        pop     %bp
#        pop     %ax
# -- end debug --

        call    disk_chs_to_lba                 # get the sector num
        addw    %ds:partition_offset_lba_lo, %cx    # start offset

        mov     %bx, %di                        # es:(di) buffer
1:
        xor     %dx, %dx
        call    sd_read_block
        addw    $0x0200, %di
        inc     %cx
        dec     %al
        jnz     1b

        pop     %di
        pop     %dx
        pop     %cx
        pop     %bx
        pop     %ax

        xorb    %ah, %ah
        clc
        ret


##################################################
# carry: error
# ax: error message

disk_reset:
        push    %cx
        push    %dx
        push    %es
        push    %si
        push    %di



# -- debug --
#        push    %ax         # int_dbg alters %al, hence saving it
#        push    %bp
#        mov     $0x0013, %bp
#        push    %bp
#        call    int_dbg
#        pop     %bp
#        pop     %bp
#        pop     %ax
# -- end debug --


        mov     $DSEG, %cx
        mov     %cx, %es

        movw    %ds:(sdcard_block_to_byte), %ax
        cmpw    $0x0009, %ax
        movb    $0xAA, %ah                  # SDcard block size is not 512
        stc
        jnz     9f

# --- load the MBR
        mov     $disk_buffer, %di
        mov     $0x0000, %cx
        mov     $0x0000, %dx
        call    sd_read_block               # into %es:(%di)
        movb    $0xAA, %ah                  # Cannot read MBR
        jc      9f

        movw    $0xAA55, %ax                # MBR signature
        cmpw    %es:(disk_buffer + 510), %ax
        movb    $0xAA, %ah                  # MBR signature mismatch
        stc
        jnz     9f
# --- extract the partiton table from the disk buffer into 'partition status'
        movw    $0x0010, %cx                # one partition entry, 16 bytes
        movw    $(disk_buffer + 446), %si   # 446 bytes
        movw    $partition_status, %di
1:
        movb    %es:(%si), %al
        movb    %al, %ds:(%di)
        inc     %si
        inc     %di
        loop    1b
# --- check if partition is bootable
        movb    %ds:partition_status, %al
        cmpb    $0x80, %al
        movb    $0xAA, %ah                  # First partition isn't active
        stc
        jnz     9f
# --- check partition size and select disk parameters
        movw    %ds:partition_total_sects_hi, %ax
        or      %ax, %ax
        movb    $0xAA, %ah                  # Incompatible partition size
        stc
        jnz     9f

        movw    %ds:partition_total_sects_lo, %ax
        cmpw    $0x0B40, %ax                # 2880(0x0B40) x 512 = 1.44Mb
        jnz     1f
        mov     $dpt_1440, %si
        call    disk_init
        jmp     2f
1:
        movw    %ds:partition_total_sects_lo, %ax
        cmpw    $0x0960, %ax                # 2400(0x0960) x 512 = 1.2Mb
        jnz     1f
        mov     $dpt_1200, %si
        call    disk_init
        jmp     2f
1:
        movw    %ds:partition_total_sects_lo, %ax
        cmpw    $0x02D0, %ax                # 720(0x0@D0) x 512 = 360kb
        jnz     1f
        mov     $dpt_360, %si
        call    disk_init
        jmp     2f
1:
        movb    $0xAA, %ah                  # Unrecognized partition size
        stc
        jmp     9f
2:
        movb    $0x00, %ah                  # All good
        clc
9:
        pop     %di
        pop     %si
        pop     %es
        pop     %dx
        pop     %cx
        ret

##################################################

ipl:
        push    %cx
        push    %dx
        push    %es
        push    %di
        mov     $ZEROSEG, %cx
        mov     %cx, %es

# --- load the boot sector of the first partition to 7C00
        mov     $BOOTADDR, %di
        mov     %ds:partition_offset_lba_lo, %cx
        mov     %ds:partition_offset_lba_hi, %dx

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
text_ipl_bootsect:
        .asciz   "boot sector not found\n"

##################################################

