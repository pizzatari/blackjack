; -----------------------------------------------------------------------------
; Desc:     Defines routines common to the banks.
; Inputs:   bank number
; Outputs:
; -----------------------------------------------------------------------------
    MAC BANK_PROCS

; -----------------------------------------------------------------------------
; Desc:     Gets the currently selected betting menu item.
; Inputs:
; Outputs:  A register (selected menu index)
; -----------------------------------------------------------------------------
Bank{1}_GetBetMenu SUBROUTINE
    lda CurrState
    and #CURR_BET_MENU_MASK
    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the currently selected betting menu item.
; Outputs:  A register (selected menu index)
; Outputs:
; -----------------------------------------------------------------------------
Bank{1}_SetBetMenu SUBROUTINE
#if 1
    ; uses less RAM
    tay
    lda CurrState
    and #~CURR_BET_MENU_MASK
    sta CurrState
    tya
    ora CurrState
    sta CurrState
#else
    ; more efficient
    lda CurrState
    and #~CURR_BET_MENU_MASK
    ora Arg1
    sta CurrState
#endif
    rts

; -----------------------------------------------------------------------------
; Desc:     Gets the currently selected betting menu item.
; Inputs:
; Outputs:  A register (selected menu index)
; -----------------------------------------------------------------------------
Bank{1}_GetDashMenu SUBROUTINE
    lda CurrState
    and #CURR_DASH_MENU_MASK
    lsr
    lsr
    lsr
    rts

; -----------------------------------------------------------------------------
; Desc:     Sets the currently selected betting menu item.
; Outputs:  A register (selected dash index << 3)
; Outputs:
; -----------------------------------------------------------------------------
Bank{1}_SetDashMenu SUBROUTINE
    ;asl
    ;asl
    ;asl
    tay
    lda CurrState
    and #~CURR_DASH_MENU_MASK
    sta CurrState
    tya
    ora CurrState
    sta CurrState
    rts

    ENDM
