ASM			= dasm
M4			= m4
PERL		= perl
FIND		= find
MAKE_SPRITE = ./bin/make-sprite
MAKE_PFIELD = ./bin/make-playfield

ASM_FLAGS   = -v0 -f3 -l"$*.lst" -s"$*.sym" 

DEPS_ASM	= $(wildcard ./lib/*.asm) $(wildcard ./gfx/*.asm) $(wildcard bank?/*.asm)
DEPS_H		= $(wildcard ./include/*.h)

DEPS_M4		= $(wildcard ./lib/*.m4)
DEPS_S		= $(DEPS_M4:.m4=.s)

DEPS_MSP	= $(wildcard ./dat/*.msp) $(wildcard ./bank?/dat/*.msp)
DEPS_SP		= $(DEPS_MSP:.msp=.sp)

DEPS_MPF	= $(wildcard ./dat/*.mpf)
DEPS_PF		= $(DEPS_MPF:.mpf=.pf)

TARGET		= blackjack.bin

.PHONY: all
all: $(TARGET) 

$(TARGET): $(DEPS_S) $(DEPS_SP) $(DEPS_PF) $(DEPS_ASM) $(DEPS_H)

%.bin: %.asm
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"

%.sp: %.msp $<
	$(PERL) $(MAKE_SPRITE) "$<" -o"$@"

%.pf: %.mpf
	$(PERL) $(MAKE_PFIELD) "$<" > $@

%.s: %.m4 $<
	$(M4) "$<" > "$@"

%.bin: %.s $<
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"

.PHONY: clean
clean:
	rm -v -f *.bin *.lst *.sym *.s *.pf *.sp dat/*.pf dat/*.sp bank0/*.sp

