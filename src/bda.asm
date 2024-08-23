

.equ    BDASEG,         0x0040


.equ    BDA_EBDA_WORD,              0x0E
.equ    BDA_EQUIPMENTLIST_WORD,     0x10
.equ    BDA_MEMORYSIZE_WORD,        0x13

.equ    BDA_KEYBFLAG_WORD,          0x17


.equ    BDA_KEYBUFHEAD_WORD,        0x1A
.equ    BDA_KEYBUFTAIL_WORD,        0x1C
.equ    BDA_KEYBUF_32YTES,          0x1E

.equ    BDA_COLUMNS_WORD,           0x4A

.equ    BDA_DAILYCOUNTERL_WORD,     0x6C
.equ    BDA_DAILYCOUNTERH_WORD,     0x6E

.equ    BDA_ROWS_WORD,              0x84



bda_ctrinc:
    push    %es
    push    %ax
    push    %bx
    push    %di
    movw    $BDASEG, %ax
    movw    %ax, %es

    movw    $BDA_DAILYCOUNTERL_WORD, %di
    movw    %es:(%di), %ax
    movw    $BDA_DAILYCOUNTERH_WORD, %di
    movw    %es:(%di), %bx
    inc     %ax
    jnz     9f
    inc     %bx
    movw    %bx, %es:(%di)
9:
    movw    $BDA_DAILYCOUNTERL_WORD, %di
    movw    %ax, %es:(%di)
    pop     %di
    pop     %bx
    pop     %ax
    pop     %es
    ret



# %di: address (%es=0x0040 relative)
# %ax: value
bda_storew:
    push    %es
    push    %ax
    movw    $BDASEG, %ax
    movw    %ax, %es
    pop     %ax

    movw    %ax, %es:(%di)

    pop     %es
    ret

# %di: address (%es=0x0040 relative)
# %ax: value
bda_loadw:
    push    %es
    movw    $BDASEG, %ax
    movw    %ax, %es

    movw    %es:(%di), %ax

    pop     %es
    ret




bda_init:
    push    %ax
    push    %di

    MEMSET  $BDASEG, $0x0, $0x0, $0x100


    pop     %di
    pop     %ax
    ret

    movw    $0x0000, %ax
    movw    $BDA_EBDA_WORD, %di
    call    bda_storew

    movw    $0x0101, %ax
    movw    $BDA_EQUIPMENTLIST_WORD, %di
    call    bda_storew

    movw    $640, %ax
    movw    $BDA_MEMORYSIZE_WORD, %di
    call    bda_storew

    movw    $80, %ax
    movw    $BDA_COLUMNS_WORD, %di
    # call    bda_storew

    movw    $20, %ax
    movw    $BDA_ROWS_WORD, %di
    # call    bda_storew


    pop     %di
    pop     %ax
    ret
     

