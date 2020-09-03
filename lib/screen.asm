    MAC MACRO_ROUTINES
    ; -----------------------------------------------------------------------------
    ; Desc:     Horizontally positions both P0 and P1 sprites in the same line
    ;           given positioning presets.
    ; Inputs:   Y register (SPRITE_GRAPHICS_IDX, SPRITE_CARDS_IDX, SPRITE_MEDIUM_IDX)
    ; Outputs:
    ; Notes:    Consumes 2 lines.
    ; -----------------------------------------------------------------------------
Bank{1}_PositionSprites SUBROUTINE
    ;------------------------------ cpu cycles --- tia clocks
    lda Bank{1}_SpritePositions0,y
    sta HMCLR                       
    sta WSYNC
    sec                             ; 2 (2)          6 [6]      
.divideby15
    sbc #15                         ; 2 (4)          6 [12]     
    bcs .divideby15                 ; 3 (7)          9 [21]
                                    ; 2 (11+)        6 [27+]
    SLEEP 6                         ; 9 (20+)
    sta RESP0                       ; 3 (23+)        9 [69+]
    sta RESP1                       ; 3 (27+)        9 [78+]

    ; fix up the positioning
    lda Bank{1}_SpriteAdjust0,y
    sta HMP0
    lda Bank{1}_SpriteAdjust1,y
    sta HMP1

    lda #0
    sta WSYNC
    sta HMOVE
    rts

    ENDM    ; MACRO_ROUTINES

; -----------------------------------------------------------------------------
; Desc:     Collection of sprite options.
; Inputs:   bank number   
; Outputs:
; -----------------------------------------------------------------------------
    MAC SPRITE_COLORS

    ; -----------------------------------------------------------------------------
    ; Desc:     Set screen options.
    ; Inputs:   bank number   
    ;           Y register (MSG_BAR_IDX, POPUP_BAR_IDX, TABLE_IDX, CARDS_IDX,
    ;                       CHIPS_IDX)
    ; Outputs:
    ; Notes:    Consumes 1 line.
    ; -----------------------------------------------------------------------------
Bank{1}_SetColors SUBROUTINE
    lda Bank{1}_BGPalette,y
    ldx Bank{1}_FGPalette,y
    sta WSYNC
    sta COLUBK
    stx COLUP0
    stx COLUP1
    lda Bank{1}_PFFPalette,y
    sta COLUPF
    rts

Bank{1}_SetPlayfield SUBROUTINE
    ; raise playfield priority to conceal menu items
    lda #0              ; 2 (2)
    sta CTRLPF          ; 3 (5)

    clc                 ; 2 (7)
    lda #%00001000      ; 2 (9)
    and SWCHB           ; 4 (13)
    bne .SwitchOn       ; 2 (15)    3 (16)
    dc.b $2c            ; 4 (19)
.SwitchOn
    lda #%01010101      ;           2 (18)

    sta PF0             ; 3 (22)    3 (21)
    sta PF2             ; 3 (25)    3 (24)
    asl                 ; 2 (27)    2 (26)
    sta PF1             ; 3 (30)    3 (29)
    rts                 ; 6 (36)    6 (35)

; MSG_BAR_IDX, POPUP_BAR_IDX, COLOR_TABLE_IDX, COLOR_CARDS_IDX, COLOR_CHIPS_IDX
; OPT_BAR_IDX
Bank{1}_BGPalette
    dc.b COLOR_DRED, COLOR_GRAY, COLOR_GREEN, COLOR_GREEN, COLOR_GREEN, COLOR_DRED
Bank{1}_FGPalette
    dc.b COLOR_YELLOW, COLOR_WHITE, COLOR_DGREEN, COLOR_WHITE, COLOR_YELLOW, COLOR_YELLOW
Bank{1}_PFFPalette
    dc.b COLOR_YELLOW, COLOR_WHITE, COLOR_DGREEN, COLOR_DGREEN, COLOR_DGREEN, COLOR_DRED

Bank{1}_PFColors
    dc.b PF_COLOR, BG_COLOR

    ENDM

; -----------------------------------------------------------------------------
; Desc:     Collection of sprite options.
; Inputs:   bank number   
; Outputs:
; -----------------------------------------------------------------------------
    MAC SPRITE_OPTIONS
Bank{1}_SpriteSize
    dc.b NUSIZE_3_CLOSE     ; SPRITE_GRAPHICS_IDX
    dc.b NUSIZE_3_MEDIUM    ; SPRITE_CARDS_IDX
    dc.b NUSIZE_3_CLOSE     ; SPRITE_BET_IDX
    dc.b NUSIZE_3_CLOSE     ; SPRITE_STATUS_IDX
    dc.b NUSIZE_3_CLOSE     ; SPRITE_HELP_IDX
Bank{1}_SpriteDelay
    dc.b 1                  ; SPRITE_GRAPHICS_IDX
    dc.b 0                  ; SPRITE_CARDS_IDX
    dc.b 1                  ; SPRITE_BET_IDX
    dc.b 1                  ; SPRITE_STATUS_IDX
    dc.b 1                  ; SPRITE_HELP_IDX
Bank{1}_SpritePositions0
    dc.b 75                 ; SPRITE_GRAPHICS_IDX
    dc.b 60                 ; SPRITE_CARDS_IDX
    dc.b 75                 ; SPRITE_BET_IDX
    dc.b 75                 ; SPRITE_STATUS_IDX
    dc.b 75                 ; SPRITE_HELP_IDX
    ;dc.b 100               ; SPRITE_HELP_IDX
Bank{1}_SpritePositions1
    dc.b 0                  ; SPRITE_GRAPHICS_IDX
    dc.b 0                  ; SPRITE_CARDS_IDX
    dc.b 0                  ; SPRITE_BET_IDX
    dc.b 0                  ; SPRITE_STATUS_IDX
    dc.b 0                  ; SPRITE_HELP_IDX
Bank{1}_SpriteAdjust0
    dc.b %00010000          ; SPRITE_GRAPHICS_IDX
    dc.b %01100000          ; SPRITE_CARDS_IDX
    dc.b %00110000          ; SPRITE_BET_IDX
    dc.b %00010000          ; SPRITE_STATUS_IDX
    dc.b %00010000          ; SPRITE_HELP_IDX
Bank{1}_SpriteAdjust1
    dc.b %00100000          ; SPRITE_GRAPHICS_IDX
    dc.b %11110000          ; SPRITE_CARDS_IDX
    dc.b %01000000          ; SPRITE_BET_IDX
    dc.b %00100000          ; SPRITE_STATUS_IDX
    dc.b %00100000          ; SPRITE_HELP_IDX

; indexed by number of cards in the hand
Bank{1}_HandNusiz1
    dc.b 0
Bank{1}_HandNusiz0
    dc.b 0, 0, 0, 2, 2, 6, 6

    ENDM

; -----------------------------------------------------------------------------
; Desc:     Erases player sprite graphics.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
    MAC CLEAR_SPRITE_GRAPHICS
        lda #0
        sta VDELP0
        sta VDELP1
        sta GRP0
        sta GRP1
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Initializes graphics registers for a message bar.
; Inputs:   text color index
; Outputs:
; -----------------------------------------------------------------------------
    MAC INIT_MSG_BAR
.IDX    SET {1}
        lda #0
        sta COLUBK
        sta PF0
        sta PF1
        sta PF2
        ldy #.IDX
        sta WSYNC                        ; hide HMOVE line
        lda TextBarPalette,y
        sta COLUBK
        lda TextBarPalette+1,y
        sta COLUP0
        sta COLUP1
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sets the game table pattern and colors.
; Inputs:        
; Outputs:
; -----------------------------------------------------------------------------
    MAC INIT_GAME_TABLE
        ; black divider line
        lda #0
        sta COLUBK
        ldx #PF_COLOR
        ldy #BG_COLOR
        lda #%01010101
        sta WSYNC

        ; card playfield
        stx COLUPF
        sty COLUBK
        sta PF1
        asl
        sta PF0
        sta PF2
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite pointers to the same sprite character given by
;           the 16 bit address.
; Inputs:   SpritePtrs, SpriteAddr
; Outputs:
; -----------------------------------------------------------------------------
    MAC SET_SPRITE_PTR
.PTRS   SET {1}
.ADDR   SET {2}
        lda #<.ADDR
        ldx #>.ADDR
        ldy #[NUM_VISIBLE_CARDS*2-2]
.Loop
        sta .PTRS,y
        stx .PTRS+1,y
        dey
        dey
        bpl .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sets the 6 sprites to sprite pointers.
; Inputs:   SpritePtrs, Sprite1, Sprite2, Sprite3, Sprite4, Sprite5, Sprite6
; Outputs:
; -----------------------------------------------------------------------------
    MAC SET_SPRITE_PTRS
.PTRS   SET {1}
.SPRITE1  SET {2}
.SPRITE2  SET {3}
.SPRITE3  SET {4}
.SPRITE4  SET {5}
.SPRITE5  SET {6}
.SPRITE6  SET {7}
        ; lsb
        lda #<.SPRITE1
        sta .PTRS
        lda #<.SPRITE2
        sta .PTRS+2
        lda #<.SPRITE3
        sta .PTRS+4
        lda #<.SPRITE4
        sta .PTRS+6
        lda #<.SPRITE5
        sta .PTRS+8
        lda #<.SPRITE6
        sta .PTRS+10
        ; msb
        lda #>.SPRITE1
        sta .PTRS+1
        lda #>.SPRITE2
        sta .PTRS+3
        lda #>.SPRITE3
        sta .PTRS+5
        lda #>.SPRITE4
        sta .PTRS+7
        lda #>.SPRITE5
        sta .PTRS+9
        lda #>.SPRITE6
        sta .PTRS+11
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite pointers to the same characters from the same page.
; Inputs:   SpritePtrs, Sprite1, Sprite2, Sprite3, Sprite4, Sprite5, Sprite6
; Outputs:
; -----------------------------------------------------------------------------
    MAC SET_SPRITE_PAGE_PTRS
.PTRS   SET {1}
.SPRITE1  SET {2}
.SPRITE2  SET {3}
.SPRITE3  SET {4}
.SPRITE4  SET {5}
.SPRITE5  SET {6}
.SPRITE6  SET {7}
        lda #<.SPRITE1
        sta .PTRS
        lda #<.SPRITE2
        sta .PTRS+2
        lda #<.SPRITE3
        sta .PTRS+4
        lda #<.SPRITE4
        sta .PTRS+6
        lda #<.SPRITE5
        sta .PTRS+8
        lda #<.SPRITE6
        sta .PTRS+10
        lda #>.SPRITE1
        sta .PTRS+1
        sta .PTRS+3
        sta .PTRS+5
        sta .PTRS+7
        sta .PTRS+9
        sta .PTRS+11
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Assigns the score sprites as a 2 digit score.
; Inputs:   SpritePtrs, PlayerScore
;           X register (player index)
; Outputs:
; -----------------------------------------------------------------------------
    MAC SET_SPRITE_SCORE
.PTR    SET {1}
.NUM    SET {2}

        ; ten's place
        ldy .NUM,x
        lda Bank3_Divide10,y
        tay
        lda Bank3_Multiply6,y
        clc
        adc #<Digit0
        sta .PTR
        lda #>Digit0
        adc #0
        sta .PTR+1

        ; one's place
        ldy .NUM,x
        lda Bank3_Mod10,y
        tay
        lda Bank3_Multiply6,y
        clc
        adc #<Digit0
        sta .PTR+2
        lda #>Digit0
        adc #0
        sta .PTR+3
    ENDM
