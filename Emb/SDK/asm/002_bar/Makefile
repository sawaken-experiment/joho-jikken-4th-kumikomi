######################################################################
# MieruEMB System V1.0  2011-10-01                Arch Lab. TOKYO TECH
######################################################################

TARGET   = init
OBJS = startup.o main.o
CMDPREF = /home/share/cad/mipsel-emb/usr/bin/

MIPSCC  = $(CMDPREF)mipsel-linux-gcc
MIPSAS  = $(CMDPREF)mipsel-linux-as
MIPSLD  = $(CMDPREF)mipsel-linux-ld
OBJDUMP = $(CMDPREF)mipsel-linux-objdump
MEMGEN  = memgen

AFLAGS  = 
LFLAGS  = -static

.SUFFIXES:
.SUFFIXES: .o .S
######################################################################
all:
	$(MAKE) $(TARGET)
	$(MAKE) image

$(TARGET): $(OBJS)
	$(MIPSLD) $(LFLAGS) -T stdld.script $(OBJS) -o $(TARGET)

.S.o:
	$(MIPSAS) $(AFLAGG) $(@D)/$(<F) -o $(@D)/$(@F)

image:
	$(MEMGEN) -b $(TARGET) 512 > $(TARGET).bin

dump:
	$(OBJDUMP) -S $(TARGET)

read:
	readelf -a $(TARGET)

clean:
	rm -f *.o *~ log.txt $(TARGET) $(TARGET).bin
######################################################################
