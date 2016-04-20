######################################################################
# MieruEMB System V1.0  2011-10-01                Arch Lab. TOKYO TECH
######################################################################

TARGET  = init
OBJS    = startup.o main.o
CMDPREF = /home/share/cad/mipsel-emb/usr/bin/
#CMDPREF = /home/share/cad/mipsel/usr/bin/

MIPSCC  = $(CMDPREF)mipsel-linux-gcc
MIPSAS  = $(CMDPREF)mipsel-linux-as
MIPSLD  = $(CMDPREF)mipsel-linux-ld
OBJDUMP = $(CMDPREF)mipsel-linux-objdump
MEMGEN  = memgen

AFLAGS  = 
CFLAGS  = -Wall -O2
LFLAGS  =

.SUFFIXES:
.SUFFIXES: .o .c .S
######################################################################
all:
	$(MAKE) clean
	$(MAKE) $(TARGET)
	$(MAKE) image

$(TARGET): $(OBJS)
	$(MIPSLD) $(LFLAGS) -T stdld.script $(OBJS) -o $(TARGET)

.c.o:
	$(MIPSCC) $(CFLAGS) -c $(@D)/$(<F) -o $(@D)/$(@F)

.S.o:
	$(MIPSCC) $(AFLAGG) -c $(@D)/$(<F) -o $(@D)/$(@F)

image:
	$(MEMGEN) -b $(TARGET) 512 > $(TARGET).bin

dump:
	$(OBJDUMP) -D $(TARGET)

read:
	readelf -a $(TARGET)

clean:
	rm -f *.o *~ log.txt $(TARGET) $(TARGET).bin
######################################################################
