.code16
.arch i8086  #,nojumps             # see documentation

.global main
.global _start

.equ    ESEG,       0x4000
.equ    ROMSEG,     0xE000      # First ROM address

.equ    UART_BASE,  0x0020
.equ    PIC_BASE,   0x0040
.equ    IO_BASE,    0x0060

# upper 512 byte of the interrupt table
.equ    SSEG,               0x0020
.equ    STACKP,             0x0200

# First address above the interrupt table
.equ    DSEG,               0x0040

##################################################
.section .bss

.local ramsize
.comm ramsize, 2, 2

##################################################
.section .text

_start:
        cli                             # mask all interrupts
        cld                             # direction reg

##################################################

cpu_test:
        xor     %ax, %ax           ; AX = 0
        jb      cpu_fail
        jo      cpu_fail
        js      cpu_fail
        jnz     cpu_fail
        jpo     cpu_fail
        add     $1, %ax            ; AX = 1
        jz      cpu_fail
        jpe     cpu_fail
        sub     $0x8002, %ax
        js      cpu_fail
        inc     %ax
        jno     cpu_fail
        shl     $1, %ax
        jnb     cpu_fail
        jnz     cpu_fail
        shl     $1, %ax
        jb      cpu_fail

        mov     $0xAAAA, %ax
cpu_test_1:
        mov     %ax, %ds
        mov     %ds, %bx
        mov     %bx, %es
        mov     %es, %cx
        mov     %cx, %ss
        mov     %ss, %dx
        mov     %dx, %bp
        mov     %bp, %sp
        mov     %sp, %si
        mov     %si, %di
        cmp     $0xAAAA, %di
        jnz     cpu_test_2
        mov     %di, %ax
        not     %ax
        jmp     cpu_test_1
cpu_test_2:
        cmp     $0x5555, %di
        jz      cpu_ok

cpu_fail:
        mov     $0x02, %bx
        jmp     halt_blink
cpu_ok:

##################################################
# Skip all RAM checks when we're running from RAM
# otherwise some checks would overwrite the program 
# and stored data

        mov     %cs, %ax
        cmp     $ROMSEG, %ax
        jb      skip_ram_checks

##################################################
# Test minimal RAM

.equ    MIN_RAM,    0x7FFF      # first 32k

        xor     %ax, %ax
        mov     %ax, %ds        # first segment

        movb    $0x55, %al      # pattern 1
        movb    $0xAA, %bl      # pattern 2

        mov     $MIN_RAM, %cx   # cycle counter
ram_fill1_loop:
        mov     %cx, %di
        movb    %al, (%di)      # fill with pattern 1
        loop    ram_fill1_loop

        mov     $MIN_RAM, %cx   # cycle counter
ram_ver1_loop:
        mov     %cx, %di
        cmpb    (%di), %al      # verify against pattern 1
        jnz     ram_fail1
        movb    %bl, (%di)      # fill with pattern 2
        loop    ram_ver1_loop

        mov     $MIN_RAM, %cx   # cycle counter
ram_ver2_loop:
        mov     %cx, %di
        cmpb    (%di), %bl      # verify against pattern 2
        jnz     ram_fail2
        loop    ram_ver2_loop

        jmp     ram_ok
ram_fail1:
        mov     $0x03, %bx
        jmp      halt_blink
ram_fail2:
        mov     $0x04, %bx
        jmp     halt_blink
ram_ok:


##################################################
# Detect total RAM
# INT 12h should return this number

.equ    RAM_DET_GRANUL,    0x0040      # every 1kbyte

        movb    $0x55, %al      # pattern 1
        movb    $0xAA, %bl      # pattern 2
        xor     %di, %di    

        xor     %cx, %cx        # cycle counter
ram_det1_loop:
        mov     %cx, %ds
        movb    %al, (%di)      # fill with pattern 1
        add     $RAM_DET_GRANUL, %cx
        cmp     $ROMSEG, %cx
        jnz     ram_det1_loop

        xor     %cx, %cx        # cycle counter
ram_det2_loop:
        mov     %cx, %ds
        cmpb    (%di), %al      # verify against pattern 1
        jnz     ram_det_bail
        movb    %bl, (%di)      # fill with pattern 2
        add     $RAM_DET_GRANUL, %cx
        cmp     $ROMSEG, %cx
        jnz     ram_det2_loop

        xor     %cx, %cx        # cycle counter
ram_det3_loop:
        mov     %cx, %ds
        cmpb    (%di), %bl      # verify against pattern 2
        jnz     ram_det_bail
        add     $RAM_DET_GRANUL, %cx
        cmp     $ROMSEG, %cx
        jnz     ram_det3_loop

ram_det_bail:
        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     %cx, %ax
        movb    $6, %cl          # convert segment to kb
        shr     %cl, %ax
        mov     $ramsize, %di
        mov     %ax, (%di)      # store the result

skip_ram_checks:

##################################################
# set up segment registers
        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     $SSEG, %ax
        mov     %ax, %ss
        mov     $ESEG, %ax
        mov     %ax, %es
        mov     $STACKP,%sp

##################################################
# init hardware and interrupt table

        call    int_init
        call    pic_init
        sti
        call    uart_init
        call    spi_init

##################################################

        call    led_off
        call    print_banner

##################################################

main_help:
        movw    $main_help_text, %si
        call    print_str_cs
        call    print_seginfo
        call    print_regs

mainloop:
        call    get_byte

        cmp     $'d', %al
        jnz     1f
        call    main_dump
        jmp     2f              # help
1:
        cmp     $'e', %al
        jnz     1f
        call    main_eseg_chg
        jmp     2f              # help
1:
        cmp     $'r', %al
        jnz     1f
        call    main_recv
        jmp     2f              # help
1:
        cmp     $'g', %al
        jnz     1f
        call    main_jmp
        jmp     2f              # help
1:
        cmp     $'\n', %al
        jnz     1f
        jmp     2f              # help
1:
        cmp     $'\r', %al
        jnz     1f
        jmp     2f              # help
1:
        jmp     3f
2:
        jmp     main_help
3:
        jmp     mainloop

main_help_text:
        .ascii "\n  [nl] : help\n"
        .ascii   "     e : set ES\n"
        .ascii   "     r : receive to [ES:0000]\n"
        .ascii   "     g : execute at [ES:start]\n"
        .asciz   "     d : dump [ES:start]\n\n"

##################################################

main_dump:
        movw    $text_main_dump_start, %si
        call    print_str_cs
        call    get_h16
        jc      2f
        push    %ax
        movw    $text_main_dump_help, %si
        call    print_str_cs
main_dump_loop:

        mov     $0x10, %cx              # 16 lines
1:
        pop     %ax
        mov     %ax, %si
        add     $0x10, %ax
        push    %ax
        call    dump_mem_line
        loop    1b

        call    get_byte
        cmp     $'\n', %al
        jz      main_dump_loop
        cmp     $'\r', %al
        jz      main_dump_loop
        pop     %ax
2:
        ret

text_main_dump_start:
        .asciz  "\nstart>"
text_main_dump_help:
        .ascii "\n  [nl] : continue\n"
        .asciz   " [esc] : end\n\n"

##################################################
main_recv:
        movw    $text_main_recv, %si
        call    print_str_cs
        call    led_on
        mov     $0x0000, %di
main_recv_loop:
        call    get_byte
        movb    %al, %es:(%di)
        inc     %di
        jnz     main_recv_loop
        call    led_off
        ret

text_main_recv:
        .asciz  "\nreceiving..\n"

##################################################

main_eseg_chg:
        movb    $'>', %al
        call    print_byte
        call    get_h16
        jc      1f
        movw    %ax, %es
1:
        ret

##################################################

main_jmp:

        mov     %es, %ax
        push    %ax
        mov     $text_jmp_start, %si
        call    print_str_cs
        call    get_h16
        jc      1f
        push    %ax
        mov     %es, %ax
        call    print_h16
        movb    $':', %al
        call    print_byte
        pop     %ax
        push    %ax
        call    print_h16
        movb    $'\n', %al
        call    print_byte
        lret
1:
        pop     %ax
        ret

text_jmp_start:
        .asciz  "\nstart>"

##################################################
# al: data byte
print_byte:
        movb    $0x0E, %ah
        int     $0x10
        ret

##################################################
# al: return data byte
get_byte:
        movb    $0x00, %ah
        int     $0x16
        ret

##################################################

print_banner:
        movw    $text_banner, %si
        call    print_str_cs

        movw    $text_rom, %si          # ROM date
        call    print_str_cs
        movw    $text_romdate, %si
        call    print_str_cs
        movb    $'\n', %al
        call    print_byte

        movw    $text_cpu, %si          # CPU type
        call    print_str_cs
        call    cpu_id
        mov     %ax, %si
        call    print_str_cs
        movb    $'\n', %al
        call    print_byte

        movw    $text_maxram, %si       # max RAM
        call    print_str_cs
        int     $0x12                   # get the value 
        call    print_dec16
        movb    $'k', %al
        call    print_byte
        movb    $'\n', %al
        call    print_byte

        ret

text_banner:
        .ascii "\n\n *************\n"
        .ascii     " * small x86 *\n"
        .asciz     " *************\n\n"

text_rom:
        .asciz  " ROM : "
text_cpu:
        .asciz  " CPU : "
text_maxram:
        .asciz  " RAM : "

##################################################

.include    "uart.inc"
.include    "string.inc"
.include    "led.inc"
.include    "spi.inc"
.include    "cpu.inc"
.include    "int.inc"
.include    "misc.inc"

# ==== CPU cold start ====

.section .cpu_entry

.equ    CSEG,       0xF000

cpu_start:
        jmp     $CSEG,$_start
text_romdate:
.include    "date.inc"

