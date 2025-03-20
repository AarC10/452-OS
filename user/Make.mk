#
# Makefile fragment for the user components of the system.
# 
# THIS IS NOT A COMPLETE Makefile - run GNU make in the top-level
# directory, and this will be pulled in automatically.
#

SUBDIRS += user

###################
#  FILES SECTION  #
###################

USER_SRC := user/idle.c user/init.c user/shell.c \
	user/progABC.c user/progDE.c user/progFG.c user/progH.c \
	user/progI.c user/progJ.c user/progKL.c user/progMN.c \
	user/progP.c user/progQ.c user/progR.c user/progS.c \
	user/progTUV.c user/progW.c user/progX.c user/progY.c \
	user/progZ.c

USER_OBJ := $(patsubst %.c, $(BUILDDIR)/%.o, $(USER_SRC))

USER_BIN := $(basename $(USER_SRC))
USER_BIN := $(addprefix $(BUILDDIR)/, $(USER_BIN))

ULDFLAGS := -T user/user.ld
ULIBS := -luser -lcommon

###################
#  RULES SECTION  #
###################

userland: $(USER_BIN)

$(BUILDDIR)/user/%.o: user/%.c $(BUILDDIR)/.vars.CFLAGS
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILDDIR)/user/%: $(BUILDDIR)/user/%.o
	@mkdir -p $(@D)
	$(LD) $(ULDFLAGS) $(LDFLAGS) -o $@ $@.o $(ULIBS)
	$(OBJDUMP) -S $@ > $@.asm
	$(NM) -n $@ > $@.sym
	$(READELF) -a $@ > $@.info

user.img:	$(USR_BIN) mkblob
	mkblob $(USER_BIN)
