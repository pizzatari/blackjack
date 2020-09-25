; -----------------------------------------------------------------------------
    SEG bank0

    ORG BANK0_ORG, FILLER_CHAR
    RORG BANK0_RORG

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
; Kernel
CurrY       SET LocalVars+14
Gfx3        SET LocalVars+15
IdleTimer   SET LocalVars+16

; SetupChipsPot
ChipBits    SET LocalVars+14

; wide sprite rendering
DrawHeight SET LocalVars+6
;PalettePtr SET LocalVars+7


; -----------------------------------------------------------------------------
; Subroutines
; -----------------------------------------------------------------------------
Bank0_Reset
    nop     ; 3 bytes for bit instruction
    nop
    nop
    CLEAN_START
    cli

Bank0_Init
    jsr Bank0_InitGlobals
    jsr Bank0_ClearSprites

    CALL_BANK PROC_SOUNDQUEUECLEAR, 1, 0
    CALL_BANK PROC_ANIMATIONCLEAR, 3, 0

    lda #0
    sta IdleTimer

Bank0_FrameStart SUBROUTINE

    ; -------------------------------------------------------------------------
    ; vertical sync
    ; -------------------------------------------------------------------------
Bank0_VerticalSync
    VERTICAL_SYNC

    ; -------------------------------------------------------------------------
    ; vertical blank
    ; -------------------------------------------------------------------------
Bank0_VerticalBlank
    lda #TIME_VBLANK_TITLE
    sta TIM64T

    lda #0
    sta VBLANK
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2

    lda #COLOR_GREEN
    sta COLUP0
    sta COLUP1

    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank0_PositionSprites

    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank0_InitSpriteSpacing

    TIMER_WAIT
    sta WSYNC

    ; -------------------------------------------------------------------------
    ; Title kernel
    ; -------------------------------------------------------------------------
Bank0_TitleKernel
    SLEEP_LINES 30

    ; cycle the logo color
    lda FrameCtr
    and #%00111100
    lsr
    lsr
    clc
    adc #$e0
    sta TIM64T

    jsr Bank0_DrawTitleGraphic
    SLEEP_LINES 10

    lda #COLOR_ORANGE
    sta COLUP0
    sta COLUP1
    SLEEP_LINES 8

    SET_6_POINTERS SpritePtrs, Bank0_TitleEdition
    ldy #TITLE_EDITION_HEIGHT-1
    jsr Draw6Sprite56

    SLEEP_LINES 10

    lda #COLOR_WHITE
    sta COLUP0
    sta COLUP1
    SET_6_POINTERS SpritePtrs, Bank0_TitleCards
    ldy #TITLE_CARDS_HEIGHT-1
    jsr Draw6Sprite56

    sta WSYNC
    lda #0                      ; 2 (2)
    sta GRP0                    ; 3 (5)
    sta GRP1                    ; 3 (8)
    sta GRP0                    ; 3 (11)
    sta COLUP0                  ; 3 (14)
    sta COLUP1                  ; 3 (17)
    lda #<Bank0_MenuPalette     ; 2 (19)
    sta TempPtr                 ; 3 (22)
    lda #>Bank0_MenuPalette     ; 2 (24)
    sta TempPtr+1               ; 3 (27)

    SLEEP_LINES 5
    SET_6_POINTERS SpritePtrs, Bank0_TitleMenu

    ldy #TITLE_MENU_HEIGHT-1
    jsr DrawColor6Sprite56

    lda #COLOR_BLACK
    sta COLUBK
    sta COLUPF
    sta GRP0
    sta GRP1
    sta GRP0
    SLEEP_LINES 16

    lda #COLOR_VIOLET
    sta COLUP0
    sta COLUP1

    SET_6_PAGE_POINTERS SpritePtrs, Bank0_TitleCopyright
    ldy #TITLE_COPY_HEIGHT-1
    jsr Draw6Sprite56

    SET_6_PAGE_POINTERS SpritePtrs, Bank0_TitleName
    ldy #TITLE_NAME_HEIGHT-1
    jsr Draw6Sprite56

    lda #0
    sta VDELP0
    sta VDELP1
    sta GRP0
    sta GRP1
    sta GRP0

    SLEEP_LINES 10

    ; -------------------------------------------------------------------------
    ; overscan
    ; -------------------------------------------------------------------------
Bank0_Overscan
    lda #TIME_OVERSCAN
    sta TIM64T

    lda #%00000010
    sta VBLANK
    sta WSYNC
    inc FrameCtr

    ; read input
    jsr Bank0_ReadSwitches
    jsr Bank0_ReadJoystick

    ; check for idle timeout
    inc IdleTimer

    ; check for button press
    lda #JOY_FIRE_PACKED_MASK
    bit JoyRelease
    beq .Continue

    ; clear any joystick events
    lda #0
    sta JoyRelease

    lda #GS_NEW_GAME
    sta GameState

    JUMP_BANK PROC_BANK1_INIT, 1

.Continue

    TIMER_WAIT
    sta WSYNC

    jmp Bank0_FrameStart

; -----------------------------------------------------------------------------
; SUBROUTINES
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Desc:     Sets up global variables.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_InitGlobals SUBROUTINE
    lda #GS_START_STATE
    sta GameState
    lda SWCHA
    sta JoySWCHA
    lda SWCHB
    sta JoySWCHB
    lda INPT4
    sta JoyINPT4
    ldx #1
    stx RandNum
    stx FrameCtr
    IF TEST_RAND_ON == 2
    ldx #0
    ENDIF
    stx RandAlt
    lda #NUM_DECKS-1 & FLAGS_LATE_SURRENDER & FLAGS_HIT_SOFT17
    sta GameOpts
    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite pointers to blank sprites.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_ClearSprites SUBROUTINE
    ; assign to blank sprites
    lda #<Bank0_BlankSprite
    ldx #>Bank0_BlankSprite
    ldy #NUM_VISIBLE_CARDS*2-2
.Loop
    sta SpritePtrs,y
    stx SpritePtrs+1,y
    dey
    dey
    bpl .Loop
    rts

; -----------------------------------------------------------------------------
; Desc:     Draw multi-color graphics for the title scren.
; Inputs:   
; Ouputs:
; -----------------------------------------------------------------------------
    PAGE_BOUNDARY_SET
    include "lib/draw.asm"

Bank0_DrawTitleGraphic SUBROUTINE
    ldy #TITLE_LOGO_HEIGHT-1
    DRAW_RAINBOW_GRAPHIC Bank0_TitleSprite
    rts

#if 0
Bank0_DrawTitleEdition SUBROUTINE
    ldy #TITLE_EDITION_HEIGHT-1
    DRAW_RAINBOW_GRAPHIC Bank0_TitleEdition
    rts
#endif

    PAGE_BOUNDARY_CHECK "(1) Title kernels"

; -----------------------------------------------------------------------------
; Desc:     Sets sprite spacing gaps.
; Inputs:   Y register (sprite index)
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_InitSpriteSpacing SUBROUTINE
    lda Bank0_SpriteSize,y
    sta NUSIZ0
    sta NUSIZ1
    lda Bank0_SpriteDelay,y
    sta VDELP0
    sta VDELP1
    rts

    ALIGN 256, FILLER_CHAR
    PAGE_BOUNDARY_SET
    ; Bank tailored subroutines from lib\macros.asm
    SPRITE_POSITIONING 0
    PAGE_BOUNDARY_CHECK "Bank0 position"

    ; Bank tailored subroutines from lib\bankprocs.asm
    BANK_PROCS 0

; -----------------------------------------------------------------------------
; Desc:     Reads the console switches and assigns state variables.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_ReadSwitches SUBROUTINE
    lda SWCHB
    tax

    ; check for a reset 
    ora #~SWITCH_RESET_MASK
    cmp #$FF
    beq .CheckSelect
    jmp Bank0_Reset

.CheckSelect
    ; check if the switch changed
    txa
    eor JoySWCHB                        ; detect differences
    beq .Return

    ; check if the change was the select button
    and #SWITCH_SELECT_MASK             ; 0 = no change, 1 = changed
    beq .Return                         ; branch if no change
    ; check if it was pressed or released
    bit JoySWCHB                        ; 1 = released, 0 = pressed
    bne .Return                         ; branch on press event
    ora JoyRelease                      ; record release event
    sta JoyRelease

.Return
    stx JoySWCHB
    rts

; -----------------------------------------------------------------------------
; Desc:     Reads the joystick and generates joystick events. Events are
;           triggered on the joystick release (as opposed to the press).
; Inputs:
; Ouputs:   JoyRelease (joystick bitmask)
; Notes:
;
; Multiple sequential presses and releases are ignored (debouced).
; A button press is the change from 1 to 0. A button release is 0 to 1.
;
; JoySWCHA and JoyINPT4 are copies of the previous SWCHA and INPT4.
;
; JoyRelease stores the player's SWCHA and INPT4 bits.
;   Bit:  7-4:    SWCHA
;   Bit:  3-0:    INPT4
;
; Bit values are inverted:
;   1 = joystick/button released event
;   0 = no event
; -----------------------------------------------------------------------------
Bank0_ReadJoystick SUBROUTINE
    lda SWCHA
    tax                             ; save a copy: X = SWCHA
    eor JoySWCHA                    ; A = which bits have changed
    tay                             ; save a copy: Y = changed bits

    beq .CheckFire                  ; branch if no change
.CheckRight
    bpl .CheckLeft                  ; 0 = no change, 1 = changed
    lda #JOY0_RIGHT_MASK
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckLeft                  ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckLeft
    tya                             ; A = changed bits
    and #JOY0_LEFT_MASK             ; 0 = no change, 1 = changed
    beq .CheckDown                  ; branch if no change
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckDown                  ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckDown
    tya                             ; A = changed bits
    and #JOY0_DOWN_MASK             ; 0 = no change, 1 = changed
    beq .CheckUp                    ; branch if no change
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckUp                    ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckUp
    tya                             ; A = changed bits
    and #JOY0_UP_MASK               ; 0 = no change, 1 = changed
    beq .CheckFire                  ; branch if no change
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckFire                  ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckFire
    lda INPT4
    tay                             ; save a copy
    eor JoyINPT4                    ; A = changed bits
    and #JOY_FIRE_MASK              ; 0 = no change, 1 = changed
    bpl .Return                     ; branch if no change
    bit JoyINPT4                    ; 1 = released, 0 = pressed
    bne .Return                     ; branch if this is a press event
    lda #JOY_FIRE_PACKED_MASK
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.Return
    stx JoySWCHA
    sty JoyINPT4
    rts

; -----------------------------------------------------------------------------
; Desc:     Implements the game screen kernel.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_BettingKernel SUBROUTINE
    lda #7*76/64
    sta TIM64T
    TIMER_WAIT

    ; message prompt section --------------------------------------------------
    ldy #MSG_BAR_IDX
    jsr Bank0_SetColors
    
    lda #MSG_ROW_HEIGHT*76/64
    sta TIM64T

    jsr Bank0_SetupOptionsPrompt           ; "Options"
    ldy #MESSAGE_TEXT_HEIGHT-1
    jsr Bank0_DrawMessageBar

    jsr Bank0_SetupOptionsDash
    ldy #DASHOPTS_HEIGHT-1
    jsr Bank0_DrawMessageBar

    TIMER_WAIT

    ; tableau section (upper) -------------------------------------------------
    ldy #SPRITE_CARDS_IDX
    jsr Bank0_PositionSprites

    ; hide MOVE line
    lda #$0
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2

    ldy #COLOR_CHIPS_IDX
    jsr Bank0_SetColors
    sta WSYNC
    jsr Bank0_SetPlayfield

    ldy #SPRITE_CARDS_IDX
    jsr Bank0_SetSpriteOptions
    jsr Bank0_ClearSprites

    SLEEP_LINES 33

    ; casino chips section ----------------------------------------------------
    TIMED_JSR Bank0_SetupChipsPot, TIME_CHIPS_POT, TIM8T
    ldy #CHIPS_HEIGHT-1
    jsr Bank0_Draw6Sprites

    SLEEP_LINES 8

    ;------
    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank0_SetSpriteOptions
    jsr Bank0_PositionSprites

    lda #$0                 ; 2 (2)
    sta COLUBK              ; 3 (5)
    sta PF0                 ; 3 (8)
    sta PF1                 ; 3 (11)
    sta PF2                 ; 3 (14)

    ldy #MSG_BAR_IDX
    jsr Bank0_SetColors

    jsr Bank0_SetupBettingPrompt2      ; prompt: "Bet!"
    ldy #MESSAGE_TEXT_HEIGHT-1
    jsr Bank0_DrawMessageBar
    ;------

    ; current bet section -----------------------------------------------------
    jsr Bank0_SetupBettingBar

    ldy #SPRITE_BET_IDX
    jsr Bank0_SetSpriteOptions
    jsr Bank0_PositionSprites

    ; hide MOVE line
    lda #$0                 ; 2 (2)
    sta COLUBK              ; 3 (5)

    ldy #POPUP_BAR_IDX
    ;ldy #MSG_BAR_IDX
    jsr Bank0_SetColors
    lda #$0e
    sta COLUP0
    sta COLUP1
    ldy #STATUS_TEXT_HEIGHT
    sta WSYNC
    sta WSYNC
    jsr Bank0_Draw48PixelSprite
    sta WSYNC

    ldy #SPRITE_CARDS_IDX
    jsr Bank0_PositionSprites

    ; hide MOVE line
    lda #$0                 ; 2 (2)
    sta PF0                 ; 3 (8)
    sta PF1                 ; 3 (11)
    sta PF2                 ; 3 (14)
    sta COLUBK              ; 3 (5)

    ; tableau section (lower) -------------------------------------------------
    ldy #COLOR_CHIPS_IDX
    jsr Bank0_SetColors
    sta WSYNC
    jsr Bank0_SetPlayfield
    sta WSYNC
    sta WSYNC
    sta WSYNC

    ldy #SPRITE_CARDS_IDX
    jsr Bank0_SetSpriteOptions

    SLEEP_LINES 28

    ; player's chip section ---------------------------------------------------
    jsr Bank0_ClearGraphicsOpts
    lda #CHIP_COLOR
    sta COLUP0
    sta COLUP1

    TIMED_JSR Bank0_SetupPlayerChips, TIME_CHIP_MENU_SETUP, TIM8T
    ldy #CHIPS_HEIGHT-1
    jsr Bank0_Draw6Sprites

    ; chip denomination section -----------------------------------------------
    sta WSYNC
    ldy #TIMES_HEIGHT-1
    DRAW_2_GRAPHIC Bank0_TimesSprite, Bank0_TimesSprite
    CLEAR_GRAPHICS

    sta WSYNC
    ldy #DENOMS_HEIGHT-1
    DRAW_6_GRAPHIC Bank0_DenomSprite
    CLEAR_GRAPHICS

    ; status bar section -----------------------------------------------------
    TIMED_JSR Bank0_SetupStatusBar, TIME_STATUS_BAR, TIM8T

    ldy #SPRITE_STATUS_IDX
    jsr Bank0_SetSpriteOptions
    jsr Bank0_PositionSprites

    ; hide MOVE line
    lda #$0                 ; 2 (2)
    sta PF0                 ; 3 (8)
    sta PF1                 ; 3 (11)
    sta PF2                 ; 3 (14)
    sta COLUBK              ; 3 (5)

    ldy #MSG_BAR_IDX
    jsr Bank0_SetColors
    ldy #STATUS_TEXT_HEIGHT
    jsr Bank0_Draw48PixelSprite

    ; cleanup -----------------------------------------------------------------
    lda #0
    sta WSYNC
    sta COLUBK
    sta PF0
    sta PF1
    jsr Bank0_ClearGraphicsOpts

    ; saving 2 bytes of stack by jumping
    JUMP_BANK PROC_BANK2_OVERSCAN0, 2

; -----------------------------------------------------------------------------
; Desc:     Draws a big sprite.
; Notes:    Placing here because this routine must not cross a page boundary.
; Inputs:   X register (the sprite's height)
; Ouputs:
; -----------------------------------------------------------------------------
; VDEL sequence
;           Delay0  Live0   Delay1  Live1   On Screen
;------------------------------------------------------ begin loop
; GRP0:     0-1
; GRP1:     0-1'    0-1'    1-2 
; GRP0:     0-3     0-1     1-2'    1-2'
; ...
;                                           0-1
; GRP1:     0-3'    0-3'    1-4     1-2     1-2
; GRP0:     0-5     0-3     1-4'    1-4'    0-3
; GRP1:     0-5'    0-5'    1-6     1-4     1-4
; GRP0:     0-7     0-5     1-6     1-6     0-5
;                                           1-6
;------------------------------------------------------ begin loop
; GRP0:     0-8     0-7     1-6'    1-6'
; GRP1:     0-8'    0-8'    1-9     1-6
; GRP0:     0-10    0-8     1-9'    1-9'
; ...
;                                           0-8
; GRP1:     0-10'   0-10'   1-11    1-9     1-9
; GRP0:     0-12    0-10    1-11'   1-11'   0-10
; GRP1:     0-12'   0-12'   1-13    1-11    1-11
; GRP0:     0-14    0-12    1-13    1-13    0-12
;

    ;ALIGN 256, FILLER_CHAR
    PAGE_BOUNDARY_SET

; -----------------------------------------------------------------------------
; Desc:     Draws a multi-color message bar.
; Inputs:        
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_DrawMessageBar SUBROUTINE
    DRAW_48_COLOR_SPRITE SpritePtrs, Bank0_MessagePalette
    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
    rts

; -----------------------------------------------------------------------------
; Desc:     Draw a 48 pixel wide sprite.
; Inputs:   Y register (sprite height - 1)
;           SpritePtrs (array of 6 words)
; Outputs:
; Notes:    P0 position=55; P1 position=63
; -----------------------------------------------------------------------------
Bank0_Draw48PixelSprite SUBROUTINE
    DRAW_48_SPRITE SpritePtrs
    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
    rts

; -----------------------------------------------------------------------------
; Desc:     Draws 6 medium sprites in a row.
; Inputs:   Y register (sprite height - 1)
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_Draw6Sprites SUBROUTINE
    DRAW_6_SPRITES SpritePtrs
    rts

    PAGE_BOUNDARY_CHECK "(3) Kernels"

; -----------------------------------------------------------------------------
; Desc:     Performs game IO during blank.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_GameIO SUBROUTINE
    jsr Bank0_ReadSwitches
    jsr Bank0_ReadJoystick
    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the sprites to the options prompt message.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetupOptionsPrompt SUBROUTINE
    lda #<Bank0_BlankSprite
    sta SpritePtrs
    sta SpritePtrs+10
    lda #>Bank0_BlankSprite
    sta SpritePtrs+1
    sta SpritePtrs+11

    lda #<Bank0_OptionsStr1
    sta SpritePtrs+2

    lda #<Bank0_OptionsStr2
    sta SpritePtrs+4

    lda #<Bank0_OptionsStr3
    sta SpritePtrs+6

    lda #<Bank0_OptionsStr4
    sta SpritePtrs+8

    lda #>Bank0_OptionsStr1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9

    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the sprites to the options prompt message.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetupOptionsDash SUBROUTINE
    lda #<Bank0_BlankSprite
    sta SpritePtrs+2
    sta SpritePtrs+6
    sta SpritePtrs+10
    lda #>Bank0_BlankSprite
    sta SpritePtrs+3
    sta SpritePtrs+7
    sta SpritePtrs+11

    ldx #>Bank0_Opts

    lda #<Bank0_OptsEarlySurr
    sta SpritePtrs
    stx SpritePtrs+1

    lda #<Bank0_OptsHard17
    sta SpritePtrs+4
    stx SpritePtrs+5

    lda #FLAGS_LATE_SURRENDER
    bit GameOpts
    beq .CheckSoft17

    lda #<Bank0_OptsLateSurr
    sta SpritePtrs
    stx SpritePtrs+1

.CheckSoft17
    lda #FLAGS_HIT_SOFT17
    bit GameOpts
    beq .NumDecks

    lda #<Bank0_OptsSoft17
    sta SpritePtrs+4
    stx SpritePtrs+5

.NumDecks
    lda #NUM_DECKS_MASK
    and GameOpts

    tay
    clc

    lda Bank0_Multiply6,y
    adc #<Bank0_Opts
    sta SpritePtrs+8
    stx SpritePtrs+9
    
    rts

; -----------------------------------------------------------------------------
; Desc:     Assign sprite pointers to betting prompt.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetupBettingPrompt2 SUBROUTINE
    ldx #>Bank0_BettingStr0
    stx SpritePtrs + 1
    stx SpritePtrs + 11

    ldx #>Bank0_BettingStr1
    stx SpritePtrs + 3
    stx SpritePtrs + 5
    stx SpritePtrs + 7
    stx SpritePtrs + 9

    lda #<Bank0_BettingStr0
    sta SpritePtrs
    lda #<Bank0_BettingStr1
    sta SpritePtrs + 2
    lda #<Bank0_BettingStr2
    sta SpritePtrs + 4
    lda #<Bank0_BettingStr3
    sta SpritePtrs + 6
    lda #<Bank0_BettingStr4
    sta SpritePtrs + 8
    lda #<Bank0_BettingStr5
    sta SpritePtrs + 10
    rts

; -----------------------------------------------------------------------------
; Desc:     Assigns the chip score sprites.
; Inputs:   SpritePtrs, Player Index
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetupStatusBar SUBROUTINE
    ;SET_CHIP_SCORE SpritePtrs, PLAYER1_IDX
    ldx #0;
.Loop
    ; left digit
    lda PlayerChips+[PLAYER1_IDX*NUM_CHIP_BYTES],x
    lsr
    lsr
    lsr
    lsr
    tay
    lda Bank0_Multiply6,y
    ldy Bank0_Multiply4,x
    clc
    adc #<Bank0_Digit0
    sta SpritePtrs,y
    lda #>Bank0_Digit0
    adc #0
    sta SpritePtrs+1,y

    ; right digit
    lda PlayerChips+[PLAYER1_IDX*NUM_CHIP_BYTES],x
    and #$0F
    tay
    lda Bank0_Multiply6,y
    ldy Bank0_Multiply4,x
    clc
    adc #<Bank0_Digit0
    sta SpritePtrs+2,y
    lda #>Bank0_Digit0
    adc #0
    sta SpritePtrs+3,y

    inx
    cpx #NUM_CHIP_BYTES
    bne .Loop
    rts

; -----------------------------------------------------------------------------
; Desc:     Assigns the bet sprites as a 4 digit number.
; Inputs:   SpritePtrs, Current Bet (2 bytes)
; Outputs:
; -----------------------------------------------------------------------------
Bank0_SetupBettingBar SUBROUTINE
    lda #<Bank0_Dollar
    sta SpritePtrs
    lda #>Bank0_Dollar
    sta SpritePtrs+1

    lda #<Bank0_BlankSprite
    sta SpritePtrs+10
    lda #>Bank0_BlankSprite
    sta SpritePtrs+11

    ldx #0;
.Loop
    ; left digit
    lda CurrBet,x
    lsr
    lsr
    lsr
    lsr
    tay
    lda Bank0_Multiply6,y
    ldy Bank0_Multiply4,x
    clc
    adc #<Bank0_Digit0
    sta SpritePtrs+2,y
    lda #>Bank0_Digit0
    adc #0
    sta SpritePtrs+3,y

    ; right digit
    lda CurrBet,x
    and #$0F
    tay
    lda Bank0_Multiply6,y
    ldy Bank0_Multiply4,x
    clc
    adc #<Bank0_Digit0
    sta SpritePtrs+4,y
    lda #>Bank0_Digit0
    adc #0
    sta SpritePtrs+5,y

    inx
    cpx #NUM_BET_BYTES
    bne .Loop
    rts

; -----------------------------------------------------------------------------
; Desc:     Setup top row of chip sprites representing the pot.
; Inputs:        
; Ouputs:
; -----------------------------------------------------------------------------
#if 0
    ds.b 7, <Bank0_ChipBlank

    ; 0   1    2    3    4    5    6    7
    ; 0,  100, 100, 100, 100, 100, 100, 100
Bank0_Chips1000
    ds.b 1, <Bank0_ChipBlank
    ds.b 7, <Bank0_Chip6Sprite

Bank0_Chips100
Bank0_Chips10
Bank0_Chips1

Bank0_SetupChipsPot SUBROUTINE
    sed

    ; CurrBet
    ; 00 09
    ; 1000: 100
    ;  100: 100
    ;   10: 10, 50
    
    
    ; 
    lda CurrBet+1
    and #$07
    tax
    ldy #NUM_SPRITES-1
.Loop1000
    lda Bank0_Chips1000,x
    dex
    dey
    bmi .Loop1000

    ; initialize high byte
    lda #>Bank0_ChipBlank
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11

    cld
    rts
#endif

#if 0
Bank0_SetupChipsPot SUBROUTINE
    ; 12 34
    sed

    lda CurrBet
    and #$f0
    beq .Do100

    ldx #NUM_SPRITES*2-1
    ldy #<Bank0_ChipBlank
.Loop1000
    clc
    sbc #$10
    beq .Do100
    sty SpritePtrs,x
    dex
    dex
    bne .Loop1000
    

.Do100
    lda CurrBet
    and #$0f
    beq .Do10

.Do10
    lda CurrBet+1
    and #$f0
    beq .Do1

.Do1
    lda CurrBet+1
    and #$0f
    beq .Continue

.Continue

    cld

    ; initialize high byte
    lda #>Bank0_Chips
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11

    ; bits:
    ;    7   6   5   4   3   2   1   0  : bit
    ;    -   -   6   5   4   3   2   1  : sprite position
    ;    -   - 100  50  25  10   5   1  : chip denomination

    rts
#endif

#if 1
; original: working
Bank0_SetupChipsPot SUBROUTINE
    clc
    sed

    ldy #0                        ; sprite selector

    lda CurrBet
    cmp #0
    beq .Next50
    ldx #<Bank0_Chip5
    stx SpritePtrs,y
    ldx #>Bank0_Chip5
    stx SpritePtrs+1,y
    iny
    iny

.Next50
    lda CurrBet+1
    cmp #$50
    bcc .Next25
    ldx #<Bank0_Chip4
    stx SpritePtrs,y
    ldx #>Bank0_Chip4
    stx SpritePtrs+1,y
    iny
    iny
    sbc #$50

.Next25
    cmp #$25
    bcc .Next10
    ldx #<Bank0_Chip3
    stx SpritePtrs,y
    ldx #>Bank0_Chip3
    stx SpritePtrs+1,y
    iny
    iny
    sbc #$25

.Next10
    cmp #$10
    bcc .Next5
    ldx #<Bank0_Chip2
    stx SpritePtrs,y
    ldx #>Bank0_Chip2
    stx SpritePtrs+1,y
    iny
    iny
    sbc #$10
    cmp #$10
    bcc .Next5
    sbc #$10

.Next5
    cmp #$05
    bcc .Next1
    ldx #<Bank0_Chip1
    stx SpritePtrs,y
    ldx #>Bank0_Chip1
    stx SpritePtrs+1,y
    iny
    iny
    sbc #$05

.Next1
    cmp #1
    bcc .Done
    ldx #<Bank0_Chip0
    stx SpritePtrs,y
    ldx #>Bank0_Chip0
    stx SpritePtrs+1,y
    iny
    iny

.Done
    lda #<Bank0_BlankSprite
    ldx #>Bank0_BlankSprite

.Blanks
    cpy #NUM_SPRITES*2
    bcs .Return
    sta SpritePtrs,y
    stx SpritePtrs+1,y
    iny
    iny
    jmp .Blanks

.Return
    cld

    rts
#endif

; -----------------------------------------------------------------------------
; Desc:     Setup bottom chip menu row of sprites.
; Inputs:        
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetupPlayerChips SUBROUTINE
    ; assign pointers to chip sprite graphics
    lda #>Bank0_Chips
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11

    lda #<Bank0_Chip0
    sta SpritePtrs
    lda #<Bank0_Chip1
    sta SpritePtrs+2
    lda #<Bank0_Chip2
    sta SpritePtrs+4
    lda #<Bank0_Chip3
    sta SpritePtrs+6
    lda #<Bank0_Chip4
    sta SpritePtrs+8
    lda #<Bank0_Chip5
    sta SpritePtrs+10

    ; don't flicker the selection on specific frames
    lda #%00011000
    bit FrameCtr
    bne .Return

    ; only flicker when gamestate wants it
    ldx GameState
    lda Bank0_GameStateFlags,x
    and #GS_FLICKER_FLAG
    beq .Return

    ; get currently selected bet
    jsr Bank0_GetBetMenu

    ; blank the currently selected sprite
    asl                         ; A = A * 2
    tay
    lda #<Bank0_BlankSprite
    sta SpritePtrs,y
    lda #>Bank0_BlankSprite
    sta SpritePtrs+1,y
.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite pointers to the same sprite character given by the
;           16 bit address.
; Inputs:   Y register (SPRITE_GRAPHICS_IDX, SPRITE_CARDS_IDX, SPRITE_BET_IDX, SPRITE_STATUS_IDX)
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetSpriteOptions SUBROUTINE
    lda Bank0_SpriteSize,y
    sta NUSIZ0
    sta NUSIZ1
    lda Bank0_SpriteDelay,y
    sta VDELP0
    sta VDELP1
    rts

; -----------------------------------------------------------------------------
; Desc:     Horizontally positions two sprites at close distance.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_ClearGraphicsOpts SUBROUTINE
    lda #0
    sta VDELP0
    sta VDELP1
    sta GRP0
    sta GRP1
    rts

; indicates which are set to blank sprites
; Bit: 0-5  sprites 1 through 6
; Bit: 6-7  unused
Bank0_ResultMessageBlanks
    dc.b 0
    dc.b 0                          ; FLAGS_LOST
    dc.b %00100001                  ; FLAGS_BUST
    dc.b %00100000                  ; FLAGS_21
    dc.b %00100001                  ; FLAGS_PUSH
    dc.b %00100000                  ; FLAGS_WIN
    dc.b 0                          ; FLAGS_BLACKJACK

; indicates which are set to blank sprites
; Bit: 0-5  sprites 1 through 6
; Bit: 6-7  unused
Bank0_PromptMessageBlanks
    dc.b 0
    dc.b %00100001
    dc.b 0
    dc.b 0
    dc.b 0
    dc.b %00100001
    dc.b 0

; Indexed by game state values.
; bit 7:        show betting row
; bit 6:        show dashboard
; bit 5:        show dealer's hole card
; bit 4:        show dealer's score
; bit 3:        flicker the currently selected object
; bit 0,1,2:    index into PromptMessages table
Bank0_GameStateFlags
    dc.b #0                 ; GS_TITLE_SCREEN
    dc.b #%10101001         ; GS_NEW_GAME
    dc.b #%10001001         ; GS_PLAYER_BET
    dc.b #%10001001         ; GS_PLAYER_BET_DOWN
    dc.b #%10001001         ; GS_PLAYER_BET_UP
    dc.b #%01000000         ; GS_OPEN_DEAL1
    dc.b #%01000000         ; GS_OPEN_DEAL2
    dc.b #%01000000         ; GS_OPEN_DEAL3
    dc.b #%01000000         ; GS_OPEN_DEAL4
    dc.b #%01000000         ; GS_OPEN_DEAL5
    dc.b #%01000010         ; GS_DEALER_SET_FLAGS
    dc.b #%01000010         ; GS_PLAYER_SET_FLAGS
    dc.b #%01000010         ; GS_PLAYER_TURN
    dc.b #%01000010         ; GS_PLAYER_PRE_HIT
    dc.b #%01000010         ; GS_PLAYER_HIT
    dc.b #%01000010         ; GS_PLAYER_POST_HIT
    dc.b #%01000011         ; GS_PLAYER_SURRENDER
    dc.b #%01000100         ; GS_PLAYER_DOUBLEDOWN
    dc.b #%01000101         ; GS_PLAYER_SPLIT
    dc.b #%01000101         ; GS_PLAYER_SPLIT_DEAL
    dc.b #%01000110         ; GS_PLAYER_INSURANCE
    dc.b #%00110000         ; GS_PLAYER_BLACKJACK
    dc.b #%00110000         ; GS_PLAYER_WIN
    dc.b #%00110000         ; GS_PLAYER_PUSH
    dc.b #0                 ; GS_PLAYER_HAND_OVER
    dc.b #%00110000         ; GS_DEALER_TURN
    dc.b #%00110000         ; GS_DEALER_PRE_HIT
    dc.b #%00110000         ; GS_DEALER_HIT
    dc.b #%00110000         ; GS_DEALER_POST_HIT
    dc.b #%00110000         ; GS_DEALER_HAND_OVER
    dc.b #%00110000         ; GS_GAME_OVER
    dc.b #%00110000         ; GS_INTERMISSION

Bank0_PlayMenuSprite
    dc.b <HelpHit           ; DASH_HIT_IDX
    dc.b <HelpDoubledown    ; DASH_DOUBLEDOWN_IDX
    dc.b <HelpSurrender     ; DASH_SURRENDER_IDX
    dc.b <HelpInsurance     ; DASH_INSURANCE_IDX
    dc.b <HelpSplit         ; DASH_SPLIT_IDX
Bank0_CancelMenuSprite
    dc.b <HelpCancel        ; DASH_HIT_IDX
    dc.b <HelpDoubledown    ; DASH_DOUBLEDOWN_IDX
    dc.b <HelpSurrender     ; DASH_SURRENDER_IDX
    dc.b <HelpInsurance     ; DASH_INSURANCE_IDX
    dc.b <HelpSplit         ; DASH_SPLIT_IDX

; -----------------------------------------------------------------------------
; Shared procedures
; -----------------------------------------------------------------------------
PROC_BANK1_INIT             = 0
PROC_ANIMATIONCLEAR         = 1
PROC_SOUNDQUEUECLEAR        = 2
PROC_BANK2_OVERSCAN0        = 3

Bank0_ProcTableLo
    dc.b <Bank1_Init
    dc.b <AnimationClear
    dc.b <SoundQueueClear
    dc.b <Bank2_Overscan

Bank0_ProcTableHi
    dc.b >Bank1_Init
    dc.b >AnimationClear
    dc.b >SoundQueueClear
    dc.b >Bank2_Overscan

    PAGE_BOUNDARY_SET
Bank0_MessagePalette
    dc.b $3e, $3c, $ee, $ee, $ee, $ec, $ea
    dc.b $2e, $3e, $3c, $3a, $fe, $ee, $1e, $de
Bank0_MenuPalette
    dc.b $00, $06, $08, $0a, $0c, $0e
    dc.b $0c, $0a, $08, $06, $04, $02
    PAGE_BOUNDARY_SET "(1) Sprite data"

; -----------------------------------------------------------------------------
; Graphics
; -----------------------------------------------------------------------------
    ;ALIGN 256, FILLER_CHAR

    PAGE_BOUNDARY_SET
Bank0_BlankSprite
    ds.b 12, 0
    include "bank0/gfx/digits.asm"
    include "bank0/gfx/betting-menu.asm"
    PAGE_BOUNDARY_SET "(2) Sprite data"

    include "bank0/arithmetic.asm"

    ; Bank tailored data from lib\macros.asm
    SPRITE_OPTIONS 0
    SPRITE_COLORS 0

    PAGE_BYTES_REMAINING

; -----------------------------------------------------------------------------
    ORG BANK0_ORG + $d00
    RORG BANK0_RORG + $d00

    include "bank0/gen/title-logo-48.sp"

    ORG BANK0_ORG + $e00
    RORG BANK0_RORG + $e00

Bank0_GraphicBlank
    ds.b 19, 0              

    PAGE_BOUNDARY_SET
    include "bank0/gen/title-copy-48.sp"
    include "bank0/gen/title-copy.sp"
    include "bank0/gen/title-name.sp"

    PAGE_BOUNDARY_CHECK "Bank0 Copyright"
    PAGE_BYTES_REMAINING

    ALIGN 256, FILLER_CHAR
    PAGE_BOUNDARY_SET
    include "bank0/gen/title-menu-48.sp"
    include "bank0/gen/prompts-48.sp"
    PAGE_BOUNDARY_CHECK "Bank0 Menu"
    PAGE_BYTES_REMAINING

    ; horizontal positioning data
    ORG BANK0_ORG + $ff6-BS_SIZEOF-$f
    RORG BANK0_RORG + $ff6-BS_SIZEOF-$f

    HORIZ_POS_TABLE 0

    ORG BANK0_ORG + $ff6-BS_SIZEOF
    RORG BANK0_RORG + $ff6-BS_SIZEOF

    BANKSWITCH_ROUTINES 0, BANK0_HOTSPOT

    ; bank switch hotspots
    ORG BANK0_ORG + $ff6
    RORG BANK0_RORG + $ff6
    ds.b 4, 0

    ; interrupts
    ORG BANK0_ORG + $ffa
    RORG BANK0_RORG + $ffa

Bank0_Interrupts
    .word Bank0_Reset       ; NMI    $*ffa, $*ffb
    .word Bank0_Reset       ; RESET  $*ffc, $*ffd
    .word Bank0_Reset       ; IRQ    $*ffe, $*fff
