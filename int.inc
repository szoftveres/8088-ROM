
##################################################

.macro  HALT_WAIT
        pushf
        sti
        hlt
        popf
.endm


# flags
# CS
# IP <-
# %bp
# %ds
# <optional: int number>
# return address from handler
# handler address
# %ax


.macro  INTERRUPT_DISPATCH      dispatch_table:req, num
        push    %bp
        push    %ds
        mov     $DSEG, %bp
        mov     %bp, %ds
        .ifnb   \num
            movw    $\num, %bp              # interrupt number
            push    %bp
        .endif
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
        movw    %ax, %ss:2(%bp)
#         movw    %ss:10(%bp), %bp        # temporarily restore original bp
        pop     %ax
        ret                             # call the handler (address in stack)
1:
        push    %ax
        pushf
        pop     %ax
        movw    %sp, %bp
        andw    $0x0001, %ax            # carry set?
        .ifnb   \num
            andw    $0xFFFE, %ss:12(%bp)
            orw     %ax, %ss:12(%bp)
        .else
            andw    $0xFFFE, %ss:10(%bp)
            orw     %ax, %ss:10(%bp)
        .endif
        pop     %ax
        .ifnb   \num
            pop     %bp                     # clean up int number
        .endif
        pop     %ds
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
        mov     $BOOTSEG, %di
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
        .word   int_17h         # INT 17
        .word   int_18h         # INT 18
        .word   int_19h         # INT 19
        .word   int_bad         # INT 1A
        .word   int_bad         # INT 1B
        .word   int_bad         # INT 1C
        .word   int_bad         # INT 1D
        .word   int_bad         # INT 1E
        .word   int_bad         # INT 1F

int_dummy:
        iret

int_bad:
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
        clc                     # happy
        ret

# interrupt number in stack
int_dbg:
        push    %si
        push    %bp
        push    %ax
        movw    $text_int_dbg1, %si
        call    print_str_cs
        movw    %sp, %bp
        movw    %ss:8(%bp), %ax
        call    print_h8
        movw    $text_int_dbg2, %si
        call    print_str_cs
        pop     %ax
        pop     %bp
        pop     %si
        call    print_regs
        movb    $0x00, %al
        stc                     # sad
        ret

text_int_dbg1:
        .asciz  "\n -> int "
text_int_dbg2:
        .asciz  " --------------------"

##################################################

# INT 10 -- video services

int_10h:
        INTERRUPT_DISPATCH int_10_dispatch, 0x10
        iret

int_10_dispatch:
        .word   int_dbg         # 0x00
        .word   int_dbg         # 0x01
        .word   int_dbg         # 0x02
        .word   int_10_03       # 0x03
        .word   int_dbg         # 0x04
        .word   int_dbg         # 0x05
        .word   int_dbg         # 0x06
        .word   int_dbg         # 0x07
        .word   int_dbg         # 0x08
        .word   int_10_09       # 0x09
        .word   int_10_0A       # 0x0A
        .word   int_dbg         # 0x0B
        .word   int_dbg         # 0x0C
        .word   int_dbg         # 0x0D
        .word   uart_send_byte  # 0x0E
        .word   int_dbg         # 0x0F

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
        pop     %ds
        pop     %di
        iret

##################################################

# INT 13 -- disk services

int_13h:
        INTERRUPT_DISPATCH int_13_dispatch, 0x13
        iret

int_13_dispatch:
        .word   int_13_00               # 0x00
        .word   int_13_01               # 0x01
        .word   int_13_02               # 0x02
        .word   int_dbg                 # 0x03
        .word   int_dbg                 # 0x04
        .word   int_dbg                 # 0x05
        .word   int_dbg                 # 0x06
        .word   int_dbg                 # 0x07

        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x07

int_13_00:
int_13_01:
        xorb    %ah, %ah
        clc
        ret


int_13_02:
        push    %ax
        push    %bx
        push    %cx
        push    %dx
        push    %di

        push    %ax
        push    %bp
        mov     $0x0013, %bp
        push    %bp
        call    int_dbg
        pop     %bp
        pop     %bp
        pop     %ax

        call    disk_chs_to_lba                 # get the sector num
        addw    partition_offset_lba_lo, %cx    # start offset
        xor     %dx, %dx

1:
        mov     %bx, %di                        # es:(di) buffer
        call    sd_read_block
        addw    $0x0200, %di
        inc     %cx
        dec     %al
        jnz     1b
        
        pop     %di
        pop     %dx
        pop     %cx
        pop     %bx
        pop     %ax

        xorb    %ah, %ah
        clc
        ret


##################################################

# INT 14 -- serial port services

int_14h:
        INTERRUPT_DISPATCH int_unimplemented_dispatch, 0x14
        iret

##################################################

# INT 15 -- misc services

int_15h:
        INTERRUPT_DISPATCH int_unimplemented_dispatch, 0x15
        iret

##################################################

# INT 16 -- keyboard services

int_16h:
        push    %bp
        push    %ds
        mov     $DSEG, %bp
        mov     %bp, %ds


        orb     %ah, %ah
        jnz     1f
        call    uart_receive_byte
        jmp     2f
1:
        cmpb    $0x01, %ah
        jnz     1f
        call    uart_byte_available
        push    %bp
        mov     %sp, %bp
        andw    $0xFFBF, %ss:6(%bp)         # zero flag treatment
        orw     %ax, %ss:6(%bp)
        pop     %bp
        or      %ax, %ax
        jnz     1f
        call    uart_receive_byte
1:
2:
        pop     %ds
        pop     %bp
        iret

##################################################

# INT 17 -- printer services

int_17h:
        INTERRUPT_DISPATCH int_unimplemented_dispatch, 0x17
        iret

##################################################

# INT 18 -- execute BASIC

int_18h:
        push    %ax
        movw    $0x0018, %ax
        push    %ax
        call    int_dbg
        pop     %ax
        pop     %ax
1:
        HALT_WAIT
        jmp     1b
        iret

##################################################

# INT 19 -- boot the OS

int_19h:
        push    %ax
        movw    $0x0019, %ax
        push    %ax
        call    int_dbg
        pop     %ax
        pop     %ax

        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     boot_cs, %ax
        push    %ax
        mov     $startover, %ax
        push    %ax                     # start address offset
        lret

##################################################

int_unimplemented_dispatch:
        .word   int_dbg                 # 0x00
        .word   int_dbg                 # 0x01
        .word   int_dbg                 # 0x02
        .word   int_dbg                 # 0x03
        .word   int_dbg                 # 0x04
        .word   int_dbg                 # 0x05
        .word   int_dbg                 # 0x06
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x08
        .word   int_dbg                 # 0x09
        .word   int_dbg                 # 0x0A
        .word   int_dbg                 # 0x0B
        .word   int_dbg                 # 0x0C
        .word   int_dbg                 # 0x0D
        .word   int_dbg                 # 0x0E
        .word   int_dbg                 # 0x0F

        .word   int_dbg                 # 0x00
        .word   int_dbg                 # 0x01
        .word   int_dbg                 # 0x02
        .word   int_dbg                 # 0x03
        .word   int_dbg                 # 0x04
        .word   int_dbg                 # 0x05
        .word   int_dbg                 # 0x06
        .word   int_dbg                 # 0x07
        .word   int_dbg                 # 0x08
        .word   int_dbg                 # 0x09
        .word   int_dbg                 # 0x0A
        .word   int_dbg                 # 0x0B
        .word   int_dbg                 # 0x0C
        .word   int_dbg                 # 0x0D
        .word   int_dbg                 # 0x0E
        .word   int_dbg                 # 0x0F

