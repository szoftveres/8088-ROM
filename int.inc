
##################################################

.macro  HALT_WAIT
        pushf
        sti
        hlt
        popf
.endm



.macro  INTERRUPT_DISPATCH      num, dispatch_table
        push    %bp
        movw    \num, %bp               # interrupt number
        push    %bp
        movw    $1f, %bp                # return address
        push    %bp
        push    %bp                     # space for the handler address
        push    %ax
        mov     %ah, %al
        shl     %ax
        xorb    %ah, %ah
        movw    %ax, %bp                # offset in %bp
        movw    %cs:\dispatch_table(%bp), %ax
        movw    %sp, %bp
        movw    %ax, %ss:-2(%bp)
        pop     %ax
        ret                             # call the handler (address in stack)
1:
        pop     %bp                     # clean up int number
        pop     %bp
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
        .word   int_11h         # INT 11
        .word   int_12h         # INT 12 - return RAM size
        .word   int_13h         # INT 13 - disk ops
        .word   int_14h         # INT 14
        .word   int_15h         # INT 15
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

# interrupt number in stack
int_debug:
        call    print_regs
        stc                     # Sad
        movb    $0x00, %al
        ret

##################################################

# INT 10 -- video services

int_10h:
        INTERRUPT_DISPATCH $0x0010, int_10_dispatch
        iret

oldint10_h:
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
        .word   int_10_03       # 0x03
        .word   int_success     # 0x04
        .word   int_success     # 0x05
        .word   int_success     # 0x06
        .word   int_success     # 0x07
        .word   int_success     # 0x08
        .word   int_10_09       # 0x09
        .word   int_10_0A       # 0x0A
        .word   int_success     # 0x0B
        .word   int_success     # 0x0C
        .word   int_success     # 0x0D
        .word   uart_send_byte  # 0x0E
        .word   int_success     # 0x0F

int_10_03:
        xor     %cx, %cx
        xor     %dx, %dx
        clc
        ret

int_10_09:
int_10_0A:
        push    %ax
        push    %cx
1:
        pop     %ax
        call    uart_send_byte
        push    %ax
        loop    1b
        pop     %cx
        pop     %ax
        clc
        ret

##################################################

# INT 11 -- return equipment list
# ax: result

int_11h:
        movw    $0x0001, %ax    # nobody gets jealous of this config for sure
        clc
        iret

##################################################

# INT 12 -- return RAM size
# (cx == 0xA55A && dx == 0x5AA5) : real size, otherwise max 640k
# ax: result

int_12h:
        push    %di
        push    %ds
        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     $ramsize, %di
        mov     (%di), %ax      # get the value into ax
        cmpw    $0xA55A, %cx    # check for magic numbers
        jnz     1f
        cmpw    $0x5AA5, %dx
        jnz     1f
        jmp     2f
1:
        cmpw    $640, %ax       # don't report more than 640k
        jna     2f
        movw    $640, %ax
2:
        clc
        pop     %ds
        pop     %di
        iret

##################################################

# INT 13 -- disk services

int_13h:
        INTERRUPT_DISPATCH $0x0013, int_unimplemented_dispatch
        iret

##################################################

# INT 14 -- serial port services

int_14h:
        INTERRUPT_DISPATCH $0x0014, int_unimplemented_dispatch
        iret

##################################################

# INT 15 -- misc services

int_15h:
        INTERRUPT_DISPATCH $0x0015, int_unimplemented_dispatch
        iret

##################################################

# INT 16 -- keyboard services

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

# INT 17 -- printer services

int_17h:
        INTERRUPT_DISPATCH $0x0017, int_unimplemented_dispatch
        iret

##################################################

# INT 18 -- execute BASIC

int_18h:
        push    %ax
        movw    $0x0018, %ax
        push    %ax
        call    int_debug
        pop     %ax
        pop     %ax
        iret

##################################################

# INT 19 -- boot the OS

int_19h:
        push    %ax
        movw    $0x0019, %ax
        push    %ax
        call    int_debug
        pop     %ax
        pop     %ax
        iret

##################################################

int_unimplemented_dispatch:
        .word   int_debug               # 0x00
        .word   int_debug               # 0x01
        .word   int_debug               # 0x02
        .word   int_debug               # 0x03
        .word   int_debug               # 0x04
        .word   int_debug               # 0x05
        .word   int_debug               # 0x06
        .word   int_debug               # 0x07
        .word   int_debug               # 0x08
        .word   int_debug               # 0x09
        .word   int_debug               # 0x0A
        .word   int_debug               # 0x0B
        .word   int_debug               # 0x0C
        .word   int_debug               # 0x0D
        .word   int_debug               # 0x0E
        .word   int_debug               # 0x0F

