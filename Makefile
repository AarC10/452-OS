#
# Makefile to control the compiling, assembling and linking of standalone
# programs in the DSL.  Used for both individual interrupt handling
# assignments and the SP baseline OS (with appropriate tweaking).
#

##################
#  FILE SECTION  #
##################

#
# OS files
#

NET_C_SRC = ethernet.c ipv4.c udp.c net.c
NET_C_OBJ = ethernet.o ipv4.o udp.o net.o

DRIVER_C_SRC = intel8255x.c intel8255x_ops.c
DRIVER_C_OBJ = intel8255x.o intel8255x_ops.o

OS_C_SRC = cio.c clock.c klibc.c kmem.c list.c main.c procs.c \
	   sio.c support.c syscalls.c user.c dmx.c pci.c $(NET_C_SRC) $(DRIVER_C_SRC)
OS_C_OBJ = cio.o clock.o klibc.o kmem.o list.o main.o procs.o \
	   sio.o support.o syscalls.o user.o dmx.o pci.o $(NET_C_OBJ) $(DRIVER_C_OBJ)

OS_S_SRC = startup.o isrs.o
OS_S_OBJ = startup.o isrs.o

OS_LIBS =

OS_SRCS = $(OS_S_SRC) $(OS_C_SRC)
OS_OBJS = $(OS_S_OBJ) $(OS_C_OBJ)

#
# "Userland" files
#

USR_C_SRC = userland.c ulibc.c
USR_C_OBJ = userland.o ulibc.o


USR_S_SRC = ulibs.S
USR_S_OBJ = ulibs.o

USR_LIBS  =

USR_SRCS  = $(USR_S_SRC) $(USR_C_SRC)
USR_OBJS  = $(USR_S_OBJ) $(USR_C_OBJ)

#
# Bootstrap files
#

BOOT_SRC = boot.S
BOOT_OBJ = boot.o

# Collections of files

OBJECTS = $(OS_OBJS) $(USR_OBJS)

SOURCES = $(BOOT_SRC) $(OS_SRCS) $(USR_SRCS)

#####################
#  OPTIONS SECTION  #
#####################

########################################
# Compilation/assembly definable options
########################################

#
# General options:
#   CLEAR_BSS           include code to clear all BSS space
#   GET_MMAP            get BIOS memory map via int 0x15 0xE820
#   OS_CONFIG           OS-related (vs. just standalone) variations;
#                       also enables GET_MMAP and CLEAR_BSS
#   CONSOLE_STATS       the cio module will print various stats when
#                       characters are typed on the console keyboard
#   FORCE_INLINING      force "inline" functions to be inlined even if
#                       we aren't compiling with at least -O2
#   MAKE_IDENTITY_MAP   Compile vmtables.c with an "identity" page
#                       map table for the first 4MB of the address space.
#   SYSTEM_STATUS=n     clock ISR periodically reports queue and SIO info
#                       every 'n' seconds
#   VIDEO_BW            select black characters on white background for VGA
#   VERBOSE_IDLE        idle process periodically prints '.' characters 
#

GEN_OPTIONS = -DOS_CONFIG -DSYSTEM_STATUS=10 -DFORCE_INLINING \
	      -DCONSOLE_STATS
#		-DVIDEO_BW

#
# Debugging options:
#   ANNOUNCE_ENTRY      announce entry and exit from kernel functions
#   RPT_INT_UNEXP       report any 'unexpected' interrupts
#   RPT_INT_MYSTERY     report interrupt 0x27 specifically
#   TRACE_CX            context restore tracing
#   SANITY=n            enable "sanity check" level 'n' (0/1/2/3/4)
#   CIO_DUP2_SIO        copy all console output to SIO as well
#
# Some modules have their own internal debugging options, described
# in their introductory comments.
#
# Define SANITY as 0 for minimal runtime checking (critical errors only).
# If not defined, SANITY defaults to 9999.
#

DBG_OPTIONS = -DRPT_INT_UNEXP -DTRACE_CX -DCIO_DUP2_SIO

#
# T_ options are used to define bits in a "tracing" bitmask, to allow
# checking of individual conditions. The following are defined:
#
#   T_PCB                   PCB alloc/dealloc
#   T_VM                    VM-related tasks
#   T_QUE                   PCB queue manipulation
#   T_SCH, T_DSP            Scheduler and dispatcher
#   T_SCALL, T_SRET         System call entry and exit
#   T_EXIT                  Process exit actions
#   T_FORK, T_EXEC          Fork and exec actions
#   T_INIT                  Module init function tracing
#   T_KM, T_KMFR, T_KMIN    Kmem module tracing
#   T_SIO, T_SIOR, T_SIOW   General SIO module checks
#   T_USER, T_ELF           User module operations
#   T_STK                   Stack operations
#
# You can add compilation options "on the fly" by using EXTRAS=thing
# on the command line.  For example, to compile with -H (to show the
# hierarchy of #includes):
#
#	make EXTRAS=-H
#

TRACE_OPTIONS = -DT_INIT

USER_OPTIONS = $(GEN_OPTIONS) $(DBG_OPTIONS) $(TRACE_OPTIONS) $(EXTRAS)

#
# Compilation/assembly control
#

#
# We only want to include from the common header directory
#
INCLUDES = -I. -I./include

#
# Compilation/assembly/linking commands and options
#
CPP = cpp
CPPFLAGS = $(USER_OPTIONS) -nostdinc $(INCLUDES)

#
# Compiler/assembler/etc. settings for 32-bit binaries
#
CC = gcc
CFLAGS = -m32 -ggdb -fno-pic -fno-pie -std=c99 -fno-stack-protector -fno-builtin -Wall -Wstrict-prototypes -MD $(CPPFLAGS)
# uncomment this if you want optimization
# CFLAGS += -O2

# assembler settings
AS = as
ASFLAGS = --32

# linker settings
LD = ld
LDFLAGS = -melf_i386 -no-pie -nostdlib

# kernel load point - must agree with what's in kernel.ld!
KLDPT = 0x10000

# kernel linker flags
KLDFLAGS = -Ttext $(KLDPT) -Map=kernel.map

# flags for creating binary blobs (.b files)
BLDFLAGS = -Ttext 0 -s --oformat binary

# archiver flags
AR = ar
#ARFLAGS = rvU
ARFLAGS = rsU

# other programs we use
OBJDUMP = objdump
OBJCOPY = objcopy
NM      = nm
READELF = readelf
PERL    = perl
HEXDUMP = hexdump

#
# QEMU settings
#

# Location of the QEMU binary
#
QEMU = /home/course/csci352/bin/qemu-system-i386

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)

# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)

# options for QEMU
#
# run 'make' with -DQEMUEXTRA=xxx to add option 'xxx' when QEMU is run
#
# does not include a '-serial' option, as that may or may not be needed
QEMUOPTS = -drive file=disk.img,index=0,media=disk,format=raw -netdev user,id=net0 -net nic,model=i82557b,netdev=net0 $(QEMUEXTRA)

##########################
#  TRANSFORMATION RULES  #
##########################

#		
# Transformation rules - these ensure that all compilation
# flags that are necessary are specified
#
# Note use of 'cpp' to convert .S files to temporary .s files: this allows
# use of #include/#define/#ifdef statements. However, the line numbers of
# error messages reflect the .s file rather than the original .S file. 
# (If the .s file already exists before a .S file is assembled, then
# the temporary .s file is not deleted.  This is useful for figuring
# out the line numbers of error messages, but take care not to accidentally
# start fixing things by editing the .s file.)
#
# The .c.X rule produces a .X file which contains the original C source
# code from the file being compiled mixed in with the generated
# assembly language code.  Very helpful when you need to figure out
# exactly what C statement generated which assembly statements!
#

.SUFFIXES:	.S .b .X .i

.c.X:
	$(CC) $(CFLAGS) -g -c -Wa,-adhln $*.c > $*.X

.c.s:
	$(CC) $(CFLAGS) -S $*.c

.S.s:
	$(CPP) $(CPPFLAGS) -o $*.s $*.S

#.S.o:
#	$(CC) $(CFLAGS) -c -o $*.o $*.S
#	$(OBJDUMP) -S $*.o > $*.asm

.S.o:
	$(CPP) $(CPPFLAGS) -o $*.s $*.S
	$(AS) $(ASFLAGS) -o $*.o $*.s -a=$*.lst
	$(RM) -f $*.s

.s.b:
	$(AS) $(ASFLAGS) -o $*.o $*.s -a=$*.lst
	$(LD) $(LDFLAGS) $(BLDFLAGS) -e bootentry -o $*.b $*.o

.c.o:
	$(CC) $(CFLAGS) -c -o $*.o $*.c

.c.i:
	$(CC) -E $(CFLAGS) -c $*.c > $*.i

#
# Update vars.X if variable X has changed since the last time
# 'make' was run.
#
# Rules that use variable X should depend on vars.X.  If the variable's
# value has changed, this will update the vars file and force a rebuild
# of the rule that depends on it.
#

vars.%: FORCE
	echo "$($*)" | cmp -s $@ || echo "$($*)" > $@

.PRECIOUS:      vars.%

.PHONY: FORCE

#############
#  TARGETS  #
#############

#
# Targets for remaking bootable image of the program
#
# Default target:  disk.img
#

disk.img: include/offsets.h boot.b kernel.b BuildImage
	./BuildImage -d usb -o disk.img -b boot.b kernel.b $(KLDPT)

#kernel:	$(OBJECTS) vars.CFLAGS vars.LDFLAGS vars.KLDFLAGS
#	$(LD) $(LDFLAGS) $(KLDFLAGS) -o kernel $(OBJECTS)
#	$(OBJDUMP) -S kernel > kernel.asm
#	$(NM) -n kernel > kernel.sym

kernel.o:	$(OBJECTS) vars.CFLAGS vars.LDFLAGS vars.KLDFLAGS
	$(LD) $(LDFLAGS) $(KLDFLAGS) -o kernel.o $(OBJECTS)
	$(OBJDUMP) -S kernel.o > kernel.asm
	$(NM) -n kernel.o > kernel.sym

kernel.b:	kernel.o vars.BLDFLAGS
	$(LD) $(LDFLAGS) -o kernel.b -s --oformat binary -Ttext $(KLDPT) kernel.o

#boot.o:	boot.S vars.CFLAGS
#	$(CC) $(CFLAGS) -c -o $*.o $*.S
#	$(OBJDUMP) -S $*.o > $*.asm

#boot.b:	boot.o vars.LDFLAGS vars.BLDFLAGS
#	$(LD) $(LDFLAGS) $(BLDFLAGS) -e bootentry -o boot.b boot.o

# all object files
$(OBJECTS):	vars.CFLAGS

#
# Debugging aid
#

kernel.hex:	kernel
	$(HEXDUMP) -C kernel > kernel.hex
	$(OBJCOPY) -S -O binary -j .data kernel kernel.data
	$(HEXDUMP) -C kernel.data > kernel.data.hex
	$(OBJCOPY) -S -O binary -j .rodata kernel kernel.rodata
	$(HEXDUMP) -C kernel.rodata > kernel.rodata.hex

#
# Targets for copying bootable image onto boot devices
#

usb:	disk.img
	/usr/local/dcs/bin/dcopy disk.img

# how to create the .gdbinit config file if we need it
.gdbinit: gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

# "ordinary" gdb
gdb:
	gdb -q -n -x .gdbinit

# gdb with the super-fancy Text User Interface
gdbtui:
	gdb -q -n -x .gdbinit -tui

qemu: disk.img
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

qemu-nox: disk.img
	$(QEMU) -nographic $(QEMUOPTS)

qemu-gdb: disk.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -serial mon:stdio $(QEMUOPTS) -S $(QEMUGDB)

qemu-nox-gdb: disk.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -nographic $(QEMUOPTS) -S $(QEMUGDB)

#
# Special rules for creating the utility programs.  These are required
# because we don't want to use the same options as for the standalone
# binaries - we want these to be compiled as "normal" programs.
#

BuildImage:     BuildImage.c
	@mkdir -p $(@D)
	$(CC) -std=c99 -ggdb -o BuildImage BuildImage.c

networktest: networktests.c
	@echo "Compiling network stack..."
	$(CC) -m32 -std=c99 -ggdb -I./include -DUSE_STDLIB_MEM_FUNCTIONS networktests.c ethernet.c ipv4.c udp.c -o networktest

#
# Offsets is compiled using -mx32 to force a 32-bit execution environment
# for a program that runs under a 64-bit operating system.  This ensures
# that pointers and long ints are 32 bits rather than 64 bits, which is
# critical to correctly determining the size of types and byte offsets for
# fields in structs. We also compile with "-fno-builtin" to avoid signature
# clashes between declarations in our system and function declarations
# built into the C compiler.
#
# If compiled with the CPP macro CREATE_HEADER_FILE defined, Offsets
# accepts a command-line argument "-h". This causes it to write its
# output as a standard C header file into a file named "include/offsets.h"
# where it can be included into other source files (e.g., to provide
# sizes of structs in C and assembly, or to provide byte offsets into
# structures for use in assembly code).
#

Offsets:        Offsets.c
	$(CC) -mx32 -std=c99 -DCREATE_HEADER_FILE $(INCLUDES) -fno-builtin \
		-o Offsets Offsets.c

include/offsets.h:	Offsets
	@./Offsets -h
	-@sh -c 'cmp -s include/offsets.h new_offsets.h || \
		(cp new_offsets.h include/offsets.h; \
		echo "\n*** NOTE - updated include/offsets.h, rebuild!")'
	@rm -f new_offsets.h

#
# Clean out this directory
#

clean:
	rm -f *.nl *.nll *.lst *.asm *.sym *.b *.i *.o *.X *.dis *.hex *.d

realclean:	clean
	rm -f kernel *.img *.map BuildImage Offsets
	rm -f .gdbinit offsets.h vars.* *.d qlog.txt LOG
	rm -rf X

#
# Create a printable namelist from the prog.o file
#

prog.nl: prog.o
	nm -Bng prog.o | pr -w80 -3 > prog.nl

prog.nll: prog.o
	nm -Bn prog.o | pr -w80 -3 > prog.nll

#
# Generate a disassembly
#

prog.dis: prog.o
	objdump -d prog.o > prog.dis

#
# 'makedepend' is a program which creates dependency lists by looking
# at the #include lines in the source files.
#
#
#depend:
#	makedepend $(INCLUDES) $(SOURCES)
#
# DO NOT DELETE THIS LINE -- make depend depends on it.

# use the preprocessor-generated dependency files for this
-include *.d
