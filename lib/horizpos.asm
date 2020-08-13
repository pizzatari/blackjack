; -----------------------------------------------------------------------------
; Desc:     Positions an object horizontally using the divide by 15 method with a table
;           lookup for fine adjustments.
; Input:    Bank?.fineAdjustTable
;           A register (horizontal position)
;           X register (sprite to position : 0 to 4)
; Output:   A = fine adjustment value
;           Y = the remainder minus an additional 15
; Notes:
;   0 = Player 0
;   1 = Player 1
;   2 = Missile 0
;   3 = Missile 1
;   4 = Ball
;
;    Scanlines: If control comes on or before cycle 73, then 1 scanline is consumed.
;               If control comes after cycle 73, then 2 scanlines are consumed.
;    Control is returned on cycle 6 of the next scanline.
; -----------------------------------------------------------------------------

    ; canonical position object
    MAC HORIZ_POS_OBJECT2
.TABLE  SET {1}
        sta WSYNC       ; 3 (3)
        sec             ; 2 (2)

.Div15
        sbc #15         ; 2 (4)
        bcs .Div15      ; 3 (7)

        tay             ; 2 (8)
        lda .TABLE,y    ; 4 (12)
        sta HMP0,x      ; 4 (16)
        sta RESP0,x     ; 4 (20)
    ENDM

    ; this version moves the sec before the WSYNC and the RESP0 write before HMP0
    MAC HORIZ_POS_OBJECT
.TABLE  SET {1}
        sec             ; 2 (2)     Set the carry flag so no borrow will be applied during the division.
        sta WSYNC       ; 3 (5)     Sync to start of scanline.

.Div15 
        sbc #15         ; 2 (2)     Waste the necessary amount of time dividing X-pos by 15!
        bcs .Div15      ; 3 (5)     06/07  11/16/21/26/31/36/41/46/51/56/61/66

        tay             ; 2 (6)
        nop             ; 2 (8)
        nop             ; 2 (10)
        nop             ; 2 (12)
        sta RESP0,x     ; 4 (16)    21/ 26/31/36/41/46/51/56/61/66/71 - Set the rough position.
        lda .TABLE,y    ; 4 (20)    13 -> Consume 5 cycles by guaranteeing we cross a page boundary
        sta HMP0,x      ; 4 (24)
    ENDM

    ; battlezone position object
    MAC HORIZ_POS_BZ
.TABLE  SET {1}
        sec             ; 2 (2)
        sta WSYNC       ; 3 (5)
.Div15
        sbc #15         ; 2 (2)     each time thru this loop takes 5 cycles, which is 
        bcs .Div15      ; 3 (5)     the same amount of time it takes to draw 15 pixels

        eor #7          ; 2 (6)     The EOR & ASL statements convert the remainder
        asl             ; 2 (8)     of position/15 to the value needed to fine tune
        asl             ; 2 (10)    the X position
        asl             ; 2 (12)
        asl             ; 2 (14)

        sta.wx HMP0,X   ; 5 (19)    store fine tuning of X
        sta RESP0,X     ; 4 (23)    set coarse X position of object
    ENDM

; Fine adjustment lookup table for horizontal positioning.
;
; This table converts the remainder of the division by 15 (-1 to -15) to the correct
; fine adjustment value. This table is on a page boundary to guarantee the processor
; will cross a page boundary and waste a cycle in order to be at the precise position
; for a RESP0,x write.
;
    MAC HORIZ_POS_TABLE
Bank{1}_fineAdjustBegin
    dc.b %01110000; Left 7
    dc.b %01100000; Left 6
    dc.b %01010000; Left 5
    dc.b %01000000; Left 4
    dc.b %00110000; Left 3
    dc.b %00100000; Left 2
    dc.b %00010000; Left 1
    dc.b %00000000; No movement.
    dc.b %11110000; Right 1
    dc.b %11100000; Right 2
    dc.b %11010000; Right 3
    dc.b %11000000; Right 4
    dc.b %10110000; Right 5
    dc.b %10100000; Right 6
    dc.b %10010000; Right 7
Bank{1}_fineAdjustTable EQU Bank{1}_fineAdjustBegin - %11110001; NOTE: %11110001 = -15
    ENDM
