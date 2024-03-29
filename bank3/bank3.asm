
; Start of bank 3
; -----------------------------------------------------------------------------
    SEG Bank3

    ORG BANK3_ORG, FILLER_CHAR
    RORG BANK3_RORG

; -----------------------------------------------------------------------------
; Shared Variables
; -----------------------------------------------------------------------------
;Bank3_SeqPtr        SET TempVars
; animation add (must be same as vars in Bank2)
;Bank3_AddID         SET TempVars+2
;Bank3_AddPos        SET TempVars+3

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
; dashboard rendering
PF0Bits             SET TempVars
PF2Bits             SET TempVars+1

; card rendering
TempIdx             = Arg1
;StartIdx            = Arg1
;EndIdx              = Arg2

PlyrIdx             SET TempVars+1

HoleIdx             SET TempVars+4      ; indexes Bank3_(Rank|Suit)RuleTable
GapIdx              SET TempVars+4      ; indexes Bank3_GapTable
GapGfxLast          SET TempVars+5

Bank3_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank3_PlayKernel SUBROUTINE
;    tsx
;   lda #$aa
;.Loop
;    sta 0,x
;
;    cpx #<BankVarsEnd
;    bpl .Loop

    jsr Bank3_SetupIndexes
    jsr Bank3_SetupMessageBar
    ldy #OPT_BAR_IDX
    jsr Bank3_SetColors2
    jsr Bank3_SetupDashboardMask
    TIMER_WAIT                          ; wait for vertical blank to finish

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
    TIMER_WAIT

    ; lower playfield priority
    lda #0
    sta CTRLPF

    ldx #DEALER_IDX
    ldy PlayerNumCards,x
    lda Bank3_HandNusiz0,y
    sta NUSIZ0
    lda Bank3_HandNusiz1,y
    sta NUSIZ1

    ; Dealer cards row --------------------------------------------------------
    lda #16*76/64
    sta TIM64T

    ldy #SPRITE_CARDS_IDX
    jsr Bank3_PositionSprites    ; 9 (9)

    ; hide MOVE line
    sta COLUBK                  ; 3 (12)
    ldy #COLOR_CARDS_IDX        ; 2 (14)

    sta WSYNC
    jsr Bank3_SetColors2        ; 36 (36)
    sta WSYNC
    jsr Bank3_SetTableau

    ; lower playfield priority
    lda #0
    sta CTRLPF

    sta WSYNC

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
    lda CurrBet
    sta TempInt
    lda CurrBet+1
    sta TempInt+1
    lda CurrBet+2
    sta TempInt+2

    jsr Bank3_SetupChipSprites
    
    lda #<Bank3_ChipPalette
    sta TempPtr
    lda #>Bank3_ChipPalette
    sta TempPtr+1
    ldy #CHIPS_HEIGHT-1
    jsr Bank3_Draw6ColorSprites

    lda #1
    sta VDELP0
    sta VDELP1

    lda #29*76/64
    sta TIM64T

    ; decide if game over prompt should be displayed
    lda GameState
    cmp #GS_BROKE_PLAYER
    beq .ShowPrompt
    cmp #GS_BROKE_BANK
    beq .ShowPrompt

    ; decide if navigation menu should be displayed
    lda CurrState
    bpl .ShowPlayerCards

    ; Menu prompt row --------------------------------------------------------
.ShowPrompt
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
    sta WSYNC
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

    ; Player cards rows -------------------------------------------------------
.ShowPlayerCards
    TIMER_WAIT

    lda #CARD_COLOR
    sta COLUP0
    sta COLUP1
    lda #1
    sta VDELP0
    sta VDELP1

    lda #FLAGS_SPLIT_TAKEN
    bit GameFlags
    beq .NoSplit

.SplitHand
    lda #TIME_CARD_SETUP
    sta TIM8T

    ; assign card colors (active/inactive, dealer is always active)
    lda #PLAYER2_IDX << 2       ; 2 (2)
    ora CurrPlayer              ; 3 (5)
    tay                         ; 2 (7)
    lda Bank3_ColorMatrix,y     ; 4 (11)
    sta COLUP0                  ; 3 (14)
    sta COLUP1                  ; 3 (17)

    ldx #PLAYER2_IDX            ; 2 (19)
    stx PlyrIdx                 ; 3 (22)
    ldy PlayerNumCards,x        ; 4 (26)
    lda Bank3_HandNusiz0,y      ; 4 (30)
    ldx Bank3_HandNusiz1,y      ; 4 (34)

    jsr Bank3_SetupCardSprites
    TIMER_WAIT

    ldx PlyrIdx                 ; 3 (3)
    ldy PlayerNumCards,x        ; 4 (4)
    lda Bank3_HandNusiz0,y      ; 4 (4)
    ldx Bank3_HandNusiz1,y      ; 4 (4)
    sta WSYNC                   
    sta NUSIZ0                  ; 3 (3)
    stx NUSIZ1                  ; 3 (3)

    jsr Bank3_RenderCardSprites

    sta WSYNC
    sta WSYNC
    sta WSYNC
    sta WSYNC
    jmp .OneHand

    ; Blank space ------------------------------------------------------------
.NoSplit
    SLEEP_LINES 32

.OneHand
    lda #TIME_CARD_SETUP
    sta TIM8T

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

    sta WSYNC
    sta WSYNC
    sta WSYNC

    ; Player chips row --------------------------------------------------------
    lda #CHIP_COLOR
    sta COLUP0
    sta COLUP1
    lda #NUSIZE_3_MEDIUM
    sta NUSIZ0
    sta NUSIZ1
    lda #0
    sta VDELP0
    sta VDELP1

    lda PlayerChips
    sta TempInt
    lda PlayerChips+1
    sta TempInt+1
    lda PlayerChips+2
    sta TempInt+2

    TIMED_JSR Bank3_SetupChipSprites, TIME_CHIP_MENU_SETUP, TIM8T

    lda #<Bank3_ChipPalette
    sta TempPtr
    lda #>Bank3_ChipPalette
    sta TempPtr+1
    ldy #CHIPS_HEIGHT-1
    jsr Bank3_Draw6ColorSprites

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
    JUMP_BANK Bank2_Overscan

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

; -----------------------------------------------------------------------------
; Desc:     Sets the message prompt graphics.
; Inputs:
; Ouputs:   
; -----------------------------------------------------------------------------
Bank3_SetupPromptBar SUBROUTINE
    ; check for game over and the player is out of chips
    lda GameState
    cmp #GS_BROKE_PLAYER
    bne .CheckBankBroke

    lda #<Bank3_OutOfChipsStr0
    sta SpritePtrs
    lda #<Bank3_OutOfChipsStr1
    sta SpritePtrs+2
    lda #<Bank3_OutOfChipsStr2
    sta SpritePtrs+4
    lda #<Bank3_OutOfChipsStr3
    sta SpritePtrs+6
    lda #<Bank3_OutOfChipsStr4
    sta SpritePtrs+8
    lda #<Bank3_OutOfChipsStr5
    sta SpritePtrs+10

    lda #>Bank3_OutOfChipsStr0
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

.CheckBankBroke
    lda GameState
    cmp #GS_BROKE_BANK
    bne .CheckGameOver

    lda #<Bank3_BankBrokeStr0
    sta SpritePtrs
    lda #<Bank3_BankBrokeStr1
    sta SpritePtrs+2
    lda #<Bank3_BankBrokeStr2
    sta SpritePtrs+4
    lda #<Bank3_BankBrokeStr3
    sta SpritePtrs+6
    lda #<Bank3_BankBrokeStr4
    sta SpritePtrs+8
    lda #<Bank3_BankBrokeStr5
    sta SpritePtrs+10

    lda #>Bank3_BankBrokeStr0
    sta SpritePtrs+1
    sta SpritePtrs+3
    sta SpritePtrs+5
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
    rts

.CheckGameOver
    ; check for game over state
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

; -----------------------------------------------------------------------------
; Desc:     Sets the dashboard graphics.
; Inputs:
; Ouputs:   
; -----------------------------------------------------------------------------
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

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite characters for the bottom status bar.
; Inputs:
; Ouputs:
; Notes:
;
; SpritePtrs elements 4, 5, 6 display the shoe graphic
;
; DealDepth and number of decks scale the shoe graphics. The shoe
; uses two graphics arrays to represent 6 intervals. The tail segment
; will either be 100% or 50%.
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
; Scale          Shoe             Tail
;       ._______._______._______.
;     5 |_______._______._______| 100%
;     4 |_______._______.___|   .  50%
;     3 |_______._______|       . 100%
;     2 |_______.___|   .       .  50%
;     1 |_______|       .       . 100%
;     0 |___|   .       .       .  50%
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
    ; scale the shoe size according to deal depth and number of decks
    ; 1 deck:   DealDepth / 8
    ; 2 decks:  DealDepth / 16
    ; 4 decks:  DealDepth / 32

    ; get number of decks
    lda GameOpts
    and #NUM_DECKS_MASK
    tax

    lda DealDepth
    ; divide by 8
    lsr
    lsr
    lsr
    cpx #0                  ; if number of decks == 1
    beq .Assign

    ; divide by 16
    lsr
    cpx #3                  ; if number of decks < 4
    bcc .Assign

    ; divide by 32          ; number of decks == 4
    lsr

.Assign
    tax
    lda Bank3_ShoeSprite,x
    sta SpritePtrs+6
    lda Bank3_ShoeSprite+2,x
    sta SpritePtrs+8
    lda Bank3_ShoeSprite+4,x
    sta SpritePtrs+10

    lda #>Bank3_Shoes
    sta SpritePtrs+7
    sta SpritePtrs+9
    sta SpritePtrs+11
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

    INCLUDE_CHIP_SUBS 3

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

; -----------------------------------------------------------------------------
; Desc:     Pre-computes indexes used for rendering.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
#if 1
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
    rts

#else
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
#endif

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

Bank3_SetupCardSprites SUBROUTINE       ; 6 (6)
    ; high bytes
    lda #>BlankCard                     ; 2 (8)
    sta SpritePtrs+1                    ; 3 (11)
    sta SpritePtrs+3                    ; 3 (14)
    sta SpritePtrs+5                    ; 3 (17)
    sta SpritePtrs+7                    ; 3 (20)
    sta SpritePtrs+9                    ; 3 (23)
    sta SpritePtrs+11                   ; 3 (26)

    ; handle 3 scenarios differently: 0 cards, 1-5 cards, and 6 cards
    ldx PlyrIdx                         ; 3 (29)
    ldy PlayerNumCards,x                ; 4 (33)
    sty GapIdx                          ; 3 (36)
    cpy #NUM_VISIBLE_CARDS              ; 2 (38)
    beq .FullHand                       ; 2 (40)    if num cards == 6
    cpy #0                              ; 2 (42)
    bne .SomeCards                      ; 3 (45)    if num cards == 0

    ; no cards
    lda #<BlankCard                     ; 2 [2]
    sta SpritePtrs                      ; 3 [5]
    sta SpritePtrs+2                    ; 3 [8]
    sta SpritePtrs+4                    ; 3 [11]
    sta SpritePtrs+6                    ; 3 [14]
    sta SpritePtrs+8                    ; 3 [17]
    sta SpritePtrs+10                   ; 3 [20]
    tsx                                 ; 2 [22]
    sta  0,x                            ; 4 [26]
    sta -1,x                            ; 4 [30]
    sta -2,x                            ; 4 [34]
    sta -3,x                            ; 4 [38]
    sta -4,x                            ; 4 [42]
    sta -5,x                            ; 4 [46]
    rts                                 ; 6 [52]

.SomeCards
    ; assign blank graphics
    lda #<BlankCard                     ; 3 (48)
.Blanks
    ldx Bank3_Mult2,y                   ; 4 [4]     index into SpritePtrs
    sta SpritePtrs,x                    ; 4 [8]
    pha                                 ; 2 [10]
    iny                                 ; 2 [12]
    cpy #NUM_VISIBLE_CARDS              ; 2 [14]
    bne .Blanks                         ; 3 [17]

    ldx PlyrIdx                         ; 3 (3)
    ldy PlayerNumCards,x                ; 4 (7)

.FullHand
    ; get a pointer to &PlayerCards[PlyrIdx]
    clc                                 ; 2 (9)
    lda #<PlayerCards                   ; 2 (11)
    adc Bank3_Mult6,x                   ; 2 (13)
    sta TempPtr                         ; 3 (16)
    lda #>PlayerCards                   ; 2 (18)
    sta TempPtr+1                       ; 3 (21)

    ; assign card graphics
    dey                                 ; 2 (23)
.Loop
    lda (TempPtr),y                     ; 5 (5)
    ; assign rank graphics
    and #CARD_RANK_MASK                 ; 2 (7)
    tax                                 ; 2 (9)
    lda Bank3_CardRankGfx,x             ; 4 (13)
    ldx Bank3_Mult2,y                   ; 4 (17)    index into SpritePtrs
    sta SpritePtrs,x                    ; 4 (21)
    ; assign suit graphics
    lda (TempPtr),y                     ; 5 (26)
    and #CARD_SUIT_MASK                 ; 2 (28)
    lsr                                 ; 2 (30)
    lsr                                 ; 2 (32)
    lsr                                 ; 2 (34)
    lsr                                 ; 2 (36)
    tax                                 ; 2 (38)
    lda Bank3_CardSuitGfx,x             ; 4 (42)    get a LSB pointer to graphics
    pha                                 ; 3 (45)    pass suit on the stack
    dey                                 ; 2 (47)
    bpl .Loop                           ; 3 (50)

    ; determine if the dealer's hole card is face up or face down
    ldx PlyrIdx                         ; 3 (3)
    lda CurrState                       ; 3 (6)
    bpl .ShowCard                       ; 3 (9)     if CurrState & $80
    cpx #DEALER_IDX                     ; 2 [2]
    bne .ShowCard                       ; 2 [4]    if PlyrIdx == DEALER

    ; overwrite hole card with back side graphics
    lda #<RankBack                      ; 2 [6]
    sta SpritePtrs+2                    ; 4 [10]
    lda #<SuitBack                      ; 2 [12]
    tsx                                 ; 2 [14]
    sta 2,x                             ; 4 [18]
    ldx PlyrIdx                         ; 3 [21]

.ShowCard
    ; check if there's an animating card
    lda FlipFrame                       ; 3 (12)
    and #FLIP_FRAME_MASK                ; 2 (14)
    beq .Continue                       ; 2 (16)

    tay                                 ; 2 (18)    Y = frame#

    ; check if it's for this hand
    lda FlipFrame                       ; 3 (21)
    and #FLIP_PLAYER_MASK               ; 2 (23)
    clc                                 ; 2 (25)
    rol                                 ; 2 (27)
    rol                                 ; 2 (29)
    rol                                 ; 2 (31)
    cmp PlyrIdx                         ; 3 (34)
    bne .Continue                       ; 2 (36)

    ; assign the gap graphics
    clc                                 ; 2 (38)
    lda Bank3_Mult11-1,y                ; 4 (42)    (frame# - 1) * 11
    adc PlayerNumCards,x                ; 4 (46)    
    adc #11                             ; 2 (48)    select dynamic indexes
    sta GapIdx                          ; 3 (51)

    ; get the animating card number
    lda FlipFrame                       ; 3 (54)
    and #FLIP_CARD_MASK                 ; 2 (56)
    lsr                                 ; 2 (58)
    lsr                                 ; 2 (60)
    lsr                                 ; 2 (62)
    sta TempIdx                         ; 3 (65)

    ; assign rank graphics
    asl                                 ; 2 (67)
    tax                                 ; 2 (69)
    lda Bank3_FlipRankGfxLo,y           ; 4 (73)
    sta SpritePtrs-2,x                  ; 4 (77)

    ; assign suit graphics
    tsx                                 ; 2 (79)    add card# to stack pointer
    txa                                 ; 2 (81)
    clc                                 ; 2 (83)
    adc TempIdx                         ; 2 (85)
    tax                                 ; 2 (87)
    lda Bank3_FlipSuitGfxLo,y           ; 4 (91)
    sta 0,x                             ; 4 (95)

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
    tsx                                 ; 2 (97) [23]
    txa                                 ; 2 (99) [25]
    clc                                 ; 2 (101) [27]
    adc #6                              ; 2 (103) [29]
    tax                                 ; 2 (105) [31]
    txs                                 ; 2 (107) [33]
    rts                                 ; 6 (113) [39]

    ; max cycles 0 cards:  99 = 44 + 52
    ; max cycles 1 card : 317 = 48 + (17 * 5 - 1) + 23 + (50 * 1 - 1) + 113
    ; max cycles 3 cards: 390 = 48 + (17 * 3 - 1) + 23 + (50 * 3 - 1) + 117
    ; max cycles 5 cards: 465 = 48 + (17 * 1 - 1) + 23 + (50 * 5 - 1) + 117
    ; max cycles 6 cards: 469 = 41 + 16 + (50 * 6 - 1) + 113

    INCLUDE_SPRITE_OPTIONS 3
    INCLUDE_SPRITE_COLORS 3

    ORG BANK3_ORG + $700, FILLER_CHAR
    RORG BANK3_RORG + $700

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
; Desc:     Draws 6 medium spaced sprites in a row.
; Inputs:   Y register (sprite height - 1)
;           SpritePtrs (array of 6 pointers)
; Outputs:
; Notes:    VDEL must be off
;   ldy #HEIGHT-1
;   jsr Bank3_Draw6Sprites
; -----------------------------------------------------------------------------
Bank3_Draw6ColorSprites SUBROUTINE
    DRAW_6_COLOR_SPRITES SpritePtrs, TempPtr
    rts

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $800, FILLER_CHAR
    RORG BANK3_RORG + $800

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
; GRP 0,1,0      GRP1       GRP0       GRP1       GRP0      : GRPn writes
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
    ldy Bank3_GapTable,x    ; 4 (19)    (57)
    lda Bank3_GapGfx,y      ; 4 (23)    (69)
    sta GapGfxLast          ; 3 (26)    (78)    last card in set
    ldy Bank3_GapTable+5,x  ; 4 (30)    (90)
    ldx Bank3_GapGfx,y      ; 4 (34)    (102)   first card in set

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
    ldy Bank3_GapTable+4,x  ; 4 (2)     (6)
    lda Bank3_GapGfx,y      ; 4 (6)     (18)
    ldy Bank3_GapTable+3,x  ; 4 (10)    (30)
    sta GRP1                ; 3 (13)    (39)       D1     >D1     ^D2      *

    lda Bank3_GapGfx,y      ; 4 (17)    (51)
    ldy Bank3_GapTable+2,x  ; 4 (21)    (63)
    sta GRP0                ; 3 (24)    (72)      ^D3      D1      D2     >D2

    bit $0                  ; 3 (27)    (81)

    lda Bank3_GapGfx,y      ; 4 (31)    (93)
    ldy Bank3_GapTable+1,x  ; 4 (35)    (105)               !
    sta GRP1                ; 3 (38)    (114)      D3     >D3     ^D4      D2

    lda Bank3_GapGfx,y      ; 4 (42)    (126)                               !
    sta GRP0                ; 3 (45)    (135)     ^D5      D3!     D4     >D4

    lda GapGfxLast          ; 3 (48)    (144)
    sta GRP1                ; 3 (51)    (153)      D5     >D5     ^D6      D4!
    sta GRP0                ; 3 (54)    (162)      D5     ^D7      D6     >D6

    ; updating the suit graphics
    pla                     ; 4 (58)    (174)               !
    sta SpritePtrs+2        ; 3 (61)    (183)                                !
    pla                     ; 4 (65)    (195)
    sta SpritePtrs+4        ; 3 (68)    (204)

    ; ---- line 2 ----
    ; prepare gap graphics
    ldy Bank3_GapTable+5,x  ; 4 (72)    (216)
    lda Bank3_GapGfx,y      ; 4 (0)     (0)
    ; -----------
    sta GRP0                ; 3 (3)     (9)
    ldy Bank3_GapTable+4,x  ; 4 (7)     (21)
    lda Bank3_GapGfx,y      ; 4 (11)    (33)
    sta GRP1                ; 3 (14)    (42)       D1     >D1     ^D2      *
    ldy Bank3_GapTable+3,x  ; 4 (18)    (54)
    lda Bank3_GapGfx,y      ; 4 (22)    (66)
    sta GRP0                ; 3 (25)    (75)      ^D3      D1      D2     >D2

    ldy Bank3_GapTable+2,x  ; 4 (29)    (87)
    lda Bank3_GapGfx,y      ; 4 (33)    (99)                !
    ldy Bank3_GapTable+1,x  ; 4 (37)    (111)
    sta GRP1                ; 3 (40)    (120)      D3     >D3     ^D4      D2!

    lda Bank3_GapGfx,y      ; 4 (44)    (132)
    sta GRP0                ; 3 (47)    (141)     ^D5      D3!     D4     >D4

    lda GapGfxLast          ; 3 (50)    (150)                               !
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

    lda #0                  ; 2 (22)
    sta GRP0                ; 3 (25)
    sta GRP1                ; 3 (28)
    sta GRP0                ; 3 (31)

#if PIP_COLORS
    ; color test
    sta ENABL               ; 3 (3)
    sta PF0                 ; 3 (3)
    lda #BG_COLOR           ; 2 (2)
    sta COLUPF              ; 3 (5)
#endif

    rts                     ; 6 (43)    884 cpu cycles (11.6 lines)

    ORG BANK3_ORG + $900, FILLER_CHAR
    RORG BANK3_RORG + $900
    include "bank3/gen/messages-48.sp"  ; must not cross a page bondary

    ORG BANK3_ORG + $a00, FILLER_CHAR
    RORG BANK3_RORG + $a00
    include "bank3/gen/broke-48.sp"     ; must not cross a page bondary

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $b00, FILLER_CHAR
    RORG BANK3_RORG + $b00
    include "bank3/gfx/cards.asm"

; -----------------------------------------------------------------------------
    ORG BANK3_ORG + $c00, FILLER_CHAR
    RORG BANK3_RORG + $c00

    include "bank3/gfx/betting.asm"    ; must reside within a single page

; indexed by PlayerFlags
Bank3_ResultMessagesLSB
    ; FLAGS_LOST
    dc.b <Bank3_DealerWinsStr0, <Bank3_DealerWinsStr1, <Bank3_DealerWinsStr2
    dc.b <Bank3_DealerWinsStr3, <Bank3_DealerWinsStr4, <Bank3_DealerWinsStr5
    ; FLAGS_BUST
    dc.b <Bank3_BustStr0, <Bank3_BustStr1, <Bank3_BustStr2
    dc.b <Bank3_BustStr3, <Bank3_BustStr4, <Bank3_BustStr5
    ; FLAGS_21
    dc.b <Bank3_WinnerStr0, <Bank3_WinnerStr1, <Bank3_WinnerStr2
    dc.b <Bank3_WinnerStr3, <Bank3_WinnerStr4, <Bank3_WinnerStr5
    ; FLAGS_PUSH
    dc.b <Bank3_PushStr0, <Bank3_PushStr1, <Bank3_PushStr2
    dc.b <Bank3_PushStr3, <Bank3_PushStr4, <Bank3_PushStr5
    ; FLAGS_WIN
    dc.b <Bank3_WinnerStr0, <Bank3_WinnerStr1, <Bank3_WinnerStr2
    dc.b <Bank3_WinnerStr3, <Bank3_WinnerStr4, <Bank3_WinnerStr5
    ; FLAGS_BLACKJACK
    dc.b <Bank3_BJackStr0, <Bank3_BJackStr1, <Bank3_BJackStr2
    dc.b <Bank3_BJackStr3, <Bank3_BJackStr4, <Bank3_BJackStr5
    ; GS_BROKE_PLAYER
    ;dc.b <Bank3_OutOfChipsStr0, <Bank3_OutOfChipsStr1, <Bank3_OutOfChipsStr2
    ;dc.b <Bank3_OutOfChipsStr3, <Bank3_OutOfChipsStr4, <Bank3_OutOfChipsStr5

; indexed by Bank3_GameStateFlags
Bank3_PromptMessagesLSB
    ds.b 4, <Bank3_BlankStr
    dc.b <Bank3_HitStr0, <Bank3_HitStr1, <Bank3_HitStr2, <Bank3_HitStr3
    dc.b <Bank3_StayStr0, <Bank3_StayStr1, <Bank3_StayStr2, <Bank3_StayStr3
    dc.b <Bank3_SurrenderStr0, <Bank3_SurrenderStr1, <Bank3_SurrenderStr2, <Bank3_SurrenderStr3
    dc.b <Bank3_DDownStr0, <Bank3_DDownStr1, <Bank3_DDownStr2, <Bank3_DDownStr3
    dc.b <Bank3_SplitStr0, <Bank3_SplitStr1, <Bank3_SplitStr2, <Bank3_SplitStr3
    dc.b <Bank3_InsuranceStr0, <Bank3_InsuranceStr1, <Bank3_InsuranceStr2, <Bank3_InsuranceStr3

    INCLUDE_CHIP_DATA 3
    INCLUDE_POSITIONING_SUBS 3

; ----------------------------------------------------------------------------
    ORG BANK3_ORG + $d00
    RORG BANK3_RORG + $d00

    include "bank3/gen/prompts-48.sp"  ; must not cross a page boundary
    INCLUDE_MATH_FUNCS 3
    INCLUDE_MENU_SUBS 3

; ----------------------------------------------------------------------------
    ORG BANK3_ORG + $e00
    RORG BANK3_RORG + $e00

    INCLUDE_SPRITE_POSITIONING 3
    include "sys/bank3_palette.asm"

; Indexed by game state values.
; bit 7:        show dashboard
; bit 6:        show dealer's score
; bit 3-5:      (unused)
; bit 0-2:      index into PromptMessages table
Bank3_GameStateFlags
    dc.b %00000000      ; GS_NONE
    dc.b %00000000      ; GS_NEW_GAME
    dc.b %00000000      ; GS_PLAYER_BET
    dc.b %00000000      ; GS_PLAYER_BET_DOWN
    dc.b %00000000      ; GS_PLAYER_BET_UP
    dc.b %10000000      ; GS_OPEN_DEAL1
    dc.b %10000000      ; GS_OPEN_DEAL2
    dc.b %10000000      ; GS_OPEN_DEAL3
    dc.b %10000000      ; GS_OPEN_DEAL4
    dc.b %10000000      ; GS_OPEN_DEAL5
    dc.b %10000001      ; GS_DEALER_SET_FLAGS
    dc.b %10000001      ; GS_PLAYER_SET_FLAGS
    dc.b %10000001      ; GS_PLAYER_TURN
    dc.b %10000010      ; GS_PLAYER_STAY
    dc.b %10000001      ; GS_PLAYER_PRE_HIT
    dc.b %10000001      ; GS_PLAYER_HIT
    dc.b %10000001      ; GS_PLAYER_POST_HIT
    dc.b %10000011      ; GS_PLAYER_SURRENDER
    dc.b %10000100      ; GS_PLAYER_DOUBLEDOWN
    dc.b %10000101      ; GS_PLAYER_SPLIT
    dc.b %10000101      ; GS_PLAYER_SPLIT_DEAL
    dc.b %10000110      ; GS_PLAYER_INSURANCE
    dc.b %01000000      ; GS_PLAYER_BLACKJACK
    dc.b %01000000      ; GS_PLAYER_WIN
    dc.b %01000000      ; GS_PLAYER_PUSH
    dc.b %10000000      ; GS_PLAYER_HAND_OVER (show dashboard on split hand over)
    dc.b %00000000      ; GS_DEALER_TURN
    dc.b %00000000      ; GS_DEALER_PRE_HIT
    dc.b %00000000      ; GS_DEALER_HIT
    dc.b %00000000      ; GS_DEALER_POST_HIT
    dc.b %01000000      ; GS_DEALER_HAND_OVER
    dc.b %01000000      ; GS_GAME_OVER
    dc.b %01000000      ; GS_GAME_OVER_WAIT
    dc.b %01000000      ; GS_BROKE_PLAYER
    dc.b %01000000      ; GS_BROKE_BANK

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

; When there is no active card flip animation the static table is used,
; otherwise the animating table is used. Indexes are in order of right to left.
Bank3_GapTable      ; animating cards
    dc.b 5, 5, 5, 5, 5, 5, 0, 0, 0, 0, 0, 0 ; non-animating
Bank3_GapAnim
    dc.b 5, 5, 5, 5, 5, 1, 0, 0, 0, 0, 0    ; frame 1
    dc.b 5, 5, 5, 5, 5, 2, 0, 0, 0, 0, 0    ; frame 2
    dc.b 5, 5, 5, 5, 5, 3, 0, 0, 0, 0, 0    ; frame 3
    dc.b 5, 5, 5, 5, 5, 4, 0, 0, 0, 0, 0    ; frame 4
Bank3_GapStatic     ; static cards
       ; Example:    -  -  -  J  K  Q          ; 3 cards
    ;             6  5  4  3  2  1          ; card positions
; Gap graphics data
Bank3_GapGfx
    dc.b %11111111  ; 0
    dc.b %00111110  ; 1
    dc.b %00010000  ; 2
    dc.b %01111100  ; 3
    dc.b %11111111  ; 4
    dc.b %00000000  ; 5

#if 1
; Animation data:
Bank3_FlipRankGfxLo
    dc.b 0, <Bank3_FlipRank3, <Bank3_FlipRank2, <Bank3_FlipRank1, <Bank3_FlipRank0
Bank3_FlipSuitGfxLo
    dc.b 0, <Bank3_FlipSuit3, <Bank3_FlipSuit2, <Bank3_FlipSuit1, <Bank3_FlipSuit0

#else
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

;Bank3_FlipSuitSeq
;    dc.b [0 << 3] | 2
;    dc.b [1 << 5] | 4
Bank3_FlipSuitGfxLo
    dc.b 0, <Bank3_FlipSuit3, <Bank3_FlipSuit2, <Bank3_FlipSuit1, <Bank3_FlipSuit0

ANIM_ID_NONE                = 0
ANIM_ID_FLIP_CARD           = 1
Bank3_Sequences
    dc.b 0                  ; ANIM_ID_NONE
    dc.b <Bank3_FlipRankSeq ; ANIM_ID_FLIP_CARD
#endif

; ----------------------------------------------------------------------------
    ORG BANK3_ORG + $f00, FILLER_CHAR
    RORG BANK3_RORG + $f00

    include "bank3/gfx/options.asm"
    include "bank3/gfx/play.asm"

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

    INCLUDE_MULTIPLY_TABLE 3, 2, 16
    INCLUDE_MULTIPLY_TABLE 3, 4, 8
    INCLUDE_MULTIPLY_TABLE 3, 6, 10
    INCLUDE_MULTIPLY_TABLE 3, 10, 5
    INCLUDE_MULTIPLY_TABLE 3, 11, 5

; -----------------------------------------------------------------------------
; Shared procedures
; -----------------------------------------------------------------------------
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
