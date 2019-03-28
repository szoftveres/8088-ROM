OBJDIR = .
SRCDIR = .
INCLDIR = .
OUTDIR = .

## General Flags
PROGRAM = rom
CC = ia16-elf-gcc
AS = ia16-elf-gcc
LD = ia16-elf-ld
CFLAGS = -Wall -O0 -fno-PIC -funsigned-char -march=i8086 -mtune=i8086
ASFLAGS = -march=i8086 -mtune=i8086
LDFLAGS = --architecture i8086 -nostdlib -T ls.ld

## Objects that must be built in order to link
## XXX The order is important, asmstart MUST be the first one !!
OBJECTS = $(OBJDIR)/asmstart.o      \
          $(OBJDIR)/main.o          \


## Build both compiler and program
all: rom-64k

rom-64k: elf
	ia16-elf-objcopy --set-section-flags '.cpu_entry=code,noload,alloc' --pad-to 0x10000 -O binary $(OBJDIR)/$(PROGRAM).elf $(OBJDIR)/$(PROGRAM).bin
	ia16-elf-objdump -M i8086 -d $(OBJDIR)/$(PROGRAM).elf
	#hexdump -C $(OBJDIR)/$(PROGRAM).bin


## Compile source files
$(OBJDIR)/%.o : $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c -o $(OBJDIR)/$*.o $< 

## Compile source files
$(OBJDIR)/%.o : $(SRCDIR)/%.s
	$(AS) $(ASFLAGS) -c -o $(OBJDIR)/$*.o $<

elf: $(OBJECTS)
	$(LD) $(LDFLAGS) -o $(OBJDIR)/$(PROGRAM).elf $(OBJECTS)


clean:
	-rm -rf $(OBJECTS) $(OBJDIR)/$(PROGRAM).elf $(OBJDIR)/$(PROGRAM).bin

