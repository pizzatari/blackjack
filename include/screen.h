    MAC INCLUDE_SPRITE_POSITIONING
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
    sta HMOVE                       ; 3 (3)
    rts                             ; 6 (9)
    ENDM    ; SPRITE_POSITIONING

    MAC INCLUDE_SPRITE_COLORS
    ; -----------------------------------------------------------------------------
    ; Desc:     Set screen options.
    ; Inputs:   bank number   
    ;           Y register (sprite index)
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

    ; -----------------------------------------------------------------------------
    ; Desc:     Set screen options.
    ; Inputs:   bank number   
    ;           Y register (sprite index)
    ; Outputs:
    ; -----------------------------------------------------------------------------
Bank{1}_SetColors2 SUBROUTINE       ; 6 (6)
    lda Bank{1}_BGPalette,y         ; 4 (10)
    sta COLUBK                      ; 3 (13)
    lda Bank{1}_PFFPalette,y        ; 4 (17)
    sta COLUPF                      ; 3 (20)
    lda Bank{1}_FGPalette,y         ; 4 (24)
    sta COLUP0                      ; 3 (27)
    sta COLUP1                      ; 3 (30)
    rts                             ; 6 (36)

    ; sets parameters for displaying green tableau
Bank{1}_SetTableau SUBROUTINE       ; 6 (6)
    ; read status fo black & white switch    
    clc                             ; 2 (8)
    lda #%00001000                  ; 2 (10)
    and SWCHB                       ; 4 (14)
    bne .SwitchOn                   ; 3 (17)
    dc.b $2c                        ; 4 (21)
.SwitchOn
    lda #%01010101                  ; stripe pattern

    sta WSYNC                       ; 3 (24)

    ; turn on/off background stripes
    sta PF0                         ; 3 (3)
    sta PF2                         ; 3 (6)
    asl                             ; 2 (8)
    sta PF1                         ; 3 (11)
    rts                             ; 6 (17)

; MSG_BAR_IDX, POPUP_BAR_IDX, COLOR_TABLE_IDX, COLOR_CARDS_IDX, COLOR_CHIPS_IDX, OPT_BAR_IDX
Bank{1}_BGPalette
    dc.b COLOR_DRED, COLOR_GRAY, COLOR_GREEN, COLOR_GREEN, COLOR_GREEN, COLOR_DRED
Bank{1}_FGPalette
    dc.b COLOR_YELLOW, COLOR_WHITE, COLOR_DGREEN, COLOR_WHITE, COLOR_YELLOW, COLOR_YELLOW
Bank{1}_PFFPalette
    dc.b COLOR_DRED, COLOR_DRED, COLOR_DGREEN, COLOR_DGREEN, COLOR_DGREEN, COLOR_DRED

Bank{1}_PFColors
    dc.b PF_COLOR, BG_COLOR
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Collection of sprite options.
; Inputs:   bank number   
; Outputs:
; -----------------------------------------------------------------------------
    MAC INCLUDE_SPRITE_OPTIONS
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
