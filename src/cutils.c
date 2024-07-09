#include "cutils.h"


char printf_fmt[128];

char* csegstr(char* p) {
    far_strcpy(get_ds(), printf_fmt,
               get_cs(), p);
    return printf_fmt;
}

size_t strlen (const char* s) {
    size_t  ret;
    for (ret = 0; *s; ++s, ++ret);
    return ret;
}

void* memcpy (void* d, const void* s, size_t len) {
    for (;len; --len, ++d, ++s) {
        *(char*)d = *(char*)s;
    }
    return d;
}

char* strcpy (char *d, const char* s) {
    while ((*d++ = *s++));
    return d;
}


void *memset (void *s, int c, size_t n) {
    char* it = (char*)s;
    while (n--) {
        *it = (char)c;
        it++;
    }
    return s;
}


static int
_putu (unsigned int num, int digits) {
    int n = 1;
    if (num / 10){
        n += _putu(num / 10, digits ? (digits - 1) : 0);
    } else {
        while (digits) {
            bios_putch(' ');
            --digits;
            ++n;
        }
    }
    bios_putch((num % 10) + '0');
    return n;
}

static int
_putx (unsigned int num, int digits) {
    int n = 1;
    if (num / 0x10) {
        n += _putx(num / 0x10, digits ? (digits - 1) : 0);
    } else {
        while (digits) {
            bios_putch('0');
            --digits;
            ++n;
        }
    }
    bios_putch((num % 0x10) + (((num % 0x10) > 9) ? ('a' - 10) : ('0')));
    return n;
}

int bios_printf (const char* fmt, ...) {
    int c = 0;
    int digits = 0;
    va_list ap;
    va_start(ap, fmt);
    for (;*fmt; fmt++) {
        if (*fmt != '%') {
            bios_putch(*fmt);
            c++;
            continue;
        }
        fmt++;
        while ((*fmt >= '0') && (*fmt <= '9')) {
            digits *= 10;
            digits += (*fmt - '0');
            fmt++;
        }
        switch (*fmt) {
          case 'c':
            bios_putch((char)va_arg(ap, unsigned int));
            c++;
            break;
          case 's': {
                char* s = va_arg(ap, char*);
                while (*s) {
                    bios_putch(*s++);
                    c++;
                }
            }
            break;
          case 'x':
          case 'X':
            c += _putx(va_arg(ap, unsigned int), digits ? (digits - 1) : 0);
            digits = 0;
            break;
          case 'd':
          case 'i':
          case 'u':
            c += _putu(va_arg(ap, unsigned int), digits ? (digits - 1) : 0);
            digits = 0;
            break;
        }
    }
    va_end(ap);
    return c;
}


void
buf_dump (char* buf, int lines) {
    int i;
    int addr = 0;
    while (lines--) {
        bios_printf(csegstr("%4x  "), addr);
        for (i = 0; i != 16; i++) {
            bios_printf(csegstr("%2x "), *buf++);
            if (i == 7) {
                bios_printf(csegstr(" "));
            }
        }
        buf -= 16;
        bios_printf(csegstr(" |"));
        for (i = 0; i != 16; i++) {
            if (*buf < 0x20 || *buf > 0x7E) {
                bios_printf(csegstr("."));
            } else {
                bios_printf(csegstr("%c"), *buf);
            }
            buf++;
        }
        addr += 16;
        bios_printf(csegstr("|\n"));
    }
    return;
}

