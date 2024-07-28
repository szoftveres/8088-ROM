
main_help:
        NEWLINE
        call    print_clock
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
        cmp     $'b', %al
        jnz     1f
        call    main_flash
        jmp     2f              # help
1:
        cmp     $'s', %al
        jnz     1f
        call    diskmenu_entry
        jmp     2f              # help
1:
        cmp     $'t', %al
        jnz     1f
        call    main_hex_echo
        jmp     2f              # help
1:
        cmp     $'w', %al
        jnz     1f
        call    main_warmboot
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
        .ascii "\n  [nl] : main menu help\n"
        .ascii   "     e : set ES\n"
        .ascii   "     d : memdump [ES:<start>]\n"
        .ascii   "     r : receive to [ES:0000]\n"
        .ascii   "     c : copy [<seg>:0000] to [ES:0000]\n"
        .ascii   "     b : burn [ES:0000] to ROM [F000:0000]\n"
        .ascii   "     g : execute at [ES:0000]\n"
        .ascii   "     s : -> disk menu\n"
        .ascii   "     t : terminal hex echo\n"
        .ascii   "     w : warm boot on next reset\n"
        .asciz   "\n"

##################################################


main_dump:
        NEWLINE
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
        NEWLINE
        call    pic_disable_timers
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
        NEWLINE
        call    led_off
        call    pic_enable_timers
        ret

text_main_recv:
        .ascii  "\nreceiving\n"
        .asciz  "\________________\n"

##################################################

main_eseg_chg:
        NEWLINE
        PRINT_CHAR $'>'
        call    get_h16
        jc      1f
        movw    %ax, %es
1:
        ret

##################################################

main_flash:
        NEWLINE
        push %si

        mov     $main_flash_prompt, %si
        call    print_str_cs
        call    get_h16
        cmpw    $0x8088, %ax
        jnz     1f
        NEWLINE

        call    flash_unlock
        call    erase_seg
        jc      1f
        call    byte_program_seg
        jc      1f
        call    verify_seg
1:
        call    flash_lock
        pop     %si
        ret

main_flash_prompt:
        .asciz  "\nType '8088': "
##################################################

main_warmboot:
        NEWLINE
        movw    $WARMBOOT_REQUEST, %ax
        movw    %ax, warmboot_request
        NEWLINE
        ret

##################################################

main_hex_echo:
        GET_CHAR
        call print_h8
        NEWLINE
        jmp main_hex_echo

        
##################################################

main_cpy:
        NEWLINE
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
        NEWLINE

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
        NEWLINE
        ret

text_jmp_ret:
        .asciz  "\n::"


