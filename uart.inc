

##################################################
.section .bss

.local uart_rcvbuf
.comm uart_rcvbuf, 64, 2
.local uart_rcvbuf_wr
.comm uart_rcvbuf_wr, 2, 2
.local uart_rcvbuf_rd
.comm uart_rcvbuf_rd, 2, 2

.section .text
##################################################
uart_init:
        push    %ax
        movb    $0x80, %al              # DLAB = 1
        outb    %al, $UART_BASE+3       # LCR
        movb    $0x04, %al              # 16 (38400 baud)
        outb    %al, $UART_BASE+0       # divisor LSB
        movb    $0x00, %al              # 0  (38400 baud)
        outb    %al, $UART_BASE+1       # divisor MSB
        movb    $0x03, %al              # DLAB = 0,    N,8,1
        outb    %al, $UART_BASE+3       # LCR
        movb    $0x00, %al              # 
        outb    %al, $UART_BASE+4       # MCR
        movb    $0xC7, %al              # FIFO enable, clear, 14 byte trigger
        outb    %al, $UART_BASE+2       # FCR
#        movb    $0x03, %al              # enable tx and rx interrupts
        movb    $0x01, %al              # rx interrupts
        outb    %al, $UART_BASE+1       # IER

        xor     %ax, %ax
        movw    %ax, uart_rcvbuf_rd
        movw    %ax, uart_rcvbuf_wr
        pop     %ax
        ret

##################################################

int_uart:
        push    %ax
        push    %bp
        push    %si
1:
        inb     $UART_BASE+5, %al       # LSR
        and     $0x0001, %ax            # byte received?
        jz      2f

        mov     $uart_rcvbuf, %bp
        mov     uart_rcvbuf_wr, %si
        inc     %si
        and     $0x003F, %si            # 64
        mov     %si, uart_rcvbuf_wr
        inb     $UART_BASE+0, %al
        movb    %al, (%bp,%si)

        jmp     1b
2:

        pop     %si
        pop     %bp
        pop     %ax
        call    pic_eoi
        iret


##################################################
# al: data byte

uart_send_byte:
        push    %ax;
uart_send_poll:
        inb     $UART_BASE+5, %al       # LSR
        and     $0x0020, %ax
        jz      uart_send_poll
        pop     %ax
        outb    %al, $UART_BASE+0
        ret

##################################################
# al: return data byte

# uart_receive_byte:
#         inb     $UART_BASE+5, %al       # LSR
#         and     $0x0001, %ax
#         jz      uart_receive_byte
#         inb     $UART_BASE+0, %al
#        ret

uart_receive_byte:
        push    %bp
        push    %si
1:
        mov     uart_rcvbuf_rd, %si
        mov     uart_rcvbuf_wr, %ax
        cmp     %ax, %si
        jnz     2f

        sti
        call    led_on
        hlt
        call    led_off
        cli
        jmp     1b
2:

        mov     $uart_rcvbuf, %bp
        inc     %si
        and     $0x003F, %si            # 64
        mov     %si, uart_rcvbuf_rd
        movb    (%bp,%si), %al

        pop     %si
        pop     %bp

        ret


##################################################

