
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
        push    %dx
        mov     $IO_BASE, %dx
        mov     $0x08, %cx              # cycle counter
        push    %ax

spi_transfer_loop:

# --- MSB out
        pop     %ax
        mov     %ax, %bx
        push    %ax
        in      (%dx), %al
        and     $0x80, %bl              # MSB
        jz      1f
        or      $MOSI_BIT, %al
        jmp     2f
1:
        and     $NMOSI_BIT, %al
2:
        out     %al, (%dx)


# --- clock flip
        in      (%dx), %al
        xor     $CLK_BIT, %ax
        out     %al, (%dx)


# --- MSB in and rotate

        in      (%dx), %al
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
        in      (%dx), %al
        xor     $CLK_BIT, %ax
        out     %al, (%dx)


# --- cycle counter
        dec     %cx
        jnz     spi_transfer_loop


        pop     %ax
        pop     %dx
        pop     %cx
        pop     %bx
        ret

##################################################

spi_init:
        push    %dx
        push    %ax
        call    spi_deassert
        mov     $IO_BASE, %dx
        in      (%dx), %al
        and     $NCLK_BIT, %al          # clock init state: L
        out     %al, (%dx)
        call    spi_assert
        call    spi_deassert
        pop     %ax
        pop     %dx
        ret

##################################################

spi_assert:
        push    %dx
        push    %ax
        mov     $IO_BASE, %dx
        in      (%dx), %al
        and     $NCS_BIT, %al
        out     %al, (%dx)
        pop     %ax
        pop     %dx
        ret

##################################################

spi_deassert:
        push    %dx
        push    %ax
        mov     $IO_BASE, %dx
        in      (%dx), %al
        or      $CS_BIT, %al
        out     %al, (%dx)
        pop     %ax
        pop     %dx
        ret




