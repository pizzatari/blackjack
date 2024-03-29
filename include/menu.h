; -----------------------------------------------------------------------------
; Macros
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Returns the current dashboard menu selection.
; Inputs:
; Outputs:      A register (menu selection)
; -----------------------------------------------------------------------------
    MAC GET_DASH_MENU
        lda CurrState
        and #CURR_DASH_MENU_MASK
        lsr
        lsr
        lsr
    ENDM

; -----------------------------------------------------------------------------
; Sets the current dashboard menu selection.
; Inputs:       Y register (menu selection)
; Outputs:
; -----------------------------------------------------------------------------
    MAC SET_DASH_MENU
        lda CurrState
        and #~CURR_DASH_MENU_MASK
        sta CurrState
        tya
        asl
        asl
        asl
        ora CurrState
        sta CurrState
    ENDM
; -----------------------------------------------------------------------------
; Desc:     Defines routines common to the banks.
; Inputs:   bank number
; Outputs:
; -----------------------------------------------------------------------------
    MAC INCLUDE_MENU_SUBS

; -----------------------------------------------------------------------------
; Desc:     Gets the currently selected betting menu item.
; Inputs:
; Outputs:  A register (selected menu index)
; -----------------------------------------------------------------------------
Bank{1}_GetBetMenu SUBROUTINE   ; 6 (6)
    lda CurrState               ; 3 (9)
    and #CURR_BET_MENU_MASK     ; 2 (11)
    rts                         ; 6 (17)

; -----------------------------------------------------------------------------
; Desc:     Sets the currently selected betting menu item.
; Outputs:  A register (selected menu index)
; Outputs:
; -----------------------------------------------------------------------------
Bank{1}_SetBetMenu SUBROUTINE
    tay
    lda CurrState
    and #~CURR_BET_MENU_MASK
    sta CurrState
    tya
    ora CurrState
    sta CurrState
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
