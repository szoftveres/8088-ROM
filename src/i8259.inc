
##################################################

pic_init:
        push    %ax

        movb    $0x13, %al          # ICW1 - edge triggered, single, ICW4
        outb    %al, $PIC_BASE+0
        movb    $0x08, %al          # ICW2 - interrupt vector offset = 8
        outb    %al, $PIC_BASE+1
        movb    $0x01, %al          # ICW4 - non buffered mode, 8086/8088
        outb    %al, $PIC_BASE+1

        movb    $0x4F, %al          # OCW1: unmask UART and timer
        outb    %al, $PIC_BASE+1

        pop     %ax
        ret

##################################################

pic_eoi:
        push    %ax
        movb    $0x20, %al
        outb    %al, $PIC_BASE+0
        pop     %ax
        ret

##################################################

