
; Start of bank 3
; -----------------------------------------------------------------------------
    SEG Bank3

    ORG BANK3_ORG, FILLER_CHAR
    RORG BANK3_RORG

; -----------------------------------------------------------------------------
; Shared Variables
; -----------------------------------------------------------------------------
Bank3_SeqPtr        SET TempVars
; animation add (must be same as vars in Bank2)
Bank3_AddID         SET TempVars+2
Bank3_AddPos        SET TempVars+3

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
; dashboard rendering
PF0Bits             SET TempVars
PF2Bits             SET TempVars+1

; card rendering
CardIdx             = Arg1
SprIdx              = Arg2

PlyrIdx             SET TempVars+1
TempVal             SET TempVars+2

AnimIdx             SET TempVars+3
AnimRow             SET TempVars+4

HoleGfx             SET TempVars+7
HoleIdx             SET TempVars+5
GapIdx              SET TempVars+5
GapLastElem         SET TempVars+6

; wide sprite rendering for Bank3_DrawColorText & Bank3_DrawColorTextJump
;DrawHeight SET TempVars+6
;PalettePtr SET TempVars+7

Bank3_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank3_PlayKernel SUBROUTINE
	; 7 lines of vertical blank are reserved for additional setup
    lda #7*76/64
    sta TIM64T

#if 0 ; PIP_COLORS
    ; position ball
    lda #69
    ldx #4
    HORIZ_POS_BZ Bank3_fineAdjustTable
    sta WSYNC
    sta HMOVE
#endif

	jsr Bank3_SetupIndexes
    jsr Bank3_SetupMessageBar
    ldy #OPT_BAR_IDX
    jsr Bank3_SetColors2
    jsr Bank3_SetupDashboardMask

    TIMER_WAIT      ; Wait for vertical blank to finish

    lda #0
    sta WSYNC
    sta VBLANK

    ; Top dashboard rows -----------------------------------------------------
    lda #MSG_ROW_HEIGHT*76/64
    sta TIM64T

    ; draw 1st dashboard row
    ldy #MESSAGE_TEXT_HEIGHT-1
    jsr Bank3_DrawMessageBar

    ; draw 2nd dashboard row
    jsr Bank3_SetupDashboard
    ldy #DASHOPTS_HEIGHT-1
    jsr Bank3_DrawMessageBar

    lda #0
    sta PF0
    sta PF1
    sta PF2

	; lower playfield priority
	lda #0
	sta CTRLPF

    TIMER_WAIT

    ; Dealer cards row --------------------------------------------------------
    lda #17*76/64
    sta TIM64T

    ldx #DEALER_IDX
    ldy PlayerNumCards,x
    lda Bank3_HandNusiz0,y
    sta NUSIZ0
    lda Bank3_HandNusiz1,y
    sta NUSIZ1

    ldy #SPRITE_CARDS_IDX
    jsr Bank3_PositionSprites	; 9 (9)

    ; hide MOVE line
    sta COLUBK  				; 3 (12)
    ldy #COLOR_CARDS_IDX		; 2 (14)

    sta WSYNC
    jsr Bank3_SetColors2		; 36 (36) 
    sta WSYNC
    jsr Bank3_SetTableau

	; lower playfield priority
	lda #0
	sta CTRLPF

    sta WSYNC

    ;jsr Bank3_ResetCardSprites
    ldx #DEALER_IDX
    stx PlyrIdx
    jsr Bank3_SetupCardSprites

    TIMER_WAIT

    jsr Bank3_RenderCardSprites

    lda #0
    sta GRP0
    sta GRP1
    sta GRP0
    sta VDELP0
    sta VDELP1

    ; Betting pot row ---------------------------------------------------------
    lda #CHIP_COLOR
    sta COLUP0
    sta COLUP1
    lda #NUSIZE_3_MEDIUM
    sta NUSIZ0
    sta NUSIZ1

    ; draw dealer's pot of chips
    jsr Bank3_SetupChipsPot
    ldy #CHIPS_HEIGHT-1
    jsr Bank3_Draw6Sprites

    lda #1
    sta VDELP0
    sta VDELP1

    lda #29*76/64
    sta TIM64T

    ; decide if navigation menu should be displayed
    lda CurrState
    bpl .PlayerNoMenu

    ; Menu prompt row --------------------------------------------------------

#if 0
    sta WSYNC
    lda #0
    sta PF0
    sta PF1
    sta PF2

    lda #NUSIZE_3_CLOSE
    sta NUSIZ0
    sta NUSIZ1
    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank3_PositionSprites

    ; hide MOVE line
    lda #$0
    sta COLUBK
#endif

    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank3_SetSpriteOptions
    jsr Bank3_PositionSprites

    lda #$0                 ; 2 (2)
    sta COLUBK              ; 3 (5)
    sta PF0                 ; 3 (8)
    sta PF1                 ; 3 (11)
    sta PF2                 ; 3 (14)

    ldy #MSG_BAR_IDX
    jsr Bank3_SetColors

    jsr Bank3_SetupPromptBar
    ldy #MESSAGE_TEXT_HEIGHT-1
    jsr Bank3_DrawMessageBar

    sta WSYNC

    lda #NUSIZE_3_MEDIUM
    sta NUSIZ0
    sta NUSIZ1
    ldy #SPRITE_CARDS_IDX
    jsr Bank3_PositionSprites

    ; hide MOVE line
    lda #$0
    sta PF0
    sta PF1
    sta PF2
    sta COLUBK

    ldy #COLOR_CARDS_IDX
    jsr Bank3_SetColors
    sta WSYNC
    jsr Bank3_SetTableau
    sta WSYNC
    jmp .PlayerSection

    ; Blank space ------------------------------------------------------------
.PlayerNoMenu
    ;SLEEP_LINES 22

    ; Player cards rows -------------------------------------------------------
.PlayerSection
    TIMER_WAIT 

    lda #CARD_COLOR
    sta COLUP0
    sta COLUP1
    lda #1
    sta VDELP0
    sta VDELP1
    ;jsr Bank3_ResetCardSprites

    lda #FLAGS_SPLIT_TAKEN
    bit GameFlags
    beq .NoSplit

.SplitHand
    lda #12*76/64
    sta TIM64T

    ; assign card colors (active/inactive, dealer is always active)
    lda #PLAYER2_IDX << 2
    ora CurrPlayer
    tay
    lda Bank3_ColorMatrix,y
    sta COLUP0
    sta COLUP1

    ldx #PLAYER2_IDX
    stx PlyrIdx
    ldy PlayerNumCards,x
    lda Bank3_HandNusiz0,y
    ldx Bank3_HandNusiz1,y

    sta WSYNC
    sta NUSIZ0
    stx NUSIZ1

    jsr Bank3_SetupCardSprites
    TIMER_WAIT

    jsr Bank3_RenderCardSprites

    lda #0
    sta GRP0
    sta GRP1
    jmp .OneHand

    ; Blank space ------------------------------------------------------------
.NoSplit
    SLEEP_LINES 32

.OneHand
    lda #12*76/64
    sta TIM64T

    ; assign card colors (active/inactive, dealer is always active)
    lda #PLAYER1_IDX << 2
    ora CurrPlayer
    tay
    lda Bank3_ColorMatrix,y
    sta COLUP0
    sta COLUP1

    ldx #PLAYER1_IDX
    stx PlyrIdx
    ldy PlayerNumCards,x
    lda Bank3_HandNusiz0,y
    ldx Bank3_HandNusiz1,y

    sta WSYNC
    sta NUSIZ0
    stx NUSIZ1

    jsr Bank3_SetupCardSprites
    TIMER_WAIT

    jsr Bank3_RenderCardSprites

    lda #0
    sta GRP0
    sta GRP1
    sta VDELP0
    sta VDELP1

    ; Player chips row --------------------------------------------------------
    lda #CHIP_COLOR
    sta COLUP0
    sta COLUP1
    lda #NUSIZE_3_MEDIUM
    sta NUSIZ0
    sta NUSIZ1

    TIMED_JSR Bank3_SetupPlayerChips, TIME_CHIP_MENU_SETUP, TIM8T
    ldy #CHIPS_HEIGHT-1
    jsr Bank3_Draw6Sprites

    ; Bottom text row ---------------------------------------------------------
    TIMED_JSR Bank3_SetupStatusBar, TIME_STATUS_BAR, TIM8T

    ldy #SPRITE_STATUS_IDX
    jsr Bank3_SetSpriteOptions
    jsr Bank3_PositionSprites

    ; hide MOVE line
    lda #$0
    sta PF0
    sta PF1
    sta PF2
    sta COLUBK

    ldy #MSG_BAR_IDX
    jsr Bank3_ClearPlayfield
    lda Bank3_MsgPalette,y
    sta COLUBK
    lda Bank3_MsgPalette+1,y
    sta COLUP0
    sta COLUP1

    ; draw the status bar
    ldy #STATUS_TEXT_HEIGHT-1
    jsr Bank3_DrawMessageBar

    ; Cleanup -----------------------------------------------------------------
    lda #0
    sta WSYNC
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2
    sta VDELP0
    sta VDELP1
    sta GRP0
    sta GRP1

    ; saving 2 bytes of stack by jumping
    JUMP_BANK PROC_BANK3_OVERSCAN, 2, 3

; -----------------------------------------------------------------------------
; SUBROUTINES
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Desc:     Sets the sprites to the prompt message or result message.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank3_SetupMessageBar SUBROUTINE
    lda GameState
    cmp #GS_GAME_OVER
    bcs .ResultMessage          ; if GameState >= Game Over
    
    lda #<Bank3_OptionsStr0
    sta SpritePtrs

    lda #<Bank3_OptionsStr1
    sta SpritePtrs+2

    lda #<Bank3_OptionsStr2
    sta SpritePtrs+4

    lda #<Bank3_OptionsStr3
    sta SpritePtrs+6

    lda #<Bank3_OptionsStr4
    sta SpritePtrs+8

    lda #<Bank3_OptionsStr5
    sta SpritePtrs+10

    ldx #>Bank3_OptionsStr0
    jmp .Return

.ResultMessage
    ldx CurrPlayer
    lda PlayerFlags,x
    and #FLAGS_HANDOVER

    ; map highest PlayerFlags bit to a result message
    jsr Bank3_Log2
    dex
    ldy Bank3_Mult6,x

    lda Bank3_ResultMessagesLSB,y
    sta SpritePtrs
    lda Bank3_ResultMessagesLSB+1,y
    sta SpritePtrs+2
    lda Bank3_ResultMessagesLSB+2,y
    sta SpritePtrs+4
    lda Bank3_ResultMessagesLSB+3,y
    sta SpritePtrs+6
    lda Bank3_ResultMessagesLSB+4,y
    sta SpritePtrs+8
    lda Bank3_ResultMessagesLSB+5,y
    sta SpritePtrs+10

    ldx #>Bank3_BlankMessage

.Return
    stx SpritePtrs+1
    stx SpritePtrs+3
    stx SpritePtrs+5
    stx SpritePtrs+7
    stx SpritePtrs+9
    stx SpritePtrs+11

    rts

Bank3_SetupPromptBar SUBROUTINE
    lda GameState
    cmp #GS_GAME_OVER
    bcs .NoPrompt
    
    ; map lowest 3 bits of PlayerFlags to a prompt
    ldx GameState
    lda Bank3_GameStateFlags,x
    and #GS_PROMPT_IDX_MASK             ; chop off extra bits
    tax
    ldy Bank3_Mult4,x

    lda #<Bank3_LeftArrow
    sta SpritePtrs
    lda #>Bank3_LeftArrow
    sta SpritePtrs+1

    lda Bank3_PromptMessagesLSB,y
    sta SpritePtrs+2
    lda Bank3_PromptMessagesLSB+1,y
    sta SpritePtrs+4
    lda Bank3_PromptMessagesLSB+2,y
    sta SpritePtrs+6
    lda Bank3_PromptMessagesLSB+3,y
    sta SpritePtrs+8

    lda #<Bank3_RightArrow
    sta SpritePtrs+10
    lda #>Bank3_RightArrow
    sta SpritePtrs+11
    lda #>Bank3_BlankStr
    jmp .Return

.NoPrompt
    lda #<Bank3_BlankStr
    sta SpritePtrs
    sta SpritePtrs+2
    sta SpritePtrs+4
    sta SpritePtrs+6
    sta SpritePtrs+8
    sta SpritePtrs+10

    lda #>Bank3_BlankStr
    sta SpritePtrs+1
    sta SpritePtrs+11
.Return
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9

    rts

; -----------------------------------------------------------------------------
; Desc:     Initializes the playfield bits for the dashboard.
; Inputs:
; Ouputs:   PF0Bits, PF2Bits
; Notes:    Dashboard masking bits
;           PF0, PF1, PF2, PF0, PF1, PF2
;                     |_____|
;
;           Bits:     0-7, 4-7
; -----------------------------------------------------------------------------
Bank3_SetupDashboardMask SUBROUTINE
    ; turn off all dashboard menus: 1 is off, 0 is on
    lda #%11111111  ; graphics: I, Sp
    ;lda #%11001111  ; graphics: I, Sp
    sta PF0Bits
    lda #%11110000  ; graphics: left arrow, D, Su
    sta PF2Bits

    ; check if double down and surrender are allowed
    lda #FLAGS_DOUBLEDOWN_ALLOWED|FLAGS_SURRENDER_ALLOWED
    bit GameFlags
    beq .CheckInsurance
    ; turn on double down and surrender icons
    lda #0
    sta PF2Bits

.CheckInsurance
    lda #FLAGS_INSURANCE_ALLOWED
    bit GameFlags
    beq .CheckInsTaken
    ; turn on insurance icon
    lda #%11000000
    and PF0Bits
    sta PF0Bits

.CheckInsTaken
    ; if insurance taken, inverse the icon
    ldx CurrPlayer
    lda #FLAGS_INSURANCE_TAKEN
    and PlayerFlags,x
    beq .CheckSplit
    ; turn on insurance icon
    lda #%11000000
    and PF0Bits
    sta PF0Bits

.CheckSplit
    lda #FLAGS_SPLIT_ALLOWED
    bit GameFlags
    beq .Continue
    ; turn on split icon
    lda #%00110000
    and PF0Bits
    sta PF0Bits

.Continue
    rts

Bank3_SetupDashboard SUBROUTINE
    ldx GameState
    lda Bank3_GameStateFlags,x
    and #GS_SHOW_DASHBOARD_FLAG
    beq .ShowOptions

    ; displays play menu on the game screen

    ; raise playfield priority to conceal menu items
    lda #%00000100
    sta CTRLPF
    lda PF0Bits
    sta PF0
    lda PF2Bits
    sta PF2

    lda #>Dashboard
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11

    lda #<Dashboard0
    sta SpritePtrs
    lda #<Dashboard1
    sta SpritePtrs+2
    lda #<Dashboard2
    sta SpritePtrs+4
    lda #<Dashboard3
    sta SpritePtrs+6
    lda #<Dashboard4
    sta SpritePtrs+8
    lda #<Dashboard5
    sta SpritePtrs+10

    ldx CurrPlayer
    lda PlayerFlags,x
    and #FLAGS_INSURANCE_TAKEN
    beq .NoInsurance

    lda #<DashboardInsurance
    sta SpritePtrs+6
    lda #>DashboardInsurance
    sta SpritePtrs+7

.NoInsurance
    rts

.ShowOptions
    ; displays game options on betting menu and completed hands on the game screen
    lda #<Bank3_OptsBlank
    sta SpritePtrs+2
    sta SpritePtrs+6
    sta SpritePtrs+10
    lda #>Bank3_OptsBlank
    sta SpritePtrs+3
    sta SpritePtrs+7
    sta SpritePtrs+11

    ldx #>Bank3_Opts

    lda #<Bank3_OptsEarlySurr
    sta SpritePtrs
    stx SpritePtrs+1

    lda #<Bank3_OptsHard17
    sta SpritePtrs+4
    stx SpritePtrs+5

    lda #FLAGS_LATE_SURRENDER
    bit GameOpts
    beq .CheckSoft17

    lda #<Bank3_OptsLateSurr
    sta SpritePtrs
    stx SpritePtrs+1

.CheckSoft17
    lda #FLAGS_HIT_SOFT17
    bit GameOpts
    beq .NumDecks

    lda #<Bank3_OptsSoft17
    sta SpritePtrs+4
    stx SpritePtrs+5

.NumDecks
    lda #NUM_DECKS_MASK
    and GameOpts

    tay
    clc

    lda Bank3_Mult6,y
    adc #<Bank3_Opts
    sta SpritePtrs+8
    stx SpritePtrs+9
    rts

#if 0
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
#endif

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite characters for the bottom status bar.
; Inputs:
; Ouputs:
; TODO:     The shoe indicator needs to scale for 1 and 2 decks.
; -----------------------------------------------------------------------------
Bank3_SetupStatusBar SUBROUTINE
    ; blank, digits and shoe sprites are in the same page
    lda #>BlankCard
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11

    ; only show the score of the last hand played if the current player
    ; is not the dealer.
    ldx CurrPlayer
    cpx #DEALER_IDX
    bne .Continue
    ldx #PLAYER1_IDX
.Continue

    ; 1st & 2nd sprite: player score
    lda PlayerScore,x
    lsr
    lsr
    lsr
    lsr
    tay
    lda Bank3_DigitSprite,y
    sta SpritePtrs

    lda PlayerScore,x
    and #$0f
    tay
    lda Bank3_DigitSprite,y
    sta SpritePtrs+2

    ; 3rd sprite is always blank
    ldy #<BlankCard
    sty SpritePtrs+4

    ; decide whether to reveal the dealer's score
    ; both flags (show hole card, show dealer score) must be true
    lda CurrState
    bmi .ShowShoe

    ldx GameState
    lda #GS_SHOW_DEALER_SCORE_FLAG
    and Bank3_GameStateFlags,x
    beq .ShowShoe

    ; 4th sprite is blank, 5th & 6th show dealer score

    ; 4th sprite is blank
    sty SpritePtrs+6

    ; 5th & 6th sprite: dealer score
    ldx #DEALER_IDX
    lda PlayerScore,x
    lsr
    lsr
    lsr
    lsr
    tay
    lda Bank3_DigitSprite,y
    sta SpritePtrs+8

    lda PlayerScore,x
    and #$0f
    tay
    lda Bank3_DigitSprite,y
    sta SpritePtrs+10
    jmp .Return

.ShowShoe
    ; 4th, 5th, 6th sprite show the shoe graphic
    ;
    ; DealDepth influences the state of the shoe graphics. The shoe
    ; uses two arrays of graphics to show 6 intervals. The tail segment
    ; will either show 100% of 50% used.
    ;
    ; Depth intervals by number of decks:
    ;     0-31   32-63   64-95   96-127 128-159 160-207     4 decks
    ;     0-15   16-31   32-47   48-63   64-79   80-103     2 decks
    ;     0-7     8-15   16-23   24-35   36-47   48-51      1 deck
    ;   _______________________________________________
    ;  |       |       |       |       |       |       |
    ;  |   0   |   1   |   2   |   3   |   4   |   5   |
    ;  |_______|_______|_______|_______|_______|_______|
    ;   *******         *******         *******          (evens, 100%)
    ;           *******         *******         *******  (odds,  50%)
    ;
    ; This shows every graphic combination:
    ;       Shoe                    Tail
    ;      _______._______._______.
    ;   5 |_______._______._______| 100%
    ;   4 |_______._______.___|   .  50%
    ;   3 |_______._______|       . 100%
    ;   2 |_______.___|   .       .  50%
    ;   1 |_______|       .       . 100%
    ;   0 |___|   .       .       .  50%

    ; get number of decks
    lda GameOpts
    and #NUM_DECKS_MASK
    tax

    lda DealDepth
    ; divide by 8
    lsr
    lsr
    lsr
    cpx #0
    beq .Assign
    ; divide by 16
    lsr
    cpx #3
    bcc .Assign
    ; divide by 32
    lsr

.Assign
    tax
    lda Bank3_ShoeSprite,x
    sta SpritePtrs+6
    inx
    inx
    lda Bank3_ShoeSprite,x
    sta SpritePtrs+8
    inx
    inx
    lda Bank3_ShoeSprite,x
    sta SpritePtrs+10

    lda #>Bank3_Shoes
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Setup top row of chip sprites representing the pot.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank3_SetupChipsPot SUBROUTINE
    clc
    sed

    ldy #0                        ; sprite selector

    lda CurrBet+1
    cmp #0
    beq .Next50
    ldx #<Bank3_Chip5
    stx SpritePtrs,y
    ldx #>Bank3_Chip5
    stx SpritePtrs+1,y
    iny
    iny

.Next50
    lda CurrBet+2
    cmp #$50
    bcc .Next25
    ldx #<Bank3_Chip4
    stx SpritePtrs,y
    ldx #>Bank3_Chip4
    stx SpritePtrs+1,y
    iny
    iny
    sbc #$50

.Next25
    cmp #$25
    bcc .Next10
    ldx #<Bank3_Chip3
    stx SpritePtrs,y
    ldx #>Bank3_Chip3
    stx SpritePtrs+1,y
    iny
    iny
    sbc #$25

.Next10
    cmp #$10
    bcc .Next5
    ldx #<Bank3_Chip2
    stx SpritePtrs,y
    ldx #>Bank3_Chip2
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
    ldx #<Bank3_Chip1
    stx SpritePtrs,y
    ldx #>Bank3_Chip1
    stx SpritePtrs+1,y
    iny
    iny
    sbc #$05

.Next1
    cmp #1
    bcc .Done
    ldx #<Bank3_Chip0
    stx SpritePtrs,y
    ldx #>Bank3_Chip0
    stx SpritePtrs+1,y
    iny
    iny

.Done
    lda #<Bank3_BlankSprite
    ldx #>Bank3_BlankSprite

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

; -----------------------------------------------------------------------------
; Desc:     Setup bottom chip menu row of sprites.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank3_SetupPlayerChips SUBROUTINE
    ; assign pointers to chip sprite graphics
    lda #>Bank3_Chips
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11

    lda #<Bank3_Chip0
    sta SpritePtrs
    lda #<Bank3_Chip1
    sta SpritePtrs+2
    lda #<Bank3_Chip2
    sta SpritePtrs+4
    lda #<Bank3_Chip3
    sta SpritePtrs+6
    lda #<Bank3_Chip4
    sta SpritePtrs+8
    lda #<Bank3_Chip5
    sta SpritePtrs+10

    ; flicker selected chip
    lda #%00011000
    bit FrameCtr
    bne .Return

    ; only flicker when gamestate wants it
    ldx GameState
    lda Bank3_GameStateFlags,x
    and #GS_FLICKER_FLAG
    beq .Return

    ; get currently selected object
    jsr Bank3_GetBetMenu

    ; blank the currently selected sprite
    asl                         ; A * 2
    tay
    lda #<Bank3_BlankSprite
    sta SpritePtrs,y
    lda #>Bank3_BlankSprite
    sta SpritePtrs+1,y
.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite pointers to the same sprite character given by the
;           16 bit address.
; Inputs:   Y register
; (SPRITE_GRAPHICS_IDX, SPRITE_CARDS_IDX, SPRITE_BET_IDX, SPRITE_STATUS_IDX)
; Ouputs:
; -----------------------------------------------------------------------------
Bank3_SetSpriteOptions SUBROUTINE
    lda Bank3_SpriteSize,y
    sta NUSIZ0
    sta NUSIZ1
    lda Bank3_SpriteDelay,y
    sta VDELP0
    sta VDELP1
    rts

    INCLUDE_SPRITE_POSITIONING 3

; -----------------------------------------------------------------------------
; Desc:     Initializes graphics registers for a message bar.
; Inputs:   Y register (text palette index)
; Ouputs:
; -----------------------------------------------------------------------------
Bank3_ClearPlayfield SUBROUTINE
    lda #$0                         ; 2 (2)
    sta COLUBK                      ; 3 (5)
    sta PF0                         ; 3 (8)
    sta PF1                         ; 3 (11)
    sta PF2                         ; 3 (14)
    sta WSYNC                       ; hide HMOVE line
    rts                             ; 6 (23)

    ALIGN 256, FILLER_CHAR
    PAGE_BOUNDARY_SET

; -----------------------------------------------------------------------------
; Desc:     Draw a 48 pixel wide color sprite positioned at pixel 56.
; Inputs:   Y register (sprite height - 1)
; Outputs:
; Notes:
;   ldy #HEIGHT-1
;   DRAW_48_COLOR_SPRITE SpritePtrs, Palette
;
; -----------------------------------------------------------------------------
Bank3_DrawMessageBar SUBROUTINE
    sty Arg1
    ; preload the stack with a column of pixels from SpritePtrs+6
    ldy #-1
.Preload
    iny                         ; 2 (2)
    lda (SpritePtrs+6),y        ; 5 (7)
    pha                         ; 3 (10)
    cpy Arg1                    ; 3 (13)
    bcc .Preload                ; 3 (16)

    sta WSYNC
    ldy Arg1                    ; 3 (3)
    SLEEP_56                    ; 56 (59)
    nop                         ; 2 (61)

.Loop
    ;                         Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    ; ------------------------------------------------------------------------
    ldy Arg1                    ; 3 (64) (192)
    lda (SpritePtrs),y          ; 5 (69) (207)
    sta GRP0                    ; 3 (72) (216)    D1     --      --     --
    lda Bank3_MessagePalette,y  ; 4 (76) (228)
    ; -----------------------------------------------------------------------
    ;                         Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    sta.w COLUP0                ; 4 (4) (12)
    sta COLUP1                  ; 3 (7) (33)

    lda (SpritePtrs+2),y        ; 5 (12) (36)
    sta GRP1                    ; 3 (15) (45)     D1     D1      D2     --
    lda (SpritePtrs+4),y        ; 5 (20) (60)
    sta GRP0                    ; 3 (23) (69)     D3     D1      D2     D2

    lda (SpritePtrs+8),y        ; 5 (28) (84)
    tax                         ; 2 (30) (90)
    lda (SpritePtrs+10),y       ; 5 (35) (105)
    tay                         ; 2 (37) (111)
    pla                         ; 4 (41) (123)             !       

    sta GRP1                    ; 3 (44) (132)    D3     D3      D4     D2!
    stx GRP0                    ; 3 (47) (141)    D5     D3!     D4     D4
    sty GRP1                    ; 3 (50) (150)    D5     D5      D6     D4!
    sta GRP0                    ; 3 (53) (159)    D4*    D5!     D6     D6
    dec Arg1                    ; 5 (58) (174)                            !
    bpl .Loop                   ; 3 (61) (183)

    lda #0                      ; 2 (62)
    sta GRP0                    ; 3 (65)
    sta GRP1                    ; 3 (68)
    ; 2nd write to flush VDEL
    sta GRP0                    ; 3 (71)
    sta GRP1                    ; 3 (74)
    rts                         ; 6 (4)

; -----------------------------------------------------------------------------
; Desc:     Draws a 48 pixel wide multi-color text with selectable graphics.
; Inputs:   Y register (sprite height-1)
;           SpritePtrs
;           Bank3_TextPalette
; Outputs:
; Notes:    VDEL must be enabled for GRP0 and GRP1.
;
; Example:
;   ; preload
;   lda #>(Bank3_DrawColorTextRet-1)
;   pha
;   lda #<(Bank3_DrawColorTextRet-1)
;   pha
;   ; preload the stack with SpritePtrs[6] column of pixels
;   ldy #MESSAGE_TEXT_HEIGHT-1
;   sty DrawHeight
;   ldy #-1
;.Preload
;   iny
;   lda (SpritePtrs+6),y
;   pha
;   cpy DrawHeight
;   bcc .Preload
;
;   ; jump invocation
;   sta WSYNC
;   nop     ; 4 cycle delay required
;   nop
;   jmp Bank3_DrawColorTextJump     ; 1st text row
;
;   ; jsr invocation
;Bank3_DrawColorTextRet
;   ldy #HEIGHT-1
;   jsr Bank3_DrawColorText
; -----------------------------------------------------------------------------
;#if 0
;Bank3_DrawColorText SUBROUTINE
;    sty DrawHeight          ; 3 (3)
;
;    ; preload the stack with SpritePtrs[6] column of pixels
;
;    ldy #-1                 ; 2 (5)
;.Preload
;    iny                     ; 2 (2)
;    lda (SpritePtrs+6),y    ; 5 (7)
;    pha                     ; 3 (10)
;    iny                     ; 2 (12)
;    lda (SpritePtrs+6),y    ; 5 (17)
;    pha                     ; 3 (20)
;    cpy DrawHeight          ; 3 (23)
;    bcc .Preload            ; 3 (26)
;
;    sta WSYNC               ; align cycle count
;    ; remove extra element caused by preload
;    bne .AdjustStack        ; 2 (2)    3 (3)
;    nop                     ; 2 (4)
;    dc.b $24  ; bit         ; 3 (7)
;.AdjustStack
;    pla                     ;          4 (7)
;
;Bank3_DrawColorTextJump
;    SLEEP_54                ; 54 (61)   align cycle count
;
;.Loop
;    ;                    Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
;    ; ------------------------------------------------------------------------
;    ldy DrawHeight          ; 3 (64) (192)
;    lda (SpritePtrs),y      ; 5 (69) (207)
;    sta GRP0                ; 3 (72) (216)     D1     --      --     --
;    lda Bank3_TextPalette,y ; 4 (0)  (0)
;    ; -----------------------------------------------------------------------
;    ;                    Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
;    sta.w COLUP0            ; 4 (4)  (12)
;    sta COLUP1              ; 3 (7)  (21)
;
;    lda (SpritePtrs+2),y    ; 5 (12) (36)
;    sta GRP1                ; 3 (15) (45)      D1     D1      D2     --
;    lda (SpritePtrs+4),y    ; 5 (20) (60)
;    sta GRP0                ; 3 (23) (69)      D3     D1      D2     D2
;
;    lda (SpritePtrs+8),y    ; 5 (28) (84)
;    tax                     ; 2 (30) (90)
;    lda (SpritePtrs+10),y   ; 5 (35) (105)
;    tay                     ; 2 (37) (111)
;    pla                     ; 4 (41) (123)             !
;
;    sta GRP1                ; 3 (44) (132)     D3     D3      D4     D2!
;    stx GRP0                ; 3 (47) (141)     D5     D3!     D4     D4
;    sty GRP1                ; 3 (50) (150)     D5     D5      D6     D4!
;    sta GRP0                ; 3 (53) (159)     D4*    D5!     D6     D6
;    dec DrawHeight          ; 5 (58) (174)                            !
;    bpl .Loop               ; 3 (61) (183)
;                            ; 2 (60) (180)
;    ; flush delayed values
;    lda #0                  ; 2 (62) (186)
;    sta GRP0                ; 3 (65) (195)
;    sta GRP1                ; 3 (68) (204)
;    sta GRP0                ; 3 (71) (213)
;    rts                     ; 6 (1) (3)
;#endif
;#if 0
;Bank3_DrawColorText SUBROUTINE
;    sty DrawHeight          ; 3 (3)
;
;    ; preload the stack with SpritePtrs[6] column of pixels
;
;    ldy #-1                 ; 2 (5)
;.Preload
;    iny                     ; 2 (2)
;    lda (SpritePtrs+6),y    ; 5 (7)
;    pha                     ; 3 (10)
;    iny                     ; 2 (12)
;    lda (SpritePtrs+6),y    ; 5 (17)
;    pha                     ; 3 (20)
;    cpy DrawHeight          ; 3 (23)
;    bcc .Preload            ; 3 (26)
;
;    sta WSYNC               ; align cycle count
;    ; remove extra element caused by preload
;    bne .AdjustStack        ; 2 (2)    3 (3)
;    nop                     ; 2 (4)
;    dc.b $24  ; bit         ; 3 (7)
;.AdjustStack
;    pla                     ;          4 (7)
;
;Bank3_DrawColorTextJump
;    lda #<Bank3_TextPalette ; 2 (9)
;    sta PalettePtr          ; 3 (12)
;    lda #>Bank3_TextPalette ; 2 (14)
;    sta PalettePtr+1        ; 3 (17)
;    ldy DrawHeight          ; 3 (20)
;    sty TIM64T              ; 4 (24)
;
;    SLEEP_36                ; 36 (60)   align cycle count
;
;.Loop
;    ;                    Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
;    ; ------------------------------------------------------------------------
;    ldy INTIM               ; 4 (64) (192)
;    lda (SpritePtrs),y      ; 5 (69) (207)
;    sta GRP0                ; 3 (72) (216)     D1     --      --     --
;    lda (PalettePtr),y      ; 5 (1)  (3)
;    ; -----------------------------------------------------------------------
;    ;                    Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
;    sta COLUP0              ; 3 (4)  (12)
;    sta COLUP1              ; 3 (7)  (21)
;
;    lda (SpritePtrs+2),y    ; 5 (12) (36)
;    sta GRP1                ; 3 (15) (45)      D1     D1      D2     --
;    lda (SpritePtrs+4),y    ; 5 (20) (60)
;    sta GRP0                ; 3 (23) (69)      D3     D1      D2     D2
;
;    lda (SpritePtrs+8),y    ; 5 (28) (84)
;    tax                     ; 2 (30) (90)
;    lda (SpritePtrs+10),y   ; 5 (35) (105)
;    tay                     ; 2 (37) (111)
;
;    nop                     ; 2 (39) (117)
;    nop                     ; 2 (41) (123)
;
;    sta GRP1                ; 3 (44) (132)     D3     D3      D4     D2!
;    stx GRP0                ; 3 (47) (141)     D5     D3!     D4     D4
;    sty GRP1                ; 3 (50) (150)     D5     D5      D6     D4!
;    sta GRP0                ; 3 (53) (159)     D4*    D5!     D6     D6
;
;    ldy INTIM               ; 4 (57) (171)
;    bpl .Loop               ; 3 (60) (180)
;                            ; 2 (59) (177)
;
;    ; flush delayed values
;    lda #0                  ; 2 (61) (183)
;    sta GRP0                ; 3 (64) (192)
;    sta GRP1                ; 3 (67) (201)
;    sta GRP0                ; 3 (70) (210)
;
;    ldy DrawHeight
;.Pull
;    pla
;    dey
;    bpl .Pull
;
;    rts                     ; 6 (0) (0)
;#endif
;
; -----------------------------------------------------------------------------
; Desc:     Draws 6 medium spaced sprites in a row.
; Inputs:   Y register (sprite height - 1)
;           SpritePtrs (array of 6 pointers)
; Outputs:
; Notes:    VDEL0/1 must be off
;   Sprite cycle positions
;       GRP0 1: 30 cpu (90 tia)
;       GRP1 2: 35 cpu (105 tia)
;       GRP0 3: 40 cpu (120 tia)
;       GRP1 4: 46 cpu (138 tia)
;       GRP0 5: 51 cpu (153 tia)
;       GRP1 6: 56 cpu (168 tia)
;    
;   ldy #HEIGHT-1
;   jsr Bank3_Draw6Sprites
; -----------------------------------------------------------------------------
Bank3_Draw6Sprites SUBROUTINE
.Loop
    sta WSYNC
    SLEEP 6                 ; 6 (6)     display cycle
    lda (SpritePtrs),y      ; 5 (11)
    sta GRP0                ; 3 (14)    [30-32]
    lda (SpritePtrs+2),y    ; 5 (19]
    sta GRP1                ; 3 (22)    [35-37]
    lda (SpritePtrs+6),y    ; 5 (27)
    tax                     ; 2 (29)
    lda (SpritePtrs+4),y    ; 5 (34)
    nop                     ; 2 (36)
    sta GRP0                ; 3 (39)    [40-44]
    nop                     ; 2 (41)
    stx GRP1                ; 3 (44)    [46-49]
    lda (SpritePtrs+8),y    ; 5 (49]
    sta GRP0                ; 3 (51)    [51-54]
    lda (SpritePtrs+10),y   ; 5 (56]
    sta GRP1                ; 3 (59)    [56-60]
    dey                     ; 2 (61)
    bpl .Loop               ; 3 (64)
                            ; 2 (63)
    rts                     ; 6 (69)

    PAGE_BOUNDARY_CHECK "Bank3_Draw* kernels crossed a page boundary"

    INCLUDE_MENU_SUBS 3

    include "bank3/gfx/help.asm"        ; must reside within a single page
    include "../atarilib/lib/animation.asm"

#if 0
; -----------------------------------------------------------------------------
; Desc:     Clears and initializes the queue.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
#if 1
AnimationClear SUBROUTINE
    ; erase elements
    lda #ANIM_ID_NONE
    sta AnimID
    sta AnimID+1
    sta AnimPosition
    sta AnimPosition+1
    sta AnimConfig
    sta AnimConfig+1
    rts
#else
AnimationClear SUBROUTINE
    lda #ANIM_ID_NONE
    ldx #ANIM_QUEUE_LEN-1
.Loop
    sta AnimID,x
    sta AnimPosition,x
    sta AnimConfig,x
    dex
    bpl .Loop
    rts
#endif

; -----------------------------------------------------------------------------
; Desc:     Add animation clip to the play queue.
; Inputs:   Bank3_AddID (animation id)
;           Bank3_AddPos (row, column) ($ff selects default position)
; Ouputs:
; -----------------------------------------------------------------------------
AnimationAdd SUBROUTINE
    ; search for an empty slot
    ldx #0
    lda AnimID
    beq .Found
    inx
    lda AnimID+1
    beq .Found
    jmp .Return     ; full queue

    ; store in the queue
.Found
    ; copy animation ID
    ldy Bank3_AddID
    sty AnimID,x

    ; get a pointer to the animation sequence record
    lda Bank3_Sequences,y
    sta Bank3_SeqPtr
    lda #>Bank3_Sequences
    sta Bank3_SeqPtr+1

    ; copy Bank3_SeqPtr->Position
    ldy #0
    lda (Bank3_SeqPtr),y
    sta AnimPosition,x

    ; copy Bank3_SeqPtr->Config
    ldy #1
    lda (Bank3_SeqPtr),y
    sta AnimConfig,x

    ; override default position
    lda Bank3_AddPos
    cmp #$ff
    beq .Return
    sta AnimPosition,x

.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Advance the animation frame.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
AnimationTick SUBROUTINE
    ; for each queue element advance the frame
    lda AnimID
    beq .Next1

    lda AnimPosition
    DEC_BITS ANIM_FRAME_MASK, AnimConfig

    ; check for remaining frames and remove first element on zero
    and #ANIM_FRAME_MASK
    bne .Next1

    ; erase element
    lda #ANIM_ID_NONE
    sta AnimID
    sta AnimPosition
    sta AnimConfig

.Next1
    lda AnimID+1
    beq .Return
    DEC_BITS ANIM_FRAME_MASK, AnimConfig+1

    ; check for remaining frames and remove first element on zero
    and #ANIM_FRAME_MASK
    bne .Return

    ; erase element
    lda #ANIM_ID_NONE
    sta AnimID+1
    sta AnimPosition+1
    sta AnimConfig+1

.Return
    rts
#endif

Bank3_SetupIndexes SUBROUTINE
    ; set up an index into SuitRuleTable and RankRuleTable
    lda #0                          ; 2 (2)
    ldy CurrState                   ; 3 (5)
    bpl .Skip                       ; 2 (7)
    ora #RULE_HOLE_MASK             ; 2 (9)
.Skip
    ldy PlayerNumCards+DEALER_IDX   ; 4 (13)
    ora Bank3_NumCardsFlag,y        ; 4 (17)
    ora #DEALER_IDX                 ; 2 (19)
    sta HoleIdx                     ; 3 (22)

    ; search for any card animations
    ldx #ANIM_QUEUE_LEN
.Search
    lda AnimID-1,x
    cmp #ANIM_ID_FLIP_CARD
    bne .Next
    stx AnimIdx
    lda AnimPosition-1,x    ; 11111xxx
    lsr
    lsr
    lsr
    sta AnimRow             ; xxx11112
    jmp .Found
.Next
    dex
    bne .Search
    lda #$ff
    sta AnimRow
    stx AnimIdx
.Found
	rts

; -----------------------------------------------------------------------------
; Desc:     Resets sprites to blank state. This is the fixed time part of
;           card initialization.
; Inputs:   X register (current hand)
; Ouputs:
; -----------------------------------------------------------------------------
Bank3_ResetCardSprites SUBROUTINE
#if 0
    ; assign card colors (active/inactive, dealer is always active)
    lda PlyrIdx
    asl
    asl
    ora CurrPlayer
    tay
    lda Bank3_ColorMatrix,y
    sta COLUP0
    sta COLUP1
#endif

#if 0
    lda #>BlankCard
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
#endif
    rts

; -----------------------------------------------------------------------------
; Desc:     Assigns the hand's card sprites. Ranks are loaded into SpritePtrs
;           and suits loaded on the stack .
; Inputs:   PlyrIdx (rendering player index)
; Ouputs:
; Notes:    Must be paired with Bank3_RenderCardSprites.
;
; Card Color Matrix:
; Assign the card colors for active and inactive highlighting.
;
;      Curr       CurrHand
;     Player    00   01   10
;             .--------------.
;         00  |  0 |  1 |  0 |
;         01  |  1 |  0 |  1 |
;         10  |  0 |  1 |  0 |
;             '--------------'
;
;             |     CurrPlayer
;      Hand   | Player0 Player1 Dealer
;   .---------|------------------------.
;   | Player0 |   W    |   G   |   W   |
;   | Player1 |   G    |   W   |   G   |  Colors: W=white, G=gray
;   | Dealer  |   W    |   W   |   W   |
;   '----------------------------------'
;
; Cards:       0       1       2       3       4       5
;            ____    ____    ____    ____    ____    ____
;   Ranks   |    |  |    |  |    |  |    |  |    |  |    |
;           |____|  |____|  |____|  |____|  |____|  |____|
;            ____    ____    ____    ____    ____    ____
;   Gap     |____|  |____|  |____|  |____|  |____|  |____|
;            ____    ____    ____    ____    ____    ____
;   Suits   |    |  |    |  |    |  |    |  |    |  |    |
;           |____|  |____|  |____|  |____|  |____|  |____|
;
; Assign these values:
;   1. card color (active/inactive)
;   2. suit and rank graphics
;   3. hole card graphics
;   4. card flip animation graphics
; -----------------------------------------------------------------------------
RENDER_DEBUG = 0
#if 1
Bank3_SetupCardSprites SUBROUTINE       ; 6 (6)
    lda #>BlankCard                     ; 2 (8)
    sta SpritePtrs+1                    ; 3 (11)
    sta SpritePtrs+3                    ; 3 (14)
    sta SpritePtrs+5                    ; 3 (17)
    sta SpritePtrs+7                    ; 3 (20)
    sta SpritePtrs+9                    ; 3 (23)
    sta SpritePtrs+11                   ; 3 (26)

    ; set up an index into PlayerCards
    ldy PlyrIdx                         ; 3 (29)
    ldx Bank3_Mult6+1,y                 ; 4 (33)
    stx CardIdx                         ; 3 (36)

    ; set up the default graphics pointers
    clc                                 ; 2 (38)
    ldy #NUM_VISIBLE_CARDS-1            ; 2 (40)    current card index
.Loop
    lda PlayerCards-1,x                 ; 4 (4)
    bne .ValidCard                      ; 3 (7)

    ; blank card for rank and suit
    ldx Bank3_Mult2,y                   ; 4 [4]
    lda #<BlankCard                     ; 2 [6]
    sta SpritePtrs,x                    ; 4 [10]
    jmp .Next                           ; 3 [13]

.ValidCard
    ; assign rank graphics: rank graphics go to SpritePtrs
    and #CARD_RANK_MASK                 ; 2 (9)
    tax                                 ; 2 (11)
    lda Bank3_CardRankGfx,x             ; 4 (15)    get a LSB pointer to graphics
    ldx Bank3_Mult2,y                   ; 4 (19)
    sta SpritePtrs,x                    ; 4 (23)    ranks put in SpritePtrs

    ; assign suit: suit graphics to the stack
    ldx CardIdx                         ; 3 (26)
    lda PlayerCards-1,x                 ; 4 (30)
    and #CARD_SUIT_MASK                 ; 2 (32)
    lsr                                 ; 2 (34)
    lsr                                 ; 2 (36)
    lsr                                 ; 2 (38)
    lsr                                 ; 2 (40)
    tax                                 ; 2 (42)
    lda Bank3_CardSuitGfx,x             ; 4 (46)    get a LSB pointer to graphics
.Next
    pha                                 ; 3 (49)

    dec CardIdx                         ; 5 (54)
    ldx CardIdx                         ; 3 (57)

    dey                                 ; 2 (59)
    bpl .Loop                           ; 3 (62)

    ; determine if the dealer's hole card is face up or face down
    ldx PlyrIdx                         ; 3 (3)
    cpx #DEALER_IDX                     ; 2 (5)
    bne .ShowCard                       ; 2 (7)
    ldy HoleIdx                         ; 3 (10)
    lda Bank3_SuitRuleTable,y           ; 4 (14)
    beq .ShowCard                       ; 2 (16)

    ; card is face down (i.e. static). update suit and rank graphics
    tsx                                 ; 2 [2]
    sta 2,x                             ; 4 [6]
    ; update rank graphics
    tya                                 ; 2 [8]
    eor #$0f    ; invert index          ; 2 [10]
    tay                                 ; 2 [12]
    lda Bank3_RankRuleTable,y           ; 4 [16]
    lda #<RankBack                      ; 2 [18]
    sta SpritePtrs+2                    ; 3 [21]

.StaticGap
    ; static gap graphics
    ldx PlyrIdx                         ; 3 [24]
    lda PlayerNumCards,x                ; 4 [28]
    clc                                 ; 2 [30]
    adc #Bank3_GapStatic-Bank3_GapAnim  ; 2 [32]
    sta GapIdx                          ; 3 [35]
    jmp .Continue                       ; 3 [38]

.ShowCard
    ; check if there's an animating card
    cpx AnimRow                         ; 3 (19)
    bne .StaticGap                      ; 2 (21)
    ldx AnimIdx                         ; 3 (24)
    beq .StaticGap                      ; 2 (26) 

    ; get the frame number
    lda AnimConfig-1,x                  ; 4 (30)
    and #ANIM_FRAME_MASK                ; 2 (32)
    tay                                 ; 2 (34)

    ; get the column
    lda AnimPosition-1,x                ; 4 (38)
    and #ANIM_COL_MASK                  ; 2 (40)
    pha                                 ; 3 (43)    stack var = column
    asl                                 ; 2 (45)
    tax                                 ; 2 (47)

    ; rank: update SpritePtrs
    lda Bank3_FlipRankGfxLo,y           ; 4 (51)
    sta SpritePtrs,x                    ; 4 (55)
    lda Bank3_FlipRankGfxHi,y           ; 4 (59)
    sta SpritePtrs+1,x                  ; 4 (63)

    ; animating gap graphics is in sync with card flip animation
    ldx PlyrIdx                         ; 3 (66)
    lda Bank3_Mult11-1,y                ; 4 (70)    size of row = 11
    sec                                 ; 2 (72)
    sbc #1                              ; 2 (74)    A = A - 1
    clc                                 ; 2 (76)
    adc PlayerNumCards,x                ; 4 (80)     A = A + NumCards
    sta GapIdx                          ; 3 (83)

    ; suit: update values on stack
    tsx                                 ; 2 (85)
    txa                                 ; 2 (87)
    clc                                 ; 2 (89)
    adc $1,x                            ; 4 (93)    add column number
    tax                                 ; 2 (95)
    lda Bank3_Bank3_FlipSuitGfxLo,y     ; 4 (99)
    sta $2,x                            ; 4 (103)
    pla                                 ; 4 (107)

.Continue
    ; the stack now looks like this:
    ;  ___ ___ ___.___.___.___.___.___ ___.___
    ; |   |col| 0   1   2   3   4   5 | x   x |
    ; |___|___|___.___.___.___.___.___|___.___|
    ;       ^         graphics      ^   return
    ;       |         pointers      |   address
    ;       sp                     sp+6
    ;
    ; restore the stack pointer for rts
    tsx                                 ; 2 (109)
    txa                                 ; 2 (111)
    clc                                 ; 2 (113)
    adc #6                              ; 2 (115)
    tax                                 ; 2 (117)
    txs                                 ; 2 (119)

    rts                                 ; 6 (125)
    ; total max cycles: 536 = 40 + (62*6)-1 + 125

#else
Bank3_SetupCardSprites SUBROUTINE       ; 6 (6)
    IF RENDER_DEBUG == 1
    lda #$40        ; red
    sta COLUBK
    ENDIF

    ; assign high byte
    lda #>BlankCard                     ; 2 (8)
    sta SpritePtrs+1                    ; 3 (11)
    sta SpritePtrs+3                    ; 3 (14)
    sta SpritePtrs+5                    ; 3 (17)
    sta SpritePtrs+7                    ; 3 (20)
    sta SpritePtrs+9                    ; 3 (23)
    sta SpritePtrs+11                   ; 3 (26)

    ; set up the end index into PlayerCards
    ldy PlyrIdx                         ; 3 (29)
    ldx Bank3_Mult6+1,y                 ; 4 (33)
    stx CardIdx                         ; 3 (36)

    ; set up the default graphics pointers
    clc                                 ; 2 (38)
    ldy #NUM_VISIBLE_CARDS-1            ; 2 (40)    current card index
.Assign
    ; assign rank
    lda PlayerCards-1,x                 ; 4 (4)
    pha                                 ; 3 (7)     stack temp = card
    and #CARD_RANK_MASK                 ; 2 (9)
    tax                                 ; 2 (11)
    lda Bank3_CardRankGfx,x             ; 4 (15)    get the graphics LSB
    ldx Bank3_Mult2,y                   ; 4 (19)
    sta SpritePtrs,x                    ; 4 (23)    ranks put in SpritePtrs

    ; assign suit
    pla                                 ; 4 (27)    A = card
    bne .NotEmpty                       ; 3 (30)  
    lda #<BlankCard                     ; 2 [2]
    jmp .SaveSuit                       ; 3 [5]
.NotEmpty
    and #CARD_SUIT_MASK                 ; 2 (32)
    lsr                                 ; 2 (34)
    lsr                                 ; 2 (36)
    lsr                                 ; 2 (38)
    lsr                                 ; 2 (40)
    tax                                 ; 2 (42)
    lda Bank3_CardSuitGfx,x             ; 4 (46)    get the graphics LSB
.SaveSuit
    pha                                 ; 3 (49)

    ; decrement ending and current card indexes
    dec CardIdx                         ; 5 (54)
    ldx CardIdx                         ; 3 (57)

    dey                                 ; 2 (59)
    bpl .Assign                         ; 3 (62)

    IF RENDER_DEBUG == 1
    lda #$f8
    sta COLUBK      ; light brown
    ENDIF

    ; decide if the hole card is shown
    ldx PlyrIdx                         ; 3 (3)
    cpx #DEALER_IDX                     ; 2 (5)
    bne .ShowCard                       ; 2 (7)
    ldy HoleIdx                         ; 3 (10)
    lda Bank3_SuitRuleTable,y           ; 4 (14)
    beq .ShowCard                       ; 2 (16)

    ; card is facing down. preload graphics to the stack
    tsx                                 ; 2 [2]
    sta 2,x                             ; 4 [6]
    ; update rank graphics
    tya                                 ; 2 [8]
    eor #$0f    ; invert index          ; 2 [10]
    tay                                 ; 2 [12]
    lda Bank3_RankRuleTable,y           ; 4 [16]
    sta SpritePtrs+2                    ; 3 [19]
    jmp .Continue                       ; 3 [22]

.ShowCard
    ; static gap graphics
    ldx PlyrIdx                         ; 3 (19)
    lda PlayerNumCards,x                ; 4 (23)
    clc                                 ; 2 (25)
    adc #Bank3_GapStatic-Bank3_GapAnim  ; 2 (27)
    sta GapIdx                          ; 3 (30)

    ; animate the card flip (AnimRow contains Player ID)
    ldx PlyrIdx                         ; 3 (33)
    cpx AnimRow                         ; 3 (36)
    bne .Continue                       ; 2 (38)
    ldx AnimIdx                         ; 3 (41)
    beq .Continue                       ; 2 (43) 

    ; get the frame number
    lda AnimConfig-1,x                  ; 4 (47)
    and #ANIM_FRAME_MASK                ; 2 (49)
    tay                                 ; 2 (51)

    ; get the column
    lda AnimPosition-1,x                ; 4 (55)
    and #ANIM_COL_MASK                  ; 2 (57)
    pha                                 ; 3 (60)    stack var = column
    asl                                 ; 2 (62)
    tax                                 ; 2 (64)

    ; rank: update SpritePtrs
    lda Bank3_FlipRankGfxLo,y           ; 4 (68)
    sta SpritePtrs,x                    ; 4 (72)
    lda Bank3_FlipRankGfxHi,y           ; 4 (76)
    sta SpritePtrs+1,x                  ; 4 (80)

    ldx PlyrIdx                         ; 3 (83)
    lda Bank3_Mult11-1,y                ; 4 (87)
    sec                                 ; 2 (89)
    sbc #1                              ; 2 (91)    A = A - 1
    clc                                 ; 2 (93)
    adc PlayerNumCards,x                ; 4 (97)     A = A + NumCards
    sta GapIdx                          ; 3 (100)

    ; suit: update values on stack
    tsx                                 ; 2 (102)
    txa                                 ; 2 (104)
    clc                                 ; 2 (106)
    adc $1,x                            ; 4 (110)    add column number
    tax                                 ; 2 (112)
    lda Bank3_Bank3_FlipSuitGfxLo,y     ; 4 (116)
    sta $2,x                            ; 4 (120)
    pla                                 ; 4 (124)

.Continue
    ; the stack now looks like this:
    ;  ___ ___ ___.___.___.___.___.___ ___.___
    ; |   |col| 0   1   2   3   4   5 | x   x |
    ; |___|___|___.___.___.___.___.___|___.___|
    ;       ^         graphics      ^   return
    ;       |         pointers      |   address
    ;       sp                     sp+6
    ;
    ; restore the stack pointer for rts
    tsx                                 ; 2 (126)
    txa                                 ; 2 (128)
    clc                                 ; 2 (130)
    adc #6                              ; 2 (132)
    tax                                 ; 2 (134)
    txs                                 ; 2 (136)

    rts                                 ; 6 (142)
    ; total max cycles: 553 = 40 + (62*6)-1 + 142
#endif

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $900, FILLER_CHAR
    RORG BANK3_RORG + $900

    PAGE_BOUNDARY_SET

; -----------------------------------------------------------------------------
; Desc:     Draws a row of cards.
; Inputs:   X register (rendering player index)
;           PlyrIdx (rendering player index)
; Ouputs:
; Notes:    Must be paired with Bank3_SetupCardSprites. Requires VDEL on.
;
; GRP writes must happen inside time intervals specified below.
;
;                        43______GRP0______50    54____GRP0______61
;           __         __/        __        \__/        __        \__
;          |1 |       |2 |       |3 |       |4 |       |5 |       |6 |
;          |__|       |__|       |__|       |__|       |__|       |__|
;              \________________/    \________________/
;             38      GRP1     45    48     GRP1      56
;
;          34-38      40-43      45-48      50-54      56-59      61-64
;         104-112    120-128    136-144    152-160    168-176    184-192
; 0         __         __         __         __         __         __        76
; |--------|__|-------|__|-------|__|-------|__|-------|__|-------|__|--------|
; 0   ^           ^          ^          ^          ^                        228
;     |           |          |          |          |
;  (1,2,3)       (4)        (5)        (6)        (7)
; GRP 0,1,0      GRP1       GRP0       GRP1       GRP0
;
; GRP writes must occur between these cycle intervals:
;   GRP 0,1,0 (writes 1,2,3)    between  0 - 34 cpu (  0 - 104 tia)
;   GRP1 (write 4)              between 38 - 45 cpu (112 - 136 tia)
;   GRP0 (write 5)              between 43 - 50 cpu (128 - 152 tia)
;   GRP1 (write 6)              between 48 - 56 cpu (144 - 168 tia)
;   GRP0 (write 7)              between 54 - 61 cpu (160 - 184 tia)
; -----------------------------------------------------------------------------
Bank3_RenderCardSprites SUBROUTINE
    IF RENDER_DEBUG == 1
    lda #$80
    sta COLUBK      ; blue
    ENDIF

    ; adjust the stack to begin on the start of the sprite pointers
    tsx                     ; 2 (2)     (6)
    txa                     ; 2 (4)     (12)
    sec                     ; 2 (6)     (18)
    sbc #6                  ; 2 (8)     (24)
    tax                     ; 2 (10)    (30)
    txs                     ; 2 (12)    (36)

    ; pre-cache some gap graphics
    ldx GapIdx              ; 3 (15)    (45)
    ldy Bank3_GapAnim,x     ; 4 (19)    (57)
    lda Bank3_GapGfx,y      ; 4 (23)    (69)
    sta GapLastElem         ; 3 (26)    (78)    last element
    ldy Bank3_GapAnim+5,x   ; 4 (30)    (90)
    ldx Bank3_GapGfx,y      ; 4 (34)    (102)   first element

#if PIP_COLORS
    ; color test
    lda #2
    sta ENABL
    lda #%00110000
    sta CTRLPF
    lda #%01100000
    sta PF0
    lda #BG_COLOR           ; 2 (2)
    sta COLUPF              ; 3 (5)
#endif

    ; draw top half of the card (rank)
    ldy #RANK_HEIGHT-1      ; 2 (36)    (108)
.Rank
    ;                         Explicit write ^      Implicit write >        Display !
    ;
    ;                         CPU       TIA     GRP0 -> GRP0A   GRP1 -> GRP1A
    ; -------------------------------------------------------------------------------
    lda (SpritePtrs),y      ; 5 (67)    (201)
    sta WSYNC               ; 3 (70)    (210)   
    ; -----------
    sta GRP0                ; 3 (3)     (9)     ^D1      *       *       *
    lda (SpritePtrs+2),y    ; 5 (8)     (24)
    sta GRP1                ; 3 (11)    (33)     D1     >D1     ^D2      *
    lda (SpritePtrs+4),y    ; 5 (16)    (48)
    sta GRP0                ; 3 (19)    (57)    ^D3      D1      D2     >D2

#if PIP_COLORS
    lda #$42                ; 2 (21)    (63)
    sta COLUPF              ; 3 (24)    (72)
    nop                     ; 2 (26)    (78)
    nop                     ; 2 (28)    (84)
    nop                     ; 2 (30)    (90)
#else
    bit $0                  ; 3 (22)    (66)
    nop                     ; 2 (24)    (72)
    nop                     ; 2 (26)    (78)
    nop                     ; 2 (28)    (84)
    nop                     ; 2 (30)    (90)
#endif

    lda (SpritePtrs+6),y    ; 5 (35)    (105)             !
    sta GRP1                ; 3 (38)    (114)    D3     >D3     ^D4      D2
    lda (SpritePtrs+8),y    ; 5 (43)    (129)                             !
    sta GRP0                ; 3 (46)    (138)   ^D5      D3!     D4     >D4
    lda (SpritePtrs+10),y   ; 5 (51)    (153)                             !
    sta GRP1                ; 3 (54)    (162)    D5     >D5!    ^D6      D4
    sta GRP0                ; 3 (57)    (171)   ^D6      D5      D6     >D6!

    dey                     ; 2 (59)    (177)
    bpl .Rank               ; 3 (62)    (186)
                            ; 2 (61)    (183)
    IF RENDER_DEBUG == 1
    lda #$40
    sta COLUBK      ; red
    ENDIF

    ; Suit graphics pointers are popped off the stack into
    ; SpritePtrs by interlacing the assignments with the
    ; gap rendering.

    ; updating the suit graphics
    pla                     ; 4 (65)    (195)
    sta SpritePtrs          ; 3 (68)    (204)

    ; ---- line 1 ----
    ; draw gap graphics
    stx GRP0                ; 3 (71)    (213)     ^D1      *       *       *

    ldx GapIdx              ; 3 (74)    (222)
    ldy Bank3_GapAnim+4,x   ; 4 (2)     (6)
    lda Bank3_GapGfx,y      ; 4 (6)     (18)
    ldy Bank3_GapAnim+3,x   ; 4 (10)    (30)
    sta GRP1                ; 3 (13)    (39)       D1     >D1     ^D2      *

    lda Bank3_GapGfx,y      ; 4 (17)    (51)
    ldy Bank3_GapAnim+2,x   ; 4 (21)    (63)
    sta GRP0                ; 3 (24)    (72)      ^D3      D1      D2     >D2

    bit $0                  ; 3 (27)    (81)

    lda Bank3_GapGfx,y      ; 4 (31)    (93)
    ldy Bank3_GapAnim+1,x   ; 4 (35)    (105)               !
    sta GRP1                ; 3 (38)    (114)      D3     >D3     ^D4      D2

    lda Bank3_GapGfx,y      ; 4 (42)    (126)                               !
    sta GRP0                ; 3 (45)    (135)     ^D5      D3!     D4     >D4

    lda GapLastElem         ; 3 (48)    (144)
    sta GRP1                ; 3 (51)    (153)      D5     >D5     ^D6      D4!
    sta GRP0                ; 3 (54)    (162)      D5     ^D7      D6     >D6

    ; updating the suit graphics
    pla                     ; 4 (58)    (174)               !
    sta SpritePtrs+2        ; 3 (61)    (183)                                !
    pla                     ; 4 (65)    (195)
    sta SpritePtrs+4        ; 3 (68)    (204)

    ; ---- line 2 ----
    ; prepare gap graphics
    ldy Bank3_GapAnim+5,x   ; 4 (72)    (216)
    lda Bank3_GapGfx,y      ; 4 (0)     (0)
    ; -----------
    sta GRP0                ; 3 (3)     (9)
    ldy Bank3_GapAnim+4,x   ; 4 (7)     (21)
    lda Bank3_GapGfx,y      ; 4 (11)    (33)
    sta GRP1                ; 3 (14)    (42)       D1     >D1     ^D2      *
    ldy Bank3_GapAnim+3,x   ; 4 (18)    (54)
    lda Bank3_GapGfx,y      ; 4 (22)    (66)
    sta GRP0                ; 3 (25)    (75)      ^D3      D1      D2     >D2

    ldy Bank3_GapAnim+2,x   ; 4 (29)    (87)
    lda Bank3_GapGfx,y      ; 4 (33)    (99)                !
    ldy Bank3_GapAnim+1,x   ; 4 (37)    (111)
    sta GRP1                ; 3 (40)    (120)      D3     >D3     ^D4      D2!

    lda Bank3_GapGfx,y      ; 4 (44)    (132)
    sta GRP0                ; 3 (47)    (141)     ^D5      D3!     D4     >D4

    lda GapLastElem         ; 3 (50)    (150)                               !
    sta GRP1                ; 3 (53)    (159)      D5     >D5     ^D6      D4
    sta GRP0                ; 3 (56)    (168)      D5     ^D7!     D6     >D6

    pla                     ; 4 (60)    (180)
    sta SpritePtrs+6        ; 3 (63)    (189)                               !
    pla                     ; 4 (67)    (201)
    sta SpritePtrs+8        ; 3 (70)    (210)
    pla                     ; 4 (74)    (222)
    sta SpritePtrs+10       ; 3 (1)     (3)

    IF RENDER_DEBUG == 1
    lda #$80
    sta COLUBK      ; blue
    ENDIF

    ; draw bottom half of the card (suit)
    ldy #SUIT_HEIGHT-1      ; 2 (3)     (9)
    bit $0                  ; 3 (6)     (18)    align cycles for 1st iteration
.Suit
    ;                         CPU       TIA     GRP0 -> GRP0A   GRP1 -> GRP1A
    ; -------------------------------------------------------------------------------
    lda (SpritePtrs),y      ; 5 (12)    (36)
    sta GRP0                ; 3 (15)    (45)    ^D1      *       *       *
    lda (SpritePtrs+2),y    ; 5 (20)    (60)
    sta GRP1                ; 3 (23)    (69)     D1     >D1     ^D2      *
    lda (SpritePtrs+4),y    ; 5 (28)    (84)
    sta GRP0                ; 3 (31)    (93)    ^D3      D1      D2     >D2

    lda (SpritePtrs+6),y    ; 5 (36)    (108)             !
    sta GRP1                ; 3 (39)    (117)    D3     >D3     ^D4      D2!
    lda (SpritePtrs+8),y    ; 5 (44)    (132)
    sta GRP0                ; 3 (47)    (141)   ^D5      D3!     D4     >D4
    lda (SpritePtrs+10),y   ; 5 (52)    (156)                             !
    sta GRP1                ; 3 (55)    (165)    D5     >D5     ^D6      D4
    sta GRP0                ; 3 (58)    (174)   ^D6      D5!     D6     >D6
    sta WSYNC               ; 3 (61)    (183)                             !
    ; -----------
    nop                     ; 2 (2)     (6)     align cycles
    dey                     ; 2 (4)     (12)
    bpl .Suit               ; 3 (7)     (21)

    IF RENDER_DEBUG == 1
    lda #BG_COLOR
    sta COLUBK      ; dark green
    ENDIF

    lda #0                  ; 2 (2)
    sta GRP0                ; 3 (5)
    sta GRP1                ; 3 (8)

#if PIP_COLORS
    ; color test
    sta ENABL               ; 3 (3)
    sta PF0                 ; 3 (3)
    lda #BG_COLOR           ; 2 (2)
    sta COLUPF              ; 3 (5)
#endif

    rts                     ; 6 (14)        884 cpu cycles (11.6 lines)

    PAGE_BOUNDARY_CHECK "Bank3_RenderCardSprites crossed a page boundary"

; -----------------------------------------------------------------------------
; Desc:     Compute the Log2 of A. (Returns highest bit set.)
; Inputs:   A register (value)
; Ouputs:   X register (result)
;           1-8 when A>0, 0 otherwise.
; Notes:
;   Max cycles: 67 = 7 + (7 x 7 loops) - 1 + 12 (jsr & rts)
; -----------------------------------------------------------------------------
Bank3_Log2 SUBROUTINE   ; 6 (6)
    ldx #0              ; 3 (9)
    tay                 ; 2 (11)
    cmp #0              ; 2 (13)
    beq .Return         ; 2 (15)
.Loop
    inx                 ; 2 (2)
    lsr                 ; 2 (4)
    bne .Loop           ; 3 (7)
    tya                 ; 2 (2)
.Return
    rts                 ; 6 (6)

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $a00, FILLER_CHAR
    RORG BANK3_RORG + $a00

    PAGE_BOUNDARY_SET
    include "bank3/gfx/options.asm"
    include "bank3/gfx/play.asm"
    PAGE_BOUNDARY_CHECK "Bank3 sprites crossed a page boundary"

    INCLUDE_SPRITE_OPTIONS 3
    INCLUDE_SPRITE_COLORS 3

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $b00, FILLER_CHAR
    RORG BANK3_RORG + $b00

    PAGE_BOUNDARY_SET
    include "bank3/gfx/cards.asm"
    PAGE_BOUNDARY_CHECK "Bank3 cards.asm page boundary crossed"

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $c00, FILLER_CHAR
    RORG BANK3_RORG + $c00

    PAGE_BOUNDARY_SET
    include "bank3/gfx/betting.asm"    ; must reside within a single page
    PAGE_BOUNDARY_CHECK "Bank3 betting.asm page boundary crossed"

; indexed by PlayerFlags
Bank3_ResultMessagesLSB
    ; FLAGS_LOST
    dc.b <Bank3_DealerWinsSprite0, <Bank3_DealerWinsSprite1, <Bank3_DealerWinsSprite2
    dc.b <Bank3_DealerWinsSprite3, <Bank3_DealerWinsSprite4, <Bank3_DealerWinsSprite5
    ; FLAGS_BUST
    dc.b <Bank3_BustSprite0, <Bank3_BustSprite1, <Bank3_BustSprite2
    dc.b <Bank3_BustSprite3, <Bank3_BustSprite4, <Bank3_BustSprite5
    ; FLAGS_21
    dc.b <Bank3_WinnerSprite0, <Bank3_WinnerSprite1, <Bank3_WinnerSprite2
    dc.b <Bank3_WinnerSprite3, <Bank3_WinnerSprite4, <Bank3_WinnerSprite5
    ; FLAGS_PUSH
    dc.b <Bank3_PushSprite0, <Bank3_PushSprite1, <Bank3_PushSprite2
    dc.b <Bank3_PushSprite3, <Bank3_PushSprite4, <Bank3_PushSprite5
    ; FLAGS_WIN
    dc.b <Bank3_WinnerSprite0, <Bank3_WinnerSprite1, <Bank3_WinnerSprite2
    dc.b <Bank3_WinnerSprite3, <Bank3_WinnerSprite4, <Bank3_WinnerSprite5
    ; FLAGS_BLACKJACK
    dc.b <Bank3_BJackSprite0, <Bank3_BJackSprite1, <Bank3_BJackSprite2
    dc.b <Bank3_BJackSprite3, <Bank3_BJackSprite4, <Bank3_BJackSprite5

; indexed by Bank3_GameStateFlags
Bank3_PromptMessagesLSB
    ds.b 4, <Bank3_BlankStr                                                ; 0
    dc.b <Bank3_BetStr0, <Bank3_BetStr1, <Bank3_BetStr2, <Bank3_BetStr3             ; 1
    dc.b <Bank3_HitStr0, <Bank3_HitStr1, <Bank3_HitStr2, <Bank3_HitStr3             ; 2
    dc.b <Bank3_StayStr0, <Bank3_StayStr1, <Bank3_StayStr2, <Bank3_StayStr3         ; 3
    dc.b <Bank3_SurrenderStr0, <Bank3_SurrenderStr1, <Bank3_SurrenderStr2, <Bank3_SurrenderStr3         ; 4
    dc.b <Bank3_DDownStr0, <Bank3_DDownStr1, <Bank3_DDownStr2, <Bank3_DDownStr3     ; 5
    dc.b <Bank3_SplitStr0, <Bank3_SplitStr1, <Bank3_SplitStr2, <Bank3_SplitStr3     ; 6
    dc.b <Bank3_InsuranceStr0, <Bank3_InsuranceStr1, <Bank3_InsuranceStr2, <Bank3_InsuranceStr3             ; 7

    INCLUDE_POSITIONING_SUBS 3

; ----------------------------------------------------------------------------
    ORG BANK3_ORG + $d00
    RORG BANK3_RORG + $d00

    include "bank3/gen/prompts-48.sp"  ; must not cross a page boundary

; Map rank to a card graphic
Bank3_CardRankGfx
    dc.b <BlankCard
    dc.b <AceSprite,    <Bank3_Rank2, <Bank3_Rank3
    dc.b <Bank3_Rank4,  <Bank3_Rank5, <Bank3_Rank6
    dc.b <Bank3_Rank7,  <Bank3_Rank8, <Bank3_Rank9
    dc.b <Bank3_Rank10, <JackSprite,  <QueenSprite
    dc.b <KingSprite,   <BlankCard,   <BlankCard

; Map suit to a card graphic
Bank3_CardSuitGfx
    dc.b <DiamondSprite, <ClubSprite, <HeartSprite, <SpadeSprite

; Animation data:
;   Sequence record:
;      Position    1 byte
;          Bits 3-7:    row
;          Bits 0-2:    column
;      State:     1 byte
;          Bits 5-7:    number of loops
;          Bits 0-4:    number of frames (disables the animation)
;   Sequences array[]:
;      Pointer -> Sequence
;      Pointer -> Sequence
;      Pointer -> Sequence
;      ...
Bank3_FlipRankSeq
    dc.b [0 << 3] | 2   ; row, column
    dc.b [1 << 5] | 4   ; loops, frames
Bank3_FlipRankGfxLo
    dc.b 0, <Bank3_FlipRank3, <Bank3_FlipRank2, <Bank3_FlipRank1, <Bank3_FlipRank0
Bank3_FlipRankGfxHi
    dc.b 0, >Bank3_FlipRank3, >Bank3_FlipRank2, >Bank3_FlipRank1, >Bank3_FlipRank0

;Bank3_Bank3_FlipSuitSeq
;    dc.b [0 << 3] | 2
;    dc.b [1 << 5] | 4
Bank3_Bank3_FlipSuitGfxLo
    dc.b 0, <Bank3_FlipSuit3, <Bank3_FlipSuit2, <Bank3_FlipSuit1, <Bank3_FlipSuit0

ANIM_ID_NONE                = 0
ANIM_ID_FLIP_CARD           = 1
Bank3_Sequences
    dc.b 0                  ; ANIM_ID_NONE
    dc.b <Bank3_FlipRankSeq ; ANIM_ID_FLIP_CARD

; ----------------------------------------------------------------------------
    ORG BANK3_ORG + $e00
    RORG BANK3_RORG + $e00

; Indexed by game state values.
; bit 7:        show betting row
; bit 6:        show dashboard
; bit 5:        show dealer's hole card
; bit 4:        show dealer's score
; bit 3:        flicker the currently selected object
; bit 0,1,2:    index into PromptMessages table
Bank3_GameStateFlags
    dc.b %00000000      ; GS_TITLE_SCREEN
    dc.b %10101001      ; GS_NEW_GAME
    dc.b %10001001      ; GS_PLAYER_BET
    dc.b %10001001      ; GS_PLAYER_BET_DOWN
    dc.b %10001001      ; GS_PLAYER_BET_UP
    dc.b %01000000      ; GS_OPEN_DEAL1
    dc.b %01000000      ; GS_OPEN_DEAL2
    dc.b %01000000      ; GS_OPEN_DEAL3
    dc.b %01000000      ; GS_OPEN_DEAL4
    dc.b %01000000      ; GS_OPEN_DEAL5
    dc.b %01000010      ; GS_DEALER_SET_FLAGS
    dc.b %01000010      ; GS_PLAYER_SET_FLAGS
    dc.b %01000010      ; GS_PLAYER_TURN
    dc.b %01000011      ; GS_PLAYER_STAY
    dc.b %01000010      ; GS_PLAYER_PRE_HIT
    dc.b %01000010      ; GS_PLAYER_HIT
    dc.b %01000010      ; GS_PLAYER_POST_HIT
    dc.b %01000100      ; GS_PLAYER_SURRENDER
    dc.b %01000101      ; GS_PLAYER_DOUBLEDOWN
    dc.b %01000110      ; GS_PLAYER_SPLIT
    dc.b %01000110      ; GS_PLAYER_SPLIT_DEAL
    dc.b %01000111      ; GS_PLAYER_INSURANCE
    dc.b %00110000      ; GS_PLAYER_BLACKJACK
    dc.b %00110000      ; GS_PLAYER_WIN
    dc.b %00110000      ; GS_PLAYER_PUSH
    dc.b %01000000      ; GS_PLAYER_HAND_OVER (show dashboard on split hand over)
    dc.b %00100000      ; GS_DEALER_TURN
    dc.b %00100000      ; GS_DEALER_PRE_HIT
    dc.b %00100000      ; GS_DEALER_HIT
    dc.b %00100000      ; GS_DEALER_POST_HIT
    dc.b %00110000      ; GS_DEALER_HAND_OVER
    dc.b %00110000      ; GS_GAME_OVER
    dc.b %00110000      ; GS_INTERMISSION
    dc.b %00110000      ; GS_BROKE_BANK1
    dc.b %00110000      ; GS_BROKE_BANK2

    include "sys/bank3_palette.asm"

; map deck penetration to a sprite
Bank3_ShoeSprite
    dc.b <Bank3_ShoeHead100, <Bank3_ShoeHead100
    dc.b <Bank3_ShoeHead100, <Bank3_ShoeHead50
    dc.b <Bank3_ShoeTail100, <Bank3_ShoeTail50
    dc.b <Bank3_ShoeBlank,   <Bank3_ShoeBlank
    dc.b <Bank3_ShoeBlank,   <Bank3_ShoeBlank

Bank3_DigitSprite
    dc.b <Bank3_Digit0, <Bank3_Digit1, <Bank3_Digit2, <Bank3_Digit3
    dc.b <Bank3_Digit4, <Bank3_Digit5, <Bank3_Digit6, <Bank3_Digit7
    dc.b <Bank3_Digit8, <Bank3_Digit9

; lookup table: Player Index -> PlayerCards offset
Bank3_PlayerCardsOffset
    dc.b 0
Bank3_PlayerCardsOffsetEnd
    dc.b 6, 12, 18
Bank3_CardToSpriteOffset            ; maps card position to sprite position
    dc.b 0, 2, 4, 6, 8, 10
    dc.b 0, 2, 4, 6, 8, 10
    dc.b 0, 2, 4, 6, 8, 10

; indexed by player id (0-2) or player id + 1 (1-3)
Bank3_HandOffset
    dc.b NUM_VISIBLE_CARDS*0, NUM_VISIBLE_CARDS*1
    dc.b NUM_VISIBLE_CARDS*2, NUM_VISIBLE_CARDS*3

; When there is no active card flip animation, the static table is
; used, otherwise the animation table is used.
; Factors in deciding animation state:
;   animating vs static
;   number of cards
;   card slot empty vs occuped
;   animation row, animation column
;   rendering row, rendering column
;   current animation frame progress
; Slots are read from right to left
Bank3_GapAnim
    ; animating cards
    dc.b 5, 5, 5, 5, 5, 1, 0, 0, 0, 0, 0    ; frame 1
    dc.b 5, 5, 5, 5, 5, 2, 0, 0, 0, 0, 0    ; frame 2
    dc.b 5, 5, 5, 5, 5, 3, 0, 0, 0, 0, 0    ; frame 3
    dc.b 5, 5, 5, 5, 5, 4, 0, 0, 0, 0, 0    ; frame 4
    ; static cards
Bank3_GapStatic
    dc.b 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0, 0 ; blank/solid

; Gap graphics data: indexed by Bank3_GapAnim
Bank3_GapGfx
    dc.b %11111111  ; 0
    dc.b %00111110  ; 1
    dc.b %00010000  ; 2
    dc.b %01111100  ; 3
    dc.b %11111111  ; 4
    dc.b %00000000  ; 5

; Map hole card to a flipped card graphic using a decision table.
; Three conditions must be true before using the flipped card graphic.
;   PlayerIdx = dealer, num cards >= 2, hole flag = 1
;
; Format of the index:
;   Bit 0-1:  player index [0-2]
;   Bit 2:    num cards >= 2 flag
;   Bit 3:    hole flag bit (from CurrState)
;
;     P0    P1    DLR    Player 3 is unused
;           +----------------------- hole card shown
;           |
;   0000, [0001], 0010,  0011
;   0100,  0101,  0110,  0111
;   1000,  1001,  1010,  1011
;   1100,  1101, (1110), 1111
;                  |
;                  +---------------- hole card shown
;
; The rank table is reversed and overlapping the suit table (eor $0f)
; to save space
RULE_PLAYER_MASK        = %00000011
RULE_NUMCARDS_MASK      = %00000100
RULE_HOLE_MASK          = %00001000
Bank3_RankRuleTable
    dc.b 0, <RankBack, 0, 0
Bank3_SuitRuleTable
    ds.b 14, 0
    dc.b <SuitBack
    ; dc.b 0 implied 

Bank3_NumCardsFlag      ; indexed by number of cards
    dc.b 0, 0
    ds.b 5, RULE_NUMCARDS_MASK

    INCLUDE_MULTIPLY_TABLE 3, 2, 16
    INCLUDE_MULTIPLY_TABLE 3, 4, 8
    INCLUDE_MULTIPLY_TABLE 3, 6, 10
    INCLUDE_MULTIPLY_TABLE 3, 11, 5

; ----------------------------------------------------------------------------
    ORG BANK3_ORG + $f00, FILLER_CHAR
    RORG BANK3_RORG + $f00

    include "bank3/gen/messages-48.sp" ; must not cross a page bondary

; Current Player
;  P1    P2   Dlr   Unused   ; Currently rendering hand
; 0000, 0001, 0010, 0011     ; P1
; 0100, 0101, 0110, 0111     ; P2
; 1000, 1001, 1010, 1011     ; Dealer
;
; Bits: 0-1 current player hand
;       2-3 currently rendering player hand
Bank3_ColorMatrix
    dc.b CARD_COLOR,          CARD_INACTIVE_COLOR, CARD_INACTIVE_COLOR, CARD_INACTIVE_COLOR
    dc.b CARD_INACTIVE_COLOR, CARD_COLOR,          CARD_INACTIVE_COLOR, CARD_INACTIVE_COLOR
    dc.b CARD_COLOR,          CARD_COLOR,          CARD_COLOR, CARD_INACTIVE_COLOR
    dc.b 0

; -----------------------------------------------------------------------------
; Shared procedures
; -----------------------------------------------------------------------------
PROC_BANK3_OVERSCAN    		= 0

Bank3_ProcTableLo
    dc.b <Bank2_Overscan
Bank3_ProcTableHi
    dc.b >Bank2_Overscan

    ORG BANK3_ORG + $ff6-BS_SIZEOF
    RORG BANK3_RORG + $ff6-BS_SIZEOF

    INCLUDE_BANKSWITCH_SUBS 3, BANK3_HOTSPOT

	; bank switch hotspots
    ORG BANK3_ORG + $ff6
    RORG BANK3_RORG + $ff6
    ds.b 4, 0

    ; interrupts
    ORG BANK3_ORG + $ffa
    RORG BANK3_RORG + $ffa

Bank3_Interrupts
    .word Bank3_Reset       ; NMI    $*ffa, $*ffb
    .word Bank3_Reset       ; RESET  $*ffc, $*ffd
    .word Bank3_Reset       ; IRQ    $*ffe, $*fff
