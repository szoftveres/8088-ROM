

##################################################

.macro  HALT_WAIT
        pushf
        sti
        hlt
        popf
.endm

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
        cld
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
        .word   int_bad         # INT 05
        .word   int_bad         # INT 06
        .word   int_bad         # INT 07
        .word   int_dummy       # INT 08 - IRQ0
        .word   int_dummy       # INT 09 - IRQ1
        .word   int_dummy       # INT 0A - IRQ2
        .word   int_dummy       # INT 0B - IRQ3
        .word   int_dummy       # INT 0C - IRQ4 - 2 Hz
        .word   int_dummy       # INT 0D - IRQ5 - 16 Hz
        .word   int_dummy       # INT 0E - IRQ6
        .word   int_uart        # INT 0F - IRQ7 - UART
        .word   int_10h         # INT 10 - character output
        .word   int_bad         # INT 11
        .word   int_12h         # INT 12 - return RAM size
        .word   int_13h         # INT 13 - disk ops
        .word   int_bad         # INT 14
        .word   int_bad         # INT 15
        .word   int_16h         # INT 16 - character input
        .word   int_bad         # INT 17
        .word   int_bad         # INT 18
        .word   int_bad         # INT 19
        .word   int_bad         # INT 1A
        .word   int_bad         # INT 1B
        .word   int_bad         # INT 1C
        .word   int_bad         # INT 1D
        .word   int_bad         # INT 1E
        .word   int_bad         # INT 1F

int_dummy:
        iret

int_bad:
        stc
        iret

##################################################

pic_init:
        push    %ax

        movb    $0x13, %al          # ICW1 - edge triggered, single, ICW4
        outb    %al, $PIC_BASE+0
        movb    $0x08, %al          # ICW2 - interrupt vector offset = 8
        outb    %al, $PIC_BASE+1
        movb    $0x01, %al          # ICW4 - non buffered mode, 8086/8088
        outb    %al, $PIC_BASE+1

        movb    $0x7F, %al          # OCW1: unmask UART
        outb    %al, $PIC_BASE+1

        pop     %ax
        ret

##################################################

pic_eoi:
        push    %ax
        movb    $0x20, %al
        outb    %al, $PIC_BASE+0
        pop     %ax
        ret

##################################################
# dummy handlers

int_success:
        clc                     # Happy
        movb    $0x00, %al
        ret

int_fail:
        stc                     # Sad
        ret

##################################################

# dispatch INT 10

int_10h:
        push    %di
        push    %ax
        mov     %ah, %al
        shl     $1, %ax
        xorb    %ah, %ah
        movw    %ax, %di
        pop     %ax
        call    *%cs:int_10_dispatch(%di)
        pop     %di
        iret

int_10_dispatch:
        .word   int_success     # 0x00
        .word   int_success     # 0x01
        .word   int_success     # 0x02
        .word   int_success     # 0x03
        .word   int_success     # 0x04
        .word   int_success     # 0x05
        .word   int_success     # 0x06
        .word   int_success     # 0x07
        .word   int_success     # 0x08
        .word   int_success     # 0x09
        .word   int_success     # 0x0A
        .word   int_success     # 0x0B
        .word   int_success     # 0x0C
        .word   int_success     # 0x0D
        .word   uart_send_byte  # 0x0E
        .word   int_success     # 0x0F

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
        clc
        pop     %ds
        pop     %di
        iret

##################################################

# dispatch INT 13

int_13h:
        push    %di
        push    %ax
        mov     %ah, %al
        shl     $1, %ax
        xorb    %ah, %ah
        movw    %ax, %di
        pop     %ax
        call    *%cs:int_13_dispatch(%di)
        pop     %di
        iret

int_13_dispatch:
        .word   int_success             # 0x00
        .word   int_success             # 0x01
        .word   int_success             # 0x02
        .word   int_success             # 0x03
        .word   int_success             # 0x04
        .word   int_success             # 0x05
        .word   int_success             # 0x06
        .word   int_success             # 0x07

##################################################

# dispatch INT 16

int_16h:
        push    %di
        push    %ax
        mov     %ah, %al
        shl     $1, %ax
        xorb    %ah, %ah
        movw    %ax, %di
        pop     %ax
        call    *%cs:int_16_dispatch(%di)
        pop     %di
        iret

int_16_dispatch:
        .word   uart_receive_byte       # 0x00
        .word   uart_byte_available     # 0x01
        .word   int_success             # 0x02
        .word   int_success             # 0x03
        .word   int_success             # 0x04
        .word   int_success             # 0x05
        .word   int_success             # 0x06
        .word   int_success             # 0x07

##################################################



