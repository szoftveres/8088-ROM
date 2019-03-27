.code16

.global main
.global _start


.equ    IOREG,      0x40
.equ    DSEG,       0x0000
.equ    SSEG,       0x0000

# ==== Text ====
.text

_start:
        mov     $DSEG,%ax   # set up DS
        mov     %ax,%ds

        mov     $DSEG,%ax   # set up stack
        mov     %ax,%ss
        mov     $0xFFFF,%sp

        call    load_int    # set up the int vectors
        call    main


interrupt_table:
.word   0xc3c3
.word   load_int
.word   load_int
.word   load_int
.word   0xc3c3


load_int:
        mov     $interrupt_table, %si
        mov     $0x00, %di
        ret


