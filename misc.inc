
##################################################
# es:si : address

dump_mem_line:
        push    %ax
        push    %cx
        push    %si

        mov     %es, %ax
        call    print_h16
        PRINT_CHAR $':'
        mov     %si, %ax
        call    print_h16
        PRINT_CHAR $' '
        PRINT_CHAR $' '

        pop     %si
        push    %si
        mov     $0x0010, %cx              # cycle counter
dump_mline_loop1:
        movb    %es:(%si), %al
        inc     %si
        call    print_h8
        PRINT_CHAR $' '
        loop    dump_mline_loop1

        PRINT_CHAR $' '
        PRINT_CHAR $'|'

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
        PRINT_CHAR
        loop    dump_mline_loop2

        PRINT_CHAR $'|'
        PRINT_CHAR $'\n'

        pop     %si
        pop     %cx
        pop     %ax
        ret

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
        PRINT_CHAR $':'
        movw    %sp, %ax
        call    print_h16

        PRINT_CHAR $'\n'
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

print_regs:
        push    %ax
        push    %si

        pushf
        push    %di
        push    %si
        push    %bp

        push    %dx
        push    %cx
        push    %bx
        push    %ax

 
        movw    $text_AX, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        movw    $text_BX, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        movw    $text_CX, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        movw    $text_DX, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        movw    $text_BP, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        movw    $text_SI, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        movw    $text_DI, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        movw    $text_flags, %si
        call    print_str_cs
        pop     %ax
        call    print_h16

        PRINT_CHAR $'\n'

        pop     %si
        pop     %ax
        ret

text_AX:
        .asciz "\nAX:"
text_BX:
        .asciz " BX:"
text_CX:
        .asciz " CX:"
text_DX:
        .asciz " DX:"
 
text_BP:
        .asciz "\nBP:"
text_SI:
        .asciz " SI:"
text_DI:
        .asciz " DI:"
text_flags:
        .asciz " SR:"


