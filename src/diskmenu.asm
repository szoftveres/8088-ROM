.global dump_rootdir

diskmenu_help:
        NEWLINE
        call    print_clock
        movw    $diskmenu_help_text, %si
        call    print_str_cs
        call    print_seginfo

diskmenu_loop:
        GET_CHAR

        cmp     $'b', %al
        jnz     1f
        call    disk_boot_os
        jmp     2f              # help
1:
        cmp     $'r', %al
        jnz     1f
        call    disk_full_reset
        jmp     2f              # help
1:
        cmp     $'d', %al
        jnz     1f
        call    dump_rootdir
        jmp     2f              # help
1:
        cmp     $'x', %al
        jnz     1f
        ret
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
        jmp     diskmenu_help
3:
        jmp     diskmenu_loop

diskmenu_help_text:
        .ascii "\n  [nl] : disk menu help\n"
        .ascii   "     r : full disk system reset\n"
        .ascii   "     b : boot OS from mbr [0000:7C00]\n"
        .ascii   "     d : dump rootdir\n"
        .ascii   "     x : <- back to main menu\n"
        .asciz   "\n"

##################################################

disk_boot_os:
        NEWLINE
        movw    $0x0000, %ax
        int     $0x13           # reset disk
        jc      2f
        call    ipl
        jnc     1f
2:
        mov     $boot_error_text, %si
        call    print_str_cs
        ret
1:
        mov     $ZEROSEG, %ax
        mov     %ax, %es
        mov     %ax, %ds
        jmp     $ZEROSEG,$BOOTADDR

boot_error_text:
        .asciz "boot error\n"

##################################################

disk_full_reset:
        NEWLINE

        call    sd_init
        mov     $diskfullreset_sdiniterr_text, %si
        jc      1f
        mov     $diskfullreset_sdinitok_text, %si
        call    print_str_cs

        movw    $0x0000, %ax
        int     $0x13           # reset disk
        mov     $diskfullreset_diskerr_text, %si
        jc      1f
        mov     $diskfullreset_diskok_text, %si
1:
        call    print_str_cs
        ret

diskfullreset_sdiniterr_text:
        .asciz "sdcard init error\n"
diskfullreset_sdinitok_text:
        .asciz "sdcard init ok\n"
diskfullreset_diskerr_text:
        .asciz "unrecognized partition\n"
diskfullreset_diskok_text:
        .asciz "partition found\n"


