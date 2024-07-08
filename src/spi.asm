
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


##################################################
# SPI mode 0:
# clock init state: L
# 1) data to MOSI
# 2) clock L to H
# 3) sample MISO
# 4) clock H to L
# MSB first

##################################################
# CS must be asserted separately
# al: data in- and out

.macro  SPI_BIT_TRANSFER
        movb    %bl, %bh
        andb    $MOSI_BIT, %bh          # prepare the bit in bh
        andb    $NMOSI_BIT, %al         # zero out first
        orb     %bh, %al                # then set if needed
        outb    %al, (%dx)              # MSB out
        xor     %di, %ax                # Clock flip
        outb    %al, (%dx)
        nop                             # small gap for the card
        inb     (%dx), %al              # MSB in
        movb    %al, %ch
        andb    $MISO_BIT, %ch
        orb     %ch, %cl                # set bit in out data
        xor     %di, %ax                # Clock flip
        outb    %al, (%dx)
        rol     $1, %bl                 # Rotate data
        rol     $1, %cl
.endm


spi_transfer:
        push    %bx
        push    %cx
        push    %dx
        push    %di

        mov     $CLK_BIT, %di           # Clock flip
        mov     $IO_BASE, %dx           # IO address

        movb    $0x00, %cl              # zero out 'in' data

        rol     $1, %al                 # bring MSB to bit
        rol     $1, %al                 # pos. 1
        movb    %al, %bl                # prepare 'out' data in bl

        inb     (%dx), %al
        SPI_BIT_TRANSFER                # unrolled loop 8x
        SPI_BIT_TRANSFER
        SPI_BIT_TRANSFER
        SPI_BIT_TRANSFER
        SPI_BIT_TRANSFER
        SPI_BIT_TRANSFER
        SPI_BIT_TRANSFER
        SPI_BIT_TRANSFER

        movb    %cl, %al

        rol     $1, %al                 # bring MSB to bit
        rol     $1, %al                 # pos. 7
        rol     $1, %al

        pop     %di
        pop     %dx
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

##################################################

