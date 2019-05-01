.equ    FLASH_SECT_SIZE,        0x1000

##################################################
# zeroFlag: 1: running from RAM    0: running from ROM

check_flash_cs:
        push    %ax
        mov     %cs, %ax
        cmp     $ROMSEG, %ax
        jb      1f
        mov     $0xFFFF, %ax
        or      %ax, %ax        # Z=0
        jmp     2f
1:
        xor     %ax, %ax        # Z=1
2:
        pop     %ax
        ret


##################################################
# di: address
# al: data byte

flash_write:
        push    %ds
        push    %ax
        mov     $0xF000, %ax
        mov     %ax, %ds
        pop     %ax
        movb    %al, (%di)
        pop     %ds
        ret

##################################################
# di: address
# al: data byte

flash_read:
        push    %ds
        push    %ax
        mov     $0xF000, %ax
        mov     %ax, %ds
        pop     %ax
        movb    (%di), %al
        pop     %ds
        ret


##################################################
flash_cmd:
        push    %di
        push    %ax

        movw    $0x5555, %di
        movb    $0xAA, %al
        call    flash_write

        movw    $0x2AAA, %di
        movb    $0x55, %al
        call    flash_write

        pop     %ax
        pop     %di

        ret

##################################################
# ax: result

get_rom_id:
        push    %di
        call    flash_cmd

        movw    $0x5555, %di
        movb    $0x90, %al
        call    flash_write


        movw    $0x0001, %di
        call    flash_read
        xchg    %al, %ah

        movw    $0x0000, %di
        call    flash_read
        push    %ax
        

        call    flash_cmd

        movw    $0x5555, %di
        movb    $0xF0, %al
        call    flash_write

        pop     %ax
        pop     %di
        ret

##################################################
# cx: address

erase_sector:
        push    %di
        push    %ax
        call    flash_cmd

        movw    $0x5555, %di
        movb    $0x80, %al
        call    flash_write

        call    flash_cmd

        movw    %cx, %di
        movb    $0x30, %al
        call    flash_write

                              # check for toggle
        movw    $0x0000, %di
        call    flash_read
1:
        xchg    %al, %ah
        movw    $0x0000, %di
        call    flash_read
        cmp     %al, %ah
        jnz     1b

        pop     %ax
        pop     %di
        ret


##################################################


        movw    $0x0000, %cx            # cycle counter
sector_loop:


        add     $FLASH_SECT_SIZE, %cx
        jnz     sector_loop

