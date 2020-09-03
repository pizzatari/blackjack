; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Feb 2019
; Version:  1.0
; Project:  Simple Sprite Animation 2600
; Desc:     Simple sprite animation driver for Atari 2600. This plays basic
;           animation clips for selected sprites.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Desc:     Clears and initializes the queue.
; Inputs:    
; Ouputs:
; -----------------------------------------------------------------------------
AnimationClear SUBROUTINE
    ldx #ANIM_QUEUE_LEN-1
    lda #ANIM_ID_NONE
    ldy #0
.Loop
    sta AnimID,x            ; -1
    sta AnimColumn,x        ; -1
    sta AnimRow,x           ; -1
    sty AnimCurrFrame,x     ;  0
    dex
    bpl .Loop

    rts

; -----------------------------------------------------------------------------
; Desc:     Add animation clip to the play queue.
; Inputs:   Arg1 (animation id)
;           Arg2 (column)
;           Arg3 (row)
; Ouputs:
; -----------------------------------------------------------------------------
AnimationAdd SUBROUTINE
    ldy Arg1                    ; A = animation id
    cpy #ANIM_ID_NONE
    beq .Return

    ; search for an empty slot
    lda Arg2
    ldx #0
.Loop
    ldy AnimColumn,x
    bmi .FoundEmptySlot
    cmp AnimColumn,x
    beq .FoundEmptySlot         ; choose identical matches
    inx
    cpx #ANIM_QUEUE_LEN
    bne .Loop

    ; queue is full, replace first element
    ldx #0
.FoundEmptySlot

    ; add id to the queue
    ldy Arg1
    sty AnimID,x

    ; initialize position
    lda Arg2
    sta AnimColumn,x
    lda Arg3
    sta AnimRow,x

    ; initialize current frame
    lda #1
    sta AnimCurrFrame,x

.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Advance the animation frame.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
AnimationTick SUBROUTINE
    ldx #ANIM_QUEUE_LEN-1      ; X = current queue index
.Loop
    ; check if there's an animation in the queue
    lda AnimID,x
    cmp #ANIM_ID_NONE
    beq .NextElem

    ; get a pointer to the animation data
    tay
    lda AnimTableLSB,y
    sta TempPtr
    lda AnimTableMSB,y
    sta TempPtr+1               ; TempPtr = sprite data

    ; advance the frame
    inc AnimCurrFrame,x

    ; ignore if the frame number is 0
    ldy AnimCurrFrame,x
    beq .NextElem

    ; check for terminating -1
    lda #-1
    cmp (TempPtr),y
    beq .RemoveElem
    jmp .NextElem

.RemoveElem
    ; end of the animation clip: erase the queue entry
    lda #ANIM_ID_NONE
    sta AnimColumn,x
    sta AnimRow,x
    sta AnimID,x
    lda #0
    sta AnimCurrFrame,x

.NextElem
    dex
    bpl .Loop

    rts

; -----------------------------------------------------------------------------
; Desc:     Updates animations in SpritePtrs using the animation list.
; Inputs:   Arg1 (current column)
;           Arg2 (current row)
;           SpritePtrs (array of pointers)
; Ouputs:
; -----------------------------------------------------------------------------
#if 0
AnimationUpdate SUBROUTINE
    ldx #NUM_SPRITES-1
.Loop
    lda Arg1
    cmp AnimColumn,x
    bne .Next
    lda Arg2
    cmp AnimRow,x
    bne .Next

    ; found: get a pointer to the sprite record
    ldy AnimID,x
    lda AnimTableLSB,y
    sta TempPtr
    lda AnimTableMSB,y
    sta TempPtr+1

    ; copy pointer to sprite frame data
    ldy #0
    lda (TempPtr),y
    lda Arg2                ; Y = row
    asl
    tay
    sta

    ldy #1
    lda (TempPtr),y

    lda AnimRow,y
    asl
    tax
    
.Next
    dex
    bpl .Loop
    rts
#endif
