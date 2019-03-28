.code16

.global main
.global _start


# .equ    IOREG,      0x40
.equ    DSEG,       0x0000
.equ    SSEG,       0x0000

# ==== Text ====
.section .text

_start:
        cli                             # mask all interrupts
        cld                             # direction reg
        mov     $DSEG,%ax               # set up DS

        mov     %eax,%edx

        mov     $DSEG,%ax               # set up stack
        mov     %ax,%ss
        mov     $0xFFFF,%sp

        call    load_int                # set up the int vectors
        call    main


interrupt_table:
.word   0xfeed
.word   0xbeef
.word   load_int
.word   load_int
.word   load_int
.word   0xc3c3


load_int:
        mov     $interrupt_table, %si
        mov     $0x00, %di
        ret


# ==== CPU cold start ====

.section .cpu_entry

.equ    CSEG,       0xF000

cpu_start:
        jmp     $CSEG,$_start


