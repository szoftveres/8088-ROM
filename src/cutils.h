#ifndef _CONIO_H_
#define _CONIO_H_

#include <stddef.h>
#include <stdarg.h>

int bios_printf (const char* fmt, ...);

char* csegstr(char* p);

void buf_dump (char* buf, unsigned int lines);

size_t strlen (const char* s);

void* memcpy (void* d, const void* s, size_t len);

char* strcpy (char *d, const char* s);

void *memset (void *s, int c, size_t n);


/* asm */
extern void bios_putch (int c);

extern int bios_disk_reset (void);
extern int bios_disk_read_chs (unsigned int c, unsigned int h, unsigned int s, void* buf);

extern unsigned int get_cs (void);

extern unsigned int get_ds (void);

extern unsigned int get_ss (void);

extern unsigned int inb (int addr);
extern void outb (int addr, int b);

extern void cli (void);
extern void sti (void);

extern void far_memcpy (unsigned int dst_seg,
                        void* dst_addr,
                        unsigned int src_seg,
                        void* src_addr,
                        int bytes);

extern void far_strcpy (unsigned int dst_seg,
                        char* dst_addr,
                        unsigned int src_seg,
                        char* src_addr);

unsigned int far_read (unsigned int seg, void* addr);
void far_write (unsigned int seg, void* addr, unsigned int data);



#endif

