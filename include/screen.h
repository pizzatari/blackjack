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

; -----------------------------------------------------------------------------
; Desc:     Chip rendering setup subroutine.
; Params:   bank number
; Inputs:   TempInt (3 byte integer)
; Outputs:
; -----------------------------------------------------------------------------
	MAC INCLUDE_CHIP_SUBS

Bank{1}_SetupChipSprites SUBROUTINE ; 6 (6)
    sed                             ; 2 (8)
    ldx #5*2                        ; 2 (21)    ones chip position in SpritePtrs
    ldy #6                          ; 2 (10)

    lda TempInt                     ; 3 (13)
    cmp #$10                        ; 2 (15)    if chips >= 100,000
    bcc .Next1                      ; 2 (17)
    ldy #0                          ; 2 (19)    first chip position in Bank{1}_ChipScale*
    jmp .Assign                     ; 3 (24)

.Next1
    cmp #$01                        ; 2 (26)    if chips >= 10,000
    bcc .Next2                      ; 2 (28)
    ldy #1                          ; 2 (30)
    ldx #4*2                        ; 2 (32)
    jmp .Assign                     ; 3 (35)

.Next2
    lda TempInt+1                   ; 3 (38)
    cmp #$10                        ; 2 (40)    if chips >= 1,000
    bcc .Next3                      ; 2 (42)
    ldy #2                          ; 2 (44)
    ldx #3*2                        ; 2 (46)
    jmp .Assign                     ; 3 (49)

.Next3
    cmp #$01                        ; 2 (51)    if chips >= 100
    bcc .Next4                      ; 2 (53)
    ldy #3                          ; 2 (55)
    ldx #2*2                        ; 2 (57)
    jmp .Assign                     ; 3 (60)

.Next4
    lda TempInt+2                   ; 3 (63)
    cmp #$10                        ; 2 (65)    if chips >= 10
    bcc .Next5                      ; 2 (67)
    ldy #4                          ; 2 (69)
    ldx #1*2                        ; 2 (71)
    jmp .Assign                     ; 3 (74)

.Next5
    cmp #$01                        ; 2 (76)    if chips >= 1
    bcc .Assign                     ; 2 (78)
    ldy #5                          ; 2 (80)
    ldx #0*2                        ; 2 (82)

.Assign
    cld                             ; 2 (87)

    ; populate SpritePtrs
    lda Bank{1}_ChipScaleLo,y       ; 4 (91)
    sta SpritePtrs                  ; 4 (95)
    lda Bank{1}_ChipScaleHi,y       ; 4 (99)
    sta SpritePtrs+1                ; 4 (103)

    lda Bank{1}_ChipScaleLo+1,y     ; 4 (107)
    sta SpritePtrs+2                ; 4 (111)
    lda Bank{1}_ChipScaleHi+1,y     ; 4 (115)
    sta SpritePtrs+3                ; 4 (119)

    lda Bank{1}_ChipScaleLo+2,y     ; 4 (123)
    sta SpritePtrs+4                ; 4 (127)
    lda Bank{1}_ChipScaleHi+2,y     ; 4 (131)
    sta SpritePtrs+5                ; 4 (135)

    lda Bank{1}_ChipScaleLo+3,y     ; 4 (139)
    sta SpritePtrs+6                ; 4 (143)
    lda Bank{1}_ChipScaleHi+3,y     ; 4 (147)
    sta SpritePtrs+7                ; 4 (151)

    lda Bank{1}_ChipScaleLo+4,y     ; 4 (155)
    sta SpritePtrs+8                ; 4 (159)
    lda Bank{1}_ChipScaleHi+4,y     ; 4 (163)
    sta SpritePtrs+9                ; 4 (167)

    lda Bank{1}_ChipScaleLo+5,y     ; 4 (171)
    sta SpritePtrs+10               ; 4 (175)
    lda Bank{1}_ChipScaleHi+5,y     ; 4 (179)
    sta SpritePtrs+11               ; 4 (183)

    ; adjust the scale of the ones chip graphic
    lda TempInt+2                   ; 3 (186)
    beq .Blank                      ; 2 (188)
    cmp #$10                        ; 2 (190)
    bcs .Return                     ; 2 (192)
    lsr                             ; 2 (194)
    tay                             ; 2 (196)
    lda Bank{1}_Mult10,y            ; 4 (200)     chip sprite height = 10
    clc                             ; 2 (202)
    adc #<Bank{1}_Chip0             ; 2 (204)
    sta SpritePtrs,x                ; 4 (208)
    rts                             ; 6 (214)

.Blank
    ; show blank if lowest 2 digits == 00
    lda #<Bank{1}_BlankSprite       ; 2 (195)
    sta SpritePtrs,x                ; 4 (199)
    lda #>Bank{1}_BlankSprite       ; 2 (201)
    sta SpritePtrs+1,x              ; 4 (205)

.Return
    rts                             ; 6 (212)

	ENDM

; -----------------------------------------------------------------------------
; Desc:     Data for the Bank*_SetupChipsPot routines.
; Inputs:   bank number   
; Outputs:
; -----------------------------------------------------------------------------
	MAC INCLUDE_CHIP_DATA
Bank{1}_ChipScaleLo
    dc.b <Bank{1}_Chip5, <Bank{1}_Chip5, <Bank{1}_Chip5
    dc.b <Bank{1}_Chip5, <Bank{1}_Chip5, <Bank{1}_Chip4
    dc.b <Bank{1}_BlankSprite, <Bank{1}_BlankSprite, <Bank{1}_BlankSprite
    dc.b <Bank{1}_BlankSprite, <Bank{1}_BlankSprite, <Bank{1}_BlankSprite
Bank{1}_ChipScaleHi
    dc.b >Bank{1}_Chip5, >Bank{1}_Chip5, >Bank{1}_Chip5
    dc.b >Bank{1}_Chip5, >Bank{1}_Chip5, >Bank{1}_Chip4
    dc.b >Bank{1}_BlankSprite, >Bank{1}_BlankSprite, >Bank{1}_BlankSprite
    dc.b >Bank{1}_BlankSprite, >Bank{1}_BlankSprite, >Bank{1}_BlankSprite
	ENDM

