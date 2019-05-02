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
        mov     $0xE000, %ax
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
        mov     $0xE000, %ax
        mov     %ax, %ds
        pop     %ax
        movb    (%di), %al
        pop     %ds
        ret


##################################################
# al: command byte
# di: 3rd command address

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
        call    flash_write

        ret

##################################################
# ax: result

get_rom_id:
        push    %di

        movb    $0x90, %al
        movw    $0x5555, %di
        call    flash_cmd

        movw    $0x0001, %di
        call    flash_read
        xchg    %al, %ah

        movw    $0x0000, %di
        call    flash_read
        push    %ax

        movb    $0xF0, %al
        movw    $0x5555, %di
        call    flash_cmd

        pop     %ax
        pop     %di
        ret

##################################################
# %di: last address
# %al: last data (0xFF if it was a sector erase)
# carry: error

flash_wait_complete:
        push    %bx
        push    %cx

        movb    %al, %bl
        andb    $0x80, %bl      # prepare bit 7

        movw    $0x8000, %cx    # will make this many attempts
        call    flash_read
1:
        dec     %cx
        stc
        jz      2f
        clc
        xchg    %al, %ah
        call    flash_read
        cmp     %al, %ah
        jnz     1b              # toggle, go back
        push    %ax
        and     $0x80, %al
        cmp     %al, %bl        # not true data on bit 7, go back
        pop     %ax
        jnz     1b
2:
        pop     %cx
        pop     %bx
        ret

##################################################
# di: sector
# carry: error

erase_sector:
        push    %ax
        push    %di

        movb    $0x80, %al
        movw    $0x5555, %di
        call    flash_cmd

        movb    $0x30, %al
        pop     %di
        call    flash_cmd

        movb    $0xFF, %al          
        call    flash_wait_complete

        pop     %ax
        ret

##################################################
# carry: error

erase_chip:
        push    %ax
        push    %di

        movb    $0x80, %al
        movw    $0x5555, %di
        call    flash_cmd

        movb    $0x10, %al
        movw    $0x5555, %di
        call    flash_cmd

        movb    $0xFF, %al
        call    flash_wait_complete

        pop     %di
        pop     %ax
        ret

##################################################
# %di: address
# %al: data
# carry: error

program_byte:
        push    %ax
        push    %di

        movb    $0xA0, %al
        movw    $0x5555, %di
        call    flash_cmd

        pop     %di
        pop     %ax
        call    flash_write
        call    flash_wait_complete
        ret

##################################################
# es: data source
# carry: error

program_seg:
        push    %ax
        push    %cx
        push    %dx

        movb    $'\n', %al
        call    print_byte

        movw    $0x0000, %cx            # cycle counter
sector_loop:
        mov     %cx, %di
        call    erase_sector
        jc      1f
        movb    $'-', %al
        call    print_byte
        add     $FLASH_SECT_SIZE, %cx
        jnz     sector_loop

        movb    $'\n', %al
        call    print_byte

        movw    $0x0000, %cx            # cycle counter
        movw    $FLASH_SECT_SIZE, %dx   # cycle counter
byte_loop:
        mov     %cx, %di
        movb    %es:(%di), %al
        call    program_byte
        jc      1f

        dec     %dx
        jnz     2f
        movw    $FLASH_SECT_SIZE, %dx   # cycle counter
        movb    $'+', %al
        call    print_byte
2:
        inc     %cx
        jnz     byte_loop

        movb    $'\n', %al
        call    print_byte

        movw    $0x0000, %cx            # cycle counter
        movw    $FLASH_SECT_SIZE, %dx   # cycle counter
verify_loop:
        mov     %cx, %di
        call    flash_read
        cmpb    %es:(%di), %al
        jnz     1f

        dec     %dx
        jnz     2f
        movw    $FLASH_SECT_SIZE, %dx   # cycle counter
        movb    $'=', %al
        call    print_byte
2:
        inc     %cx
        jnz     verify_loop

        movb    $'\n', %al
        call    print_byte

1:
        pop     %dx
        pop     %cx
        pop     %ax
        ret


