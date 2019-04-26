
.equ    LED_BIT,    0x08
.equ    NLED_BIT,    0xF7


##################################################
# doesn't use neither data nor stack (RAM)
# bx: number of blinks

halt_blink:
        mov     %bx, %di
hb_forever:
        mov     %di, %bx
hb_blinks:

        mov     $0x3000, %cx
hb_off_loop:
        nop
        dec     %cx
        nop
        or      %cx,%cx
        jnz     hb_off_loop
        movb    $LED_BIT, %al
        outb    %al, $IO_BASE

        mov     $0x2000, %cx
hb_on_loop:
        nop
        dec     %cx
        nop
        or      %cx,%cx
        jnz     hb_on_loop
        movb    $0x00, %al
        outb    %al, $IO_BASE

        dec     %bx
        jne     hb_blinks

        mov     $0xE000, %cx
hb_break_loop:    
        nop
        dec     %cx
        nop     
        or      %cx,%cx
        jnz     hb_break_loop

        jmp     hb_forever


##################################################

led_flip:
        push    %ax
        inb     $IO_BASE, %al
        xor     $LED_BIT, %al
        outb    %al, $IO_BASE
        pop     %ax
        ret

##################################################

led_on:
        push    %ax
        inb     $IO_BASE, %al
        or      $LED_BIT, %al
        outb    %al, $IO_BASE
        pop     %ax
        ret

##################################################

led_off:
        push    %ax
        inb     $IO_BASE, %al
        and     $NLED_BIT, %al
        outb    %al, $IO_BASE
        pop     %ax
        ret



