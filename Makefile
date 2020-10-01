ASM			= dasm
M4			= m4
PERL		= perl
FIND		= find
MAKE_SPRITE = ./bin/make-sprite
MAKE_PFIELD = ./bin/make-playfield

ASM_FLAGS   = -v0 -f3 -l"$*.lst" -s"$*.sym" 

DEPS_ASM	= $(wildcard ./lib/*.asm) $(wildcard ./gfx/*.asm) \
			$(wildcard bank?/*.asm) $(wildcard bank?/gfx/*.asm) \
			$(wildcard ./sys/*.asm)
DEPS_H		= $(wildcard ./include/*.h) $(wildcard ./sys/*.h)

DEPS_M4		= $(wildcard ./lib/*.m4)
DEPS_S		= $(DEPS_M4:.m4=.s)

DEPS_MSP	= $(wildcard ./gen/*.sprite) $(wildcard ./bank?/gen/*.sprite)
DEPS_SP		= $(DEPS_MSP:.sprite=.sp)

DEPS_MPF	= $(wildcard ./gen/*.mpf) $(wildcard ./bank?/gen/*.mpf)
DEPS_PF		= $(DEPS_MPF:.mpf=.pf)

TARGET		= blackjack.bin

.PHONY: all
all: $(TARGET) 

$(TARGET): $(DEPS_S) $(DEPS_SP) $(DEPS_PF) $(DEPS_ASM) $(DEPS_H)

%.bin: %.asm
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"

%.sp: %.sprite $<
	$(PERL) $(MAKE_SPRITE) "$<" -o"$@" -H1

%.pf: %.mpf
	$(PERL) $(MAKE_PFIELD) "$<" > $@

%.s: %.m4 $<
	$(M4) "$<" > "$@"

%.bin: %.s $<
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"

.PHONY: deploy
deploy: all
	cp blackjack.bin blackjack.lst blackjack.sym /var/www/html/roms/
	chmod ugo+r /var/www/html/roms/blackjack.bin
	echo http://98.225.37.203/roms/blackjack.bin

.PHONY: clean
clean:
	find . "(" -iname '*.bin' -or -iname '*.lst' -or -iname '*.sym' \
	-or -iname '*.pf' -or -iname '*.sp' -or -name "*.exe" ")" \
	-exec rm -fv {} +
