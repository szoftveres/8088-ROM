
.global print_dec16

##################################################
# al: data

print_h4:
        push    %ax
        and     $0x000F, %ax            # lowest 4 bits
        add     $0x30, %ax
        cmp     $0x3a, %ax
        jb      print_h4_num
        add     $0x07, %ax
print_h4_num:
        PRINT_CHAR
        pop     %ax
        ret

##################################################
# [0-9, a-f, A-F]
# al: return data
# carry set: error

get_h4:
        GET_CHAR
        and     $0x00FF, %ax
        cmp     $0x30, %ax
        jb      2f              # bail
        sub     $0x30, %ax
        cmp     $0x0a, %ax
        jb      1f              # numeric, done
        sub     $0x07, %ax
        cmp     $0x0a, %ax
        jb      2f              # bail
        cmp     $0x10, %ax
        jb      1f              # capital case alpha, done
        sub     $0x20, %ax
        cmp     $0x0a, %ax
        jb      2f              # bail
        cmp     $0x0f, %ax
        ja      2f              # bail
1:
        and     $0x0F, %al
        clc
        ret
2:
        stc
        ret

##################################################
# al: data

print_h8:
        push    %ax
        push    %cx
        movb    $4, %cl
        rol     %cl, %al
        call    print_h4
        rol     %cl, %al
        call    print_h4
        pop     %cx
        pop     %ax
        ret

##################################################
# [0-9, a-f, A-F]
# al: return data
# carry set: error

get_h8:
        push    %bx
        push    %cx
        movb    $4, %cl
        call    get_h4
        jc      1f
        shl     %cl, %al
        mov     %al, %bl
        call    get_h4
        jc      1f
        add     %bl, %al
1:
        pop     %cx
        pop     %bx
        ret

##################################################
# ax: data

print_h16:
        push    %ax
        push    %cx
        movb    $4, %cl
        rol     %cl, %ax
        call    print_h4
        rol     %cl, %ax
        call    print_h4
        rol     %cl, %ax
        call    print_h4
        rol     %cl, %ax
        call    print_h4
        pop     %cx
        pop     %ax
        ret

##################################################
# [0-9, a-f, A-F]
# ax: return data
# carry set: error

get_h16:
        push    %bx
        push    %cx
        movb    $8, %cl
        mov     $0x0000, %bx
        call    get_h8
        jc      1f
        and     $0x00FF, %ax
        add     %ax, %bx
        shl     %cl, %bx
        call    get_h8
        jc      1f
        and     $0x00FF, %ax
        add     %ax, %bx
        mov     %bx, %ax
1:
        pop     %cx
        pop     %bx
        ret

##################################################
# ax: data

print_dec16:
        push    %bx
        push    %dx

        xor     %dx, %dx
        mov     $10, %bx

        div     %bx
        or      %ax, %ax
        jz      1f

        call    print_dec16
1:
        mov     %dx, %ax
        add     $'0', %al
        PRINT_CHAR
        pop     %dx
        pop     %bx
        ret

##################################################
# Print null-terminated string from current DS
# si: address

print_str:
        push    %ax
        push    %si
print_str_loop:
        movb    %ds:(%si), %al
        inc     %si
        and     $0x00FF, %ax
        jz      print_str_done
        PRINT_CHAR
        jmp     print_str_loop
print_str_done: 
        pop     %si
        pop     %ax
        ret

##################################################
# Print null-terminated string from CS
# si: address

print_str_cs:
        push    %ax
        mov     %ds, %ax
        push    %ax                     # Save current DS
        movw    %cs, %ax
        mov     %ax, %ds
        call    print_str
        pop     %ax
        mov     %ax, %ds                # restore DS
        pop     %ax
        ret

##################################################

