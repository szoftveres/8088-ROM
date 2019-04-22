
##################################################
# ax: string address

cpu_id:

        mov     $0x0101, %ax
        aad     $0x10               # NEC V20 ignores the argument
        cmp     $0x0B, %al          # and always does AL = AL * 0Ah + AH
        jnz     1f
        mov     $text_cpu_v20, %ax
        jmp     2f
1:
        mov     $text_cpu_8088, %ax
2:
        ret


text_cpu_v20:
        .asciz   "NEC V20"

text_cpu_8088:
        .asciz   "8088"


##################################################
# ax: RAM top segment + 1

ram_det:

        push    %bx
        push    %cx
        push    %di

        push    %ds             # save DS

        mov     $0x0000, %cx    # segment counter
        mov     $0x0000, %di    
ram_det_loop:

        mov     %cx, %ds

        movb    (%di), %bl      # save contents
        movb    $0x55, %al
        movb    %al, (%di)      # fill with pattern 1
        movb    (%di), %al
        movb    %bl, (%di)      # restore contents
        cmpb    $0x55, %al      # compare pattern
        jnz     ram_det_bail

        movb    (%di), %bl      # save contents
        movb    $0xAA, %al
        movb    %al, (%di)      # fill with pattern 2
        movb    (%di), %al
        movb    %bl, (%di)      # restore contents
        cmpb    $0xAA, %al      # compare pattern
        jnz     ram_det_bail

        add     $0x0010, %cx    # check every 256th byte
        cmp     $ROMSEG, %cx
        jnz     ram_det_loop

ram_det_bail:

        pop     %ds             # restore DS

        mov     %cx, %ax        # result in AX

        pop     %di
        pop     %cx
        pop     %bx
        ret

##################################################


