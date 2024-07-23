.code16
.arch i8086 #,nojumps             # see documentation

# 0000:0000 - 0000:03FF   1kB  interrupt vectors
# 0020:0200               SP on top of interrupt vectors
# 0040:0000               DS

.global main
.global _start


# == Memory map ==

# 0x00000-0x003FF         interrupt vectors   1k    ->| 1k
# 0x00400-0x004FF         Bios data area      256b  ->| 1.25k
# 0x00500-0x07BFF         Free RAM area     29.75k  ->| 31.5k
# 0x07C00-0x07FFF         OS load buffer      512b  ->| 32k

# BIOS cpu configuration:
#   DSEG:0x0000
#   SSEG:0x0000
#   SP:  0x0000:0400

# Linker script to initialize .bss to 0x0400
# ================


.equ    IO_BASE,    0x0060



.equ    ROMSEG,     0xE000      # First ROM address
.equ    BIOSVAR_AREA_SIZE,  0x1000 # 4k

.equ    SSEG,               (ROMSEG - (BIOSVAR_AREA_SIZE >> 4))
.equ    STACKP,             BIOSVAR_AREA_SIZE
.equ    DSEG,               (ROMSEG - (BIOSVAR_AREA_SIZE >> 4))

# Boot sector load address
.equ    ZEROSEG,        0x0000
.equ    BOOTADDR,       0x7C00

##################################################
.section .bss

.local ramsize
.comm ramsize, 2, 2
.local boot_cs
.comm boot_cs, 2, 2
.local warmboot_request
.comm warmboot_request, 2, 2

.equ    WARMBOOT_REQUEST,   0x5A85

##################################################
.section .text

.include    "src/macros.inc"

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

        movw    $DSEG, %ax
        movw    %ax, %ds
        movw    %ds:warmboot_request, %ax
        cmpw    $WARMBOOT_REQUEST, %ax
        movw    $0x0000, %ds:warmboot_request
        jz      startover
        movw    %cs, %ax
        cmpw    $ROMSEG, %ax
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
        mov     %ax, %ds:(%di)      # store the result

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
        call    clock_init
        sti
        call    uart_init
        call    spi_init
        call    sd_init

##################################################

        call    led_off
        call    print_banner
        call    uart_type

#        movw    $0x8888, %ax
#        push    %ax
#        pop     %es
#        movw    $0x1111, %ax
#        movw    $0x2222, %bx
#        movw    $0x3333, %cx
#        movw    $0x4444, %dx
#        movw    $0x5555, %bp
#        movw    $0x6666, %si
#        movw    $0x7777, %di

#        int     $0x10
#        call    print_regs
#        call    print_seginfo


##################################################
1:
        call    main_help       # Going to the main menu
        jmp     1b

##################################################


print_banner:
        NEWLINE
        movw    $text_banner, %si
        call    print_str_cs
        NEWLINE

        movw    $text_rom, %si          # ROM date
        call    print_str_cs
        movw    $text_romdate, %si
        call    print_str_cs
        NEWLINE

        movw    $text_cpu, %si          # CPU type
        call    print_str_cs
        call    cpu_id
        mov     %ax, %si
        call    print_str_cs
        NEWLINE

        movw    $text_maxram, %si       # max RAM
        call    print_str_cs

        movw    $0xA55A, %cx            # Int12 magic numbers
        movw    $0x5AA5, %dx
        int     $0x12                   # get the value 

        call    print_dec16
        PRINT_CHAR $'k'
        NEWLINE

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

.include    "src/mainmenu.asm"
.include    "src/diskmenu.asm"
.include    "src/string.asm"
.include    "src/i8259.asm"
.include    "src/int.asm"
.include    "src/uart.asm"
.include    "src/timer.asm"
.include    "src/led.asm"
.include    "src/spi.asm"
.include    "src/sd.asm"
.include    "src/disk.asm"
.include    "src/cpu.asm"
.include    "src/misc.asm"
.include    "src/flash.asm"

# ==== CPU cold start ====

.section .cpu_entry

# BIOS 
.equ    ROM_BOOT_SEG,   0xF000

cpu_start:
        jmp     $ROM_BOOT_SEG,$_start
text_romdate:
.include    "date.inc"

