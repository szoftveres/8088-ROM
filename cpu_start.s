.code16

.global _start

.section cpu_entry

.equ    CSEG,       0xF000

.org    0xFFF0
cpu_start:
        jmp     $CSEG,$_start

