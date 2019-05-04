
##################################################
# src: src byte (default: %al)

.macro  PRINT_CHAR      src

    .ifnb   \src
        movb    \src, %al
    .endif
        movb    $0x0E, %ah
        int     $0x10
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
        
        
