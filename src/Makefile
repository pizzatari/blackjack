ASM			= dasm
M4			= m4
PERL		= perl
FIND		= find
#FIND		= C:\DevBin\MinGW\msys\1.0\bin\find.exe
MAKE_SPRITE = ../../bin/make-big-sprite

FLAGS		= -f3 -l"$*.lst" -s"$*.sym" 

DEPS_ASM	= $(wildcard ./bank?/*.asm) $(wildcard ./lib/*.asm)
DEPS_M4		= $(wildcard ./bank?/*.m4) $(wildcard ./lib/*.m4)
DEPS_DAT	= $(wildcard ./bank?/*.dat) $(wildcard ./dat/*.dat)
DEPS_SPR	= $(wildcard ./bank?/*.spr) $(wildcard ./dat/*.spr)
DEPS_GFX	= $(DEPS_DAT:.dat=.gfx)
DEPS_S		= $(DEPS_M4:.m4=.s)

TARGET		= blackjack.bin

all: $(TARGET)

$(TARGET): $(TARGET:.bin=.asm) $(DEPS_ASM) $(DEPS_DAT) $(DEPS_GFX) \
	$(DEPS_SPR) $(DEPS_M4) $(DEPS_S)

# .asm to .bin
%.bin: %.asm $<
	$(ASM) "$<" $(FLAGS) -o"$@"

# .dat graphics data to .gfx
%.gfx: %.dat $<
	$(PERL) $(MAKE_SPRITE) "$<"

# .m4 to .s
%.s: %.m4 $<
	$(M4) "$<" > "$@"

# .s to .bin
%.bin: %.s $<
	$(ASM) "$<" $(FLAGS) -o"$@"

.PHONY: clean
clean:
	rm -rf *.bin *.lst *.sym *.s *.gfx gfx/*.gfx bank[0-9]/*.gfx

