; -----------------------------------------------------------------------------
; Desc:     Sleeps for fixed number of cycles using less ROM space than SLEEP.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
    MAC SLEEP_14
        bit $1000                   ; +4 (4)
        bit $1000                   ; +4 (8)
        bit $1000                   ; +4 (12)
        nop                         ; +2 (14)
    ENDM

    MAC SLEEP_17
        ldy #1                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    2 * 5 - 1 = 9 cycles
        nop                         ; +2
        nop                         ; +2
        nop                         ; +2
        ; 17 total cycles = 8 + 9
    ENDM

    MAC SLEEP_36
        ldy #6                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    7 * 5 - 1 = 34 cycles
        ; 36 total cycles = 2 + 34
    ENDM

    MAC SLEEP_43
        ldy #7                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    8 * 5 - 1 = 39 cycles
        nop                         ; +2
        ; 43 total cycles = 4 + 39
    ENDM

    MAC SLEEP_45
        ldy #7                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    8 * 5 - 1 = 39 cycles
        nop                         ; +2
        nop                         ; +2
        ; 45 total cycles = 6 + 39
    ENDM

    MAC SLEEP_48
        ldy #8                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    9 * 5 - 1 = 44 cycles
        nop                         ; +2
        ; 48 total cycles = 4 + 44
    ENDM

    MAC SLEEP_49
        ldy #8                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    9 * 5 - 1 = 44 cycles 
        bit $0                      ; +3
        ; 49 total cycles = 5 + 44
    ENDM

    MAC SLEEP_51
        ldy #9                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    10 * 5 - 1 = 49 cycles 
        ; 51 total cycles = 2 + 49
    ENDM

    MAC SLEEP_52
        ldy #8                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    9 * 5 - 1 = 44 cycles 
        bit $0                      ; +3
        bit $0                      ; +3
        ;jmp * + 3                   ; +3
        ;jmp * + 3                   ; +3
        ; 52 total cycles = 2 + 44 + 6
    ENDM

    MAC SLEEP_54
        ldy #9                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    10 * 5 - 1 = 49 cycles 
        bit $0                      ; +3
        ; 54 total cycles = 2 + 49 + 3
    ENDM

    MAC SLEEP_55
        ldy #9                      ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    10 * 5 - 1 = 49 cycles 
        nop                         ; +2
        nop                         ; +2
        ; 55 total cycles = 6 + 51
    ENDM

    MAC SLEEP_56
        ldy #10                     ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    11 * 5 - 1 = 54 cycles 
        ; 56 total cycles = 2 + 54
    ENDM

    MAC SLEEP_61
        ldy #11                     ; +2
.Sleep
        dey                         ; +2
        bpl .Sleep                  ; +3    12 * 5 - 1 = 59 cycles 
        ; 61 total cycles = 2 + 59
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Draw a 48 pixel wide sprite.
; Inputs:   pointers variable (array of 6 words)
;           Y register (sprite height - 1)
; Outputs:
; Notes:    P0 position=55; P1 position=63
;
;   ldy #HEIGHT-1
;   DRAW_48_SPRITE SpritePtrs
;
; -----------------------------------------------------------------------------
; VDEL sequence 
; ()    Write to GRP0 or GRP1
; ->    Automatic transfer triggered by writing to GRP0/GRP1
; ?     Random data
; *     Discarded
;
;               GRP0            GRP1
;           ------------    ------------
;           Delay   Live    Delay   Live    On Screen
;------------------------------------------------------ begin loop
; GRP0:    (0-1)     ?       ?   ->  ?      |      
; GRP1:     0-1  -> 0-1    (1-2)     ?      | horizontal blank
; GRP0:    (0-3)    0-1     1-2  -> 1-2     |
; ...
;                                           0-1
; GRP1:     0-3  -> 0-3    (1-4)    1-2     1-2
; GRP0:    (0-5)    0-3     1-4  -> 1-4     0-3
; GRP1:     0-5  -> 0-5    (1-6)    1-4     1-4
; GRP0:   (*1-4)    0-5     1-6  -> 1-6     0-5
;                                           1-6
;------------------------------------------------------ begin loop
; GRP0:    (0-7)   *1-4     1-6  -> 1-6     |
; GRP1:     0-7  -> 0-7    (1-8)    1-6     | horizontal blank
; GRP0:    (0-9)    0-7     1-8  -> 1-8     |
; ...
;                                           0-7
; GRP1:     0-9  -> 0-9    (1-10)   1-8     1-8
; GRP0:    (0-11)   0-9     1-10 -> 1-10    0-9 
; GRP1:     0-11 -> 0-11   (1-12)   1-10    1-10
; GRP0:   (*1-10)   0-11    1-12 -> 1-12    0-11
;                                           1-12
;
; Original notes:
;
;   Player 0 has been set to pixel 123 (including horz blank) and Player 1
;   has been set to pixel 131.
;   [I.e., centered, starting at pixels 55 and 63 of the visible area.]
;   So the digits [sprites] begin at pixels 123, 131, 139, 147, 155, 163.
;
; -----------------------------------------------------------------------------
    MAC DRAW_48_SPRITE
.PTRS   SET {1}

        sty Arg1
        sty WSYNC
.Loop
        ;                        Cycles  Pixel    GRP0   GRP0A   GRP1   GRP1A
        ; --------------------------------------------------------------------
        ldy  Arg1               ; +3  64  192
        lda  (.PTRS),y          ; +5  69  207
        sta  GRP0               ; +3  72  216      D1     --      --     --
        sta  WSYNC              ; +3  75  225
        ; --------------------------------------------------------------------
        lda  (.PTRS+2),y        ; +5   5   15
        sta  GRP1               ; +3   8   24      D1     D1      D2     --
        lda  (.PTRS+4),y        ; +5  13   39
        sta  GRP0               ; +3  16   48      D3     D1      D2     D2
        lda  (.PTRS+6),y        ; +5  21   63
        sta  Arg2               ; +3  24   72
        lda  (.PTRS+8),y        ; +5  29   87
        tax                     ; +2  31   93
        lda  (.PTRS+10),y       ; +5  36  108
        tay                     ; +2  38  114
        lda  Arg2               ; +3  41  123              !
        sta  GRP1               ; +3  44  132      D3     D3      D4     D2!
        stx  GRP0               ; +3  47  141      D5     D3!     D4     D4
        sty  GRP1               ; +3  50  150      D5     D5      D6     D4!
        sta  GRP0               ; +3  53  159      D4*    D5!     D6     D6
        dec  Arg1               ; +5  58  174                             !
        bpl  .Loop              ; +3  61  183
        ; --------------------------------------------------------------------
        ; At the *, the value written to GRP0 does not matter. What does matter is
        ; that this write triggers GRP1A to receive new contents from GRP1.  A "!"
        ; indicates that that register is being used for displaying at that moment.
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Draw a 48 pixel wide color sprite.
; Inputs:   pointers variable (array of 6 words), palette variable
;           Y register (sprite height - 1)
; Outputs:
; Notes:
;
;   ldy #HEIGHT-1
;   DRAW_48_COLOR_SPRITE SpritePtrs, Palette
;
; -----------------------------------------------------------------------------
    MAC DRAW_48_COLOR_SPRITE
.PTRS       SET {1}
.PALETTE    SET {2}

    sty Arg1

    ; preload the stack with .PTRS+6 column of pixels
    ldy #-1                     ; +2
.Preload
    iny                         ; +2 (2)
    lda (.PTRS+6),y             ; +5 (7)
    pha                         ; +3 (10)
    cpy Arg1                    ; +3 (13)
    bcc .Preload                ; +3/2 (16)

    sta WSYNC
    ldy Arg1                    ; +3 (3)
    SLEEP_56                    ; +56 (59)  burn cycles to align cycle count
    nop                         ; +2 (61)

.Loop
    ;                         Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    ; ------------------------------------------------------------------------
    ldy Arg1                    ; +3  64  192
    lda (.PTRS),y               ; +5  69  207
    sta GRP0                    ; +3  72  216      D1     --      --     --
    lda .PALETTE,y              ; +4  76  228
    ; -----------------------------------------------------------------------
    ;                         Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    sta.w COLUP0                ; +4   4   12
    sta COLUP1                  ; +3   7   33

    lda (.PTRS+2),y             ; +5  12   36
    sta GRP1                    ; +3  15   45      D1     D1      D2     --
    lda (.PTRS+4),y             ; +5  20   60
    sta GRP0                    ; +3  23   69      D3     D1      D2     D2

    lda (.PTRS+8),y             ; +5  28   84
    tax                         ; +2  30   90
    lda (.PTRS+10),y            ; +5  35  105
    tay                         ; +2  37  111
    pla                         ; +4  41  123                 !

    sta GRP1                    ; +3  44  132      D3     D3      D4     D2!
    stx GRP0                    ; +3  47  141      D5     D3!     D4     D4
    sty GRP1                    ; +3  50  150      D5     D5      D6     D4!
    sta GRP0                    ; +3  53  159      D4*    D5!     D6     D6
    dec Arg1                    ; +5  58  174                             !
    bpl .Loop                   ; +3  61  183
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Draws a 48 bit color sprite as a graphic image.
; Inputs:   address to 6 sprite graphics, palette variable
;           Y register (sprite height - 1)
; Outputs:
; Notes:    P0 position=56; P1 position=59
;
;   ldy #HEIGHT-1
;   DRAW_COLOR_GRAPHIC Graphic, Palette
; -----------------------------------------------------------------------------
#if 0
    MAC DRAW_COLOR_GRAPHIC
.GFX_ADDR   SET {1}
.PALETTE    SET {2}

.GFX0   SET {1}0
.GFX1   SET {1}1
.GFX2   SET {1}2
.GFX3   SET {1}3
.GFX4   SET {1}4
.GFX5   SET {1}5

        ; align so that the firt GRP0A write lands on cpu cycle 41 (tia 123)
        sta WSYNC
        SLEEP_56            ; +56  56   align to start of the next scan line
        tya                 ;  +2  58 
        sta.w Arg1          ;  +4  62

.Loop
        ;                     Cycles  Pixel    GRP0   GRP0A   GRP1   GRP1A
        ; --------------------------------------------------------------------
        ldy  Arg1           ; +3  65  192
        lda  .GFX0,y        ; +4  69  207
        sta  GRP0           ; +3  72  216      D1     --      --     --
        lda .PALETTE,y      ; +4  76 
        ; ----------------------------------------------------- new scan line
        sta  COLUP0         ; +3   3
        sta  COLUP1         ; +3   6
        lda  .GFX1,y        ; +4  10   15
        sta  GRP1           ; +3  13   24      D1     D1      D2     --
        lda  .GFX2,y        ; +4  17   39
        sta  GRP0           ; +3  20   48      D3     D1      D2     D2
        lda  .GFX3,y        ; +4  24   63
        sta  Arg2           ; +3  27   72
        lda  .GFX4,y        ; +4  31   87
        tax                 ; +2  33   93
        lda  .GFX5,y        ; +4  37  108
        tay                 ; +2  39  114
        lda  Arg2           ; +3  42  123              !
        sta  GRP1           ; +3  45  132      D3     D3      D4     D2!
        stx  GRP0           ; +3  48  141      D5     D3!     D4     D4
        sty  GRP1           ; +3  51  150      D5     D5      D6     D4!
        sta  GRP0           ; +3  54  159      D4*    D5!     D6     D6
        dec  Arg1           ; +5  59  174                             !
        bpl  .Loop          ; +3  62  183
    ENDM
#endif
#if 1
    MAC DRAW_COLOR_GRAPHIC
.GFX_ADDR   SET {1}
.PALETTE    SET {2}

.GFX0   SET {1}0
.GFX1   SET {1}1
.GFX2   SET {1}2
.GFX3   SET {1}3
.GFX4   SET {1}4
.GFX5   SET {1}5

        ; save stack pointer
        tsx
        stx Arg3

        ; set sp = y
        tya
        tax
        txs

        ; align so that the firt GRP0A write lands on cpu cycle 41 (tia 123)
        sta WSYNC
        SLEEP_56            ; +56 56   align to start of the next scan line
        bit $0              ; +3  59
        nop                 ; +2  61
        tsx                 ; +2  63

.Loop
        nop                 ; +2  65
        nop                 ; +2  67

        ;                     Cycles  Pixel    GRP0   GRP0A   GRP1   GRP1A
        ; --------------------------------------------------------------------
        lda  .GFX0,x        ; +4  71  207
        sta  GRP0           ; +3  74  216      D1     --      --     --
        ; ----------------------------------------------------- new scan line
        lda .PALETTE,x      ; +4   2
        sta  COLUP0         ; +3   5
        sta  COLUP1         ; +3   8
        lda  .GFX1,x        ; +4  12   15
        sta  GRP1           ; +3  15   24      D1     D1      D2     --
        lda  .GFX2,x        ; +4  19   39
        sta  GRP0           ; +3  22   48      D3     D1      D2     D2
        lda  .GFX3,x        ; +4  26   63
        sta  Arg2           ; +3  29   72
        ldy  .GFX4,x        ; +4  33   87
        lda  .GFX5,x        ; +4  37  108
        tax                 ; +2  39  114
        lda  Arg2           ; +3  42  123              !
        sta  GRP1           ; +3  45  132      D3     D3      D4     D2!
        sty  GRP0           ; +3  48  141      D5     D3!     D4     D4
        stx  GRP1           ; +3  51  150      D5     D5      D6     D4!
        sta  GRP0           ; +3  54  159      D4*    D5!     D6     D6
        tsx                 ; +2  56                                 !
        dex                 ; +2  58
        txs                 ; +2  60
        bpl  .Loop          ; +3  63

        ; restore stack pointer
        ldx Arg3
        txs
    ENDM
#endif
#if 1
    MAC DRAW_COLOR_PTRS
.PTRS1      SET {1}
.PTRS2      SET {2}
.PALETTE    SET {3}

        ; align so that the firt GRP0A write lands on cpu cycle 41 (tia 123)
        sta WSYNC
        sty Arg1            ; 3 (3)

        ; save stack pointer
        tsx                 ; 2 (5)
        stx Arg3            ; 3 (8)

        ; prime the colors
        lda .PALETTE,y      ; 4 (12)
        sta  COLUP0         ; 3 (15)
        sta  COLUP1         ; 3 (18)

        SLEEP_45            ; 45 (63)   align the next scan line
        ldy Arg1            ; 3 (66)

        ; even/odd scan lines
.Loop
        ;                     Cycles  GRP0   GRP0A   GRP1   GRP1A
        ; --------------------------------------------------------------------
        lda (.PTRS1),y      ; 5 (73)
        sta GRP0            ; 3 (76)   D1     --      --     --
        lda (.PTRS1+2),y    ; 5 (5)
        sta GRP1            ; 3 (8)   D1     D1      D2     --
        lda (.PTRS1+4),y    ; 5 (13)
        sta GRP0            ; 3 (16)  D3     D1      D2     D2
        lda (.PTRS1+6),y    ; 5 (21)
        sta Arg2            ; 3 (24)
        lda (.PTRS1+8),y    ; 5 (29)
        tax                 ; 2 (31)
        lda (.PTRS1+10),y   ; 5 (36)
        tay                 ; 2 (38)
        lda Arg2            ; 3 (41)           !
        sta GRP1            ; 3 (44)  D3     D3      D4     D2!
        stx GRP0            ; 3 (47)  D5     D3!     D4     D4
        sty GRP1            ; 3 (50)  D5     D5      D6     D4!
        sta GRP0            ; 3 (53)  D4*    D5!     D6     D6

        ; --------------------------------------------------------------------
        ldy Arg1            ; 3 (56)
        dey                 ; 2 (58)
        lda .PALETTE,y      ; 4 (62)
        sta  COLUP0         ; 3 (65)
        sta  COLUP0         ; 3 (68)

        ;                     Cycles  GRP0   GRP0A   GRP1   GRP1A
        ; --------------------------------------------------------------------
        lda (.PTRS2),y      ; 5 (73)
        sta GRP0            ; 3 (76)   D1     --      --     --
        lda (.PTRS2+2),y    ; 5 (5)
        sta GRP1            ; 3 (8)   D1     D1      D2     --
        lda (.PTRS2+4),y    ; 5 (13)
        sta GRP0            ; 3 (16)  D1     D2     D2
        lda (.PTRS2+6),y    ; 5 (21)
        sta Arg2            ; 3 (25)
        lda (.PTRS2+8),y    ; 5 (30)
        tax                 ; 2 (32)
        lda (.PTRS2+10),y   ; 5 (37)
        tay                 ; 2 (39)
        lda Arg2            ; 3 (42)           !
        sta GRP1            ; 3 (45)  D3     D3      D4     D2!
        stx GRP0            ; 3 (48)  D5     D3!     D4     D4
        sty GRP1            ; 3 (51)  D5     D5      D6     D4!
        sta GRP0            ; 3 (54)  D4*    D5!     D6     D6

        nop                 ; 2 (56)

        lda Arg1            ; 3 (59)
        sbc #2              ; 2 (61)
        sta Arg1            ; 3 (65)
        tay                 ; 2 (67)
        bpl  .Loop          ; 3 (70)

        ; restore stack pointer
        ldx Arg3
        txs
    ENDM
#endif

; -----------------------------------------------------------------------------
; Desc:     Draws a 48 bit color sprite with a repeating pattern.
; Inputs:   address to 1 sprite graphic, palette variable
;           Y register (sprite height - 1)
; Outputs:
; Notes:    P0 position=56; P1 position=59
;
;   ldy #HEIGHT-1
;   DRAW_COLOR_PATTERN Graphic, Palette
; -----------------------------------------------------------------------------
    MAC DRAW_COLOR_PATTERN
.GFX_ADDR   SET {1}
.PALETTE    SET {2}

.Loop
        sta WSYNC
        lda  .GFX_ADDR,y
        sta  GRP0
        sta  GRP1
        lda  .PALETTE,y
        sta  COLUP0
        sta  COLUP1
        dey
        bpl  .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Draws 2 close sprites in a row.
; Inputs:   pointers variable (array of 2 words)
;           Y register (sprite height - 1)
; Outputs:
;
;   ldy #HEIGHT-1
;   DRAW_2_SPRITES SpritePtrs
;
; -----------------------------------------------------------------------------
    MAC DRAW_2_SPRITES
.PTRS   SET {1}

.Loop
        sta WSYNC               ; 3 (0)
        lda (.PTRS),y           ; 5 (5) 
        sta GRP0                ; 3 (8)     Sprite 1 [30-32]
        lda (.PTRS+2),y         ; 5 (13]
        sta GRP1                ; 3 (16)    Sprite 2 [35-37]
        dey
        bpl .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Draws 6 medium spaced sprites in a row.
; Inputs:   pointers variable (array of 6 words)
;           Y register (sprite height - 1)
; Outputs:
;
;   ldy #HEIGHT-1
;   DRAW_6_SPRITES SpritePtrs
;
; -----------------------------------------------------------------------------
    MAC DRAW_6_SPRITES
.PTRS   SET {1}

.Loop
        sta WSYNC
        SLEEP 6                 ; 6 (6)
        lda (.PTRS),y           ; 5 (11) 
        sta GRP0                ; 3 (14)    Sprite 1 [30-32]
        lda (.PTRS+2),y         ; 5 (19]
        sta GRP1                ; 3 (22)    Sprite 2 [35-37]
        lda (.PTRS+6),y         ; 5 (27)
        tax                     ; 2 (29)
        lda (.PTRS+4),y         ; 5 (34)
        nop                     ; 2 (36)
        sta GRP0                ; 3 (39)    Sprite 3 [40-44]
        nop                     ; 2 (41)
        stx GRP1                ; 3 (44)    Sprite 4 [46-49]
        lda (.PTRS+8),y         ; 5 (49]
        sta GRP0                ; 3 (51)    Sprite 5 [51-54]
        lda (.PTRS+10),y        ; 5 (56]
        sta GRP1                ; 3 (59)    Sprite 6 [56-60]
        dey                     ; 2 (61)
        bpl .Loop               ; 3 (64)
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Draws 6 medium spaced sprites in a row from 2 ROM data pointers.
; Inputs:   ROM graphics (PF0), ROM graphics (PF1)
;           Y register (sprite height - 1)
; Outputs:
;
;   ldy #HEIGHT-1
;   DRAW_2_GRAPHIC Graphic0, Graphic1
;
; -----------------------------------------------------------------------------
    MAC DRAW_2_GRAPHIC
.GFX_ADDR0   SET {1}
.GFX_ADDR1   SET {2}

        ldx #0
.Loop
        sta WSYNC               ; 3 (3)
        lda .GFX_ADDR0,y        ; 5 (8) 
        sta GRP0                ; 3 (11)
        lda .GFX_ADDR1,y        ; 5 (16)
        sta GRP1                ; 3 (19)
        dey                     ; 2 (21)
        bpl .Loop               ; 3 (24)
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Draws 6 medium spaced sprites in a row from ROM data.
; Inputs:   base graphics address, palette variable
;           Y register (sprite height - 1)
; Outputs:
; Notes:
;   On screen pixel position
;   GRP0 position = 36,68,100
;   GRP1 position = 52,84,116
;
;   TIA clock position
;   GRP0 position = 104,136,168
;   GRP1 position = 120,152,184
;
;   ldy #HEIGHT-1
;   DRAW_6_GRAPHIC Graphic
;
; -----------------------------------------------------------------------------
    MAC DRAW_6_GRAPHIC
.GFX_ADDR   SET {1}

.GFX0   SET {1}0
.GFX1   SET {1}1
.GFX2   SET {1}2
.GFX3   SET {1}3
.GFX4   SET {1}4
.GFX5   SET {1}5

.Loop                   ;   cpu  |tia write |tia pos|
        sta WSYNC       ; 3   (0)
        lda .GFX0,y     ; 4   (4)
        sta GRP0        ; 3   (7)    (21)     (104)
        lda .GFX1,y     ; 4  (11)
        sta GRP1        ; 3  (14)    (42)     (120)
        lda .GFX2,y     ; 4  (18)
        tax             ; 2  (20)
        lda .GFX3,y     ; 4  (24)
        SLEEP_14        ; 14 (38)
        stx GRP0        ; 3  (41)   (123)     (136)
        sta GRP1        ; 3  (44)   (132)     (152)
        lda .GFX4,y     ; 4  (48)
        sta GRP0        ; 3  (51)   (153)     (168)
        lda .GFX5,y     ; 4  (55)
        sta GRP1        ; 3  (58)   (174)     (184)
        dey             ; 2  (60)
        bpl .Loop       ; 3  (63)
        lda #0
        sta GRP0
        sta GRP1
    ENDM
