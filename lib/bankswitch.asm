; -----------------------------------------------------------------------------
; Macros and subroutines for calling a procedure in another bank.
;
;   JUMP_BANK
;   CALL_BANK
;   BANKSWITCH_ROUTINES
; -----------------------------------------------------------------------------

BS_SIZEOF = $2d

BS_VERSION = 2  ; 0=original; 1=optimized1; 2=optimized2
; vers 0:   original with brk
; vers 1:   slightly optimized with brk
; vers 2:   faster/shorter subroutines with no brk

#if BS_VERSION == 2
; -----------------------------------------------------------------------------
; Desc:     Call a procedure in another bank.
; Inputs:   dest proc, dest bank num, source bank #
; Outputs:
; Notes:    Wrapper for compatibility.
; -----------------------------------------------------------------------------
    MAC CALL_BANK
.DSTPROC    SET {1}
.DSTBANK    SET {2}
.SRCBANK    SET {3}

        ldx #.DSTPROC
        ldy #.DSTBANK
        lda #.SRCBANK
        jsr Bank{2}_CallBank
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Jump to a label in another bank.
; Inputs:   destination proc, destination bank #
; Outputs:
; Notes:    Wrapper for compatibility.
; -----------------------------------------------------------------------------
    MAC JUMP_BANK
.DSTPROC    SET {1}
.DSTBANK    SET {2}

    ldx #.DSTPROC
    ldy #.DSTBANK
    jmp Bank{2}_JumpBank

    ENDM

    MAC BANKSWITCH_ROUTINES
    ; -------------------------------------------------------------------------
    ; Desc:     Call a procedure in another bank.
    ; Inputs:   X register (destination proc idx)
    ;           Y register (destination bank #)
    ;           A register (source bank #)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_CallBank SUBROUTINE
    ; map procedure idx to procedure
    pha                         ; 3 (3)     save source bank #
    lda Bank{1}_ProcTableLo,x   ; 4 (7)
    sta TempPtr                 ; 3 (10)
    lda Bank{1}_ProcTableHi,x   ; 4 (14)
    sta TempPtr+1               ; 3 (17)

    ; do the bank switch
    lda BANK0_HOTSPOT,y         ; 4 (21)

    ; do the subroutine call
    lda #>(.Return-1)           ; 2 (23)    push the return address
    pha                         ; 3 (26)
    lda #<(.Return-1)           ; 2 (28)
    pha                         ; 3 (31)
    jmp (TempPtr)               ; 5 (36)

    ; rts                       ; 6 (42)
.Return
    pla                         ; 4 (46)    fetch source bank # 
    tay                         ; 2 (48)
    lda BANK0_HOTSPOT,y         ; 4 (52)    do the return bank switch
    rts                         ; 6 (58)

    ; -------------------------------------------------------------------------
    ; Desc:     Jump to a label in another bank.
    ; Inputs:   X register (destination proc idx)
    ;           Y register (destination bank #)
    ; Outputs:
    ; -------------------------------------------------------------------------
Bank{1}_JumpBank SUBROUTINE
    ; map procedure idx to procedure
    lda Bank{1}_ProcTableLo,x   ; 4 (7)
    sta TempPtr                 ; 3 (10)
    lda Bank{1}_ProcTableHi,x   ; 4 (14)
    sta TempPtr+1               ; 3 (17)

    ; do the bank switch
    lda BANK0_HOTSPOT,y         ; 4 (21)
    jmp (TempPtr)               ; 5 (64)

    ENDM
#endif

#if BS_VERSION < 2
; -----------------------------------------------------------------------------
; Desc:     Jump to a label in another bank.
; Inputs:   destination proc, destination bank #
; Outputs:
; -----------------------------------------------------------------------------
    MAC JUMP_BANK
.DSTPROC    SET {1}
.DSTBANK    SET {2}

        ; pass the subroutine
        lda #<.DSTPROC
        sta TempPtr
        lda #>.DSTPROC
        sta TempPtr+1

        lda #-1             ; -1 indicates not to return
        pha                 ; pass source argument

        ; call interrupt handler
        brk
        dc.b .DSTBANK
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Call a procedure in another bank.
; Inputs:   dest proc, dest bank num, source bank #
;           A register (optional subroutine parameter)
; Outputs:
; -----------------------------------------------------------------------------
    MAC CALL_BANK
.DSTPROC    SET {1}
.DSTBANK    SET {2}
.SRCBANK    SET {3}

        ; pass the subroutine
        lda #<.DSTPROC                  ; 2 (5)
        sta TempPtr                     ; 3 (8)
        lda #>.DSTPROC                  ; 2 (10)
        sta TempPtr+1                   ; 3 (13)

        lda #.SRCBANK                   ; 2 (15)
        pha                             ; 3 (18)        push source argument

        ; call interrupt handler
        brk                             ; 7 (25)
        dc.b .DSTBANK
        pla                             ; 4             pop source argument
    ENDM

    MAC BANKSWITCH_ROUTINES
    ; -------------------------------------------------------------------------
    ; Desc:     Interrupt handler for jumping to a label or calling an
    ;           arbitrary subroutine in another bank. 
    ;
    ;           This subroutine must exist in each bank at the same offset.
    ;
    ; Inputs:   brk padding byte (destination bank #)
    ;           stack variable (source bank #)
    ;           TempPtr (label to jump to or subroutine to call)
    ; Outputs:
    ; Usage:    lda #SubroutineParameter    ; (optional)
    ;           CALL_BANK Subroutine, DestinationBankNum, SourceBankNum
    ;
    ; Notes:
    ;    Brk trick using 1 byte pad argument. For subroutine calls, assign pad
    ;    argument to the source bank number. For jumps assign to any negative
    ;    number.
    ;
    ;    Caller
    ;           |brk |dst#|
    ;             v     v
    ;        ...|____|____|____|____|____|____|...
    ;
    ;    Stack                    return   src#
    ;                      | ps | LSB MSB | n  |
    ;    ...|____|____|____|____|____.____|____|...
    ;                        ^ 
    ;                       sp    +1   +2   +3
    ;                             sp   +1   +2 
    ; -------------------------------------------------------------------------
#if BS_VERSION == 1
Bank{1}_CallBank SUBROUTINE
    plp                     ; 4 (4)     pop status flags
    tsx                     ; 2 (6)
    inx                     ; 2 (8)

    ; adjust return address for rts
    lda $00,x               ; 4 (12)
    bne .SkipDec            ; 2/3 (15)
    dec $01,x               ; 6 (21)    handle borrow
.SkipDec
    dec $00,x               ; 6 (27)

    ; do the bank switch
    lda ($00,x)             ; 6 (33)    read destination argument (from rom)
    tay                     ; 2 (35)
    lda BANK0_HOTSPOT,y     ; 4 (39)

    ; determine if this is CALL_BANK or JUMP_BANK
    lda $02,x               ; 6 (45)    read source bank (from stack)
    bmi .Jump               ; 2/3 (47)  -1 indicates JUMP_BANK, otherwise CALL_BANK

    ; this is a subroutine call to another bank
    lda #>(.Return-1)       ; 2 (49)    push the return address
    pha                     ; 3 (52)
    lda #<(.Return-1)       ; 2 (54)
    pha                     ; 3 (57)
    jmp (TempPtr)           ; 5 (62)    do the subroutine call
.Return                     ; 6 (68)    return from subroutine
    tsx                     ; 2 (70)
    ldy $03,x               ; 4 (74)    read source bank (from stack)
    lda BANK0_HOTSPOT,y     ; 4 (78)    do the return bank switch
    rts                     ; 6 (84)

.Jump
    ; this is a jump to another bank that won't return
    pla                     ; 4 (51)    pop brk return addr LSB
    pla                     ; 4 (55)    pop brk return addr MSB
    pla                     ; 4 (59)    pop source bank #
    jmp (TempPtr)           ; 5 (64)

#endif  ; BS_VERSION == 1

#if BS_VERSION == 0
Bank{1}_CallBank SUBROUTINE
    plp                     ; 4 (4)     pop status flags
    tsx                     ; 2 (6)
    inx                     ; 2 (8)

    ; decrement return address for rts (and handle underflow)
    sec                     ; 2 (10)
    lda $00,x               ; 4 (14)    decrement LSB
    sbc #1                  ; 2 (16)
    sta $00,x               ; 4 (20)
    lda $01,x               ; 4 (24)    carry borrow to the MSB
    sbc #0                  ; 2 (26)
    sta $01,x               ; 4 (30)
    
    lda ($00,x)             ; 6 (36)    read destination bank number (sp+0)
    tay                     ; 2 (38)
    lda BANK0_HOTSPOT,y     ; 4 (42)    do the bankswitch

    lda $02,x               ; 6 (48)    check src bank # (sp+3)
    bmi .Jump               ; 2 (50)    3 (51)

    ; this is a subroutine call
    lda #>(.Return-1)       ; 2 (52)    push the return address
    pha                     ; 3 (55)
    lda #<(.Return-1)       ; 2 (57)
    pha                     ; 3 (60)
    jmp (TempPtr)           ; 5 (65)    do the subroutine call
.Return                     ; 6 (71)    return from subroutine
    tsx                     ; 2 (73)
    ldy $03,x               ; 4 (77)    read the src bank number (sp+3)
    lda BANK0_HOTSPOT,y     ; 4 (81)    do the return bank switch
    rts                     ; 6 (87)

.Jump
    ; this is a jump to a label
    pla                     ; 4 (55)    pop brk return addr LSB
    pla                     ; 4 (59)    pop brk return addr MSB
    pla                     ; 4 (63)    pop bank #
    jmp (TempPtr)           ; 5 (68)
#endif  ; BS_VERSION == 0

    ENDM
#endif  ; BS_VERSION < 2
