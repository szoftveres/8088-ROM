
OUTPUT_ARCH(i8086)

SECTIONS
{
  . = 0x0000;
  .text : {
    . = 0x0000;
    *(.text)
    *(.data) 
    *(.rodata*)
    . = 0xFFF0;
    *(.cpu_entry)
    }
  . = 0x0000;
  .bss : {
    *(.bss)
  }
}
