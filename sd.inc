
.equ    SDCMD_INIT,        0
.equ    SDCMD_READBLOCK,   17
.equ    SDCMD_WRITEBLOCK,  24


##################################################
.section .bss

.local sdcard_ok
.comm sdcard_ok, 2, 2

.section .text
##################################################
# al: command, response
# cx: arg lo
# dx: arg hi
# carry: error

sd_command:
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
        mov     $0x0100, %cx        # 256 retries
1:
        
        movb    $0xFF, %al
        call    spi_transfer        # receive response
        clc
        cmpb    $0xFF, %al
        jz      2f
        loop    1b
        stc
2:
        pop     %cx
        ret

##################################################

sd_init:
        push    %ax
        push    %cx
        push    %dx

        mov     $0x0010, %cx        # 16 retries

1:
        push    %cx
        xor     %cx, %cx
        xor     %dx, %dx
        movb    $SDCMD_INIT, %al
        call    sd_command
        pop     %cx
        jc      2f
        loop    1b
2:


        pop     %dx
        pop     %cx
        pop     %ax
        ret



