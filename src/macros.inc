
##################################################
# src: src byte (default: %al)

.macro  PRINT_CHAR      src

    .ifnb   \src
        push    %ax
        movb    \src, %al
    .endif
        movb    $0x0E, %ah
        int     $0x10
    .ifnb   \src
        pop     %ax
    .endif
.endm

##################################################
# dst: destination (default: %al)

.macro  GET_CHAR        dst

        movb    $0x00, %ah
        int     $0x16
    .ifnb   \dst
        movb    %al, \dst
    .endif
.endm

##################################################

.macro  NEWLINE
    PRINT_CHAR $'\n'
.endm

##################################################

.macro  MEMSET  segm, addr, data, bytes
    push    %ax
    push    %cx
    push    %es
    push    %di

    movw    \segm, %ax
    movw    %ax, %es
    movw    \addr, %di
    movb    \data, %al
    movw    \bytes, %cx
    call    memset_ll

    pop     %di
    pop     %es
    pop     %cx
    pop     %ax
.endm

        
