
.equ    SDCMD_IDLE,        0    # R1(0x01)
.equ    SDCMD_INIT,        1    # R1(0x00)
.equ    SDCMD_CSD_READ,    9    # R1(0x00) + [0xFE + 32bytes + CRC16]
.equ    SDCMD_CID_READ,    10   # R1(0x00) + [0xFE + 32bytes + CRC16]
.equ    SDCMD_READBLOCK,   17   # R1(0x00) + [0xFE + 512bytes + CRC16]
.equ    SDCMD_WRITEBLOCK,  24

# BIT 5
.equ    DET_BIT,        0x20

##################################################
.section .bss

.local sdcard_blocks_lo                 # number of total blocks
.comm sdcard_blocks_lo, 2, 2
.local sdcard_blocks_hi
.comm sdcard_blocks_hi, 2, 2

.local sdcard_block_to_byte             # rotate cycles
.comm sdcard_block_to_byte, 2, 2

.local sdcard_init_data                 # sdcard init parameters
.comm sdcard_init_data, 16, 2

.section .text

##################################################
sd_delay:
        push    %cx
        mov     $0x0010, %cx        # 16 cycles
1:
        nop
        loop    1b
        pop     %cx
        ret

##################################################
sd_dummy_clocks:
        push    %ax
        push    %cx
        call    sd_delay
        mov     $0x000A, %cx        # 10 bytes
1:
        movb    $0xFF, %al
        call    spi_transfer
        loop    1b

        call    sd_delay
        pop     %cx
        pop     %ax
        ret

##################################################
# carry set: card not present

sd_hwdet:
        push    %ax
        
        inb     $IO_BASE, %al
        andb    $DET_BIT, %al
        clc
        jz      1f
        stc
1:        
        pop     %ax
        ret


##################################################
# al: command, response
# cx: arg lo
# dx: arg hi

sd_command:
        push    %bx
        orb     $0x40, %al          # prefix
        call    spi_transfer        # cmd
        movb    %dh, %al
        call    spi_transfer        # byte 3
        movb    %dl, %al
        call    spi_transfer        # byte 2
        movb    %ch, %al
        call    spi_transfer        # byte 1
        movb    %cl, %al
        call    spi_transfer        # byte 0
        movb    $0x95, %al
        call    spi_transfer        # CRC

        push    %cx
        mov     $0x0200, %cx        # 512 retries
1:
        movb    $0xFF, %al
        call    spi_transfer        # receive response
        movb    %al, %bl
        andb    $0x80, %bl
        jz      2f
        call    sd_delay
        loop    1b
2:
        pop     %cx
        pop     %bx
        ret


##################################################
# es:(di)     buffer
# cx: bytes to read (not including 2 bytes of CRC)
# carry set: error

sd_read_data:
        push    %ax
        push    %bx
        push    %di
        push    %cx

        mov     $0x0100, %cx        # Waiting for the data token, 256 cycles
1:        
        movb    $0xFF, %al
        call    spi_transfer
        cmpb    $0xFE, %al
        jz      2f                  # Data token received, GO!
        movb    %al, %bl
        andb    $0xE0, %bl
        stc
        jz      9f                  # Error token received, bail
        call    sd_delay
        loop    1b
        stc
        jmp     9f
2:        
        pop     %cx
        push    %cx                 # pop number of bytes into %cx
3:
        movb    $0xFF, %al
        call    spi_transfer
        movb    %al, %es:(%di)
        inc     %di
        loop    3b

        movb    $0xFF, %al
        call    spi_transfer        # CRC byte 1
        movb    $0xFF, %al
        call    spi_transfer        # CRC byte 2

        call    sd_delay
        clc
9:
        pop     %cx
        pop     %di
        pop     %bx
        pop     %ax
        ret


##################################################
# es:(di)     buffer
# cx: bytes to read (!! must be integer multiple of 16)
# carry set: error

sd_read_data_16:
        push    %ax
        push    %bx
        push    %di
        push    %cx

        mov     $0x0100, %cx        # Waiting for the data token, 256 cycles
1:        
        movb    $0xFF, %al
        call    spi_transfer
        cmpb    $0xFE, %al
        jz      2f                  # Data token received, GO!
        movb    %al, %bl
        andb    $0xE0, %bl
        stc
        jz      9f                  # Error token received, bail
        call    sd_delay
        loop    1b
        stc
        jmp     9f
2:        
        pop     %cx
        push    %cx                 # pop number of bytes into %cx
        shr     $1, %cx
        shr     $1, %cx
        shr     $1, %cx
        shr     $1, %cx             # dividing the number of bytes by 16
3:
        call    spi_read_16
        loop    3b

        movb    $0xFF, %al
        call    spi_transfer        # CRC byte 1
        movb    $0xFF, %al
        call    spi_transfer        # CRC byte 2

        call    sd_delay
        clc
9:
        pop     %cx
        pop     %di
        pop     %bx
        pop     %ax
        ret


##################################################
# es:(di)     buffer
# cx: bytes to write (not including 2 bytes of CRC)
# carry set: error

sd_write_data:
        push    %ax
        push    %bx
        push    %di
        push    %cx

        movb    $0xFE, %al          # Sending data token
        call    spi_transfer
        call    sd_delay

        pop     %cx
        push    %cx                 # pop number of bytes into %cx
3:
        movb    %es:(%di), %al
        call    spi_transfer
        inc     %di
        loop    3b
        call    sd_delay

        mov     $0x0100, %cx        # Waiting for the data accepted token, 256 cycles
1:
        movb    $0xFF, %al
        call    spi_transfer
        orb     $0x1F, %al
        cmpb    $0x05, %al
        jz      2f                  # Data accepted
        loop    1b
        stc
        jmp     9f                  # Data never got accepted
2:
        
        mov     $0x0100, %cx        # Waiting for the write to finish, 256 cycles
1:
        movb    $0xFF, %al
        call    spi_transfer
        orb     %al, %al
        jnz     2f                  # Write finished
        loop    1b
        stc
        jmp     9f                  # Data never got accepted
2:

        clc
9:
        pop     %cx
        pop     %di
        pop     %bx
        pop     %ax
        ret


##################################################
# huge function: initializes the card and gets its size
# carry: error

sd_init:
        push    %ax
        push    %cx
        push    %dx
        push    %ds
        push    %es
        push    %di

        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     %ax, %es

        call    sd_hwdet
        jc      9f                  # card not present, skip init

# --- send IDLE command 
        call    sd_dummy_clocks
        mov     $0x0008, %cx        # 8 retries
1:
        push    %cx
        call    spi_assert
        call    sd_delay
        xor     %cx, %cx
        xor     %dx, %dx
        movb    $SDCMD_IDLE, %al
        call    sd_command
        call    spi_deassert
        pop     %cx
        cmpb    $0x01, %al
        clc
        jz      2f                  # OK, continue
        call    sd_delay
        loop    1b
        stc
        jmp     9f                  # bail on error
2:
# --- send init command
        call    sd_dummy_clocks
        mov     $0x0100, %cx        # many retries, this can take a long time
3:
        push    %cx
        call    spi_assert
        call    sd_delay
        xor     %cx, %cx
        xor     %dx, %dx
        movb    $SDCMD_INIT, %al
        call    sd_command
        call    spi_deassert
        pop     %cx
        orb     %al, %al
        clc
        jz      4f                  # Initialization complete
        call    sd_delay
        stc
        loop    3b
4:
# --- get card parameters
        call    spi_assert
        call    sd_delay
        xor     %cx, %cx
        xor     %dx, %dx
        movb    $SDCMD_CSD_READ, %al
        call    sd_command
        orb     %al, %al
        stc
        jnz     9f                  # bail if response is not OK (0x00)
# --- read data
        call    sd_delay
        mov     $DSEG, %cx
        mov     %cx, %es
        mov     $sdcard_init_data, %di
        mov     $0x0010, %cx        # 16 bytes
        call    sd_read_data        # into es:(di)
        jc      9f
        call    spi_deassert

# --- extract C_SIZE
        movb    %es:0x06(%di), %ah
        andb    $0x03, %ah          # lowest 2 bits
        movb    %es:0x08(%di), %al
        andb    $0xC0, %al          # highest 2 bits
        orb     %al, %ah
        movb    %es:0x07(%di), %al
        rol     $1, %ax
        rol     $1, %ax
        mov     %ax, %ds:sdcard_blocks_lo
# --- extract READ_BL_LEN
        movb    %es:0x05(%di), %cl
        andb    $0x0F, %cl          # lowest 4 bits
        xor     %ch, %ch
        movw    %cx, %ds:sdcard_block_to_byte
# --- extract C_SIZE_MULT
        movb    %es:0x09(%di), %al
        andb    $0x03, %al          # lowest 2 bits
        movb    %es:0x0A(%di), %ah
        andb    $0x80, %ah          # highest 1 bit
        rol     $1, %ax
        inc     %al
        inc     %al
# --- calculate card size
        movb    %al, %cl
        mov     $0x0001, %ax
        shl     %cl, %ax
        mov     %ax, %cx
        mov     %ds:sdcard_blocks_lo, %ax
        inc     %ax                 # ((size + 1)* mult * bytes)
        mul     %cx
        mov     %ax, %ds:sdcard_blocks_lo
        mov     %dx, %ds:sdcard_blocks_hi

        clc
9:
        pushf
        call    spi_deassert
        popf
        pop     %di
        pop     %es
        pop     %ds
        pop     %dx
        pop     %cx
        pop     %ax
        ret

##################################################
# cx: block num lo
# dx: block num hi
# es:(di)     buffer
# carry: error

sd_read_block:
        push    %ax
        push    %cx
        push    %dx

        movw    %cx, %ax
        movw    %ds:sdcard_block_to_byte, %cx
1:
        shl     %ax                 # uppermost bit goes to carry
        rcl     %dx                 # lowest bit comes from the carry
        loop    1b

        mov     %ax, %cx

        call    spi_assert
        call    sd_delay
        movb    $SDCMD_READBLOCK, %al
        call    sd_command
        orb     %al, %al
        stc
        jnz     2f                  # 0x00 response, OK
        movw    %ds:sdcard_block_to_byte, %cx
        mov     $0x0001, %ax
        shl     %cl, %ax
        mov     %ax, %cx
        call    sd_read_data_16
2:
        pushf
        call    spi_deassert
        popf
        pop     %dx
        pop     %cx
        pop     %ax
        ret


##################################################
# cx: block num lo
# dx: block num hi
# es:(di)     buffer
# carry: error

sd_write_block:
        push    %ax
        push    %cx
        push    %dx

        movw    %cx, %ax
        movw    %ds:sdcard_block_to_byte, %cx
1:
        shl     %ax                 # uppermost bit goes to carry
        rcl     %dx                 # lowest bit comes from the carry
        loop    1b

        mov     %ax, %cx

        call    spi_assert
        call    sd_delay
        movb    $SDCMD_WRITEBLOCK, %al
        call    sd_command
        orb     %al, %al
        stc
        jnz     2f                  # 0x00 response, OK
        movw    %ds:sdcard_block_to_byte, %cx
        mov     $0x0001, %ax
        shl     %cl, %ax
        mov     %ax, %cx
        call    sd_write_data
2:
        pushf
        call    spi_deassert
        popf
        pop     %dx
        pop     %cx
        pop     %ax
        ret


##################################################


