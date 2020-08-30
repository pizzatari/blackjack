; TaskWork 4-bit format:
; Bits 0-3:     1st task
; Bits 4-7:     2nd task
TSK_QUEUE1                  = %00001111
TSK_QUEUE2                  = %11110000

; -----------------------------------------------------------------------------
; Desc:     Adds a task to the front of the queue (high nibble).
; Inputs:   A register (task id << 4)
;           TaskQueue
; Outputs:
; -----------------------------------------------------------------------------
Bank2_EnqueueFirst SUBROUTINE
    sta Arg5

    ; check if the front is empty
    lda #TSK_QUEUE2
    bit TaskQueue
    beq .Add

    ; shift right
    lda TaskQueue
    lsr
    lsr
    lsr
    lsr
    ora Arg5
    sta TaskQueue
    rts

.Add
    lda Arg5
    ora TaskQueue
    sta TaskQueue
    rts

; -----------------------------------------------------------------------------
; Desc:     Removes the trailing task, which may be in the high or low nibble.
; Inputs:   TaskQueue
; Outputs:  A register (task id or 0)
;           00000000 -> 00000000
;           11110000 -> 00000000
;           00001111 -> 00000000 >>4
;           11111111 -> 00001111 >>4
; -----------------------------------------------------------------------------
Bank2_DequeueLast SUBROUTINE
    ; check if the tail is empty
    lda #TSK_QUEUE1
    bit TaskQueue
    beq .Clear

    lda TaskQueue
    lsr
    lsr
    lsr
    lsr
    sta TaskQueue
    rts

.Clear
    lda #0
    sta TaskQueue
    rts

; -----------------------------------------------------------------------------
; Desc:     Get the trailing task, which may be in the high or low nibble.
;           TaskQueue is unmodified.
; Inputs:   TaskQueue
; Outputs:  A register (task id or 0)
; -----------------------------------------------------------------------------
Bank2_QueueGetLast SUBROUTINE
    lda TaskQueue
    and #TSK_QUEUE1
    bne .Done
    lda TaskQueue
    lsr
    lsr
    lsr
    lsr
.Done
    rts
