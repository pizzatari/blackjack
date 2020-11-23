; -----------------------------------------------------------------------------
; Start of bank 2
; -----------------------------------------------------------------------------
    SEG bank2

    ORG BANK2_ORG, FILLER_CHAR
    RORG BANK2_RORG

; -----------------------------------------------------------------------------
; Shared Variables
; -----------------------------------------------------------------------------
; animation add (must be same as vars in Bank2)
Bank2_AddID   SET TempVars+2
Bank2_AddPos  SET TempVars+3

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
TriggerTimer    = RandAlt
StackPtr        = TempVars
Score           = TempVars+1
NumAces         = TempVars+2
NewCard         = TempVars+2
FindStart       = TempVars+2
BetSelect       = TempVars+2

; disable trigger after the end of a game: RandAlt is safe to use in the
; intermission state (GS_INTERMISSION)
TGR_TIMER       = 60        ; 1 second

Bank2_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank2_Init
    ; debug ram
    lda #$4f
    ldy #$e0
.Init
    sta 0,y
    iny
    bne .Init

    jsr Bank2_ResetGame

    ; joystick delay
    lda #JOY_TIMER_DELAY
    sta JoyTimer

    lda #0
    sta REFP0
    sta REFP1
    sta PlayerChips
    lda #>NEW_PLAYER_CHIPS
    sta PlayerChips+1
    lda #<NEW_PLAYER_CHIPS
    sta PlayerChips+2

    lda #DENOM_START_SELECTION
    jsr Bank2_SetBetMenu

    ; Wait for previous overscan to finish to stabilize line count
    TIMER_WAIT
    sta WSYNC

Bank2_FrameStart SUBROUTINE
    ; -------------------------------------------------------------------------
    ; VerticalSync
    ; -------------------------------------------------------------------------
    lda #%00000000
    sta VBLANK
    VERTICAL_SYNC
    ; -------------------------------------------------------------------------

    ; -------------------------------------------------------------------------
    ; VerticalBlank
    ; -------------------------------------------------------------------------
    ldy GameState
    lda #30*76/64   ;#TIME_VBLANK
    sta TIM64T

    ; Play sound associated with the game state
    ldx #0
.Search
    ; lookup audio clip
    lda Bank2_GameStateSound,x
    beq .Done
    cmp GameState
    beq .Found
    inx
    inx
    jmp .Search
.Found
    lda Bank2_GameStateSound+1,x
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
.Done

    ; dispatch task or game handler
    jsr Bank2_QueueGetTail
    beq .DispatchGame

    ; task handler ------------------------------------------------------------
.DispatchTask
    asl                            ; A = A * 2
    tay
    lda Bank2_TaskHandlers,y
    sta TempPtr
    lda Bank2_TaskHandlers+1,y
    sta TempPtr+1

    ; push return address to the stack
    lda #>(.ReturnAddr-1)
    pha
    lda #<(.ReturnAddr-1)
    pha

    ; call the handler
    jmp (TempPtr)
    jmp .ReturnAddr

    ; game handler ------------------------------------------------------------
.DispatchGame
    lda GameState
    asl                            ; A = A * 2
    tay
    lda Bank2_GameStateHandlers,y
    sta TempPtr
    lda Bank2_GameStateHandlers+1,y
    sta TempPtr+1

    ; push return address to the stack
    lda #>(.ReturnAddr-1)
    pha
    lda #<(.ReturnAddr-1)
    pha

    ; call the handler
    jmp (TempPtr)

.ReturnAddr
    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank2_InitSpriteSpacing
    jsr Bank2_ClearEvents

    TIMER_WAIT

    ; -------------------------------------------------------------------------
    ; kernel
    ; -------------------------------------------------------------------------
    ; decide which kernel to execute
    ldy GameState
    lda Bank2_GameStateFlags,y
    and #GS_SHOW_BETTING_FLAG
    beq .PlayKernel

    JUMP_BANK PROC_BANK0_BETTINGKERNEL, 0
    jmp Bank2_Overscan

.PlayKernel
    JUMP_BANK PROC_BANK3_PLAYKERNEL, 3

    ; -------------------------------------------------------------------------
    ; overscan
    ; -------------------------------------------------------------------------
Bank2_Overscan
    lda #%00000010
    sta WSYNC
    sta VBLANK

    lda #TIME_OVERSCAN
    sta TIM64T

Debug1
    CALL_BANK PROC_BANK0_GAMEIO, 0, 2
    CALL_BANK PROC_SOUNDQUEUETICK, 1, 2

    ; test keypad

    ; position selector
    ldy #SPRITE_GRAPHICS_IDX
    jsr Bank2_PositionSprites

    lda #0
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2

    ldy #MSG_BAR_IDX
    lda Bank2_TextBarPalette+1,y
    sta COLUP0
    sta COLUP1

Debug2
    ; read keypad
    CALL_BANK PROC_BANK0_READKEYPAD, 0, 2
Debug3

    inc FrameCtr

    TIMER_WAIT
    ; -------------------------------------------------------------------------

    jmp Bank2_FrameStart

; -----------------------------------------------------------------------------
; SUBROUTINES
; -----------------------------------------------------------------------------
Bank2_DeckChange SUBROUTINE
    ; increment the number of decks.
    lda GameOpts
    and #NUM_DECKS_MASK
    tay                         ; Y = num decks (save a copy)
.No3Deck
    iny                         ; Y = num decks + 1
    cpy #2
    beq .No3Deck                ; 3 decks is not allowed
    cpy #NUM_DECKS
    bcc .SetDecks               ; handle overflow of num decks
    ldy #0
.SetDecks
    lda GameOpts
    and #~NUM_DECKS_MASK
    sta GameOpts
    tya                         ; A = num decks
    ora GameOpts                ; merge num decks with GameOpts
    sta GameOpts
    rts

; -----------------------------------------------------------------------------
; Desc:     Increases bet by the amount selected by Bank2_DenomValue[X]
; Inputs:   X (index to Bank2_DenomValue)
; Ouputs:
; Notes:    BCD must be turned on.
; -----------------------------------------------------------------------------
Bank2_IncreaseBet SUBROUTINE
    ; denomination values are -1 their actual value, so correct for this by
    ; forcing a borrow
    sec
    lda CurrBet+1
    adc Bank2_DenomValue,x
    sta CurrBet+1
    lda CurrBet
    adc #0
    sta CurrBet
    rts

; -----------------------------------------------------------------------------
; Desc:     Decreases bet by the amount selected by Bank2_DenomValue[X]
; Inputs:   X (index to Bank2_DenomValue)
; Ouputs:
; Notes:    BCD must be turned on.
; -----------------------------------------------------------------------------
Bank2_DecreaseBet SUBROUTINE
    ; denomination values are -1 their actual value, so correct for this by
    ; forcing a carry
    clc
    lda CurrBet+1
    sbc Bank2_DenomValue,x
    sta CurrBet+1
    lda CurrBet
    sbc #0
    sta CurrBet
    rts

; -----------------------------------------------------------------------------
; Desc:     Check if player has enough chips to match CurrBet. Prevent bets
;           higher than player's available chips.
; Inputs:   Arg1 (MSB), Arg2 (LSB)
; Ouputs:   A register (1 for yes, 0 for no)
; Notes:    BCD must be turned on.
; -----------------------------------------------------------------------------
Bank2_PlayerHasEnoughChips SUBROUTINE
    ; check for 0 chips
    clc
    lda PlayerChips
    adc PlayerChips+1
    adc PlayerChips+2
    beq .BadBet

    ; check 100,000's and 10,000's places
    lda #0
    cmp PlayerChips
    bcc .GoodBet                                        ; if A < M
    bne .BadBet
    ; check 1000's and 100's places
    lda Arg1
    cmp PlayerChips+1
    bcc .GoodBet                                        ; if A < M
    bne .BadBet
    ; check 10's and 1's places
    lda PlayerChips+2
    cmp Arg2
    bcs .GoodBet                                        ; if M >= A
.BadBet
    lda #0
    rts
.GoodBet
    lda #1
    rts

; -----------------------------------------------------------------------------
; Desc:     Check if the dealer can return chps.
; Inputs:   X (index to Bank2_DenomValue)
; Ouputs:   A register (1 if good, 0 if not)
; Notes:    BCD must be turned on.
; -----------------------------------------------------------------------------
Bank2_CheckCanReturnChips SUBROUTINE
    ; prevent return when zero chips in the pot
    lda CurrBet
    ora CurrBet+1
    beq .Return

    ; prevent over-return of chips
    lda #0
    cmp CurrBet
    bcc .BetOkay                                        ; if A < M
    lda Bank2_DenomValue,x
    cmp CurrBet+1
    bcc .BetOkay                                        ; if A < M
    jmp .Return

.BetOkay
    lda #1
    rts

.Return
    lda #0
    rts

; -----------------------------------------------------------------------------
; Desc:     Make another bet using CurrBet.
; Inputs:   CurrBet
; Ouputs:
; Notes:    BCD must be turned on.
; -----------------------------------------------------------------------------
Bank2_ApplyCurrBet SUBROUTINE
    lda CurrBet
    sta Arg1
    lda CurrBet+1
    sta Arg2
    jsr Bank2_PlayerHasEnoughChips
    bne .BetOkay

    ; player does not have enough chips, so resetting bet to 0
.BadBet
    lda #0
    sta CurrBet
    sta CurrBet+1
    jmp .Return

.BetOkay
    sed
    jsr Bank2_SubtractBetChips
    cld

.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Take bet chips from player.
; Inputs:   X (index to Bank2_DenomValue)
; Ouputs:
; Notes:    BCD must be turned on.
; -----------------------------------------------------------------------------
Bank2_DecreasePlayerChips SUBROUTINE
    clc                ; extra -1
    lda PlayerChips+2
    sbc Bank2_DenomValue,x
    sta PlayerChips+2

    lda PlayerChips+1
    sbc #0
    sta PlayerChips+1

    lda PlayerChips
    sbc #0
    sta PlayerChips
    rts

; -----------------------------------------------------------------------------
; Desc:     Give chips to the player.
; Inputs:   X (index to Bank2_DenomValue)
; Ouputs:
; Notes:    BCD must be turned on.
; -----------------------------------------------------------------------------
Bank2_IncreasePlayerChips SUBROUTINE
    sec                ; extra +1
    lda PlayerChips+2
    adc Bank2_DenomValue,x
    sta PlayerChips+2

    lda PlayerChips+1
    adc #0
    sta PlayerChips+1

    lda PlayerChips
    adc #0
    sta PlayerChips
    rts

; -----------------------------------------------------------------------------
; Desc:     Returns a pseudorandom card.
; Inputs:
; Ouputs:   A (random card)
; -----------------------------------------------------------------------------
    IF TEST_RAND_ON == 2
Bank2_DealCard SUBROUTINE
    ldy RandAlt
    lda TestCards,y
    sta RandNum
    iny
    cpy #NUM_TEST_CARDS
    bne .Skip
    ldy #0
    lda TestCards,y
    sta RandNum
.Skip
    sty RandAlt
    sta Arg1

    ;
    ; do bookkeeping
    ;

    lda Arg1
    jsr Bank2_FindDiscardPosition       ; input A; output X, Y

    ; check the discard pile
    lda DiscardPile,y                   ; A = the byte
    and Bank2_Power2,x                  ; isolate the bit
    beq .NotDiscarded

    lda Arg1
    jsr Bank2_FindNextAvailableCard      ; input X, Y; output A, X, Y
    sta Arg1
.NotDiscarded

    ; mark the card as discarded
    lda DiscardPile,y                   ; load the byte
    ora Bank2_Power2,x                  ; set the bit on
    sta DiscardPile,y                   ; store the byte

    ; track how many cards have been dealt
    clc
    inc DealDepth
    lda DealDepth

    lda Arg1
    rts
    ELSE
Bank2_DealCard SUBROUTINE
    ; Calculate next random number with Galois LFSR ($b8)
    lda RandNum
    bne .SkipInx
    inx             ; prevent zeros
.SkipInx
    lsr
    bcc .SkipEor
    eor #$b8
.SkipEor
    sta RandNum
    sta NewCard

    ; verify the rank is valid: 1 <= rank <= 13
    and #CARD_RANK_MASK
    beq .InvalidRank
    cmp #CARD_RANK_MAX+1
    bcc .GoodRank
.InvalidRank
    ; RandAlt cycles from 0 to 12
    inc RandAlt
    lda RandAlt
    cmp #CARD_RANK_MAX
    bcc .NoReset                        ; if rank < 13, it's good
    lda #0
    sta RandAlt
.NoReset
    ; Merge RandAlt with the previously selected deck and suit.
    lda NewCard
    and #~CARD_RANK_MASK
    sec                                 ; +1 convert rank to 1 based
    adc RandAlt
    sta NewCard

.GoodRank
    ; get the number of decks
    lda GameOpts
    and #NUM_DECKS_MASK
    tay
    ; fix the deck to number of decks
    lda NewCard
    and Bank2_DeckMask,y
    sta NewCard

    ; verify it's not already discarded
    jsr Bank2_FindDiscardPosition       ; input A; output X, Y
    lda DiscardPile,y                   ; A = the byte
    and Bank2_Power2,x                  ; isolate the bit
    beq .NotDiscarded

    ; the card has already been dealt
    lda NewCard
    jsr Bank2_FindNextAvailableCard      ; input X, Y; output A, X, Y
    sta NewCard
.NotDiscarded

    ; mark the card as discarded
    lda DiscardPile,y                   ; load the byte
    ora Bank2_Power2,x                  ; set the bit on
    sta DiscardPile,y                   ; store the byte

    ; track how many cards have been dealt
    clc
    inc DealDepth

    ; check the deck penetration is exceeded, if so issue a shuffle
    lda GameOpts
    and #NUM_DECKS_MASK
    tay
    lda DealDepth
    cmp Bank2_DeckPenetration,y
    bcc .Return
    lda #TSK_SHUFFLE
    jsr Bank2_QueueAdd

.Return
    ; return the full card: [deck,suit,rank]
    lda NewCard
    rts

NumDecksMask
    ; decks:  0          0,1       0,1,2,3     0,1,2,3
    dc.b #%00111111, #%01111111, #%11111111, #%11111111
    ENDIF

; -----------------------------------------------------------------------------
; Card bit format:
;
;            deck    suit       rank  
;            ___     ___     ___________
;           |   |   |   |   |           |
;   Bits:   7   6   5   4   3   2   1   0

;   Decks: 0-3; Suits: 0-3
;   Ranks: 1-13 (0,14,15 are invalid)
;
;   Deck and suit bits map to the position in the discard table
;
;                bit col     table row index
;                _______     ___________
;               |       |   |           |
;   Bits:   7   6   5   4   3   2   1   0
;           |
;      top/bot half
;
;                suits col   table row index
;                    ___     ___________
;                   |   |   |           |
;   Bits:   7   6   5   4   3   2   1   0
;           |___|
;        table deck
;
; ----
; Discard table format:
;
;   Each byte represents 8 cards, so 1 bit per card. There are
;   208 cards (4 decks), which require 26 bytes of storage (208/8=26).
;   
;   Bit values: 1 = discarded, 0 = in play
;   Spades (S), Hearts (H), Clubs (C), Diamonds (D)
;   
;            |   high nibble   |    low nibble   |
;    suits-> |  S | H | C | D  |  S | H | C | D  |
;   ---------|----|---|---|----|----|---|---|----|------
;   num |rank|  7 | 6 | 5 | 4  |  3 | 2 | 1 | 0  | index
;   ----|----|-----------------------------------|------
;     1    A |    |   |   |    |    |   |   |    |  0
;     2    2 |    |   |   |    |    |   |   |    |  1
;     3    3 |    |   |   |    |    |   |   |    |  2
;     4    4 |    |   |   |    |    |   |   |    |  3
;     5    5 |    |   |   |    |    |   |   |    |  4
;     6    6 |                 |                 |  5
;     7    7 |   Deck 1 (01)   |   Deck 0 (00)   |  6
;     8    8 |                 |                 |  7
;     9    9 |    |   |   |    |    |   |   |    |  8
;    10   10 |    |   |   |    |    |   |   |    |  9
;    11    J |    |   |   |    |    |   |   |    | 10
;    12    Q |    |   |   |    |    |   |   |    | 11
;    13    K |    |   |   |    |    |   |   |    | 12
;   ----|----|----+---+---+----+----+---+---+----|------
;    14    A |    |   |   |    |    |   |   |    | 13
;    15    2 |    |   |   |    |    |   |   |    | 14
;    16    3 |    |   |   |    |    |   |   |    | 15
;    17    4 |    |   |   |    |    |   |   |    | 16
;    18    5 |    |   |   |    |    |   |   |    | 17
;    19    6 |                 |                 | 18
;    20    7 |   Deck 3 (11)   |   Deck 2 (10)   | 19
;    21    8 |                 |                 | 20
;    22    9 |    |   |   |    |    |   |   |    | 21
;    23   10 |    |   |   |    |    |   |   |    | 22
;    24    J |    |   |   |    |    |   |   |    | 23
;    25    Q |    |   |   |    |    |   |   |    | 24
;    26    K |    |   |   |    |    |   |   |    | 25
;   ----|----|-----------------------------------|------
;   num |rank|  7 | 6 | 5 | 4  |  3 | 2 | 1 | 0  | index
;   ---------|----|---|---|----|----|---|---|----|------

; -----------------------------------------------------------------------------
; Desc:     Calculates the card's row and column position into DiscardPile
; Inputs:   A (the card)
; Ouputs:   X (DiscardPile bit number: [0-7])
;           Y (DiscardPile byte offset: [0-25])
;
; TODO:     Make the subroutine work with 1 & 2 decks.
; -----------------------------------------------------------------------------
Bank2_FindDiscardPosition SUBROUTINE
    tay                                     ; save a copy

    ; retrive the high nibble & %01110000
    and #~CARD_DECK_ROW                     ; disable 7th bit
    lsr                                     ; shift [deck,suit] bits over
    lsr
    lsr
    lsr
    tax

    ; adjust the byte offset if it's in the 2nd deck row
    tya
    bmi .SecondRow
    and #CARD_RANK_MASK
    jmp .Continue
.SecondRow
    and #CARD_RANK_MASK
    clc
    adc #CARD_RANK_MAX
.Continue
    tay
    dey     ; make offset 0 based

    rts

Bank2_DeckBits
    dc.b #3
    dc.b #7
    dc.b #7
    dc.b #7

Bank2_DiscardBytes
    dc.b #13
    dc.b #13
    dc.b #26
    dc.b #26

; -----------------------------------------------------------------------------
; Desc:     Searches the discard pile for the next available card.
; Inputs:   A (original card)
;           X (DiscardPile bit number: [0-7])
;           Y (DiscardPile byte offset: [0-25])
; Outputs:  A (a new card)
; Notes:    This searches within the same row (rank) for an alternate card.
;           If no free card is found, it continues searhing in ascending order.
;           The search wraps around the bottom.
; -----------------------------------------------------------------------------
#if 1
Bank2_FindNextAvailableCard SUBROUTINE
    sty FindStart

    ; search for next available rank
.NextRow
    ldx #7

    ; fix to number of decks
    lda GameOpts
    and #NUM_DECKS_MASK
    bne .TwoPlus
    ldx #3
.TwoPlus

    ; search for next available suit
.NextCol
    lda DiscardPile,y
    and Bank2_Power2,x
    beq .Found
    dex
    bpl .NextCol

    ; advance to the next row
    iny

    ; test if looping back to the starting position
    cpy FindStart
    beq .NotFound

    ; check if this is the last row
    lda GameOpts
    and #NUM_DECKS_MASK
    tax
    tya
    cmp Bank2_DiscardBytes,x
    bcc .NextRow

    ; continue at the top row
    ldy #0
    jmp .NextRow
    
    ; Assemble the pieces of the new card:
    ;   The suit is derived from bits 0,1 of X.
    ;   The deck column is derived from bit 2 of X.
    ;   The deck row is derived from range checking Y:
    ;       0 when 0 <= Y <= 12
    ;       1 when 13 <= Y <= 25
.Found
    tya
    cmp #CARD_RANK_MAX      ; check which deck row this is
    bcc .Skip2ndRow
    ; this is the bottom row of decks (10 or 11)
    ora #CARD_DECK_ROW      ; set the deck row bit
    sec
    sbc #CARD_RANK_MAX      ; make it a valid card rank and 1 based
.Skip2ndRow
    clc
    adc #1                  ; make the rank 1 based
    sta Arg1
    ; add in the suit and bit 1 of the deck
    txa
    asl
    asl
    asl
    asl
    ora Arg1
    rts
.NotFound
    ldy Arg1
    rts

#else
Bank2_FindNextAvailableCard SUBROUTINE
    sty Arg1

    ; search for an empty spot in the current row
.NextRow
    ldx #7
    lda DiscardPile,y
    and #%10000000
    beq .Found
    dex
    lda DiscardPile,y
    and #%01000000
    beq .Found
    dex
    lda DiscardPile,y
    and #%00100000
    beq .Found
    dex
    lda DiscardPile,y
    and #%00010000
    beq .Found
    dex
    lda DiscardPile,y
    and #%00001000
    beq .Found
    dex
    lda DiscardPile,y
    and #%00000100
    beq .Found
    dex
    lda DiscardPile,y
    and #%00000010
    beq .Found
    dex
    lda DiscardPile,y
    and #%00000001
    beq .Found

    ; advance to the next row
    iny
    cpy Arg1        ; quit on the start row
    beq .NotFound

    ; check if this is the bottom row
    cpy #NUM_DISCARD_BYTES
    bcc .NextRow

    ; continue at the top row
    ldy #0
    jmp .NextRow
    
    ; Assemble the pieces of the new card:
    ;   The suit is derived from bits 0,1 of X.
    ;   The deck column is derived from bit 2 of X.
    ;   The deck row is derived from range checking Y:
    ;       0 when 0 <= Y <= 12
    ;       1 when 13 <= Y <= 25
.Found
    tya
    cmp #CARD_RANK_MAX      ; check which deck row this is
    bcc .Skip2ndRow
    ; this is the bottom row of decks (10 or 11)
    ora #CARD_DECK_ROW      ; set the deck row bit
    sec
    sbc #CARD_RANK_MAX      ; make it a valid card rank and 1 based
.Skip2ndRow
    clc
    adc #1                  ; make the rank 1 based
    sta Arg1
    ; add in the suit and bit 1 of the deck
    txa
    asl
    asl
    asl
    asl
    ora Arg1
    rts
.NotFound
    ldy Arg1
    rts
#endif
    
; -----------------------------------------------------------------------------
; Desc:     Discards the card given in the A register.
; Inputs:   A (a card)
; Ouputs:   Y (byte index into the DiscardPile)
; Notes:
;           Card = (deck) (suit) (rank)
;           bits =  7 6    5 4   3 2 1 0
; -----------------------------------------------------------------------------
Bank2_DiscardCard SUBROUTINE
    cmp #CARD_NULL                      ; ignore null cards
    beq .Return

    jsr Bank2_FindDiscardPosition

    ; load the byte
    lda DiscardPile,y                   ; A = the byte
    ora Bank2_Power2,x                  ; set the bit on
    sta DiscardPile,y                   ; save the byte back

.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Swaps the 1st ace out of the 1st card slot. No change if there are
;           two or more aces or no aces.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank2_DealerSwapAce SUBROUTINE
    lda PlayerCards+[DEALER_CARDS_OFFSET]
    and #CARD_RANK_MASK
    cmp #CARD_RANK_ACE
    bne .Return                        ; if first card is not an ace, do nothing

    ; count the aces
    ldy #1
.Loop
    lda PlayerCards+[DEALER_CARDS_OFFSET],y
    and #CARD_RANK_MASK
    cmp #CARD_RANK_ACE
    beq .Return                        ; terminate early if there is a 2nd ace
    iny
    cpy PlayerNumCards+DEALER_IDX
    bne .Loop                          ; while Y != number of cards

    ; there is only 1 ace and it's in the 1st slot, so perform the swap
    lda PlayerCards+[DEALER_CARDS_OFFSET]
    ldx PlayerCards+[DEALER_CARDS_OFFSET]+1
    sta PlayerCards+[DEALER_CARDS_OFFSET]+1
    stx PlayerCards+[DEALER_CARDS_OFFSET]

.Return
    rts

; Same as DealerSwapAce(), but for the current player.
Bank2_PlayerSwapAce SUBROUTINE
    ; get byte offset to the first card of the hand
    ldx CurrPlayer

    ; save ending position
    ldy Bank2_Multiply6,x
    tya
    clc
    adc #NUM_VISIBLE_CARDS
    sta Arg1                            ; last card slot position + 1

    ; check if first card is an ace
    lda PlayerCards,y
    and #CARD_RANK_MASK
    cmp #CARD_RANK_ACE
    bne .Return                         ; if first card is not an ace, do nothing 

    ; count the aces
    iny                                 ; Y = current card offset
.Loop
    lda PlayerCards,y
    and #CARD_RANK_MASK
    cmp #CARD_RANK_ACE
    beq .Return                         ; terminate early if there is a 2nd ace
    iny
    tya
    cmp PlayerNumCards,x
    bne .Loop                           ; while Y != number of cards

    ; swap the first card with the 2nd
    ldy Bank2_Multiply6,x
    lda PlayerCards,y
    ldx PlayerCards+1,y
    sta PlayerCards+1,y
    stx PlayerCards,y

.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Remove the 1st card from the player's onscreen hand.
; Inputs:
; Ouputs:   A (the unshifted card)
; -----------------------------------------------------------------------------
Bank2_DealerShiftCard SUBROUTINE
    ldx PlayerCards+[DEALER_CARDS_OFFSET]
    ldy #1                                      ; Y = current card
.Loop
    lda PlayerCards+[DEALER_CARDS_OFFSET],y
    sta PlayerCards+[DEALER_CARDS_OFFSET]-1,y
    iny
    cpy #NUM_VISIBLE_CARDS
    bne .Loop

    txa
    ldx #255
    stx PlayerCards+[DEALER_CARDS_OFFSET]-1,y
    rts

; Same as DealerShiftCard() but for the current player.
Bank2_PlayerShiftCard SUBROUTINE
    ldx CurrPlayer

    ldy Bank2_Multiply6,x                       ; Y = first card offset
    lda PlayerCards,y
    sta Arg2                                    ; Arg2 = first card
    tya
    clc
    adc #NUM_VISIBLE_CARDS                      ; A = Y + NUM_VISIBLE_CARDS
    sta Arg1                                    ; Arg1 = last card offset + 1
    iny                                         ; Y = second card offset
.Loop
    ; move card left
    lda PlayerCards,y
    sta PlayerCards-1,y
    iny
    cpy Arg1
    bne .Loop

    ; last card = null
    lda #CARD_NULL
    ldy Arg1
    sta PlayerCards-1,y

    ; return removed card
    lda Arg2
    rts

; -----------------------------------------------------------------------------
; Desc:     Computes the score of the selected hand.
; Inputs:   X (player index)
; Ouputs:   A (the score)
;           Y (number of aces)
; -----------------------------------------------------------------------------
Bank2_CalcHandScore SUBROUTINE
    sed

    txa                         ; A = player index
    ; save stack pointer
    tsx
    stx StackPtr
    tax                         ; X = player index
    txs                         ; SP = player index

    lda PlayerPileScore,x
    sta Score
    inx                         ; X = next player
    ldy Bank2_Multiply6,x       ; Y = last card offset + 1
                                ; (or start of next player's hand)
    ; add up card scores
    lda #0
    sta NumAces
.ScoreLoop
    dey
    lda PlayerCards,y
    and #CARD_RANK_MASK         ; A = card rank (chop off deck & suit)
    cmp #CARD_RANK_ACE
    bne .NotAce
    inc NumAces
.NotAce
    tax                         ; X = card rank
    lda Bank2_CardPointValue,x  ; look up point value of the rank
    clc
    adc Score
    sta Score                   ; Y = total score so far
    tsx                         ; X = player index
    tya
    cmp Bank2_Multiply6,x       ; if first card
    bne .ScoreLoop

    ; if there's a bust, demote any aces until <21 or out of aces
    lda Score                    ; total score
    ldy NumAces
.DemoteLoop
    ;cpy #0
    beq .Return
    cmp #BUST_SCORE
    bcc .Return
    sec
    sbc #$10                    ; demote ace
    dey
    bne .DemoteLoop

.Return
    sta Score
    ; restore stack pointer
    tsx                         ; X = player index
    txa                         ; A = player index
    ldx StackPtr
    txs
    tax                         ; X = player index
    ; save computed score
    lda Score
    sta PlayerScore,x
    ; also return # of aces
    ldy NumAces

    ; return score
    cld
    rts

; -----------------------------------------------------------------------------
; Desc:     Pay player winning chips.
; Inputs:   CurrPlayer
; Ouputs:
; -----------------------------------------------------------------------------
Bank2_PayoutWinnings SUBROUTINE
    sed

    ldx CurrPlayer

    ; pay out player winnings or refund the bet on a push
.CheckForBlackjack
    lda PlayerFlags,x
    and #FLAGS_BLACKJACK
    beq .CheckWin

    ; player has blackjack: payout 3:2
    ; pay out 1/2 now and the remainder below
    jsr Bank2_CalcHalfBetChips
    jsr Bank2_AddChips
    ldy #2
    jmp .Payout2

.CheckWin
    ldx CurrPlayer

    lda PlayerFlags,x
    and #FLAGS_WIN
    beq .CheckPush

    ; player has won: payout 2:1
    ldy #2

    ; check if there was a doubledown
    lda PlayerFlags,x
    and #FLAGS_DOUBLEDOWN_TAKEN
    beq .Payout2

    ; player won double down: payout the 2nd bet
    iny
    iny
    jmp .Payout2

.CheckPush
    lda PlayerFlags,x
    and #FLAGS_PUSH
    beq .PlayerLost

    ; player pushed: refund bet
    ldy #1

    ; check if there was a doubledown
    lda PlayerFlags,x
    and #FLAGS_DOUBLEDOWN_TAKEN
    beq .Payout2

    ; refund the double down bet
    iny
    jmp .Payout2

.PlayerLost
    ; check if the player took insurance
    lda PlayerFlags,x
    and #FLAGS_INSURANCE_TAKEN
    beq .Return

    ; check for dealer blackjack
    lda #FLAGS_BLACKJACK
    bit PlayerFlags+DEALER_IDX
    beq .Return

    ; check for bust; insurance does not pay out on a bust
    lda PlayerFlags,x
    and #FLAGS_BUST
    bne .Return
    ; player took insurance and dealer had blackjack
    ; payout 2:1; payout = (1/2 * currbet) * 2

.Payout1
    ldy #1
.Payout2
.Continue
    jsr Bank2_AddBetChips
    dey
    bne .Payout2

.Return
    cld
    rts

; -----------------------------------------------------------------------------
; Desc:     Calculates half the current bet in BCD.
; Inputs:   CurrBet (BCD)
; Ouputs:   Arg1, Arg2 (BCD)
; Notes:
;      3:2 payout = bet + (3 * bet / 2) = 2.5 x bet
;      For each thousands, hundreds, tens places:
;         treat digit as tens place (to keep the lookup table small: 20 elems)
;         divide by 2 and add to running total
;      One's and hundred's places are special cases.
;
;      Example: 2345 chips * 0.5
;        2000 / 2 = 1000
;      +  300 / 2 =  150
;      +   40 / 2 =   20
;      +    5 / 2 =    2
;      -----------------
;      =            1172
;
;      Example: 9999 chips * 0.5
;        9000 / 2 = 4500
;      +  900 / 2 =  450
;      +   90 / 2 =   45
;      +    9 / 2 =    4
;      -----------------
;      =            4999
; -----------------------------------------------------------------------------
;
; $ff = 1111 1111 
;     = 0 1001 1001 = $099
;       x 2
;     = 1 0011 0010 = $132
;
; -----------------------------------------------------------------------------
Bank2_CalcHalfBetChips SUBROUTINE
    lda #0
    sta Arg1
    sta Arg2

    clc

    ; one's place
    lda CurrBet+1
    and #$0F                               ; retrieve low digit tay
    tay
    lda Bank2_BcdOnesDivide2,y             ; divide by 2
    sta Arg2

    ; ten's place
    lda CurrBet+1
    and #$F0                               ; retrieve high digit
    lsr
    lsr
    lsr
    lsr                                    ; high digit / 10
    tay
    lda Bank2_BcdTensDivide2,y             ; divide by 2
    adc Arg2
    sta Arg2

    ; hundred's place
    ; special case: the result digits are split across the nibbles
    lda CurrBet
    and #$0F                               ; retrieve low digit
    tay
    lda Bank2_BcdTensDivide2,y             ; add in portion spilled into next nibble
    and #$0F                               ; retrieve low digit
    asl
    asl
    asl
    asl
    adc Arg2
    sta Arg2

    lda CurrBet
    and #$0F                               ; retrieve low digit
    tay
    lda Bank2_BcdTensDivide2,y             ; divide by 2
    and #$F0                               ; retrieve high digit
    lsr
    lsr
    lsr
    lsr                                    ; high digit = 100's
    adc Arg1
    sta Arg1

    ; thousand's place
    lda CurrBet
    and #$F0                               ; retrieve high digit
    lsr
    lsr
    lsr
    lsr                                    ; high digit / 10
    tay
    lda Bank2_BcdTensDivide2,y             ; divide by 2
    adc Arg1
    sta Arg1

    rts

; -----------------------------------------------------------------------------
; Desc:     Adds CurrBet chips to player's chips. Decimal mode must be set before calling.
; Inputs:   CurrBet (MSB, LSB)
; Ouputs:       
; -----------------------------------------------------------------------------
Bank2_AddBetChips SUBROUTINE
    clc
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+2
    adc CurrBet+1
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+2
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+1
    adc CurrBet
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+1
    lda PlayerChips+PLAYER1_CHIPS_OFFSET
    adc #0
    sta PlayerChips+PLAYER1_CHIPS_OFFSET
    rts

; -----------------------------------------------------------------------------
; Desc:     Subtracts CurrBet chips from player's chips. Decimal mode must be set before calling.
; Inputs:   CurrBet (MSB, LSB)
; Ouputs:       
; -----------------------------------------------------------------------------
Bank2_SubtractBetChips SUBROUTINE
    sec
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+2
    sbc CurrBet+1
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+2
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+1
    sbc CurrBet
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+1
    lda PlayerChips+PLAYER1_CHIPS_OFFSET
    sbc #0
    sta PlayerChips+PLAYER1_CHIPS_OFFSET
    rts

; -----------------------------------------------------------------------------
; Desc:     Adds chips to player's chips. Decimal mode must be set before calling.
; Inputs:   Arg1 (MSB), Arg2 (LSB)
; Ouputs:       
; -----------------------------------------------------------------------------
Bank2_AddChips SUBROUTINE
    ; additions above can't overflow, but additions below can.
    clc
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+2
    adc Arg2
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+2
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+1
    adc Arg1
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+1
    lda PlayerChips+PLAYER1_CHIPS_OFFSET
    adc #0
    sta PlayerChips+PLAYER1_CHIPS_OFFSET
    rts

; -----------------------------------------------------------------------------
; Desc:     Subtracts chips from player's chips. Decimal mode must be set before calling.
; Inputs:   Arg1 (MSB), Arg2 (LSB)
; Ouputs:       
; -----------------------------------------------------------------------------
Bank2_SubtractChips SUBROUTINE
    sec
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+2
    sbc Arg2
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+2
    lda PlayerChips+PLAYER1_CHIPS_OFFSET+1
    sbc Arg1
    sta PlayerChips+PLAYER1_CHIPS_OFFSET+1
    lda PlayerChips+PLAYER1_CHIPS_OFFSET
    sbc #0
    sta PlayerChips+PLAYER1_CHIPS_OFFSET
    rts

; -----------------------------------------------------------------------------
; Desc;     Check user input for dashboard navigation.
; Inputs:        
; Ouputs:       
; -----------------------------------------------------------------------------
Bank2_DashboardNavigate SUBROUTINE
.CheckRight
    lda #JOY0_RIGHT_MASK
    bit JoyRelease
    beq .CheckLeft

    GET_DASH_MENU
    tay

    ; search right for an allowed menu item
.RetryInc
    iny
    cpy #DASH_MAX+1
    bcc .VerifyInc
    ldy #0
.VerifyInc
    ; check if the next dashboard option is allowed
    lda Bank2_DashboardFlagsTable,y
    and GameFlags
    beq .RetryInc
    jmp .Update

.CheckLeft
    lda #JOY0_LEFT_MASK
    bit JoyRelease
    beq .Return

    GET_DASH_MENU
    tay

    ; search left for an allowed menu item
.RetryDec
    dey
    bpl .VerifyDec
    ldy #DASH_MAX
.VerifyDec
    ; check if the next dashboard option is allowed
    lda Bank2_DashboardFlagsTable,y
    and GameFlags
    beq .RetryDec
    jmp .Update

.Update
    SET_DASH_MENU

    lda Bank2_DashboardStates,y
    sta GameState

    lda #SOUND_ID_NAVIGATE
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

.Return
    rts

; -----------------------------------------------------------------------------
; Desc;     Animates the current card for the given player.
; Inputs:   X register (player id)
; Ouputs:       
; -----------------------------------------------------------------------------
Bank2_AnimateCard SUBROUTINE
    txa
    asl
    asl
    asl
    ora PlayerNumCards,x                ; num cards
    sec
    sbc #1                              ; turn num cards into a column
    sta Bank2_AddPos                    ; position (row, column)
    lda #ANIM_ID_FLIP_CARD
    sta Bank2_AddID
    CALL_BANK PROC_ANIMATIONADD, 3, 2

    lda #TSK_FLIP_CARD
    jsr Bank2_QueueAdd

    rts

; -----------------------------------------------------------------------------
; Task handlers.
; -----------------------------------------------------------------------------
DoNothing SUBROUTINE
    rts

; -----------------------------------------------------------------------------
; Desc:     Deal a card to the current player. Performing the deal as a task
;   
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
DoDealCard SUBROUTINE
    jsr Bank2_DealCard
    tay                             ; Y = new card
    clc
    ldx CurrPlayer                  ; X = player index
    lda Bank2_Multiply6,x           ; A = starting card offset
    adc PlayerNumCards,x            ; A = next card offset
    tax                             ; X = next card offset
    sty PlayerCards,x
    
    ldx CurrPlayer
    inc PlayerNumCards,x

    ; check if this is the hole card; don't animate if it is
    cpx #DEALER_IDX
    bne .Animate
    lda PlayerNumCards,x
    cmp #2
    beq .Return
.Animate
    jsr Bank2_AnimateCard 
.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Advances the card flipping animation to the next frame. Removes
;           itself from task work when the animation completes. The player
;           is paused during the animation.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
DoFlipCard SUBROUTINE
    ; check if there are animations
    lda #ANIM_ID_NONE
    ldx #ANIM_QUEUE_LEN-1
.Loop
    cmp AnimID,x
    bne .Tick
    dex
    bpl .Loop

FlipDone
    ; animation done; disable task
    ;lda #TSK_NONE
    ;ldy #TSK_FLIP_CARD
    ;jsr Bank2_QueueReplace
    lda #TSK_FLIP_CARD
    jsr Bank2_QueueRemove
    
    rts

    ; advance animation frame
.Tick
    lda #%00000111
    bit FrameCtr
    bne .SkipAnim
    CALL_BANK PROC_ANIMATIONTICK, 3, 2
.SkipAnim
    rts

; -----------------------------------------------------------------------------
; Desc:     Virtually shuffles the shoe by emptying the discard pile. Resets
;           TaskQueue state upon completion.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
DoShuffle SUBROUTINE
    lda #TSK_NONE
    ldy #TSK_SHUFFLE
    jsr Bank2_QueueReplace

    lda #0
    sta DealDepth

    ldx #NUM_DISCARD_BYTES-1
.Loop
    sta DiscardPile,x
    dex
    bpl .Loop

    ; re-seed random number
    lda FrameCtr
    sta RandNum

    lda #TSK_DEALER_DISCARD
    jsr Bank2_QueueAdd

    lda #SOUND_ID_SHUFFLE0
    sta Arg1
    lda #SOUND_ID_SHUFFLE1
    sta Arg2
    CALL_BANK PROC_SOUNDQUEUEPLAY2, 1, 2
    rts

; -----------------------------------------------------------------------------
; Desc:     Adds the dealer's current hand to the discard pile.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
DoDealerDiscard SUBROUTINE
    lda #TSK_NONE
    ldy #TSK_DEALER_DISCARD
    jsr Bank2_QueueReplace

    ; add any currently active cards to the discard pile
    ; count the aces
    lda #0
    sta Arg1
.Loop2
    ldy Arg1
    lda PlayerCards+[DEALER_CARDS_OFFSET],y
    jsr Bank2_DiscardCard
    inc Arg1
    lda Arg1
    cmp PlayerNumCards+DEALER_IDX
    bcc .Loop2

    rts

; Same as for DoDealerDiscard() but for player's hand 1
DoPlayer1Discard SUBROUTINE
    lda #TSK_NONE
    ldy #TSK_PLAYER1_DISCARD
    jsr Bank2_QueueReplace

    ldx #PLAYER1_IDX
    lda Bank2_Multiply6,x
    tay                                 ; Y = start offset
    sta Arg1                            ; Arg1 = start offset
    clc
    adc #NUM_VISIBLE_CARDS-1
    sta Arg2                            ; Arg2 = end offset

.NextCard
    lda PlayerCards,y                   ; Y = current card

    ; discard card
    cmp #CARD_NULL                      ; skip null cards
    beq .Skip
    jsr Bank2_FindDiscardPosition
    ; load the byte
    lda DiscardPile,y                   ; A = the byte
    ora Bank2_Power2,x                  ; set the bit on
    sta DiscardPile,y                   ; save the byte back
.Skip
    inc Arg1
    ldy Arg1
    cpy Arg2
    bne .NextCard

    rts

; Same as for DoDealerDiscard() but for player's hand 2
DoPlayer2Discard SUBROUTINE
    lda #TSK_NONE
    ldy #TSK_PLAYER2_DISCARD
    jsr Bank2_QueueReplace

    ldx #PLAYER2_IDX
    lda Bank2_Multiply6,x
    tay                                 ; Y = start offset
    sta Arg1                            ; Arg1 = start offset
    clc
    adc #NUM_VISIBLE_CARDS-1
    sta Arg2                            ; Arg2 = end offset

.NextCard
    lda PlayerCards,y                   ; Y = current card

    ; discard card
    cmp #CARD_NULL                      ; skip null cards
    beq .Skip
    jsr Bank2_FindDiscardPosition
    ; load the byte
    lda DiscardPile,y                   ; A = the byte
    ora Bank2_Power2,x                  ; set the bit on
    sta DiscardPile,y                   ; save the byte back
.Skip
    inc Arg1
    ldy Arg1
    cpy Arg2
    bne .NextCard

    rts

#if 0
; -----------------------------------------------------------------------------
; Desc:     Advances the card flipping animation to the next frame. Removes
;           itself from task work when the animation completes. The player
;           is paused during the animation.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
; TSK_RANDOM_NUM
DoPreRandom SUBROUTINE
    jsr Bank2_GetRandomByte             ; A = random number
    lda #TSK_NONE
    sta TaskQueue
    rts
#endif

; -----------------------------------------------------------------------------
; Runs a short animation on player winning the hand.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
DoBlackJackAnim SUBROUTINE
    ; check if there are animations
    lda #ANIM_ID_NONE
    ldx #ANIM_QUEUE_LEN-1
.Loop
    cmp AnimID,x
    bne .Tick
    dex
    bpl .Loop

    ; animation done; disable task
    lda #TSK_NONE
    ldy #TSK_BLACKJACK
    jsr Bank2_QueueReplace
    rts

    ; advance animation frame
.Tick
    lda #%00000111
    bit FrameCtr
    bne .SkipAnim
    CALL_BANK PROC_ANIMATIONTICK, 3, 2
.SkipAnim
    rts

DoPopupOpen SUBROUTINE
    lda #TSK_NONE
    ldy #TSK_POPUP_OPEN
    jsr Bank2_QueueReplace
    rts

; -----------------------------------------------------------------------------
; Game state handlers.
; -----------------------------------------------------------------------------
WaitTitleScreen SUBROUTINE
    rts

; begins new game
ActionNewGame SUBROUTINE
    jsr Bank2_ResetGame

    ; assign to blank sprites
    lda #<BlankCard
    ldx #>BlankCard
    ldy #NUM_VISIBLE_CARDS*2-2
.InitPtrs
    sta SpritePtrs,y
    stx SpritePtrs+1,y
    dey
    dey
    bpl .InitPtrs

    ; reset state variables
    lda CurrState
    and #CURR_BET_MENU_MASK
    ora #CURR_HOLE_CARD_MASK | [ DASH_START_SELECTION << 3]
    sta CurrState
    lda #PLAYER1_IDX
    sta CurrPlayer

    ; seed random number
    lda FrameCtr
    sta RandNum

    IF TEST_RAND_ON == 2
        lda #0
    ELSE
        lda INTIM
    ENDIF
    sta RandAlt

    ; advance game state to betting round
    lda #GS_PLAYER_BET
    sta GameState
    rts

; betting screen: waits for player input
WaitPlayerBet SUBROUTINE
    ; reload difficulty options
    lda GameOpts
    and #NUM_DECKS_MASK
    sta GameOpts
    lda SWCHB
    and #[FLAGS_LATE_SURRENDER | FLAGS_HIT_SOFT17]
    ora GameOpts
    sta GameOpts

    ; check if the number of decks changed and then reshuffle.
    lda #SWITCH_SELECT_MASK
    bit JoyRelease
    beq .CheckKeypad
    jsr Bank2_DeckChange
    lda #TSK_SHUFFLE
    jsr Bank2_QueueAdd
    jmp .CheckKeypad
    lda #SOUND_ID_ERROR
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

.CheckKeypad
    ; handle keypad number entry
    lda KeyPress
    beq .CheckJoystick

.CheckJoystick
    ; handle joystick menu navigation: get current selection
    jsr Bank2_GetBetMenu
    sta BetSelect

    ; check for joystick input
.CheckLeft
    lda #JOY0_LEFT_MASK
    bit JoyRelease
    beq .CheckRight
    lda BetSelect
    beq .UpdateState
    dec BetSelect
    jmp .UpdateState

.CheckRight
    lda #JOY0_RIGHT_MASK
    bit JoyRelease
    beq .CheckUp
    lda #NUM_SPRITES-1
    cmp BetSelect
    beq .UpdateState
    inc BetSelect
    jmp .UpdateState

.CheckUp
    lda #JOY0_UP_MASK
    bit JoyRelease
    beq .CheckDown
    lda #GS_PLAYER_BET_UP
    sta GameState
    jmp .Return

.CheckDown
    lda #JOY0_DOWN_MASK
    bit JoyRelease
    beq .CheckFire
    lda #GS_PLAYER_BET_DOWN
    sta GameState
    jmp .Return

.CheckFire
    lda #JOY_FIRE_PACKED_MASK
    bit JoyRelease
    beq .Return

    ; bet is selected: make sure CurrBet is > 0
    lda CurrBet
    adc CurrBet+1
    bne .FirstDeal

    lda #SOUND_ID_ERROR
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    jmp .Return

.FirstDeal
    lda #GS_OPEN_DEAL1
    sta GameState
    lda #DEALER_IDX
    sta CurrPlayer

.UpdateState
    ; update currently selected menu
    lda BetSelect
    jsr Bank2_SetBetMenu

    lda #SOUND_ID_STAND
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

.Return
    ;jsr Bank2_ClearEvents
    cld
    rts

; decreases bet by currently selected denomination
ActionPlayerBetDown SUBROUTINE
    sed
    jsr Bank2_GetBetMenu
    tax
    jsr Bank2_CheckCanReturnChips
    beq .Return
    jsr Bank2_DecreaseBet
    jsr Bank2_IncreasePlayerChips

.Return
    cld
    lda #GS_PLAYER_BET
    sta GameState
    rts

; increases bet by currently selected denomination
ActionPlayerBetUp SUBROUTINE
    sed
    jsr Bank2_GetBetMenu
    tax
    jsr Bank2_IncreaseBet
    lda #0
    sta Arg1
    lda Bank2_DenomValue,x
    sta Arg2
    jsr Bank2_PlayerHasEnoughChips
    bne .AllowBet

    ; player does not have enough chips; restore CurrBet to previous value
    jsr Bank2_DecreaseBet
    jmp .Return

.AllowBet
    jsr Bank2_DecreasePlayerChips
.Return
    cld
    lda #GS_PLAYER_BET
    sta GameState
    rts

; -----------------------------------------------------------------------------
; Desc:     This is the opening deal: two cards for each player. The opening
;           deal is split across handlers to spread work across multiple TV
;           frames. DealCard is computationally expensive when the discard pile
;           is filled up.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
ActionOpenDeal1 SUBROUTINE
    lda #DEALER_IDX
    sta CurrPlayer

    ; advance state
    lda #GS_OPEN_DEAL2
    sta GameState

    jsr DoDealCard
    rts

ActionOpenDeal2 SUBROUTINE
    lda #PLAYER1_IDX
    sta CurrPlayer

    ; advance state
    lda #GS_OPEN_DEAL3
    sta GameState

    jsr DoDealCard
    rts

ActionOpenDeal3 SUBROUTINE
    lda #DEALER_IDX
    sta CurrPlayer

    ; advance state
    lda #GS_OPEN_DEAL4
    sta GameState

    jsr DoDealCard
    rts

ActionOpenDeal4 SUBROUTINE
    lda #PLAYER1_IDX
    sta CurrPlayer

    ; advance state
    lda #GS_OPEN_DEAL5
    sta GameState

    jsr DoDealCard
    rts

ActionOpenDeal5 SUBROUTINE
    ; calculate scores
    ldx #DEALER_IDX
    jsr Bank2_CalcHandScore

    ldx CurrPlayer
    jsr Bank2_CalcHandScore

    ; advance state
    lda #GS_DEALER_SET_FLAGS
    sta GameState

    lda #TSK_POPUP_OPEN
    ldx #ARG_POPUP_OPEN
    jsr Bank2_QueueAdd
    rts

; opening move checks:
;   * check for dealer blackjack (and remember for later)
;   * make idiompotent
ActionDealerSetFlags SUBROUTINE
    lda PlayerFlags+DEALER_IDX

    ; check for blackjack score
    ldy PlayerScore+DEALER_IDX
    cpy #BLACKJACK_SCORE
    bne .Return
    ora #FLAGS_21           ; dealer has 21

    ; check if it's with 2 cards
    ldy PlayerNumCards+DEALER_IDX
    cpy #2
    bne .Return
    ora #FLAGS_BLACKJACK    ; turn on the dealer's blackjack flag

.Return
    sta PlayerFlags+DEALER_IDX

    ; advance state
    lda #GS_PLAYER_SET_FLAGS
    sta GameState
    rts

; opening move checks:
;   * enable/disable doubledown, split, surrender, and insurance
;   * check for player blackjack
;   * called for each player hand
ActionPlayerSetFlags SUBROUTINE
    ldx CurrPlayer
    lda GameFlags

    ; disable flags
    and #~FLAGS_ALLOWED_MASK        ; disable flags set by this routine
    ora #FLAGS_HIT_ALLOWED          ; enable hit

    ; allow surrender and doubledown if this is an opening deal
    ldy PlayerNumCards,x
    cpy #2                          ; check for only 2 cards
    bne .SkipSurrender

    ; enable surrender and doubledown
    ora #[FLAGS_SURRENDER_ALLOWED | FLAGS_DOUBLEDOWN_ALLOWED]
.SkipSurrender
    sta GameFlags

    ; check if dealer has a blackjack and it's a late surrender game
    ; then disallow surrender 
    lda #FLAGS_BLACKJACK
    bit PlayerFlags+DEALER_IDX
    beq .SurrAllowed

    lda #FLAGS_LATE_SURRENDER
    bit GameOpts
    beq .SurrAllowed

    ; disable surrender: dealer has blackjack and game is late surrender
    lda GameFlags
    and #~FLAGS_SURRENDER_ALLOWED
    sta GameFlags
.SurrAllowed

    ; check if score is 21
    ldy PlayerScore,x
    cpy #BLACKJACK_SCORE
    bne .Continue

    ; set 21 flag
    lda PlayerFlags,x
    ora #FLAGS_21
    sta PlayerFlags,x

    ; if there is a split, there can't be a natural blackjack
    lda #FLAGS_SPLIT_TAKEN
    bit GameFlags
    bne .Continue

    ; blackjack must have 2 cards
    ldy PlayerNumCards,x
    cpy #2
    bne .Continue

    ; player has blackjack; set blackjack flag
    lda PlayerFlags,x
    ora #FLAGS_BLACKJACK
    sta PlayerFlags,x

    ; check if the dealer also has a blackjack
    lda #FLAGS_BLACKJACK
    bit PlayerFlags+DEALER_IDX
    beq .Blackjack

    ; both have blackjack, so player pushes
    lda PlayerFlags,x
    and #~FLAGS_BLACKJACK
    ora #FLAGS_PUSH
    sta PlayerFlags,x

    lda PlayerFlags+DEALER_IDX
    and #~FLAGS_BLACKJACK
    ora #FLAGS_PUSH
    sta PlayerFlags+DEALER_IDX

    jmp .HandOver

.Blackjack
    ; dealer does not have blackjack, so player wins
    lda PlayerFlags,x
    ora #FLAGS_WIN
    sta PlayerFlags,x

.HandOver
    lda #GS_PLAYER_HAND_OVER
    sta GameState
    rts

.Continue
    ; check if player previously split (insurance cannot be taken again
    ; because the player knows dealer does not have a blackjack) 
    lda #FLAGS_SPLIT_TAKEN
    bit GameFlags
    bne .PlayerTurn

    ; player has not split; check there are 2 equivalently valued cards

    ; look up 1st card
    ldy Bank2_Multiply6,x
    lda PlayerCards,y
    and #CARD_RANK_MASK
    tay
    lda Bank2_CardPointValue,y
    sta Arg1                        ; Arg1 = 1st card

    ; lookup 2nd card
    ldy Bank2_Multiply6,x
    lda PlayerCards+1,y
    and #CARD_RANK_MASK
    tay
    lda Bank2_CardPointValue,y      ; A = 2nd card

    ; compare 1st and 2nd cards
    cmp Arg1
    bne .CheckInsurance

    ; split allowed
    lda GameFlags
    ora #FLAGS_SPLIT_ALLOWED
    sta GameFlags

.CheckInsurance
    ; check if dealer's up card is an ace
    lda PlayerCards+DEALER_CARDS_OFFSET
    and #CARD_RANK_MASK
    cmp #CARD_RANK_ACE
    beq .OfferInsurance

    ; check if dealer's up card is a 10 point card
    tay
    lda Bank2_CardPointValue,y
    cmp #10
    bne .PlayerTurn

.OfferInsurance
    ; dealer's up card is an ace or a 10 value card, so offer insurance
    lda GameFlags
    ora #FLAGS_INSURANCE_ALLOWED
    sta GameFlags

.PlayerTurn
    lda #GS_PLAYER_TURN
    sta GameState

    ; force split allowed: remove this hack for real play
    ;lda GameFlags
    ;ora #FLAGS_SPLIT_ALLOWED
    ;sta GameFlags

    rts

WaitPlayerTurn SUBROUTINE
    ldx CurrPlayer

    ; check if player wants to hit
    lda #JOY0_DOWN_MASK | JOY_FIRE_PACKED_MASK
    bit JoyRelease
    beq .CheckStand

    ; player has hit
    lda #GS_PLAYER_PRE_HIT
    sta GameState

    lda #SOUND_ID_HIT
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

    ; check if dealer has blackjack before proceeding
    lda #FLAGS_BLACKJACK
    bit PlayerFlags+DEALER_IDX
    beq .Return

    ; reload current player
    ldx CurrPlayer

    ; dealer has blackjack; player lost
    lda #GS_DEALER_HAND_OVER
    sta GameState
    jmp .Return

.CheckStand
    lda #JOY0_UP_MASK
    bit JoyRelease
    beq .CheckNavigation

    ; player stands
    lda #GS_PLAYER_HAND_OVER
    sta GameState

    lda #SOUND_ID_STAND
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    
    jmp .Return

.CheckNavigation
    jsr Bank2_DashboardNavigate

.Return
    rts

WaitPlayerStay SUBROUTINE
    ; check if player wants to stand
    lda #JOY0_DOWN_MASK | JOY0_UP_MASK | JOY_FIRE_PACKED_MASK
    bit JoyRelease
    beq .CheckNavigation

    ; player stands
    lda #GS_PLAYER_HAND_OVER
    sta GameState

    lda #SOUND_ID_STAND
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    
    jmp .Return

.CheckNavigation
    jsr Bank2_DashboardNavigate

.Return
    rts

; player hits:
; * check for an empty card slot
; * if hand is full, shift 1st non-ace into pile score
; * an ace may be removed if there are 2+ aces
ActionPlayerPreHit SUBROUTINE
    ldx CurrPlayer

    ; check if there are open card slots
    lda PlayerNumCards,x
    cmp #NUM_VISIBLE_CARDS
    bcc .Return

    ; slots are full: pull the 1st card and shift remaining cards left
    jsr Bank2_PlayerSwapAce             ; move the Ace if it's first
    jsr Bank2_PlayerShiftCard           ; A is the unshifted card

    ; add the pulled card to the total
    ldx CurrPlayer

    and #CARD_RANK_MASK                 ; A = rank value
    cmp #CARD_RANK_ACE                  ; shifting an ace is a special case
    bne .NotAnAce

    ; card is an ace (merge into the pile score)
    sed
    clc

    ; pulled ace is always a demoted ace (1 point)
    lda PlayerPileScore,x
    adc #1
    sta PlayerPileScore,x
    cld

    jmp .DecrementCards

.NotAnAce
    tay                                 ; Y = card rank
    sed
    clc
    ; add score into pile score
    lda PlayerPileScore,x
    adc Bank2_CardPointValue,y          ; lookup rank score and add
    sta PlayerPileScore,x
    cld

.DecrementCards
    dec PlayerNumCards,x

.Return
    ; disable options after the 1st hit
    lda GameFlags
    and #~[FLAGS_DOUBLEDOWN_ALLOWED|FLAGS_SURRENDER_ALLOWED|FLAGS_INSURANCE_ALLOWED|FLAGS_SPLIT_ALLOWED]
    sta GameFlags

    lda #GS_PLAYER_HIT
    sta GameState

    rts

ActionPlayerHit SUBROUTINE
    lda #GS_PLAYER_POST_HIT
    sta GameState

    ;jsr Bank2_ClearEvents
    jsr DoDealCard
    rts

ActionPlayerPostHit SUBROUTINE
    ldx CurrPlayer
    jsr Bank2_CalcHandScore

    ; check for a bust
    cmp #BUST_SCORE
    bmi .CheckWin

    ; player busted; hand is over
    lda #GS_PLAYER_HAND_OVER
    sta GameState
    lda PlayerFlags,x
    ora #FLAGS_BUST | FLAGS_LOST
    sta PlayerFlags,x
    jmp .Return

.CheckWin
    ; check if player has 21 points
    cmp #BLACKJACK_SCORE
    bne .Continue

    ; player has 21; end the hand
    lda #GS_PLAYER_HAND_OVER
    sta GameState
    lda PlayerFlags,x
    ora #FLAGS_21
    sta PlayerFlags,x
    jmp .Return

.Continue
    ; check if ths is a double down hit
    ldx CurrPlayer

    lda PlayerFlags,x
    and #FLAGS_DOUBLEDOWN_TAKEN
    beq .PlayerTurn

    ; player doubled down; hand is over
    lda #GS_PLAYER_HAND_OVER
    sta GameState
    jmp .Return
    
.PlayerTurn
    lda #GS_PLAYER_TURN
    sta GameState

.Return
    ;jsr Bank2_ClearEvents
    rts

WaitPlayerSurrender SUBROUTINE
    ; check if player surrendered
    lda #JOY0_DOWN_MASK | JOY_FIRE_PACKED_MASK
    bit JoyRelease
    beq .CheckNavigation

    ; check if surrender allowed
    lda #FLAGS_SURRENDER_ALLOWED
    bit GameFlags
    beq .NotAllowed

    lda #SOUND_ID_SURRENDER
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

    ; player surrendered; hand is over
    ldx CurrPlayer

    lda PlayerFlags,x
    and #[~FLAGS_HANDOVER]  ; turn off previously set win/push states
    ora #FLAGS_LOST
    sta PlayerFlags,x

    ; pay back 1/2 the bet chips
    sed
    jsr Bank2_CalcHalfBetChips
    jsr Bank2_AddChips
    cld

    ; check if surrendering the split hand or main hand
    ldx CurrPlayer
    beq .HandOver

    ; surrended split hand; continue to main hand
    dec CurrPlayer

    lda #GS_PLAYER_SET_FLAGS
    sta GameState
    jmp .Return   

.HandOver
    lda #GS_DEALER_HAND_OVER
    sta GameState
    jmp .Return

.NotAllowed
    lda #SOUND_ID_ERROR
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    jmp .Return

.CheckNavigation
    jsr Bank2_DashboardNavigate

.Return
    ;jsr Bank2_ClearEvents
    rts

WaitPlayerDoubleDown SUBROUTINE
    ; check if player double downed
    lda #JOY0_DOWN_MASK | JOY_FIRE_PACKED_MASK
    bit JoyRelease
    beq .CheckNavigation

    ; check if double down allowed
    lda #FLAGS_DOUBLEDOWN_ALLOWED
    bit GameFlags
    beq .NotAllowed

    ; check if player has enough chips
    lda CurrBet
    sta Arg1
    lda CurrBet+1
    sta Arg2

    jsr Bank2_PlayerHasEnoughChips
    beq .NotAllowed

    lda #SOUND_ID_DOUBLEDOWN
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

    ; player has enough chips
    jsr Bank2_ApplyCurrBet

    ldx CurrPlayer

    lda PlayerFlags,x
    ora #FLAGS_DOUBLEDOWN_TAKEN
    sta PlayerFlags,x

    ; turn off double down
    lda GameFlags
    and #[~FLAGS_DOUBLEDOWN_ALLOWED]
    sta GameFlags

    ; reset current dashboard selection
    lda #DASH_HIT_IDX << 3
    jsr Bank2_SetDashMenu

    ; proceed to hit
    lda #GS_PLAYER_PRE_HIT
    sta GameState
    jmp .Return

.NotAllowed
    lda #SOUND_ID_ERROR
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    jmp .Return

.CheckNavigation
    jsr Bank2_DashboardNavigate

.Return
    ;jsr Bank2_ClearEvents
    rts

WaitPlayerInsurance SUBROUTINE
    ; check if player chose insurance
    lda #JOY0_DOWN_MASK | JOY_FIRE_PACKED_MASK
    bit JoyRelease
    beq .CheckNavigation

    ; check if insurance allowed
    lda #FLAGS_INSURANCE_ALLOWED
    bit GameFlags
    beq .NotAllowed

    ; fixing insurance bet to 1/2 current bet
    sed
    jsr Bank2_CalcHalfBetChips
    jsr Bank2_PlayerHasEnoughChips
    beq .NotAllowed
    jsr Bank2_SubtractChips
    cld

    lda #SOUND_ID_INSURANCE
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

    ldx CurrPlayer

    lda PlayerFlags,x
    ora #FLAGS_INSURANCE_TAKEN
    sta PlayerFlags,x

    ; turn off insurance
    lda GameFlags
    and #[~FLAGS_INSURANCE_ALLOWED]
    sta GameFlags

    ; reset current dashboard selection
    lda #DASH_HIT_IDX << 3
    jsr Bank2_SetDashMenu

    ; return to normal play
    lda #GS_PLAYER_TURN
    sta GameState
    jmp .Return

.NotAllowed
    cld
    lda #SOUND_ID_ERROR
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    jmp .Return

.CheckNavigation
    jsr Bank2_DashboardNavigate

.Return
    ;jsr Bank2_ClearEvents
    rts

WaitPlayerSplit SUBROUTINE
    lda #JOY0_DOWN_MASK | JOY_FIRE_PACKED_MASK
    bit JoyRelease
    bne .CheckSplitAllowed 
    jmp .CheckNavigation        ; branch exceeds 256 bytes

.CheckSplitAllowed
    ; check if split allowed
    lda #FLAGS_SPLIT_ALLOWED
    bit GameFlags
    beq .NotAllowed

    ; check if player has enough chips
    lda CurrBet
    sta Arg1
    lda CurrBet+1
    sta Arg2

    jsr Bank2_PlayerHasEnoughChips
    bne .Allowed

.NotAllowed
    lda #SOUND_ID_ERROR
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    jmp .Return

.Allowed
    lda #SOUND_ID_SPLIT
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

    ; player has enough chips
    jsr Bank2_ApplyCurrBet

    lda GameFlags
    ; flag as split
    ora #FLAGS_SPLIT_TAKEN
    ; prevent further splits on split hands
    and #[~FLAGS_SPLIT_ALLOWED]
    sta GameFlags

    ; move 2nd card to split hand
    lda PlayerCards+PLAYER1_CARDS_OFFSET+1
    sta PlayerCards+PLAYER2_CARDS_OFFSET

    ; adjust split hand score
    and #CARD_RANK_MASK
    tax
    lda Bank2_CardPointValue,x
    sta PlayerScore+PLAYER2_IDX

    ; adjust main hand score
    lda PlayerCards+PLAYER1_CARDS_OFFSET
    and #CARD_RANK_MASK
    tax
    lda Bank2_CardPointValue,x
    sta PlayerScore+PLAYER1_IDX

    ; adjust number of cards
    lda #1
    sta PlayerNumCards+PLAYER1_IDX
    sta PlayerNumCards+PLAYER2_IDX

    ; erase moved card
    lda #CARD_NULL
    sta PlayerCards+PLAYER1_CARDS_OFFSET+1

    ; play moves to the split hand
    lda #PLAYER2_IDX
    sta CurrPlayer

    ; reset current dashboard selection
    lda #DASH_HIT_IDX << 3
    jsr Bank2_SetDashMenu

    ; turn off insurance; insurance can't be taken on split hands (as the player now knows
    ; the dealer does not have blackjack)
    lda GameFlags
    and #[~FLAGS_INSURANCE_ALLOWED]
    sta GameFlags

    ; continue play
    lda #GS_PLAYER_SPLIT_DEAL
    sta GameState

#if 0
    ; deal a card
    lda #TSK_DEAL_CARD
    jsr Bank2_QueueAdd
#endif
    jmp .Return

.CheckNavigation
    jsr Bank2_DashboardNavigate

.Return
    ;jsr Bank2_ClearEvents
    rts

ActionPlayerSplitDeal SUBROUTINE
    ldx CurrPlayer
    jsr Bank2_CalcHandScore

    ; pass the deal the next hand
    dec CurrPlayer
    bpl .Return

    ; all split hands dealt; begin play
    lda #GS_PLAYER_SET_FLAGS
    sta GameState
    lda #PLAYER2_IDX
    sta CurrPlayer

.Return
    rts

ActionPlayerHandOver SUBROUTINE
    ; check if there are still hands to finish out otherwise pass to dealer
    lda #FLAGS_SPLIT_TAKEN
    bit GameFlags
    beq .SingleHand

    ; check if currently on the split hand
    ldx CurrPlayer
    cpx #PLAYER2_IDX
    bne .DealersTurn

    ; check for a bust
    lda PlayerFlags,x
    and #FLAGS_BUST
    beq .NextHand

    lda #SOUND_ID_LOST
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

.NextHand
    ; play moves to the main hand
    dec CurrPlayer

    lda #GS_PLAYER_SET_FLAGS
    sta GameState
    rts

.SingleHand
    ldx CurrPlayer

    ; check if player has a blackjack
    lda PlayerFlags,x
    and #FLAGS_BLACKJACK
    beq .CheckBusted

    lda #GS_DEALER_HAND_OVER
    sta GameState
    rts

.CheckBusted
    lda PlayerFlags,x
    and #FLAGS_BUST
    beq .DealersTurn

    ; player has busted, game over
    lda #GS_DEALER_HAND_OVER
    sta GameState
    rts

.DealersTurn
    lda #GS_DEALER_TURN
    sta GameState
    rts

ActionDealerTurn SUBROUTINE
    lda #CURR_HOLE_CARD_MASK
    bit CurrState 
    beq .NoFlip

    ; reveal hole card
    lda #~CURR_HOLE_CARD_MASK
    and CurrState
    sta CurrState

    ldx #DEALER_IDX
    jsr Bank2_AnimateCard

.NoFlip
    lda #DEALER_IDX
    sta CurrPlayer

    lda #GS_DEALER_PRE_HIT
    sta GameState
    rts

; Deal the dealer a card, shift cards around, calc score
ActionDealerPreHit SUBROUTINE
    ; count the aces
    ldy #0                                  ; Y = num aces
    ldx PlayerNumCards+DEALER_IDX           ; X = num cards
    dex
.CountAces
    lda PlayerCards+DEALER_CARDS_OFFSET,x
    and #CARD_RANK_MASK
    cmp #CARD_RANK_ACE
    bne .NotAnAce
    iny
.NotAnAce
    dex
    bpl .CountAces                      ; while X >= 0
    
    ; check if dealer stands
    lda PlayerScore+DEALER_IDX
    cmp #STAND_SCORE
    beq .SoftHit                        ; if score == 17, check for soft hit
    bpl .DealerStands                   ; if score > 17, dealer stands

    ; check if there are open card slots
    lda PlayerNumCards+DEALER_IDX
    cmp #NUM_VISIBLE_CARDS
    bcc .Continue

    ; slots are full: pull the 1st card and shift remaining cards left
    jsr Bank2_DealerSwapAce
    jsr Bank2_DealerShiftCard               ; A contains the moved card

    ; add the pulled card to the total
    and #CARD_RANK_MASK                     ; convert the card to the rank
    tax
    clc
    lda PlayerPileScore+DEALER_IDX
    adc Bank2_CardPointValue,x                    ; lookup rank score and add
    sta PlayerPileScore+DEALER_IDX
    dec PlayerNumCards+DEALER_IDX

.Continue
    lda #GS_DEALER_HIT
    sta GameState
    rts

.SoftHit
    ; Y = number of aces; soft hit when Y != 0; stand when Y == 0
    cpy #0
    beq .DealerStands
    ; check for easy mode (don't hit soft 17)
    lda #FLAGS_HIT_SOFT17
    bit GameOpts
    beq .DealerStands
    jmp .Continue

.DealerStands
    lda #GS_DEALER_HAND_OVER
    sta GameState
    rts

ActionDealerHit SUBROUTINE
    lda #GS_DEALER_POST_HIT
    sta GameState

    ;jsr Bank2_ClearEvents
    jsr DoDealCard
    rts

ActionDealerPostHit SUBROUTINE
    ldx #DEALER_IDX
    jsr Bank2_CalcHandScore

    ; check if score is 21
    cmp #BLACKJACK_SCORE
    bne .CheckBust

    ; dealer has 21
    lda PlayerFlags+DEALER_IDX
    ora #FLAGS_21
    sta PlayerFlags+DEALER_IDX
    jmp .HandOver

.CheckBust
    ; check if dealer busted
    cmp #BUST_SCORE
    bmi .CheckStand

    ; dealer busted
    lda PlayerFlags+DEALER_IDX
    ora #FLAGS_BUST | FLAGS_LOST
    sta PlayerFlags+DEALER_IDX
    jmp .HandOver

.CheckStand
    ; check if dealer has 21
    cmp #BLACKJACK_SCORE
    bne .Check17

    ; dealer has 21
    lda PlayerFlags+DEALER_IDX
    ora #FLAGS_21
    sta PlayerFlags+DEALER_IDX
    jmp .HandOver

.Check17
    ; check if score >= 17
    cmp #STAND_SCORE
    beq .SoftHit        ; check if the dealer will hit on soft 17
    bpl .HandOver
    ; dealer continues hitting
    lda #GS_DEALER_TURN
    sta GameState
    rts
.SoftHit
    ; Y = number of aces; soft hit when Y != 0; stand when Y == 0
    cpy #0
    beq .HandOver       ; no aces is a hard 17
    ; check for easy mode (don't hit soft 17)
    lda #FLAGS_HIT_SOFT17
    bit GameOpts
    beq .HandOver
    lda #GS_DEALER_TURN
    sta GameState
    rts
.HandOver
    lda #GS_DEALER_HAND_OVER
    sta GameState
    rts

ActionDealerHandOver SUBROUTINE

    lda #CURR_HOLE_CARD_MASK
    bit CurrState 
    beq .NoFlip

    ; reveal hole card
    lda #~CURR_HOLE_CARD_MASK
    and CurrState
    sta CurrState

    ldx #DEALER_IDX
    jsr Bank2_AnimateCard

.NoFlip

    ldx #PLAYER1_IDX

    ; check if this is a split hand
    lda #FLAGS_SPLIT_TAKEN
    bit GameFlags
    beq .Compare

    ; begin with split hand
    ldx #PLAYER2_IDX

    ; compare results and do payouts
.Compare
    stx CurrPlayer
.NextPlayer
    ldx CurrPlayer
    
    ; check if player has blackjack
    lda #FLAGS_BLACKJACK
    and PlayerFlags,x
    bne .DoPayout

    ; check if player lost
    lda #FLAGS_LOST
    and PlayerFlags,x
    ; player may have insurance, so PayoutWinnings will handle insurance
    bne .DoPayout

    ; check if player busted
    lda #FLAGS_BUST
    and PlayerFlags,x
    bne .SkipPayout

    ; check if dealer busted
    lda #FLAGS_BUST
    bit PlayerFlags+DEALER_IDX
    beq .Continue

    ; dealer busted, so player wins
    lda PlayerFlags,x
    ora #FLAGS_WIN
    sta PlayerFlags,x
    jmp .DoPayout

.Continue ; check scores
    lda PlayerScore,x
    cmp PlayerScore+DEALER_IDX
    bcc .PlayerLost             ; check if A < M
    beq .DoPush                 ; check if A == M

    ; player has higher score wins
    lda PlayerFlags,x
    ora #FLAGS_WIN
    sta PlayerFlags,x
    jmp .DoPayout

.PlayerLost
    lda PlayerFlags,x
    ora #FLAGS_LOST
    sta PlayerFlags,x
    ; player may have insurance, so PayoutWinnings will handle insurance
    jmp .DoPayout

.DoPush
    lda PlayerFlags,x
    ora #FLAGS_PUSH
    sta PlayerFlags,x
    
.DoPayout
    jsr Bank2_PayoutWinnings

.SkipPayout
    dec CurrPlayer
    bpl .NextPlayer

    ; return CurrPlayer to a valid state
    lda #PLAYER1_IDX
    sta CurrPlayer

    lda #GS_GAME_OVER
    sta GameState
    rts

ActionGameOver SUBROUTINE
    lda #FLAGS_WIN
    and PlayerFlags
    beq .CheckPush

    lda #SOUND_ID_WIN0
    sta Arg1
    lda #SOUND_ID_WIN1
    sta Arg2
    CALL_BANK PROC_SOUNDQUEUEPLAY2, 1, 2
    jmp .Return

.CheckPush
    lda #FLAGS_PUSH
    and PlayerFlags
    beq .CheckLoss
    lda #SOUND_ID_PUSH
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2
    
.CheckLoss
    lda #FLAGS_LOST | FLAGS_BUST
    and PlayerFlags
    beq .Return

    lda #SOUND_ID_LOST
    sta Arg1
    CALL_BANK PROC_SOUNDQUEUEPLAY, 1, 2

.PlaySound
    
.Return
    lda #1
    sta TriggerTimer
    lda #GS_INTERMISSION
    sta GameState
    rts

WaitIntermission SUBROUTINE
    ; block trigger input for a duration
    inc TriggerTimer
    lda TriggerTimer
    beq .CheckFire
    cmp #TGR_TIMER
    bcc .CheckSplit

.CheckFire
    lda #JOY_FIRE_PACKED_MASK
    bit JoyRelease
    bne .NewGame

.CheckSplit
    ; check if there's a split hand
    lda #FLAGS_SPLIT_TAKEN
    bit GameFlags
    beq .Return

    ; player split the hand; allow highlighting current hand
.CheckUp
    lda #JOY0_UP_MASK
    bit JoyRelease
    beq .CheckDown

    ; highlight split hand
    lda #PLAYER2_IDX
    sta CurrPlayer
    jmp .Return

.CheckDown
    lda #JOY0_DOWN_MASK
    bit JoyRelease
    beq .Return

    ; highlight main hand
    lda #PLAYER1_IDX
    sta CurrPlayer
    jmp .Return

.NewGame
    lda #GS_NEW_GAME
    sta GameState
    jsr Bank2_ApplyCurrBet

.Return
    ;jsr Bank2_ClearEvents
    rts

; -----------------------------------------------------------------------------
; Desc:     Returns a pseudo-random number in the A register
; Inputs:
; Ouputs:   A       (random number)
;           RandNum (random number)
; -----------------------------------------------------------------------------
    IF TEST_RAND_ON == 1

Bank2_GetRandomByte SUBROUTINE
    ldy RandAlt
    lda TestRandInts,y
    sta RandNum
    iny
    cpy #NUM_TEST_RAND
    bne .Return
    ldy #0
.Return
    sty RandAlt
    rts

    ELSE

Bank2_GetRandomByte SUBROUTINE
    ; Galois LFSR $b8
    lda RandNum
    bne .SkipInx
    inx             ; prevent zeros
.SkipInx
    lsr
    bcc .SkipEor
    eor #$b8
.SkipEor
    sta RandNum
    rts

    ENDIF

; -----------------------------------------------------------------------------
; Desc:     Sets sprite spacing gaps.
; Inputs:   Y register (sprite index)
; Ouputs:
; -----------------------------------------------------------------------------
Bank2_InitSpriteSpacing SUBROUTINE
    lda Bank2_SpriteSize,y
    sta NUSIZ0
    sta NUSIZ1
    lda Bank2_SpriteDelay,y
    sta VDELP0
    sta VDELP1
    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite pointers to blank sprites.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank2_GameClearSprites SUBROUTINE
    ; assign to blank sprites
    lda #<BlankCard
    ldx #>BlankCard
    ldy #NUM_VISIBLE_CARDS*2-2
.Loop
    sta SpritePtrs,y
    stx SpritePtrs+1,y
    dey
    dey
    bpl .Loop
    rts

; -----------------------------------------------------------------------------
; Desc:     Erases any pending joystick events.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank2_ClearEvents SUBROUTINE
    lda #0
    sta JoyRelease
    rts

; -----------------------------------------------------------------------------
; Desc:     Erases game memory.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank2_ResetGame
    ; clear memory
    ldx #0
    ldy #(MemBlockEnd - MemBlockStart)
.Memset
    stx MemBlockStart,y
    dey
    bpl .Memset

    lda #GS_NEW_GAME
    sta GameState

    ; clear any joystick events
    lda #0
    sta JoyRelease
    lda #$ff
    sta JoySWCHA
    sta JoySWCHB
    sta JoyINPT4
    rts

    include "bank2/lib/task-8bit.asm"

    ; define procedures common to multiple banks
    INCLUDE_MENU_SUBS 2

; -----------------------------------------------------------------------------
; Data 
; -----------------------------------------------------------------------------
; DeckMask is indexed by the current number of decks.
Bank2_DeckMask
    dc.b %00111111
    dc.b %01111111
    dc.b %01111111
    dc.b %11111111
Bank2_DeckPenetration
    dc.b 1 * 52 / 4 * 3
    dc.b 2 * 52 / 4 * 3
    dc.b 2 * 52 / 4 * 3
    dc.b 4 * 52 / 4 * 3

Bank2_DashboardStates
    dc.b GS_PLAYER_TURN                 ; DASH_HIT_IDX
    dc.b GS_PLAYER_STAY                 ; DASH_STAY_IDX
    dc.b GS_PLAYER_DOUBLEDOWN           ; DASH_DOUBLEDOWN_IDX
    dc.b GS_PLAYER_SURRENDER            ; DASH_SURRENDER_IDX
    dc.b GS_PLAYER_INSURANCE            ; DASH_INSURANCE_IDX
    dc.b GS_PLAYER_SPLIT                ; DASH_SPLIT_IDX

Bank2_DashboardFlagsTable
    dc.b FLAGS_HIT_ALLOWED              ; DASH_HIT_IDX (hit is always allowed)
    dc.b FLAGS_HIT_ALLOWED              ; DASH_STAY_IDX (stay is always allowed)
    dc.b FLAGS_DOUBLEDOWN_ALLOWED       ; DASH_DOUBLEDOWN_IDX
    dc.b FLAGS_SURRENDER_ALLOWED        ; DASH_SURRENDER_IDX
    dc.b FLAGS_INSURANCE_ALLOWED        ; DASH_INSURANCE_IDX
    dc.b FLAGS_SPLIT_ALLOWED            ; DASH_SPLIT_IDX

    SPRITE_OPTIONS 2

; These must be BCD values.
Bank2_CardPointValue
    ;     0   1  2  3  4  5  6  7  8  9  A   B   C   D   E  F
    ;     0   1  2  3  4  5  6  7  8  9  10  11  12  13  14 15
    ;     -   A  2  3  4  5  6  7  8  9  10  J   Q   K   -  -
    dc.b $0, $11, $2, $3, $4, $5, $6, $7, $8, $9, $10, $10, $10, $10, $0, $0

; These must be BCD values. 1 is added for the actual value.
Bank2_DenomValue 
    ;dc.b  $0, $4, $9, $24, $49, $99
    dc.b  $0, $9, $24, $99, $99, $99
Bank2_DenomValue2
    dc.b  $0, $0, $0, $0, $10, $0

    IF BALLAST_ON == 1
        ; ballast code
        LIST OFF
        REPEAT [ $1fb0 - $1e70 ] / 10
            lda $f000  ; 3
            sta $f000  ; 3
            inc $f000  ; 3
            tax        ; 1
        REPEND
        LIST ON
    ENDIF

    include "lib/test.asm"
    include "bank2/arithmetic.asm"
    include "sys/bank2_palette.asm"

; Indexed by game state values.
; bit 7:        show betting row
; bit 6:        show dashboard
; bit 5:        show dealer's hole card
; bit 4:        show dealer's score
; bit 3:        flicker the currently selected object
; bit 0,1,2:    index into PromptMessages table
Bank2_GameStateFlags
    dc.b 0                      ; GS_TITLE_SCREEN
    dc.b %10101001              ; GS_NEW_GAME
    dc.b %10001001              ; GS_PLAYER_BET
    dc.b %10001001              ; GS_PLAYER_BET_DOWN
    dc.b %10001001              ; GS_PLAYER_BET_UP
    dc.b %01000000              ; GS_OPEN_DEAL1
    dc.b %01000000              ; GS_OPEN_DEAL2
    dc.b %01000000              ; GS_OPEN_DEAL3
    dc.b %01000000              ; GS_OPEN_DEAL4
    dc.b %01000000              ; GS_OPEN_DEAL5
    dc.b %01000010              ; GS_DEALER_SET_FLAGS
    dc.b %01000010              ; GS_PLAYER_SET_FLAGS
    dc.b %01000010              ; GS_PLAYER_TURN
    dc.b %01000010              ; GS_PLAYER_STAY
    dc.b %01000010              ; GS_PLAYER_PRE_HIT
    dc.b %01000010              ; GS_PLAYER_HIT
    dc.b %01000010              ; GS_PLAYER_POST_HIT
    dc.b %01000011              ; GS_PLAYER_SURRENDER
    dc.b %01000100              ; GS_PLAYER_DOUBLEDOWN
    dc.b %01000101              ; GS_PLAYER_SPLIT
    dc.b %01000101              ; GS_PLAYER_SPLIT_DEAL
    dc.b %01000110              ; GS_PLAYER_INSURANCE
    dc.b %00110000              ; GS_PLAYER_BLACKJACK
    dc.b %00110000              ; GS_PLAYER_WIN
    dc.b %00110000              ; GS_PLAYER_PUSH
    dc.b 0                      ; GS_PLAYER_HAND_OVER
    dc.b %00110000              ; GS_DEALER_TURN
    dc.b %00110000              ; GS_DEALER_PRE_HIT
    dc.b %00110000              ; GS_DEALER_HIT
    dc.b %00110000              ; GS_DEALER_POST_HIT
    dc.b %00110000              ; GS_DEALER_HAND_OVER
    dc.b %00110000              ; GS_GAME_OVER
    dc.b %00110000              ; GS_INTERMISSION

; Game state handlers implement the core game mechanics.
;   Action handlers execute for one frame.
;   Wait handlers execute for multiple frames waiting on input.
Bank2_GameStateHandlers
    dc.w WaitTitleScreen        ; GS_TITLE_SCREEN
    dc.w ActionNewGame          ; GS_NEW_GAME
    ; betting screen
    dc.w WaitPlayerBet          ; GS_PLAYER_BET
    dc.w ActionPlayerBetDown    ; GS_PLAYER_BET_DOWN
    dc.w ActionPlayerBetUp      ; GS_PLAYER_BET_UP
    ;dc.w ActionPlayerKeypad    ; GS_PLAYER_KEYPAD
    ; opening deal
    dc.w ActionOpenDeal1        ; GS_OPEN_DEAL1: dealer 1st card
    dc.w ActionOpenDeal2        ; GS_OPEN_DEAL2: player 1st card
    dc.w ActionOpenDeal3        ; GS_OPEN_DEAL3: dealer 2nd card
    dc.w ActionOpenDeal4        ; GS_OPEN_DEAL4: player 2nd card
    dc.w ActionOpenDeal5        ; GS_OPEN_DEAL5: calculate scores
    ; analyze hands
    dc.w ActionDealerSetFlags   ; GS_DEALER_SET_FLAGS
    dc.w ActionPlayerSetFlags   ; GS_PLAYER_SET_FLAGS
    ; player's turn
    dc.w WaitPlayerTurn         ; GS_PLAYER_TURN
    dc.w WaitPlayerStay         ; GS_PLAYER_STAY
    dc.w ActionPlayerPreHit     ; GS_PLAYER_PRE_HIT
    dc.w ActionPlayerHit        ; GS_PLAYER_HIT
    dc.w ActionPlayerPostHit    ; GS_PLAYER_POST_HIT
    ; player moves
    dc.w WaitPlayerSurrender    ; GS_PLAYER_SURRENDER
    dc.w WaitPlayerDoubleDown   ; GS_PLAYER_DOUBLEDOWN
    dc.w WaitPlayerSplit        ; GS_PLAYER_SPLIT
    dc.w ActionPlayerSplitDeal  ; GS_PLAYER_SPLIT_DEAL
    dc.w WaitPlayerInsurance    ; GS_PLAYER_INSURANCE
    ; win/lose actions
    dc.w ActionGameOver         ; GS_PLAYER_BLACKJACK
    dc.w ActionGameOver         ; GS_PLAYER_WIN
    dc.w ActionGameOver         ; GS_PLAYER_PUSH
    dc.w ActionPlayerHandOver   ; GS_PLAYER_HAND_OVER
    ; dealer's turn and moves
    dc.w ActionDealerTurn       ; GS_DEALER_TURN
    dc.w ActionDealerPreHit     ; GS_DEALER_PRE_HIT
    dc.w ActionDealerHit        ; GS_DEALER_HIT
    dc.w ActionDealerPostHit    ; GS_DEALER_POST_HIT
    dc.w ActionDealerHandOver   ; GS_DEALER_HAND_OVER
    ; game over
    dc.w ActionGameOver         ; GS_GAME_OVER
    dc.w WaitIntermission       ; GS_INTERMISSION

; Tasks are prioritized and momentarily interrupt the game play
Bank2_TaskHandlers
    dc.w DoNothing              ; TSK_NONE
    dc.w DoDealCard             ; TSK_DEAL_CARD
    dc.w DoFlipCard             ; TSK_FLIP_CARD
    dc.w DoShuffle              ; TSK_SHUFFLE
    dc.w DoDealerDiscard        ; TSK_DEALER_DISCARD
    dc.w DoPlayer1Discard       ; TSK_PLAYER1_DISCARD
    dc.w DoPlayer2Discard       ; TSK_PLAYER2_DISCARD
    dc.w DoBlackJackAnim        ; TSK_BLACKJACK_ANIM
    dc.w DoPopupOpen            ; TSK_POPUP_OPEN

; Sound effect lookup table
Bank2_GameStateSound
    dc.b GS_PLAYER_BET_DOWN, SOUND_ID_CHIPS
    dc.b GS_PLAYER_BET_UP, SOUND_ID_CHIPS
    dc.b GS_PLAYER_BLACKJACK, SOUND_ID_WIN0
    dc.b GS_PLAYER_WIN, SOUND_ID_WIN0
    dc.b GS_PLAYER_PUSH, SOUND_ID_PUSH
    dc.b 0

    SPRITE_POSITIONING 2

; -----------------------------------------------------------------------------
; Shared procedures
; -----------------------------------------------------------------------------

PROC_ANIMATIONADD           = 0
PROC_ANIMATIONTICK          = 1
PROC_BANK0_BETTINGKERNEL    = 2
PROC_BANK0_GAMEIO           = 3
PROC_BANK3_PLAYKERNEL       = 4
PROC_SOUNDQUEUEPLAY         = 5
PROC_SOUNDQUEUEPLAY2        = 6
PROC_SOUNDQUEUETICK         = 7
PROC_BANK0_READKEYPAD       = 8

Bank2_ProcTableLo
    dc.b <AnimationAdd
    dc.b <AnimationTick
    dc.b <Bank0_BettingKernel
    dc.b <Bank0_GameIO
    dc.b <Bank3_PlayKernel
    dc.b <SoundQueuePlay
    dc.b <SoundQueuePlay2
    dc.b <SoundQueueTick
    dc.b <Bank0_ReadKeypad

Bank2_ProcTableHi
    dc.b >AnimationAdd
    dc.b >AnimationTick
    dc.b >Bank0_BettingKernel
    dc.b >Bank0_GameIO
    dc.b >Bank3_PlayKernel
    dc.b >SoundQueuePlay
    dc.b >SoundQueuePlay2
    dc.b >SoundQueueTick
    dc.b >Bank0_ReadKeypad

    ORG BANK2_ORG + $ff6-BS_SIZEOF
    RORG BANK2_RORG + $ff6-BS_SIZEOF
    INCLUDE_BANKSWITCH_SUBS 2, BANK2_HOTSPOT

	; bank switch hotspots
    ORG BANK2_ORG + $ff6
    RORG BANK2_RORG + $ff6
    ds.b 4, 0

    ; interrupts
    ORG BANK2_ORG + $ffa
    RORG BANK2_RORG + $ffa

Bank2_Interrupts
    .word Bank2_Reset       ; NMI    $*ffa, $*ffb
    .word Bank2_Reset       ; RESET  $*ffc, $*ffd
    .word Bank2_Reset       ; IRQ    $*ffe, $*fff
