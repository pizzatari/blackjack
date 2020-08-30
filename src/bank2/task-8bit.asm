; -----------------------------------------------------------------------------
; Desc:     Adds a task to the front of the queue.
; Inputs:   A register (task id)
;           X register (argument)
;           TaskQueue
; Outputs:
; Notes:
;   0,0 -> 1,0
;   0,1 -> 1,1
;   1,0 -> 1,1
;   1,1 -> 1,1
; -----------------------------------------------------------------------------
Bank2_QueueAdd SUBROUTINE
    ldy TaskQueue
    beq .Save
    ; shift right
    ldy TaskQueue
    sty TaskQueue+1
    ldy TaskArg
    sty TaskArg+1
.Save
    stx TaskArg
    sta TaskQueue
    rts

; -----------------------------------------------------------------------------
; Desc:     Replaces a task.
; Inputs:   A register (new task id)
;           X register (argument)
;           Y register (old task id)
;           TaskQueue
; Outputs:  A register (new task id or 0 on full)
; -----------------------------------------------------------------------------
Bank2_QueueReplace SUBROUTINE
    cpy TaskQueue
    bne .Next1

    stx TaskArg
    sta TaskQueue
    rts

.Next1
    cpy TaskQueue+1
    bne .NotFound

    stx TaskArg+1
    sta TaskQueue+1
    rts
     
.NotFound
    lda #0
    rts

; -----------------------------------------------------------------------------
; Desc:     Removes a task.
; Inputs:   A register (task id)
;           TaskQueue
; Outputs:  A register (task id or 0 on not found)
; -----------------------------------------------------------------------------
Bank2_QueueRemove SUBROUTINE
    tay
    lda #0

    cpy TaskQueue
    bne .Next1
    sta TaskArg
    sta TaskQueue
    tya
    rts

.Next1
    cpy TaskQueue+1
    bne .NotFound
    sta TaskArg+1
    sta TaskQueue+1
    tya
    rts
     
.NotFound
    lda #0
    rts

; -----------------------------------------------------------------------------
; Desc:     Clears the queue.
; Inputs:   TaskQueue
; Outputs:
; -----------------------------------------------------------------------------
Bank2_QueueClear SUBROUTINE
    lda #0
    sta TaskArg
    sta TaskArg+1
    sta TaskQueue
    sta TaskQueue+1
    rts

; -----------------------------------------------------------------------------
; Desc:     Removes the trailing task, which may be in the high or low nibble.
; Inputs:   TaskQueue
; Outputs:  A register (task id removed or 0 on empty)
;           X register (task arg removed)
; Notes:
;   0,0 -> 0,0
;   1,0 -> 0,0
;   0,1 -> 0,0
;   1,1 -> 0,1
; -----------------------------------------------------------------------------
Bank2_QueueRemoveTail SUBROUTINE
    ; check if the tail is empty
    ldy TaskQueue+1
    beq .Clear
    ldx TaskArg+1
    ; shift right
    lda TaskArg
    sta TaskArg+1
    lda TaskQueue
    sta TaskQueue+1
    tya
    rts

.Clear
    ldy TaskQueue
    ldx TaskArg
    lda #0
    sta TaskQueue
    sta TaskArg
    tya
    rts

; -----------------------------------------------------------------------------
; Desc:     Get the trailing task, which may be in the high or low byte.
;           TaskQueue is unmodified.
; Inputs:   TaskQueue
; Outputs:  A register (task id or 0 on empty)
;           X register (task arg)
; -----------------------------------------------------------------------------
Bank2_QueueGetTail SUBROUTINE
    ldy TaskQueue+1
    beq .Next
    ldx TaskArg+1
    tya
    rts
.Next
    ldx TaskArg
    lda TaskQueue
    rts

