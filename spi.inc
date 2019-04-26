
# BIT 0
.equ    CS_BIT,         0x01
.equ    NCS_BIT,        0xFE

# BIT 2
.equ    CLK_BIT,        0x04
.equ    NCLK_BIT,       0xFB

# BIT 1
.equ    MOSI_BIT,       0x02
.equ    NMOSI_BIT,      0xFD

# BIT 4
.equ    MISO_BIT,       0x10

# BIT 5
.equ    DET_BIT,        0x20


##################
# SPI mode 0:
# clock init state: L
# 1) data to MOSI
# 2) clock L to H
# 3) sample MISO
# 4) clock H to L
# MSB first


##################################################
# CS must be asserted separately
# al: data

spi_transfer:
        push    %bx
        push    %cx
        mov     $0x08, %cx              # cycle counter
        push    %ax

spi_transfer_loop:

# --- MSB out
        pop     %ax
        mov     %ax, %bx
        push    %ax
        inb     $IO_BASE, %al
        and     $0x80, %bl              # MSB
        jz      1f
        or      $MOSI_BIT, %al
        jmp     2f
1:
        and     $NMOSI_BIT, %al
2:
        outb    %al, $IO_BASE


# --- clock flip
        inb     $IO_BASE, %al
        xor     $CLK_BIT, %ax
        outb    %al, $IO_BASE


# --- MSB in and rotate

        inb     $IO_BASE, %al
        movb    %al, %bl
        pop     %ax
        and     $MISO_BIT, %bl
        jz      1f
        or      $0x80, %al              # MSB
        jmp     2f
1:
        and     $0x7F, %al              # MSB
2:
        rol     $1, %al                 # MSB first
        push    %ax

# --- clock flip
        inb     $IO_BASE, %al
        xor     $CLK_BIT, %ax
        outb    %al, $IO_BASE


# --- cycle counter
        loop     spi_transfer_loop


        pop     %ax
        pop     %cx
        pop     %bx
        ret

##################################################

spi_init:
        push    %ax
        call    spi_deassert
        inb     $IO_BASE, %al
        and     $NCLK_BIT, %al          # clock init state: L
        outb    %al, $IO_BASE
        call    spi_assert
        call    spi_deassert
        pop     %ax
        ret

##################################################

spi_assert:
        push    %ax
        inb     $IO_BASE, %al
        and     $NCS_BIT, %al
        outb    %al, $IO_BASE
        pop     %ax
        ret

##################################################

spi_deassert:
        push    %ax
        inb     $IO_BASE, %al
        or      $CS_BIT, %al
        outb    %al, $IO_BASE
        pop     %ax
        ret


