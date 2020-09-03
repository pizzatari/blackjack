; -----------------------------------------------------------------------------
; Desc:     Executes a procedure in a fixed time period.
; Inputs:   procedure address, timer intervals, timer
; Outputs:
; Notes:
;   TIMED_JSR Subroutine, 20, TIM8T
;   TIMED_JSR Subroutine, 10, TIM64T
; -----------------------------------------------------------------------------
    MAC TIMED_JSR
.PROC   SET {1}
.TIME   SET {2}
.TIMER  SET {3}
        lda #.TIME
        sta .TIMER
        jsr .PROC
.Loop
        lda INTIM
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:    Sleeps until the timer goes to zero.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
    MAC TIMER_WAIT
.Loop
        lda INTIM
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sleeps until the timer goes negative.
; Inputs:
; Outputs:
; -----------------------------------------------------------------------------
    MAC TIMER_WAIT_NEGATIVE
.Loop
        lda INTIM
        bpl .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sleeps for a specified number of scan lines.
; Inputs:   number of scan lines
; Outputs:
; -----------------------------------------------------------------------------
    MAC SLEEP_LINES
.LINES   SET {1}
        ldy #.LINES
.Loop
        sty WSYNC
        dey
        bne .Loop
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Extracts bits from a byte.
; Inputs:   bit mask, variable
; Outputs:  A register (unpacked result)
; -----------------------------------------------------------------------------
    MAC GET_BITS 
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND
        LIST ON

        ; unpack the bits
        lda .VAR
        and #.MASK
        IF .BITPOS != 1
            REPEAT .BITPOS
                lsr
            REPEND
        ENDIF
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Assigns bits in a byte.
; Inputs:   bit mask, variable
;           A register (value to set)
; Outputs:  A register (packed bit result)
; -----------------------------------------------------------------------------
    MAC SET_BITS 
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND
        LIST ON

        tay                     ; 2 (2)

        ; erase selected bits
        lda .VAR                ; 3 (5)
        and #~.MASK             ; 2 (7)
        sta .VAR                ; 3 (10)

        tya                     ; 2 (12)
        REPEAT .BITPOS-1
            asl                 ; 2 
        REPEND

        ; save bits
        ora .VAR                ; 3 (15+)
        sta .VAR                ; 3 (18+)
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Adds 1 to the bits inside the bit mask. Overflow is contained.
; Inputs:   bit mask, variable
; Outputs:  packed bits (A register)
; -----------------------------------------------------------------------------
    MAC INC_BITS
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND

        ; shift 1 to the correct position
.ADD    SET 1
        REPEAT .BITPOS-1
.ADD    SET .ADD << 1
        REPEND

        LIST ON

        ; do the addition
        lda .VAR
        clc
        adc #.ADD
        sta .VAR
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Subtracts 1 from the bits inside the bit mask. Underflow is contained.
; Inputs:   bit mask, variable
; Outputs:  packed bits (A register)
; -----------------------------------------------------------------------------
    MAC DEC_BITS
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND

        ; shift 1 to the correct position
.SUB    SET 1
        REPEAT .BITPOS-1
.SUB    SET .SUB << 1
        REPEND

        LIST ON

        ; do the subtraction
        lda .VAR
        sec
        sbc #.SUB
        sta .VAR
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Extracts bits from a byte.
; Inputs:   bit mask, variable
;           X register (variable index)
; Outputs:  A register (unpacked result)
; -----------------------------------------------------------------------------
    MAC GET_BITS_X
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND
        LIST ON

        ; unpack the bits
        lda .VAR,x
        and #.MASK
        IF .BITPOS != 1
            REPEAT .BITPOS
                lsr
            REPEND
        ENDIF
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Assigns bits in a byte.
; Inputs:   bit mask, variable
;           X register (variable index)
;           A register (value to set)
; Outputs:  A register (packed bit result)
; -----------------------------------------------------------------------------
    MAC SET_BITS_X
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND
        LIST ON

        tay                     ; 2 (2)

        ; erase selected bits
        lda .VAR,x              ; 3 (5)
        and #~.MASK             ; 2 (7)
        sta .VAR,x              ; 3 (10)

        tya                     ; 2 (12)
        REPEAT .BITPOS
            asl                 ; 2 
        REPEND

        ; save bits
        ora .VAR,x              ; 3 (15+)
        sta .VAR,x              ; 3 (18+)
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Adds 1 to the bits inside the bit mask. Overflow is contained.
; Inputs:   bit mask, variable
;           X register (variable index)
; Outputs:  A register (unpacked resulting value)
; -----------------------------------------------------------------------------
    MAC INC_BITS_X
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND

        ; shift 1 to the correct position
.ADD    SET 1
        REPEAT .BITPOS
.ADD    SET .ADD << 1
        REPEND

        LIST ON

; 0001 0001 lda
; 0001 0001 tay
; 0000 0001 and, sta

; 0001 0001 -> Y

        ; do the addition
        lda .VAR,x
        clc
        adc #.ADD
        sta .VAR,x
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Subtracts 1 from the bits inside the bit mask. Underflow is contained.
; Inputs:   bit mask, variable
;           X register (variable index)
; Outputs:  packed bits (A register)
; -----------------------------------------------------------------------------
    MAC DEC_BITS_X
.MASK   SET {1}
.VAR    SET {2}

        LIST OFF
        ; calculate right most bit position
.BITPOS SET 8
.IDX    SET 8
        REPEAT .IDX
.IDX    SET .IDX - 1
            IF ((.MASK << (.IDX-1)) & $ff) > 0
.BITPOS SET .BITPOS - 1
            ENDIF
        REPEND

        ; shift 1 to the correct position
.SUB    SET 1
        REPEAT .BITPOS
.SUB    SET .SUB << 1
        REPEND

        LIST ON

        ; do the subtraction
        lda .VAR,x
        sec
        sbc #.SUB
        sta .VAR,x
    ENDM

ROM_BYTES_REMAINING SET 0
; -----------------------------------------------------------------------------
; Desc:     Prints remaining bytes in the block.
; Inputs:   rorg starting address, length of current block
; Outputs:  ROM_BYTES_REMAINING
; -----------------------------------------------------------------------------
    MAC ECHO_REMAINING_BYTES
.START  SET {1}
.LEN    SET {2}
.BYTES  SET ((.START + .LEN) - *)

ROM_BYTES_REMAINING SET ROM_BYTES_REMAINING + .BYTES
    ;echo "Page", *-1, "-", (.START+.LEN), "has", (.BYTES)d, "remaining bytes"
    ENDM
