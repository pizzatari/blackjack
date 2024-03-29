ASM         = dasm
M4          = m4
PERL        = perl
FIND        = find
MAKE_SPRITE = ./bin/make-sprite
MAKE_PFIELD = ./bin/make-playfield

INC_DIR     = ../atarilib/include
LIB_DIR     = ../atarilib/lib

ASM_FLAGS   = -v0 -f3 -l"$*.lst" -s"$*.sym" -I$(INC_DIR) -I$(LIB_DIR)

DEPS_ASM    = $(wildcard $(LIB_DIR)/*.asm) $(wildcard ./lib/*.asm) \
            $(wildcard bank?/*.asm) $(wildcard bank?/gfx/*.asm) \
            $(wildcard ./gfx/*.asm) \
            $(wildcard ./sys/*.asm)
DEPS_H      = $(wildcard $(INC_DIR)/*.h) $(wildcard ./include/*.h) \
            $(wildcard ./sys/*.h)

DEPS_M4     = $(wildcard ./lib/*.m4)
DEPS_S      = $(DEPS_M4:.m4=.s)

DEPS_MSP    = $(wildcard ./gen/*.sprite) $(wildcard ./bank?/gen/*.sprite)
DEPS_SP     = $(DEPS_MSP:.sprite=.sp)

DEPS_MPF    = $(wildcard ./gen/*.mpf) $(wildcard ./bank?/gen/*.mpf)
DEPS_PF     = $(DEPS_MPF:.mpf=.pf)

TARGET      = blackjack.bin

.PHONY: all
all: $(TARGET) 

$(TARGET): $(DEPS_S) $(DEPS_SP) $(DEPS_PF) $(DEPS_ASM) $(DEPS_H)

%.bin: %.asm
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"
	chmod ug+x $(TARGET)

%.sp: %.sprite $<
	echo $(PERL) $(MAKE_SPRITE) "$<" -o"$@"
	$(PERL) $(MAKE_SPRITE) "$<" -o"$@"

%.pf: %.mpf
	$(PERL) $(MAKE_PFIELD) "$<" > $@

%.s: %.m4 $<
	$(M4) "$<" > "$@"

%.bin: %.s $<
	$(ASM) "$<" $(ASM_FLAGS) -o"$@"

.PHONY: deploy
deploy: all
	cp *.bin *.lst *.sym /var/www/html/roms/
	chmod ugo+r /var/www/html/roms/*.bin
	@echo Copying to webroot

.PHONY: clean
clean:
	find . "(" -iname '*.bin' -or -iname '*.lst' -or -iname '*.sym' \
	-or -iname '*.pf' -or -iname '*.sp' -or -name "*.exe" ")" \
	-exec rm -fv {} +
