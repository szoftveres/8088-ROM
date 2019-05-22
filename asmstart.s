.code16
.arch i8086  #,nojumps             # see documentation

.global main
.global _start

.equ    ROMSEG,     0xE000      # First ROM address

.equ    UART_BASE,  0x0020
.equ    PIC_BASE,   0x0040
.equ    IO_BASE,    0x0060

# upper 512 byte of the interrupt table
.equ    SSEG,               0x0020
.equ    STACKP,             0x0200

# First address above the interrupt table
.equ    DSEG,               0x0040

# Boot sector load address
.equ    BOOTSEG,        0x0000
.equ    BOOTADDR,       0x7C00

# BIOS 
.equ    ROM_BOOT_SEG,   0xF000

##################################################
.section .bss

.local ramsize
.comm ramsize, 2, 2
.local boot_cs
.comm boot_cs, 2, 2

##################################################
.section .text

.include    "macros.inc"

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
        movb    $0x02, %bl
        jmp     halt_blink
cpu_ok:

##################################################
# Skip RAM checks when we're running from RAM
# otherwise we would overwrite ourselves

        mov     %cs, %ax
        cmp     $ROMSEG, %ax
        jb      warm_start

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
        movb    $0x03, %bl
        jmp     halt_blink
ram_fail2:
        mov     $0x03, %bl
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

##################################################
# overwrite set up the interrupt table as well

warm_start:
        mov     $SSEG, %ax
        mov     %ax, %ss
        mov     $STACKP,%sp
        call    int_init

##################################################
# don't touch the interrupt table

startover:
        mov     $DSEG, %ax
        mov     %ax, %ds
        mov     $SSEG, %ax
        mov     %ax, %ss
        mov     $STACKP,%sp
        push    %cs
        pop     %es
        mov     %cs, boot_cs

##################################################
# init hardware and interrupt table

        call    pic_init
        sti
        call    uart_init
        call    spi_init
        call    sd_system_init
        call    sd_init

##################################################

        call    led_off
        call    print_banner

##################################################

main_help:
        movw    $main_help_text, %si
        call    print_str_cs
        call    print_seginfo

mainloop:
        GET_CHAR

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
        cmp     $'c', %al
        jnz     1f
        call    main_cpy
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
        cmp     $'s', %al
        jnz     1f
        call    main_flash
        jmp     2f              # help
1:
        cmp     $'b', %al
        jnz     1f
        call    main_boot
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
        call    print_regs
        jmp     main_help
3:
        jmp     mainloop

main_help_text:
        .ascii "\n  [nl] : help\n"
        .ascii   "     e : set ES\n"
        .ascii   "     d : memdump [ES:<start>]\n"
        .ascii   "     r : receive to [ES:0000]\n"
        .ascii   "     c : copy [<seg>:0000] to [ES:0000]\n"
        .ascii   "     s : burn [ES:0000] to ROM [E000:0000]\n"
        .ascii   "     g : execute at [ES:0000]\n"
        .ascii   "     b : boot [0000:7C00]\n"
        .asciz   "\n"

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

        GET_CHAR
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
        .asciz   " [any] : end\n\n"

##################################################
main_recv:
        movw    $text_main_recv, %si
        call    print_str_cs
        call    led_on
        mov     $0x0000, %di
        mov     $0x1000, %cx        # progress line
main_recv_loop:
        GET_CHAR %es:(%di)
        dec     %cx
        jnz     1f
        mov     $0x1000, %cx        # progress line
        PRINT_CHAR $'#'
1:
        inc     %di
        jnz     main_recv_loop
        PRINT_CHAR $'\n'
        call    led_off
        ret

text_main_recv:
        .ascii  "\nreceiving\n"
        .asciz  "\________________\n"

##################################################

main_eseg_chg:
        PRINT_CHAR $'>'
        call    get_h16
        jc      1f
        movw    %ax, %es
1:
        ret

##################################################

main_flash:
        call    check_flash_cs
        jnz     1f
        PRINT_CHAR $'\n'

        call    erase_seg
        jc      1f
        call    byte_program_seg
        jc      1f
        call    verify_seg
1:
        ret

##################################################

main_boot:

        call    ipl
        jnc     1f
        mov     %ax, %si
        call    print_str_cs
1:
        mov     $BOOTSEG, %ax
        mov     %ax, %es
        mov     %ax, %ds
        jmp     $BOOTSEG,$BOOTADDR

##################################################

main_cpy:
        PRINT_CHAR $'>'
        call    get_h16
        jc      1f

        push    %ds
        mov     %ax, %ds
        cld
        movw    $0x8000, %cx    # 32k Words == 64k bytes
        movw    $0x0000, %si
        movw    $0x0000, %di
        rep movsw

        pop     %ds        
1:
        ret
##################################################

main_jmp:
        PRINT_CHAR $'\n'

        push    %ds                     # save regs
        push    %es                     # save regs

        mov     %es, %ax
        mov     %ax, %ds                # Set new %ds

        push    %cs                     # return address
        mov     $main_jmp_ret, %ax
        push    %ax

        mov     %es, %ax                # start address seg
        push    %ax
        mov     $0x0000, %ax
        push    %ax                     # start address offset

        lret
main_jmp_ret:
        pop     %es
        pop     %ds
        mov     $text_jmp_ret, %si
        call    print_str_cs
        call    print_h16
        PRINT_CHAR $'\n'
        ret

text_jmp_ret:
        .asciz  "\n::"

##################################################

print_banner:
        PRINT_CHAR $'\n'
        movw    $text_banner, %si
        call    print_str_cs
        PRINT_CHAR $'\n'

        movw    $text_rom, %si          # ROM date
        call    print_str_cs
        movw    $text_romdate, %si
        call    print_str_cs
        PRINT_CHAR $'\n'

        movw    $text_cpu, %si          # CPU type
        call    print_str_cs
        call    cpu_id
        mov     %ax, %si
        call    print_str_cs
        PRINT_CHAR $'\n'

        movw    $text_maxram, %si       # max RAM
        call    print_str_cs

        movw    $0xA55A, %cx            # Int12 magic numbers
        movw    $0x5AA5, %dx
        int     $0x12                   # get the value 

        call    print_dec16
        PRINT_CHAR $'k'
        PRINT_CHAR $'\n'

        ret


text_banner:
        .ascii "                          __   __              ______   ________\n"
        .ascii "     ______ _____ _____  |  | |  |    ___  ___/  __  \\ /  _____/\n"
        .ascii "    /  ___//     \\\\__  \\ |  | |  |    \\  \\/  /)      (/       \\ \n"
        .ascii "    \\___ \\|  Y Y  \\/ __ \\|  |_|  |__   )    (/   --   \\   --   \\\n"
        .asciz "   /______)__|_|__(______)____/____/  /__/\\__\\________/\\_______/\n"

text_rom:
        .asciz  " ROM : "
text_cpu:
        .asciz  " CPU : "
text_maxram:
        .asciz  " RAM : "

##################################################

.include    "int.inc"
.include    "uart.inc"
.include    "string.inc"
.include    "led.inc"
.include    "spi.inc"
.include    "sd.inc"
.include    "disk.inc"
.include    "cpu.inc"
.include    "misc.inc"
.include    "flash.inc"

# ==== CPU cold start ====

.section .cpu_entry

cpu_start:
        jmp     $ROM_BOOT_SEG,$_start
text_romdate:
.include    "date.inc"

