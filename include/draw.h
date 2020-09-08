; -----------------------------------------------------------------------------
; Desc:     Draws a 48 bit sprite with animated rainbow colors.
; Inputs:   graphics vector
;           Y register (sprite height - 1)
; Outputs:
; Notes:    P0 position=36; P1 position=59
;
;   ldy #HEIGHT-1
;   DRAW_RAINBOW_GRAPHIC Graphic, Palette
; -----------------------------------------------------------------------------
; timer based version
    MAC DRAW_RAINBOW_GRAPHIC
.GFX_ADDR SET {1}

.GFX0   SET {1}0
.GFX1   SET {1}1
.GFX2   SET {1}2
.GFX3   SET {1}3
.GFX4   SET {1}4
.GFX5   SET {1}5

    ; align kernel to the start of 2nd scan line
    sta WSYNC
    tya                 ; +2
    sta CurrY           ; +3
    SLEEP_56            ; +56

.Loop
    ;                     Cycles   Pixel    GRP0   GRP0A   GRP1   GRP1A
    ; --------------------------------------------------------------------
    ldy  CurrY          ; +3 (59)  192
    lda  .GFX0,y        ; +4 (63)  207
    sta  GRP0           ; +3 (66)  216      D1     --      --     --
    lda  INTIM          ; +4 (70)
    sta  COLUP0         ; +3 (73)
    sta  COLUP1         ; +3 (76)
    ; start of line ------------------------------------------------------
    lda  .GFX1,y        ; +4 (4)    15
    sta  GRP1           ; +3 (7)    24      D1     D1      D2     --
    lda  .GFX2,y        ; +4 (11)   39
    sta  GRP0           ; +3 (14)   48      D3     D1      D2     D2
    lda  .GFX3,y        ; +4 (18)   63
    sta  Gfx3           ; +3 (21)   72
    lda  .GFX4,y        ; +4 (25)   87
    tax                 ; +2 (27)   93
    lda  .GFX5,y        ; +4 (31)  108
    tay                 ; +2 (33)  114
    lda  Gfx3           ; +3 (36)  123              !
    sta  GRP1           ; +3 (39)  132      D3     D3      D4     D2!
    stx  GRP0           ; +3 (42)  141      D5     D3!     D4     D4
    sty  GRP1           ; +3 (45)  150      D5     D5      D6     D4!
    sta  GRP0           ; +3 (48)  159      D4*    D5!     D6     D6
    dec  CurrY          ; +5 (53)  174                             !
    bpl  .Loop          ; +3 (56)  183
    ENDM

; stack based version
    MAC DRAW_RAINBOW_GRAPHIC2
.GFX_ADDR   SET {1}

.GFX0   SET {1}0
.GFX1   SET {1}1
.GFX2   SET {1}2
.GFX3   SET {1}3
.GFX4   SET {1}4
.GFX5   SET {1}5

    sty CurrY

    ; preload the stack with .PTRS+6 column of pixels
    ldy #-1             ; +2
.Preload
    iny                 ; +2 (2)
    lda .GFX3,y         ; +5 (7)
    pha                 ; +3 (10)
    cpy CurrY           ; +3 (13)
    bcc .Preload        ; +3/2 (16)

    ; align so that the firt GRP0A write lands on cpu cycle 41 (tia 123)
    sta WSYNC
    nop                 ; +2
    ldy CurrY           ; +3
    SLEEP_56            ; +56

.Loop
    ;                 Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    ; --------------------------------------------------------------------
    ldy  CurrY          ; +3  59  192
    lda  .GFX0,y        ; +4  63  207
    sta  GRP0           ; +3  66  216      D1     --      --     --
    lda  INTIM          ; +4  70
    sta  COLUP0         ; +3  73
    sta  COLUP1         ; +3  76
    ; --------------------------------------------------------------------
    ;                 Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    lda  .GFX1,y        ; +4   4   15
    sta  GRP1           ; +3   7   24      D1     D1      D2     --
    lda  .GFX2,y        ; +4  11   39
    sta  GRP0           ; +3  14   48      D3     D1      D2     D2

    lda  .GFX4,y        ; +4  18   87
    tax                 ; +2  20   93
    lda  .GFX5,y        ; +4  24  108
    tay                 ; +2  26  114
    pla                 ; +4  30  128

    bit $0              ; +3  33
    bit $0              ; +3  36

    sta  GRP1           ; +3  39  132      D3     D3      D4     D2!
    stx  GRP0           ; +3  42  141      D5     D3!     D4     D4
    sty  GRP1           ; +3  45  150      D5     D5      D6     D4!
    sta  GRP0           ; +3  48  159      D4*    D5!     D6     D6
    dec  CurrY          ; +5  53  174                             !
    bpl  .Loop          ; +3  56  183
    ENDM

