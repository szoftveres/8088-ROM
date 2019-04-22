
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
        mov     $IO_BASE, %dx
        movb    $LED_BIT, %al
        out     %al, (%dx)

        mov     $0x2000, %cx
hb_on_loop:
        nop
        dec     %cx
        nop
        or      %cx,%cx
        jnz     hb_on_loop
        mov     $IO_BASE, %dx
        movb    $0x00, %al
        out     %al, (%dx)

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
        push    %dx
        push    %ax
        mov     $IO_BASE, %dx
        in      (%dx), %al
        xor     $LED_BIT, %ax
        out     %al, (%dx)
        pop     %ax
        pop     %dx
        ret

##################################################

led_on:
        push    %dx
        push    %ax
        mov     $IO_BASE, %dx
        in      (%dx), %al
        or      $LED_BIT, %ax
        out     %al, (%dx)
        pop     %ax
        pop     %dx
        ret

##################################################

led_off:
        push    %dx
        push    %ax
        mov     $IO_BASE, %dx
        in      (%dx), %al
        and     $NLED_BIT, %ax
        out     %al, (%dx)
        pop     %ax
        pop     %dx
        ret



