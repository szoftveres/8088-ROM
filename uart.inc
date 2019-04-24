

##################################################
uart_init:
        mov     $UART_BASE+3, %dx       # LCR
        movb    $0x80, %al              # DLAB = 1
        outb    %al, (%dx)
        mov     $UART_BASE+0, %dx       # divisor LSB
        movb    $0x10, %al              # 16 (9600 baud)
        outb    %al, (%dx)
        mov     $UART_BASE+1, %dx       # divisor MSB
        movb    $0x00, %al              # 0  (9600 baud)
        outb    %al, (%dx)
        mov     $UART_BASE+3, %dx       # LCR
        movb    $0x03, %al              # DLAB = 0,    N,8,1
        outb    %al, (%dx)
        mov     $UART_BASE+4, %dx       # MCR
        movb    $0x00, %al              # 
        outb    %al, (%dx)
        mov     $UART_BASE+2, %dx       # FCR
        movb    $0x87, %al              # FIFO enable, clear, 8 byte trigger
        outb    %al, (%dx)
        mov     $UART_BASE+1, %dx       # IER
#        movb    $0x03, %al              # enable tx and rx interrupts
        movb    $0x05, %al              # rx interrupts
        outb    %al, (%dx)
        ret

##################################################
# al: data byte

uart_send_byte:
        push    %dx;
        push    %ax;
uart_send_poll:
        mov     $UART_BASE+5, %dx       # LSR
        inb     (%dx), %al
        and     $0x0020, %ax
        jz      uart_send_poll
        pop     %ax
        mov     $UART_BASE+0, %dx
        outb    %al, (%dx)
        pop     %dx
        ret

##################################################
# al: return data byte

uart_receive_byte:
        push    %dx;
uart_receive_poll:
        mov     $UART_BASE+5, %dx       # LSR
        inb     (%dx), %al
        and     $0x0001, %ax
        jz      uart_receive_poll
        mov     $UART_BASE+0, %dx
        inb     (%dx), %al
        pop     %dx
        ret

##################################################

