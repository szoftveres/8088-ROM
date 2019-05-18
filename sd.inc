
.equ    SDCMD_IDLE,        0
.equ    SDCMD_INIT,        1
.equ    SDCMD_READBLOCK,   17
.equ    SDCMD_WRITEBLOCK,  24

# BIT 5
.equ    DET_BIT,        0x20

##################################################
.section .bss

.local sdcard_alive
.comm sdcard_alive, 1, 2

.section .text
##################################################
sd_system_init:
        push    %ax
        movb    $0x00, %al
        movb    %al, sdcard_alive
        pop     %ax
        ret

##################################################
# carry: error (carry is the input actually)

sd_mark_state:
        pushf
        push    %ax
        jnc     1f
        movb    $0x00, %al
        movb    %al, sdcard_alive
1:
        pop     %ax
        popf
        ret

##################################################
# carry: not alive

sd_check_state:
        push    %ax
        stc
        movb    sdcard_alive, %al
        orb     %al, %al
        jz      1f
        clc
1:
        pop     %ax
        ret

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
# carry: card not present

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
# carry: error

sd_init:
        push    %ax
        push    %cx
        push    %dx
        push    %ds
        mov     $DSEG, %ax
        mov     %ax, %ds


        movb    $0x55, %al
        movb    %al, sdcard_alive   # first mark the card as alive

        call    sd_hwdet
        jc      4f                  # card not present, skip init

# --- send IDLE command 
        call    sd_dummy_clocks
        mov     $0x0008, %cx        # 8 retries
1:
        push    %cx
        call    spi_assert
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
        stc
        loop    1b
        jmp     4f                  # bail on error
2:
# --- send init command
        call    sd_dummy_clocks
        mov     $0x1000, %cx        # 512 retries
3:
        push    %cx
        call    spi_assert
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
        call    sd_mark_state
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
        push    %bx
        push    %cx
        push    %dx

#        call    sd_check_state      # check and bring up the card if necessary
#        jnc     1f
#        call    sd_init
#        jc      9f
1:
        call    spi_assert
        call    sd_delay

        movb    $SDCMD_READBLOCK, %al
        call    sd_command
        orb     %al, %al
        stc
        jnz     9f                  # 0x00 response, OK

        mov     $0x0100, %cx        # Waiting for the data token, 256 cycles
2:        
        movb    $0xFF, %al
        call    spi_transfer
        cmpb    $0xFE, %al          # Data token received, GO!
        jz      3f
        movb    %al, %bl
        andb    $0xEF, %bl
        stc
        jz      9f                  # Error token received, bail
        call    sd_delay
        loop    2b
3:        

        mov     $0x0200, %cx        # Reading 512 bytes (a block)
4:
        movb    $0xFF, %al
        call    spi_transfer
        movb    %al, %es:(%di)
        inc     %di
        loop    4b

        movb    $0xFF, %al
        call    spi_transfer        # CRC byte 1
        movb    $0xFF, %al
        call    spi_transfer        # CRC byte 2

        call    sd_delay
        clc
9:
        call    sd_mark_state
        call    spi_deassert
        pop     %dx
        pop     %cx
        pop     %bx
        pop     %ax
        ret


