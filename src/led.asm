
.equ    LED_BIT,    0x08
.equ    NLED_BIT,    0xF7



.equ    CPU_ERROR,    2
.equ    RAM_ERROR,    3


##################################################
# Fatal error LED code blinker
# no ram needed at all
# bl: number of blinks (error code)

halt_blink:
        movb    %bl, %bh            # save the blink no. in %bh
hb_forever:
        movb    %bh, %bl
hb_blinks:
        mov     $0x6000, %cx
hb_off_loop:
        nop
        nop
        nop
        nop
        loop    hb_off_loop

        movb    $0xFF, %al
        outb    %al, $IO_BASE
        mov     $0x3000, %cx
hb_on_loop:
        nop
        nop
        nop
        nop
        loop    hb_on_loop

        movb    $NLED_BIT, %al
        outb    %al, $IO_BASE

        dec     %bl
        jne     hb_blinks

        mov     $0xF000, %cx
hb_break_loop:    
        nop
        nop
        nop
        nop
        nop
        nop     
        loop    hb_break_loop

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

