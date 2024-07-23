
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

# UART IO address

.equ    UART_BASE,  0x0020

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
        movb    $0x03, %al              # enable tx and rx interrupts
#        movb    $0x01, %al              # enable rx interrupts
        outb    %al, $UART_BASE+1       # IER

        xor     %ax, %ax
        movw    %ax, %ds:uart_rcvbuf_rd
        movw    %ax, %ds:uart_rcvbuf_wr

        pop     %ax
        ret

##################################################

uart_type:
        push    %si
        push    %ax

        movw    $uart_text, %si
        call    print_str_cs

        inb     $UART_BASE+7, %al       # scratch register
        movw    %ax, %si
        movb    $0x55, %al
        outb    %al, $UART_BASE+7
        inb     $UART_BASE+7, %al
        cmpb    $0x55, %al
        jz      2f
        movw    $uart_text_8250, %ax
        jmp     9f                      # done
        movb    $0xAA, %al
        outb    %al, $UART_BASE+7
        inb     $UART_BASE+7, %al
        cmpb    $0xAA, %al
        jz      2f
        movw    $uart_text_8250, %ax
        jmp     9f                      # done
2:
        movw    %si, %ax
        outb    %al, $UART_BASE+7       # restore scratch register

        inb     $UART_BASE+2, %al
        andb    $0xC0, %al

        cmpb    $0x80, %al
        jnz     3f
        mov     $uart_text_16550, %ax
        jmp     9f                      # done
3:
        cmpb    $0x40, %al
        jnz     4f
        mov     $uart_text_unknown, %ax
        jmp     9f                      # done
4:
        cmpb    $0xC0, %al
        jnz     5f
        mov     $uart_text_16550a, %ax
        jmp     9f                      # done
5:
        mov     $uart_text_16450, %ax
9:
        movw    %ax, %si
        call    print_str_cs
        NEWLINE

        pop     %ax
        pop     %si
        ret

uart_text_8250:
        .asciz   "8250"
uart_text_16450:
        .asciz   "16450"
uart_text_16550:
        .asciz   "16550"
uart_text_16550a:
        .asciz   "16550A"
uart_text_unknown:
        .asciz   "unknown"
uart_text:
        .asciz   "UART : "

##################################################

# UART interrupt service

uart_rx_int:
        inb     $UART_BASE+5, %al       # LSR
        andb    $0x01, %al              # byte received?
        jz      1f
        mov     %ds:uart_rcvbuf_wr, %si
        inc     %si
        and     $0x003F, %si            # 64
        mov     %si, %ds:uart_rcvbuf_wr
        inb     $UART_BASE+0, %al
        movb    %al, %ds:uart_rcvbuf(%si)
        jmp     uart_rx_int
1:
        ret


int_uart:
        push    %ax
        push    %si
        push    %ds
        mov     $DSEG, %ax
        mov     %ax, %ds
1:
        inb     $UART_BASE+2, %al       # Read IIR, this deletes Tx interrupt
        testb   $0x01, %al
        jnz     9f                      # bit 0 means no pending interrupts

        testb   $0x04, %al              # RX interrupt
        # this is temporary
        jz      2f
        call    uart_rx_int
        jmp     1b                      # check for other pending interrupts
2:
        testb   $0x06, %al              # 
        jz      3f
        inb     $UART_BASE+5, %al       # read LSR
        jmp     1b                      # check for other pending interrupts
3:
        testb   $0xF0, %al                #
        jnz     9f
        inb     $UART_BASE+6, %al       # read MSR
        jmp     1b                      # check for other pending interrupts
9:
        pop     %ds
        pop     %si
        pop     %ax
        call    pic_eoi
        iret

##################################################
# ds must be set up
# al: data byte

uart_send_byte:
        push    %ax;
1:
        inb     $UART_BASE+5, %al       # LSR
        and     $0x0020, %ax
        jnz     2f
        HALT_WAIT                       # halt for interrupt 
        jmp     1b
2:
        pop     %ax
        outb    %al, $UART_BASE+0
        clc
        ret

##################################################
# ds must be set up
# ax: zero flag == 0 : (0x0000) if something available 
# ax: zero flag == 1 : (0x0040) if nothing

uart_byte_available:
        push    %si
        mov     %ds:uart_rcvbuf_rd, %si
        cmp     %ds:uart_rcvbuf_wr, %si
        pushf
        pop     %ax
        andw    $0040, %ax              # zero flag
        pop     %si
        ret

##################################################
# ds must be set up
# al: return data byte

uart_receive_byte:
        push    %si
1:
        mov     %ds:uart_rcvbuf_rd, %si
        cmp     %ds:uart_rcvbuf_wr, %si
        jnz     2f
        HALT_WAIT                       # halt for interrupt
        jmp     1b
2:
        inc     %si
        and     $0x003F, %si            # 64
        mov     %si, %ds:uart_rcvbuf_rd
        movb    %ds:uart_rcvbuf(%si), %al

        pop     %si
        clc
        ret

##################################################

