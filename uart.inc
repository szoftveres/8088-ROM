
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
        movb    $0x06, %al              # 6 (38400 baud @ 3.6864MHz)
        outb    %al, $UART_BASE+0       # divisor LSB
        movb    $0x00, %al              # 0 (38400 baud @ 3.6864MHz)
        outb    %al, $UART_BASE+1       # divisor MSB
        movb    $0x03, %al              # DLAB = 0,    N,8,1
        outb    %al, $UART_BASE+3       # LCR
        movb    $0x00, %al              # 
        outb    %al, $UART_BASE+4       # MCR
        movb    $0xC7, %al              # FIFO enable, clear, 14 byte trigger
        outb    %al, $UART_BASE+2       # FCR
#        movb    $0x03, %al              # enable tx and rx interrupts
        movb    $0x01, %al              # enable rx interrupts
        outb    %al, $UART_BASE+1       # IER

        xor     %ax, %ax
        movw    %ax, uart_rcvbuf_rd
        movw    %ax, uart_rcvbuf_wr
        pop     %ax
        ret

##################################################
# UART interrupt service

int_uart:
        push    %ax
        push    %si
1:
#        inb     $UART_BASE+2, %al       # Read IIR, this deletes Tx interrupt
        inb     $UART_BASE+5, %al       # LSR
        andb    $0x01, %al              # byte received?
        jz      2f

        mov     uart_rcvbuf_wr, %si
        inc     %si
        and     $0x003F, %si            # 64
        mov     %si, uart_rcvbuf_wr
        inb     $UART_BASE+0, %al
        movb    %al, uart_rcvbuf(%si)

        jmp     1b
2:
        pop     %si
        pop     %ax
        call    pic_eoi
        iret

##################################################
# al: data byte

uart_send_byte:
        push    %ax;
1:
        inb     $UART_BASE+5, %al       # LSR
        and     $0x0020, %ax
        jnz     2f
#        HALT_WAIT                       # halt for interrupt 
        jmp     1b
2:
        pop     %ax
        outb    %al, $UART_BASE+0
        ret

##################################################
# al: return data byte

uart_receive_byte:
        push    %si
1:
        mov     uart_rcvbuf_rd, %si
        cmp     uart_rcvbuf_wr, %si
        jnz     2f
        HALT_WAIT                       # halt for interrupt
        jmp     1b
2:
        inc     %si
        and     $0x003F, %si            # 64
        mov     %si, uart_rcvbuf_rd
        movb    uart_rcvbuf(%si), %al
        pop     %si
        ret

##################################################

