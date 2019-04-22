.code16
.arch i8086


.global main
.global _start


.equ    DSEG,       0x0000
.equ    ESEG,       0x4000
.equ    ROMSEG,     0xE000      # First ROM address


.equ    UART_BASE,  0x0020
.equ    PIC_BASE,   0x0040
.equ    IO_BASE,    0x0060


 # First address above the interrupt table
.equ    RAM_BASE,           0x0400


# ==== Text ====
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

        mov     $0x000,%ax      # Test first 64k RAM

##################################################
# Test minimal RAM
# ax: segment

.equ    MIN_RAM,    0x8000

ram_test:
        mov     %ax, %ds
        mov     %ax, %es

        movb    $0x55, %al      # pattern 1
        movb    $0xAA, %bl      # pattern 2
        mov     $MIN_RAM, %cx    # cycle counter
ram_fill1_loop:
        mov     %cx, %di
        movb    %al, (%di)      # fill with pattern 1
        loop    ram_fill1_loop
        mov     $MIN_RAM, %cx    # cycle counter
ram_ver1_loop:
        mov     %cx, %di
        cmpb    (%di), %al      # verify against pattern 1
        jnz     ram_fail1
        movb    %bl, (%di)      # fill with pattern 2
        loop    ram_ver1_loop
        mov     $MIN_RAM, %cx    # cycle counter
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
# set up segment registers
        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     %ax, %ss
        mov     $ESEG, %ax
        mov     %ax, %es
        mov     $RAM_BASE,%sp

        mov     %cs, %ax

##################################################
# init hardware and interrupt table

        call    int_init
        call    led_off
        call    uart_init
        call    spi_init

##################################################

        call    print_banner

##################################################

main_help:
        movw    $main_help_text, %si
        call    print_str_cs
        call    print_seginfo

mainloop:
        call    get_byte

        cmp     $'d', %al
        jnz     1f
        call    main_dump
        jmp     2f              # help
1:
        cmp     $'l', %al
        jnz     1f
        call    main_ledflip
        jmp     3f              # nothing
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
        call    main_exec
        jmp     2f              # help
1:
        cmp     $'j', %al
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
        .ascii "\n [nl]: help\n"
        .ascii   "    l: LED\n"
        .ascii   "    e: ES\n"
        .ascii   "    r: receive to [ES:0000]\n"
        .ascii   "    g: execute at [ES:0000]\n"
        .ascii   "    j: execute at [ES:start]\n"
        .asciz   "    d: dump [ES:start]\n\n"
        .asciz   ""

##################################################

main_dump:
        movw    $text_main_dump_start, %si
        call    print_str_cs
        call    get_h16
        jc      1f
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
1:
        ret

text_main_dump_start:
        .asciz  "\nstart>"
text_main_dump_help:
        .ascii "\n [nl]: continue\n"
        .asciz   "[esc]: end\n"

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

main_exec:
        mov     %es, %ax
        push    %ax
        call    print_h16
        movb    $':', %al
        call    print_byte
        mov     $0x0000, %ax
        push    %ax
        call    print_h16
        movb    $'\n', %al
        call    print_byte
        lret

##################################################

main_ledflip:
        call    led_flip
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
# es:si : address

dump_mem_line:
        push    %ax
        push    %cx
        push    %si

        mov     %es, %ax
        call    print_h16
        movb    $':', %al
        call    print_byte
        mov     %si, %ax
        call    print_h16
        movw    $text_mdump_sep, %si
        call    print_str_cs

        pop     %si
        push    %si
        mov     $0x0010, %cx              # cycle counter
dump_mline_loop1:
        movb    %es:(%si), %al
        inc     %si
        call    print_h8
        movb    $' ', %al
        call    print_byte
        loop    dump_mline_loop1

        movb    $' ', %al
        call    print_byte
        movb    $'|', %al
        call    print_byte

        pop     %si
        push    %si
        mov     $0x0010, %cx              # cycle counter
dump_mline_loop2:
        movb    %es:(%si), %al
        inc     %si
        cmp     $0x20, %al
        jb      dump_mline_loop2_subst
        cmp     $0x7E, %al
        ja      dump_mline_loop2_subst
        jmp     dump_mline_loop2_direct
dump_mline_loop2_subst:
        movb    $'.', %al
dump_mline_loop2_direct:
        call    print_byte
        loop    dump_mline_loop2

        movb    $'|', %al
        call    print_byte
        movb    $'\n', %al
        call    print_byte

        pop     %si
        pop     %cx
        pop     %ax
        ret

text_mdump_sep:
        .asciz "  "


##################################################

print_banner:
        movw    $text_banner, %si
        call    print_str_cs
        movw    $text_cpu, %si
        call    print_str_cs
        call    cpu_id
        mov     %ax, %si
        call    print_str_cs
        movb    $'\n', %al
        call    print_byte
        ret

text_banner:
        .ascii "\n\n ********************\n"
        .ascii     " * x86-light system *\n"
        .asciz     " ********************\n\n"

text_cpu:
        .asciz  "CPU : "

##################################################

print_seginfo:
        movw    $text_CS, %si
        call    print_str_cs
        movw    %cs, %ax
        call    print_h16
        movw    $text_DS, %si
        call    print_str_cs
        movw    %ds, %ax
        call    print_h16
        movw    $text_ES, %si
        call    print_str_cs
        movw    %es, %ax
        call    print_h16
        movw    $text_SP, %si
        call    print_str_cs
        movw    %ss, %ax
        call    print_h16
        movb    $':', %al
        call    print_byte
        movw    %sp, %ax
        call    print_h16
        movb    $'\n', %al
        call    print_byte
        ret

text_CS:
        .asciz "CS:"
text_DS:
        .asciz " DS:"
text_ES:
        .asciz " ES:"
text_SP:
        .asciz " SP:"

##################################################

.include    "uart.inc"
.include    "string.inc"
.include    "led.inc"
.include    "spi.inc"
.include    "cpu.inc"
.include    "int.inc"

# ==== CPU cold start ====

.section .cpu_entry

.equ    CSEG,       0xF000

cpu_start:
        jmp     $CSEG,$_start
        .asciz  "MKunSzabo"

