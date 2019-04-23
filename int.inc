

##################################################

int_init:
        push    %ax
        push    %di
        push    %es             # save ES
        push    %ds             # save DS

        push    %cs
        pop     %ds
        mov     $0x0000, %di
        mov     %di, %es
        mov     $int_table, %si
        mov     $0x20, %cx      # 32 Interrupt vectors
        mov     %cs, %ax
1:
        movsw                   # ISR address
        stosw                   # segments
        loop    1b
        pop     %ds             # restore DS
        pop     %es             # restore ES
        pop     %di
        pop     %ax
        ret

##################################################

int_table:
        .word   int_dummy       # INT 00 - Divide by zero
        .word   int_dummy       # INT 01 - Single step
        .word   int_dummy       # INT 02 - Non-maskable interrupt
        .word   int_dummy       # INT 03 - Debugger breakpoint
        .word   int_dummy       # INT 04 - Integer overlow (into)
        .word   int_dummy       # INT 05
        .word   int_dummy       # INT 06
        .word   int_dummy       # INT 07
        .word   int_dummy       # INT 08 - IRQ0
        .word   int_dummy       # INT 09 - IRQ1
        .word   int_dummy       # INT 0A - IRQ2
        .word   int_dummy       # INT 0B - IRQ3
        .word   int_dummy       # INT 0C - IRQ4 - 2 Hz
        .word   int_dummy       # INT 0D - IRQ5 - 16 Hz
        .word   int_dummy       # INT 0E - IRQ6
        .word   int_dummy       # INT 0F - IRQ7 - UART
        .word   int_10h         # INT 10 - character output
        .word   int_dummy       # INT 11
        .word   int_12h         # INT 12 - return RAM size
        .word   int_dummy       # INT 13
        .word   int_dummy       # INT 14
        .word   int_dummy       # INT 15
        .word   int_16h         # INT 16 - character input
        .word   int_dummy       # INT 17
        .word   int_dummy       # INT 18
        .word   int_dummy       # INT 19
        .word   int_dummy       # INT 1A
        .word   int_dummy       # INT 1B
        .word   int_dummy       # INT 1C
        .word   int_dummy       # INT 1D
        .word   int_dummy       # INT 1E
        .word   int_dummy       # INT 1F

##################################################
# dummy handler

int_dummy:
        iret

##################################################
# INT 12H handler - return RAM size
# ax: result

int_12h:
        push    %di
        push    %ds
        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     $ramsize, %di
        mov     (%di), %ax      # get the value into ax
        pop     %ds
        pop     %di
        iret

##################################################

# dispatch INT 10

int_10h:
        cmp     $0x0E, %ah      # AH = 0x0E
        jnz     1f
        call    int_10_0E
        jmp     2f
1:

2:
        iret

##################################################
# dispatch INT 16

int_16h:
        or      %ah, %ah        # AH = 0x00
        jnz     1f
        call    int_16_00
        jmp     2f
1:

2:
        iret

##################################################
# character input
# al : result

int_16_00:
        call    uart_receive_byte
        ret

##################################################
# character output
# al : byte

int_10_0E:
        call    uart_send_byte
        ret

##################################################


