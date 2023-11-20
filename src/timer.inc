
##################################################
.section .bss

.local timer_1hz
.comm timer_1hz, 1, 2

.local timer_seconds
.comm timer_seconds, 2, 2
.local timer_minutes
.comm timer_minutes, 2, 2
.local timer_hours
.comm timer_hours, 2, 2

.section .text
##################################################


clock_init:
        movw    $2, (timer_1hz)
        movw    $0, (timer_seconds)
        movw    $0, (timer_minutes)
        movw    $0, (timer_hours)
        ret

# these are two byte vars, but we're accessing
# only the LSB, for lower 8088 bus bandwidth

int_timer_2hz:
        push    %ax
        push    %ds
        mov     $DSEG, %ax
        mov     %ax, %ds

        call    led_flip
        decb    (timer_1hz)
        jnz     9f
        movb    $2, (timer_1hz)

        movb    (timer_seconds), %al
        incb    %al
        cmpb    $60, %al
        movb    %al, (timer_seconds)
        jnz     9f
        movb    $0, (timer_seconds)

        movb    (timer_minutes), %al
        incb    %al
        cmpb    $60, %al
        movb    %al, (timer_minutes)
        jnz     9f
        movb    $0, (timer_minutes)
        
        incb    (timer_hours)
9:

        pop     %ds
        pop     %ax
        call    pic_eoi
        iret


int_timer_32hz:
        int     $0x1C
        call    pic_eoi
        iret


print_clock:
        push    %ax
        push    %si
        movw    $print_clock_text, %si
        call    print_str_cs
        movw    (timer_hours), %ax
        call    print_dec16
        PRINT_CHAR  $':'
        movw    (timer_minutes), %ax
        call    print_dec16
        PRINT_CHAR  $':'
        movw    (timer_seconds), %ax
        call    print_dec16
        PRINT_CHAR  $'\n'
        pop     %si
        pop     %ax
        ret
print_clock_text:
        .asciz "Time : "




