.code16
.arch i8086  #,nojumps             # see documentation

.global bios_putch

.global bios_disk_reset
.global bios_disk_read_chs

.global get_cs
.global get_ds
.global get_ss
.global cli
.global sti
.global far_memcpy
.global far_strcpy
.global far_read
.global far_write
.global inb
.global outb




# ASM helper funcitons 
##################################################
.section .text

# character on stack as int
bios_putch:
    push    %bp
    movw    %sp,%bp
    mov     0x4(%bp),%ax
    movb    $0x0E,%ah
    int     $0x10
    pop     %bp
    ret



# return: ax
bios_disk_reset:
    push    %dx
    xor     %dx, %dx        # dl: drive no
    xor     %ax, %ax
    int     $0x13
    jc      1f
    xor     %ax, %ax
    jmp     2f
1:
    movb    %ah, %al
    xorb    %ah, %ah
2:
    pop     %dx
    ret


# character on stack as int
bios_disk_read_chs:
    push    %bp
    movw    %sp,%bp

    push    %cx
    push    %dx
    push    %es
    push    %bx

    push    %ds             # ES:BX: buffer
    pop     %es
    movw    0xA(%bp), %bx

    movw    0x6(%bp), %dx   # head
    xchg    %dl, %dh 
    movb    $0x0, %dl        # drive no.
    
    movw    0x8(%bp), %cx   # sector
    andb    $0x3F, %cl      # 6 bits

    movw    0x4(%bp), %ax   # cylinder
    movb    %al, %ch
    rorb    $1, %ah
    rorb    $1, %ah
    andb    $0xC0, %ah
    orb     %ah, %cl
        
    movb    $0x02,%ah       # AH=02h: Read Sectors From Drive
    movb    $0x01,%al       # 1 sector to read
    int     $0x13
    jc      1f
    xor     %ax, %ax
    jmp     2f
1:
    movb    %ah, %al
    xorb    %ah, %ah
2:
    pop     %bx
    pop     %es
    pop     %dx
    pop     %cx

    pop     %bp
    ret


get_cs:
        mov     %cs, %ax
        ret

get_ds:
        mov     %ds, %ax
        ret

get_ss:
        mov     %ss, %ax
        ret

cli:
        cli
        ret

sti:
        sti
        ret


#1:dst seg
#2:dst addr
#3:src seg
#4:src addr
#5:num of bytes

far_memcpy:
    push    %bp
    movw    %sp,%bp
    push    %cx
    push    %es
    push    %ds
    push    %si
    push    %di

    cld
    movw    0xc(%bp),%cx    # num of bytes
    movw    0xa(%bp),%si    # src addr
    movw    0x8(%bp),%ds    # src seg
    movw    0x6(%bp),%di    # dst addr
    movw    0x4(%bp),%es    # dst seg

    rep movsb

    pop     %di
    pop     %si
    pop     %ds
    pop     %es
    pop     %cx
    pop     %bp
    ret


#1:dst seg
#2:dst addr
#3:src seg
#4:src addr

far_strcpy:
    push    %bp
    movw    %sp,%bp
    push    %ax
    push    %es
    push    %ds
    push    %si
    push    %di

    movw    0xa(%bp),%si    # src addr
    movw    0x8(%bp),%ds    # src seg
    movw    0x6(%bp),%di    # dst addr
    movw    0x4(%bp),%es    # dst seg
1:
    movb    %ds:(%si), %al
    movb    %al, %es:(%di)
    orb     %al, %al
    jz      9f
    inc     %si
    inc     %di
    jmp     1b
9:
    pop     %di
    pop     %si
    pop     %ds
    pop     %es
    pop     %ax
    pop     %bp


#1:seg
#2:addr
far_read:
    push    %bp
    movw    %sp,%bp
    push    %si
    push    %es

    movw    0x6(%bp),%si    #addr
    movw    0x4(%bp),%es
    movw    %es:(%si),%ax

    pop     %es
    pop     %si
    pop     %bp
    ret


#1:seg
#2:addr
#3:data
far_write:
    push    %bp
    movw    %sp,%bp
    push    %di
    push    %ax
    push    %es

    movw    0x8(%bp),%ax
    movw    0x6(%bp),%di    #addr
    movw    0x4(%bp),%es
    movw    %ax,%es:(%di)

    pop     %es
    pop     %ax
    pop     %di
    pop     %bp
    ret


inb:
    push    %bp
    movw    %sp,%bp
    push    %dx
    
    movw    0x4(%bp), %dx   # port
    xor     %ax, %ax
    inb     (%dx), %al

    pop     %dx
    pop     %bp
    ret


outb:
    push    %bp
    movw    %sp,%bp
    push    %dx
    push    %ax

    movw    0x6(%bp), %ax   # data
    movw    0x4(%bp), %dx   # port
    outb    %al, (%dx)

    pop     %ax
    pop     %dx
    pop     %bp
    ret

