; -----------------------------------------------------------------------------
; Desc:     Clears and initializes the queue.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
#if 1
AnimationClear SUBROUTINE
    ; erase elements
    lda #ANIM_ID_NONE
    sta AnimID
    sta AnimID+1
    sta AnimPosition
    sta AnimPosition+1
    sta AnimConfig
    sta AnimConfig+1
    rts
#else
AnimationClear SUBROUTINE
    lda #ANIM_ID_NONE
    ldx #ANIM_QUEUE_LEN-1
.Loop
    sta AnimID,x
    sta AnimPosition,x
    sta AnimConfig,x
    dex
    bpl .Loop
    rts
#endif

; -----------------------------------------------------------------------------
; Desc:     Add animation clip to the play queue.
; Inputs:   Bank3_AddID (animation id)
;           Bank3_AddPos (row, column) ($ff selects default position)
; Ouputs:
; -----------------------------------------------------------------------------
AnimationAdd SUBROUTINE
    ; search for an empty slot
    ldx #0
    lda AnimID
    beq .Found
    inx
    lda AnimID+1
    beq .Found
    jmp .Return     ; full queue

    ; store in the queue
.Found
    ; copy animation ID
    ldy Bank3_AddID
    sty AnimID,x

    ; get a pointer to the animation sequence record
    lda Bank3_Sequences,y
    sta Bank3_SeqPtr
    lda #>Bank3_Sequences
    sta Bank3_SeqPtr+1

    ; copy Bank3_SeqPtr->Position
    ldy #0
    lda (Bank3_SeqPtr),y
    sta AnimPosition,x

    ; copy Bank3_SeqPtr->Config
    ldy #1
    lda (Bank3_SeqPtr),y
    sta AnimConfig,x

    ; override default position
    lda Bank3_AddPos
    cmp #$ff
    beq .Return
    sta AnimPosition,x

.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Advance the animation frame.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
AnimationTick SUBROUTINE
    ; for each queue element advance the frame
    lda AnimID
    beq .Next1

    lda AnimPosition
    DEC_BITS ANIM_FRAME_MASK, AnimConfig

    ; check for remaining frames and remove first element on zero
    and #ANIM_FRAME_MASK
    bne .Next1

    ; erase element
    lda #ANIM_ID_NONE
    sta AnimID
    sta AnimPosition
    sta AnimConfig

.Next1
    lda AnimID+1
    beq .Return
    DEC_BITS ANIM_FRAME_MASK, AnimConfig+1

    ; check for remaining frames and remove first element on zero
    and #ANIM_FRAME_MASK
    bne .Return

    ; erase element
    lda #ANIM_ID_NONE
    sta AnimID+1
    sta AnimPosition+1
    sta AnimConfig+1

.Return
    rts

