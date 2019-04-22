OBJDIR = .
SRCDIR = .
INCLDIR = .
OUTDIR = .

## General Flags
PROGRAM = rom
CC = ia16-elf-gcc
AS = ia16-elf-gcc
LD = ia16-elf-gcc
CFLAGS = -Wall -O0 -fno-PIC -funsigned-char -march=i8086 -mtune=i8086 -L/home/martonk/mgc/embedded/codebench/lib/gcc/ia16-elf/6.2.0 -lgcc
ASFLAGS = -march=i8086 -mtune=i8086
LDFLAGS = -march=i8086 -mtune=i8086 -T ls.ld -L/home/martonk/mgc/embedded/codebench/lib/gcc/ia16-elf/6.2.0 -lgcc

## Objects that must be built in order to link
## XXX The order is important, asmstart MUST be the first one !!
OBJECTS = $(OBJDIR)/asmstart.o      \
#          $(OBJDIR)/main.o          \
#          $(OBJDIR)/fat.o           \


## Build both compiler and program
all: rom-64k

rom-64k: elf
	ia16-elf-objcopy -O binary --pad-to 0x10000 $(OBJDIR)/$(PROGRAM).elf $(OBJDIR)/$(PROGRAM).bin
	ia16-elf-objdump -M i8086 -D $(OBJDIR)/$(PROGRAM).elf > $(OBJDIR)/$(PROGRAM).objdump
	hexdump -C $(OBJDIR)/$(PROGRAM).bin


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

