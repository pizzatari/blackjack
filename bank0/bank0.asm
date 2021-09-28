; -----------------------------------------------------------------------------
    SEG Bank0

    ORG BANK0_ORG, FILLER_CHAR
    RORG BANK0_RORG

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
; Kernel
PalIdx1     SET LocalVars
PalIdx2     SET LocalVars+1
IntPtr		SET LocalVars+2

; -----------------------------------------------------------------------------
; Subroutines
; -----------------------------------------------------------------------------
Bank0_Reset
    nop     ; 3 byte alignment for bankswitching
    nop
    nop
    CLEAN_START
    cli

Bank0_Init
    jsr Bank0_InitGlobals
    jsr Bank0_ClearSprites

    ;CALL_BANK PROC_SOUNDQUEUECLEAR, 1, 0
    ;CALL_BANK PROC_ANIMATIONCLEAR, 3, 0
    CALL_BANK SoundClear
    CALL_BANK AnimationClear

Bank0_FrameStart SUBROUTINE
    VERTICAL_SYNC
    jsr Bank0_VerticalBlank
    jsr Bank0_TitleKernel
    jsr Bank0_Overscan
    jmp Bank0_FrameStart

Bank0_VerticalBlank SUBROUTINE
    lda #TIME_VBLANK_TITLE
    sta TIM64T

    lda #0
    sta WSYNC
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
    jsr Bank0_UpdateHighlights

    TIMER_WAIT

    lda #0
    sta WSYNC
    sta VBLANK
    rts
    
Bank0_TitleKernel SUBROUTINE
    SLEEP_LINES 25
    jsr Bank0_TitleLogoKernel

    SLEEP_LINES 12
    jsr Bank0_TitleCardKernel

    SLEEP_LINES 12
    jsr Bank0_TitleEditionKernel

    SLEEP_LINES 5
    jsr Bank0_TitleMenuKernel

    SLEEP_LINES 3
    jsr Bank0_TitleCopyrightKernel

    SLEEP_LINES 9
    rts

Bank0_TitleLogoKernel SUBROUTINE
    ; cycle the logo color
    lda FrameCtr
    and #%00111100
    lsr
    lsr
    clc
    adc #$e0
    sta TIM64T
    jsr Bank0_DrawTitleGraphic
    lda #0
    sta WSYNC
    sta PF0
    sta PF1
    sta PF2
    sta COLUP0
    sta COLUP1
    sta COLUPF
    rts

Bank0_TitleCardKernel SUBROUTINE
    lda #<Bank0_CardPalette     ; 2 (19)
    sta TempPtr                 ; 3 (22)
    lda #>Bank0_CardPalette     ; 2 (24)
    sta TempPtr+1               ; 3 (27)

    SET_6_POINTERS SpritePtrs, Bank0_TitleCards

    ldx #$ff
    stx WSYNC
    stx PF0
    stx PF1
    stx PF2

    ldx #COLOR_BLACK
    ldy #TITLE_CARDS_HEIGHT-1
    jsr DrawColor6Sprite56

    lda #0
    sta WSYNC
    sta PF0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    sta GRP0
    sta COLUPF
    sta COLUP0
    sta COLUP1
    rts

Bank0_TitleEditionKernel SUBROUTINE
    SET_6_PAGE_POINTERS SpritePtrs, Bank0_TitleEdition

    lda #>Bank0_EditionPalette  ; 2 (2)
    sta TempPtr+1               ; 3 (5)
    lda PalIdx1                 ; 3 (8)
    clc                         ; 2 (12)
    adc #<Bank0_EditionPalette  ; 2 (14)
    sta TempPtr                 ; 3 (17)

    lda #$ff                    ; 2 (19)
    sta WSYNC
    sta PF0                     ; 3 (3)
    sta PF1                     ; 3 (3)
    sta PF2                     ; 3 (6)

    ldx #COLOR_BLACK            ; 2 (8)
    ldy #TITLE_EDITION_HEIGHT-1 ; 2 (10)
    jsr DrawColor6Sprite56

    ; A register will be 0
    sta COLUBK                  ; 3 (3)
    sta WSYNC
    sta GRP0                    ; 3 (5)
    sta GRP1                    ; 3 (8)
    sta GRP0                    ; 3 (11)
    sta COLUP0                  ; 3 (14)
    sta COLUP1                  ; 3 (17)
    rts

Bank0_TitleMenuKernel SUBROUTINE
    lda #<Bank0_MenuPalette     ; 2 (19)
    sta TempPtr                 ; 3 (22)
    lda #>Bank0_MenuPalette     ; 2 (24)
    sta TempPtr+1               ; 3 (27)

    SET_6_LOW_POINTERS SpritePtrs, Bank0_TitleMenu

    ldx #COLOR_BLACK
    ldy #TITLE_MENU_HEIGHT-1
    jsr DrawColor6Sprite56

    ldx #COLOR_BLACK
    stx COLUBK
    stx COLUPF
    stx GRP0
    stx GRP1
    stx GRP0

    sta WSYNC
    lda #0                      ; 2 (2)
    sta GRP0                    ; 3 (5)
    sta GRP1                    ; 3 (8)
    sta GRP0                    ; 3 (11)
    sta COLUP0                  ; 3 (14)
    sta COLUP1                  ; 3 (17)
    rts

Bank0_TitleCopyrightKernel SUBROUTINE
    lda #>Bank0_CopyPalette     ; 2 (19)
    sta TempPtr+1               ; 3 (22)
    lda #<Bank0_CopyPalette     ; 2 (24)
    clc                         ; 2 (26)
    adc PalIdx2                 ; 3 (29)
    sta TempPtr                 ; 3 (32)

    SET_6_LOW_POINTERS SpritePtrs, Bank0_TitleCopyright

    ldx #COLOR_BLACK            ; 2 (8)
    ldy #TITLE_COPY_HEIGHT-1    ; 2 (2)
    jsr DrawColor6Sprite56

    ; register A is 0 here
    sta COLUBK                  ; 3 (3)
    sta WSYNC
    sta GRP0                    ; 3 (3)
    sta GRP1                    ; 3 (6)
    sta GRP0                    ; 3 (9)
    sta COLUP0                  ; 3 (12)
    sta COLUP1                  ; 3 (15)
    sta VDELP0                  ; 3 (18)
    sta VDELP1                  ; 3 (21)
    rts

Bank0_Overscan SUBROUTINE
    lda #TIME_OVERSCAN
    sta TIM64T

    lda #%00000010
    sta VBLANK
    sta WSYNC
    inc FrameCtr

    ; check for button press
	jsr Bank0_ReadJoystick
    lda #JOY_REL_FIRE
    bit JoyRelease
    bne .JumpToBank

    jsr Bank0_ReadSwitches
    sta WSYNC
    TIMER_WAIT
    rts

.JumpToBank
    pla
    pla
    JUMP_BANK Bank1_LandingInit

Bank0_BettingKernel SUBROUTINE
	; 7 lines of vertical blank are reserved for additional setup
    lda #7*76/64
    sta TIM64T

    ldy #MSG_BAR_IDX
    jsr Bank0_SetColors2
    jsr Bank0_SetupOptionsPrompt           ; "Options"

    SET_POINTER IntPtr, CurrBet

	; 8 lines of vertical blank are reserved for additional setup
    TIMER_WAIT

    lda #0
	sta WSYNC
    sta VBLANK
    
    lda #MSG_ROW_HEIGHT*76/64
    sta TIM64T

    ; message prompt section --------------------------------------------------
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
    lda #0
	sta COLUPF
	sta COLUBK
	sta CTRLPF

    ldy #COLOR_CHIPS_IDX
    sta WSYNC
    jsr Bank0_SetColors2
	sta WSYNC
    jsr Bank0_SetTableau

    ldy #SPRITE_CARDS_IDX
    jsr Bank0_SetSpriteOptions
    jsr Bank0_ClearSprites

    SLEEP_LINES 28

    ; casino chips section ----------------------------------------------------
    lda CurrBet
    sta TempInt
    lda CurrBet+1
    sta TempInt+1
    lda CurrBet+2
    sta TempInt+2

    TIMED_JSR Bank0_SetupChipSprites, TIME_CHIPS_POT, TIM8T

    lda #<Bank0_ChipPalette
    sta TempPtr
    lda #>Bank0_ChipPalette
    sta TempPtr+1
    ldy #CHIPS_HEIGHT-1
    jsr Bank0_Draw6ColorSprites

    Sta WSYNC

    ; bet selection section ---------------------------------------------------

	; top half (red)
    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank0_SetSpriteOptions
    jsr Bank0_PositionSprites

    lda #0                  ; 2 (11)
    sta COLUBK              ; 3 (14)
	sta COLUPF				; 3 (17)

    ldy #MSG_BAR_IDX
	sta WSYNC
    jsr Bank0_SetColors2

    jsr Bank0_SetupBettingPrompt    ; prompt: "Place Your Bet"
    ldy #MESSAGE_TEXT_HEIGHT-1
    jsr Bank0_DrawMessageBar

	; bottom half (grey)
    jsr Bank0_SetupInteger

    ldy #SPRITE_BET_IDX
    jsr Bank0_SetSpriteOptions
    jsr Bank0_PositionSprites

    ; hide MOVE line
    lda #$0                 ; 2 (2)
    sta COLUBK              ; 3 (5)
	sta PF0					; 3 (3)
	sta PF1					; 3 (3)
	sta PF2					; 3 (3)

    ldy #POPUP_BAR_IDX
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
    sta COLUBK              ; 3 (5)
	sta COLUPF				; 3 (8)

    ; tableau section (lower) -------------------------------------------------
    ldy #COLOR_CHIPS_IDX
    sta WSYNC
    jsr Bank0_SetColors2
    sta WSYNC
    jsr Bank0_SetTableau

    ldy #SPRITE_CARDS_IDX
    jsr Bank0_SetSpriteOptions

    SLEEP_LINES 14

    lda #CHIP_COLOR
    sta COLUP0
    sta COLUP1

    lda PlayerChips
    sta TempInt
    lda PlayerChips+1
    sta TempInt+1
    lda PlayerChips+2
    sta TempInt+2

    TIMED_JSR Bank0_SetupChipSprites, TIME_CHIPS_POT, TIM8T

    lda #<Bank0_ChipPalette
    sta TempPtr
    lda #>Bank0_ChipPalette
    sta TempPtr+1
    ldy #CHIPS_HEIGHT-1
    jsr Bank0_Draw6ColorSprites

    SLEEP_LINES 14

    jsr Bank0_ClearGraphicsOpts
    lda #CHIP_MENU_COLOR
    sta COLUP0
    sta COLUP1

    ; player's chip section ---------------------------------------------------

    ; chip denomination section -----------------------------------------------

    lda #0
    ldy #DENOMS_HEIGHT-1
    sta WSYNC
    sta GRP0
    sta GRP1
    sta WSYNC
    DRAW_6_GRAPHIC Bank0_DenomSprite

    lda #0
    sta WSYNC
    sta GRP0
    sta GRP1

    ldy #TIMES_HEIGHT-1
    sta WSYNC
    DRAW_2_GRAPHIC Bank0_TimesSprite, Bank0_TimesSprite

    TIMED_JSR Bank0_SetupMenuChips, TIME_CHIP_MENU_SETUP, TIM8T

    lda #<(Bank0_CardPalette+3)
    sta TempPtr
    lda #>(Bank0_CardPalette+3)
    sta TempPtr+1
    ldy #CHIPS_HEIGHT-1
    jsr Bank0_Draw6ColorSprites

    ; status bar section -----------------------------------------------------
    SET_POINTER IntPtr, PlayerChips
    TIMED_JSR Bank0_SetupInteger, TIME_STATUS_BAR, TIM8T

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
    JUMP_BANK Bank2_Overscan

Bank0_UpdateHighlights SUBROUTINE   ; 6 (6)
    ldx #0                          ; 2 (8)
    lda FrameCtr                    ; 3 (11)
    cmp #256-TITLE_EDITION_HEIGHT   ; 2 (13)
    bcc .Skip1                      ; 2 (15)
    lda FrameCtr                    ; 3 (18)
    and #%00000111                  ; 2 (20)
    tax                             ; 2 (24)
    inx                             ; 2 (26)
    inx                             ; 2 (26)
.Skip1
    stx PalIdx1                     ; 3 (29)

    ; 2 (31)nd hightlight is delayed by 16 frames from 1st
    ldx #0                          ; 2 (33)
    lda FrameCtr                    ; 3 (36)
    cmp #TITLE_COPY_HEIGHT          ; 2 (38)
    bcs .Skip2                      ; 2 (40)
    lda FrameCtr                    ; 3 (43)
    and #%00001111                  ; 2 (45)
    tax                             ; 2 (47)
    inx                             ; 2 (49)
    inx                             ; 2 (49)
.Skip2
    stx PalIdx2                     ; 3 (52)
    rts                             ; 6 (58)

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
    lda #JOY0_RIGHT
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckLeft                  ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckLeft
    tya                             ; A = changed bits
    and #JOY0_LEFT                  ; 0 = no change, 1 = changed
    beq .CheckDown                  ; branch if no change
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckDown                  ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckDown
    tya                             ; A = changed bits
    and #JOY0_DOWN                  ; 0 = no change, 1 = changed
    beq .CheckUp                    ; branch if no change
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckUp                    ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckUp
    tya                             ; A = changed bits
    and #JOY0_UP                    ; 0 = no change, 1 = changed
    beq .CheckFire                  ; branch if no change
    bit JoySWCHA                    ; 1 = released, 0 = pressed
    bne .CheckFire                  ; branch if this is a press event
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.CheckFire
    lda INPT4
    tay                             ; save a copy
    eor JoyINPT4                    ; A = changed bits
    and #JOY_FIRE                   ; 0 = no change, 1 = changed
    bpl .Return                     ; branch if no change
    bit JoyINPT4                    ; 1 = released, 0 = pressed
    bne .Return                     ; branch if this is a press event
    lda #JOY_REL_FIRE
    ora JoyRelease                  ; turn the bit on
    sta JoyRelease
.Return
    stx JoySWCHA
    sty JoyINPT4
    rts

; -----------------------------------------------------------------------------
; Desc:     Sends a test signal required for reading the keypad.
; Inputs:   A (row selector)
; Ouputs:   JoyRelease (joystick bitmask)
; Notes:    Keypad
;
;   INPT0 to INPT5: bit 7 stores the column state
;
;          0 1 4   INPT    2 3 5
;   SWCHA -------         ------- SWCHA: writing to bits 0-7 to test rows
;       4 |1 2 3|         |1 2 3| 0
;       5 |4 5 6|         |4 5 6| 1 
;       6 |7 8 9|         |7 8 9| 2
;       7 |* 0 #|         |* 0 #| 3
;         -------         -------
;          left            right
;
;   Reading the keypad requires multiple rounds of testing to detect which
;   button rows are pressed. A 0 is written to SWCHA bit corresponding to the
;   button row being tested. A 1 is written to the remaining bits. The result
;   of the test is returned in bit 7 of an INPT address (INPT0 to INPT5).
;   The INPT addresses that receive a 0 indicate which columns are pressed,
;   so the combination of SWCHA and INPT specify which buttons are pressed.
;
;                      _____ 
;                     |left |
;   SWCHA and SWACNT: 7 6 5 4 3 2 1 0
;                             |_____|
;                              right
;
;   The left and right keypads can be tested together or independently. Prior
;   to testing, the SWACNT data direction must be set to output for the bits
;   in SWCHA that will be tested: left 11110000, right 00001111, both 11111111.
; -----------------------------------------------------------------------------
#if 1
Bank0_TestKeypad SUBROUTINE
    lda FrameCtr
    and #%00000011
    tay
    lda Bank0_KeyBits,y
    sta SWCHA
    rts
#else 
Bank0_TestKeypad SUBROUTINE
    lda #%11000000
    bit KeyPress    
    bmi .Left1

.Left1
    asl
    bit KeyPress    
    bmi .Left2

    lda #%00001111
    sta SWCHA
    
.Left2
    rts
#endif


#if 1
Bank0_ReadKeypad SUBROUTINE
    lda KeyPress
    beq .CheckTimer
    rts

.CheckTimer
    ldx InputTimer
    beq .ReadKey
    dex
    stx InputTimer
    rts

.ReadKey
    lda FrameCtr
    and #%00000011
    tay
    ldx Bank0_KeyCode,y         ; starting value

    lda INPT5
    bpl .ThirdPressed
    lda INPT3
    bpl .SecondPressed
    lda INPT2
    bpl .FirstPressed
    rts

.ThirdPressed
    inx
.SecondPressed
    inx
.FirstPressed
    inx
    stx KeyPress

    ;lda #INPUT_DELAY
    ;sta InputTimer
    rts

#else

Bank0_ReadKeypad SUBROUTINE
    lda KeyPress
    bne .Return

    ldx InputTimer
    bne .Decrement

    ldx #0
    sec
    lda #%11110111

.NextRow
    sta SWCHA

    ; wait 500ms
    ldy #120
.BusyWait
    dey
    bne .BusyWait

    ldy INPT5
    bpl .ThirdPressed
    ldy INPT3
    bpl .SecondPressed
    ldy INPT2
    bpl .FirstPressed

    inx
    inx
    inx

    ror
    bcs .NextRow

    ldx #-3         ; no key pressed
    
.ThirdPressed
    inx
.SecondPressed
    inx
.FirstPressed
    inx
    stx KeyPress

.Return
    rts
.Decrement
    dex
    stx InputTimer
    rts
#endif

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

    lda Bank0_Mult6,y
    adc #<Bank0_Opts
    sta SpritePtrs+8
    stx SpritePtrs+9
    
    rts

; -----------------------------------------------------------------------------
; Desc:     Assign sprite pointers to betting prompt.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetupBettingPrompt SUBROUTINE
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
; Desc:     Assigns sprite pointers to display a 6 digit number.
; Inputs:   SpritePtrs, IntPtr (pointer to 3 byte BCD integer)
; Outputs:
; -----------------------------------------------------------------------------
Bank0_SetupInteger SUBROUTINE
    ; left digit
	ldy #0
    lda (IntPtr),y
    lsr
    lsr
    lsr
    lsr
	bne .ShowNum
    ; show a dollar sign if left-most digit is 0
    lda #<Bank0_Dollar
    sta SpritePtrs
    lda #>Bank0_Dollar
    sta SpritePtrs+1
	jmp .NextDigit
.ShowNum
    tax
	lda Bank0_IntGfxLo,x
    sta SpritePtrs
	lda Bank0_IntGfxHi,x
    sta SpritePtrs+1
.NextDigit
    ; right digit
    lda (IntPtr),y
    and #$0f
    tax
	lda Bank0_IntGfxLo,x
    sta SpritePtrs+2
	lda Bank0_IntGfxHi,x
    sta SpritePtrs+3

    ; left digit
	iny
    lda (IntPtr),y
    lsr
    lsr
    lsr
    lsr
    tax
	lda Bank0_IntGfxLo,x
    sta SpritePtrs+4
	lda Bank0_IntGfxHi,x
    sta SpritePtrs+5
    ; right digit
    lda (IntPtr),y
    and #$0f
    tax
	lda Bank0_IntGfxLo,x
    sta SpritePtrs+6
	lda Bank0_IntGfxHi,x
    sta SpritePtrs+7

    ; left digit
	iny
    lda (IntPtr),y
    lsr
    lsr
    lsr
    lsr
    tax
	lda Bank0_IntGfxLo,x
    sta SpritePtrs+8
	lda Bank0_IntGfxHi,x
    sta SpritePtrs+9
    ; right digit
    lda (IntPtr),y
    and #$0f
    tax
	lda Bank0_IntGfxLo,x
    sta SpritePtrs+10
	lda Bank0_IntGfxHi,x
    sta SpritePtrs+11
    rts

    INCLUDE_CHIP_SUBS 0

; -----------------------------------------------------------------------------
; Desc:     Setup bottom chip menu row of sprites.
; Inputs:        
; Ouputs:
; -----------------------------------------------------------------------------
Bank0_SetupMenuChips SUBROUTINE
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

    ; -------------------------------------------------------------------------
    ORG BANK0_ORG + $700, FILLER_CHAR
    RORG BANK0_RORG + $700

    PAGE_BOUNDARY_SET
    include "sys/bank0_palette.asm"
    PAGE_BOUNDARY_CHECK "Bank0 palette crossed a page boundary"

    ; -------------------------------------------------------------------------
    ORG BANK0_ORG + $800, FILLER_CHAR
    RORG BANK0_RORG + $800

Bank0_DrawMessageBar SUBROUTINE
    DRAW_48_COLOR_SPRITE SpritePtrs, Bank0_MessagePalette
    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
    rts

Bank0_Draw48PixelSprite SUBROUTINE
    DRAW_48_SPRITE SpritePtrs
    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
    rts

Bank0_GameIO SUBROUTINE
    jsr Bank0_ReadSwitches

    ldx InputTimer
    bne .DecTimer
    jsr Bank0_ReadJoystick
	;jsr Bank0_TestKeypad
    rts

.DecTimer
    ; only update 1 in 64 frame ticks
    lda #%00100000
    bit FrameCtr
    bne .Return
    dex
    stx InputTimer

.Return
    rts

Bank0_InitGlobals SUBROUTINE
    lda #GS_START_STATE
    sta GameState
    lda #%00001111
    sta SWACNT
    lda SWCHA
    sta JoySWCHA
    lda SWCHB
    sta JoySWCHB
    lda INPT4
    sta JoyINPT4
    ldx #1
    stx RandNum

    IF TEST_RAND_ON == 2
    ldx #0
    stx RandAlt
    ELSE
    stx RandAlt
    ENDIF

    lda #NUM_DECKS-1 & FLAGS_LATE_SURRENDER & FLAGS_HIT_SOFT17
    sta GameOpts

    ; begin counter after 2nd highlight, because it flashes on loading
    ldx #TITLE_COPY_HEIGHT
    stx FrameCtr
    rts

    ; -------------------------------------------------------------------------
    ;ORG BANK0_ORG + $900, FILLER_CHAR
    ;RORG BANK0_RORG + $900

    include "../atarilib/lib/draw.asm"

Bank0_Draw6Sprites SUBROUTINE
    DRAW_6_SPRITES SpritePtrs
    rts

Bank0_Draw6ColorSprites SUBROUTINE
    DRAW_6_COLOR_SPRITES SpritePtrs, TempPtr
    rts

Bank0_DrawTitleGraphic SUBROUTINE
    ldy #TITLE_LOGO_HEIGHT-1
    DRAW_RAINBOW_GRAPHIC Bank0_TitleSprite
    rts

    ; -------------------------------------------------------------------------
    ORG BANK0_ORG + $a00, FILLER_CHAR
    RORG BANK0_RORG + $a00

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

Bank0_ClearGraphicsOpts SUBROUTINE
    lda #0
    sta VDELP0
    sta VDELP1
    sta GRP0
    sta GRP1
    rts

; Indexed by game state values.
; bit 7:        show betting row
; bit 6:        show dashboard
; bit 5:        show dealer's hole card
; bit 4:        show dealer's score
; bit 3:        flicker the currently selected object
; bit 0,1,2:    index into PromptMessages table
Bank0_GameStateFlags
    dc.b 0                  ; GS_TITLE_SCREEN
    dc.b %10101001          ; GS_NEW_GAME
    dc.b %10001001          ; GS_PLAYER_BET
    dc.b %10001001          ; GS_PLAYER_BET_DOWN
    dc.b %10001001          ; GS_PLAYER_BET_UP
    dc.b %01000000          ; GS_OPEN_DEAL1
    dc.b %01000000          ; GS_OPEN_DEAL2
    dc.b %01000000          ; GS_OPEN_DEAL3
    dc.b %01000000          ; GS_OPEN_DEAL4
    dc.b %01000000          ; GS_OPEN_DEAL5
    dc.b %01000010          ; GS_DEALER_SET_FLAGS
    dc.b %01000010          ; GS_PLAYER_SET_FLAGS
    dc.b %01000010          ; GS_PLAYER_TURN
    dc.b %01000010          ; GS_PLAYER_PRE_HIT
    dc.b %01000010          ; GS_PLAYER_HIT
    dc.b %01000010          ; GS_PLAYER_POST_HIT
    dc.b %01000011          ; GS_PLAYER_SURRENDER
    dc.b %01000100          ; GS_PLAYER_DOUBLEDOWN
    dc.b %01000101          ; GS_PLAYER_SPLIT
    dc.b %01000101          ; GS_PLAYER_SPLIT_DEAL
    dc.b %01000110          ; GS_PLAYER_INSURANCE
    dc.b %00110000          ; GS_PLAYER_BLACKJACK
    dc.b %00110000          ; GS_PLAYER_WIN
    dc.b %00110000          ; GS_PLAYER_PUSH
    dc.b 0                  ; GS_PLAYER_HAND_OVER
    dc.b %00110000          ; GS_DEALER_TURN
    dc.b %00110000          ; GS_DEALER_PRE_HIT
    dc.b %00110000          ; GS_DEALER_HIT
    dc.b %00110000          ; GS_DEALER_POST_HIT
    dc.b %00110000          ; GS_DEALER_HAND_OVER
    dc.b %00110000          ; GS_GAME_OVER
    dc.b %00110000          ; GS_INTERMISSION
    dc.b %00110000          ; GS_BROKE_BANK1
    dc.b %00110000          ; GS_BROKE_BANK2

    INCLUDE_SPRITE_POSITIONING 0
    INCLUDE_SPRITE_OPTIONS 0
    INCLUDE_SPRITE_COLORS 0

    ; -------------------------------------------------------------------------
    ORG BANK0_ORG + $b00, FILLER_CHAR
    RORG BANK0_RORG + $b00

    include "bank0/gen/title-gfx-48.sp"

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

    INCLUDE_CHIP_DATA 0

; Shared procedures
PROC_BANK0_LANDINGINIT		= 0
PROC_BANK0_OVERSCAN			= 1
PROC_ANIMATIONCLEAR         = 2
PROC_SOUNDQUEUECLEAR        = 3

Bank0_ProcTableLo
    dc.b <Bank1_LandingInit
    dc.b <Bank2_Overscan
    dc.b <AnimationClear
    dc.b <SoundClear

Bank0_ProcTableHi
    dc.b >Bank1_LandingInit
    dc.b >Bank2_Overscan
    dc.b >AnimationClear
    dc.b >SoundClear

Bank0_KeyBits
    dc.b %00001110, %00001101, %00001011, %00000111
Bank0_KeyCode
    dc.b 0, 3, 6, 9

    ; -------------------------------------------------------------------------
    ORG BANK0_ORG + $c00, FILLER_CHAR
    RORG BANK0_RORG + $c00

Bank0_BlankSprite
    ds.b 15, 0
    include "bank0/gfx/digits.asm"
    include "bank0/gfx/betting-menu.asm"

    ; ------------------------------------------------------------------------
    ORG BANK0_ORG + $d00, FILLER_CHAR
    RORG BANK0_RORG + $d00

    include "bank0/gen/title-logo-48.sp"

    ; ------------------------------------------------------------------------
    ORG BANK0_ORG + $e00, FILLER_CHAR
    RORG BANK0_RORG + $e00

    include "bank0/gen/title-copy-48.sp"

    ; ------------------------------------------------------------------------
    ORG BANK0_ORG + $f00, FILLER_CHAR
    RORG BANK0_RORG + $f00

    include "bank0/gen/bet-prompts-48.sp"

Bank0_IntGfxLo
	dc.b <Bank0_Digit0, <Bank0_Digit1, <Bank0_Digit2, <Bank0_Digit3
	dc.b <Bank0_Digit4, <Bank0_Digit5, <Bank0_Digit6, <Bank0_Digit7
	dc.b <Bank0_Digit8, <Bank0_Digit9

Bank0_IntGfxHi
	dc.b >Bank0_Digit0, >Bank0_Digit1, >Bank0_Digit2, >Bank0_Digit3
	dc.b >Bank0_Digit4, >Bank0_Digit5, >Bank0_Digit6, >Bank0_Digit7
	dc.b >Bank0_Digit8, >Bank0_Digit9

    INCLUDE_MULTIPLY_TABLE 0, 4, 10
    INCLUDE_MULTIPLY_TABLE 0, 5, 4
    INCLUDE_MULTIPLY_TABLE 0, 6, 20
    INCLUDE_MULTIPLY_TABLE 0, 10, 5

    INCLUDE_POSITIONING_SUBS 0
    INCLUDE_MENU_SUBS 0

    ; ------------------------------------------------------------------------
    ORG BANK0_ORG + $ff6-BS_SIZEOF
    RORG BANK0_RORG + $ff6-BS_SIZEOF

    INCLUDE_BANKSWITCH_SUBS 0, BANK0_HOTSPOT

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
