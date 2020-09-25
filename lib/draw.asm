; -----------------------------------------------------------------------------
; Desc:     Draw a 48 pixel wide sprite.
; Inputs:   pointers variable (array of 6 words)
;           Y register (sprite height - 1)
; Outputs:
; Notes:    P0 position=56; P1 position=64
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
Draw6Sprite56 SUBROUTINE
    sty Arg1
    sty WSYNC
.Loop
    ;                        Cycles  Pixel    GRP0   GRP0A   GRP1   GRP1A
    ; --------------------------------------------------------------------
    ldy  Arg1               ; +3  64  192
    lda  (SpritePtrs),y     ; +5  69  207
    sta  GRP0               ; +3  72  216      D1     --      --     --
    sta  WSYNC              ; +3  75  225
    ; --------------------------------------------------------------------
    lda  (SpritePtrs+2),y   ; +5   5   15
    sta  GRP1               ; +3   8   24      D1     D1      D2     --
    lda  (SpritePtrs+4),y   ; +5  13   39
    sta  GRP0               ; +3  16   48      D3     D1      D2     D2
    lda  (SpritePtrs+6),y   ; +5  21   63
    sta  Arg2               ; +3  24   72
    lda  (SpritePtrs+8),y   ; +5  29   87
    tax                     ; +2  31   93
    lda  (SpritePtrs+10),y  ; +5  36  108
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
    rts

; -----------------------------------------------------------------------------
; Desc:     Draw a 48 pixel wide color sprite.
; Inputs:   Y register (sprite height - 1)
;           SpritePtrs (array of 6 pointers)
;           TempPtr (palette ptr)
; Outputs:
; -----------------------------------------------------------------------------
#if 1
DrawColor6Sprite56 SUBROUTINE
    lda #$ff                    ; 2 (2)
    sta WSYNC
    sta GRP0                    ; 3 (3)
    sta GRP1                    ; 3 (6)
    sta GRP0                    ; 3 (9)
    sta PF0                     ; 3 (12)
    sta PF1                     ; 3 (15)
    lda #%00000011              ; 2 (17)
    sta PF2                     ; 3 (20)
    sta CTRLPF                  ; 3 (23)
    ; --------------------------------------------------------------------

    ; preload the stack with SpritePtrs+6 column of pixels
    sty Arg1                    ; 3 (33)
    ldy #-1                     ; 2 (35)
.Preload
    iny                         ; 2 (37)
    lda (SpritePtrs+6),y        ; 5 (42)
    pha                         ; 3 (45)
    cpy Arg1                    ; 3 (48)
    bcc .Preload                ; 3 (51)

    sta WSYNC
    ldy Arg1                    ; +3 (3)
.Loop
    ;                         Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    ; ------------------------------------------------------------------------
    ldy Arg1                    ; 3 (65) (195)
    lda (SpritePtrs),y          ; 5 (70) (210)
    sta GRP0                    ; 3 (73) (219)      D1     --      --     --
    sta WSYNC                   ; 3 (0) (0)

    ; -----------------------------------------------------------------------
    ;                         Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    lda (TempPtr),y             ; 5 (5) (15)
    sta COLUBK                  ; 3 (8) (24)

    lda (SpritePtrs+2),y        ; 5 (13) (39)
    sta GRP1                    ; 3 (16) (48)      D1     D1      D2     --
    lda (SpritePtrs+4),y        ; 5 (21) (63)
    sta GRP0                    ; 3 (24) (72)      D3     D1      D2     D2

    lda (SpritePtrs+8),y        ; 5 (29) (87)
    tax                         ; 2 (31) (93)
    lda (SpritePtrs+10),y       ; 5 (36) (108)
    tay                         ; 2 (38) (114)
    pla                         ; 4 (42) (126)                 !

    sta GRP1                    ; 3 (45) (135)      D3     D3      D4     D2!
    stx GRP0                    ; 3 (48) (144)      D5     D3!     D4     D4
    sty GRP1                    ; 3 (51) (153)      D5     D5      D6     D4!
    sta GRP0                    ; 3 (54) (162)      D4*    D5!     D6     D6
    dec Arg1                    ; 5 (59) (177)                             !
    bpl .Loop                   ; 3 (62) (186)

    sta WSYNC
    ; --------------------------------------------------------------------
    ; keep masking until end of scan line, then erase playfield
    ;   PF0 = 11111111, PF1 = 11111111, PF2 = 11000000
    lda #$ff                    ; 2 (62)
    sta PF2                     ; 3 (65)
    lda #0                      ; 2 (67)
    sta CTRLPF                  ; 3 (70)
    sta PF0                     ; 3 (73)
    sta PF1                     ; 3 (0)
    sta PF2                     ; 3 (3)
    rts                         ; 6 (9)
#else
DrawColor6Sprite56 SUBROUTINE
    sty Arg1

    ; preload the stack with SpritePtrs+6 column of pixels
    ldy #-1                     ; +2
.Preload
    iny                         ; +2 (2)
    lda (SpritePtrs+6),y        ; +5 (7)
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
    ldy Arg1                    ; 3  (64)  (192) 
    lda (SpritePtrs),y          ; 5  (69)  (207) 
    sta GRP0                    ; 3  (72)  (216)       D1     --      --     --
    lda TempPtr,y               ; 4
    ; -----------------------------------------------------------------------
    ;                         Cycles CPU  TIA     GRP0   GRP0A   GRP1   GRP1A
    sta.w COLUP0                ; 4   (4)   (12) 
    sta COLUP1                  ; 3   (7)   (21) 

    lda (SpritePtrs+2),y        ; 5  (12)   (36) 
    sta GRP1                    ; 3  (15)   (45)       D1     D1      D2     --
    lda (SpritePtrs+4),y        ; 5  (20)   (60) 
    sta GRP0                    ; 3  (23)   (69)       D3     D1      D2     D2

    lda (SpritePtrs+8),y        ; 5  (28)   (84) 
    tax                         ; 2  (30)   (90) 
    lda (SpritePtrs+10),y       ; 5  (35)  (105) 
    tay                         ; 2  (37)  (111) 
    pla                         ; 4  (41)  (123)                  !

    sta GRP1                    ; 3  (44)  (132)       D3     D3      D4     D2!
    stx GRP0                    ; 3  (47)  (141)       D5     D3!     D4     D4
    sty GRP1                    ; 3  (50)  (150)       D5     D5      D6     D4!
    sta GRP0                    ; 3  (53)  (159)       D4*    D5!     D6     D6
    dec Arg1                    ; 5  (58)  (174)                              !
    bpl .Loop                   ; 3  (61)  (183) 
    rts
#endif
