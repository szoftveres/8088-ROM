
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
        .asciz   "V20"

text_cpu_8088:
        .asciz   "8088"


##################################################


