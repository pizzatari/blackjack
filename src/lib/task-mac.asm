; -----------------------------------------------------------------------------
; Desc:     Adds a task to the front of the queue (high nibble).
; Inputs:   TaskQueue
;           Task ID
; Outputs:
; -----------------------------------------------------------------------------
    MAC TSK_ENQUEUE
.QUE    SET {1}
.TSK    SET {2}

        ; check if the front is empty
        lda #TSK_QUEUE2
        bit .QUE
        beq .Add

        ; shift right
        lda .QUE
        REPEAT 4
        lsr
        REPEND
        sta .QUE

.Add
        lda .QUE
        ora #[.TSK << 4]
        sta .QUE
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Removes the trailing task, which may be in the high or low nibble.
; Inputs:   TaskQueue
; Outputs:  A register (task id or 0)
; -----------------------------------------------------------------------------
    MAC TSK_DEQUEUE
.QUE    SET {1}

        ; check if the end is empty
        lda .QUE
        and #TSK_QUEUE1
        bne .Shift

        ; shift right
        lda .QUE
        REPEAT 4
        lsr
        REPEND
        sta .QUE

.Shift
        ; shift right
        lda .QUE
        REPEAT 4
        lsr
        REPEND
        sta .QUE
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Get the trailing task, which may be in the high or low nibble.
;           TaskQueue is unmodified.
; Inputs:   TaskQueue
; Outputs:  A register (task id or 0)
; -----------------------------------------------------------------------------
    MAC TSK_GET_LAST
.QUE    SET {1}

        lda .QUE
        and #TSK_QUEUE1
        bne .Done
        
        lda .QUE
        REPEAT 4
        lsr
        REPEND
.Done
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Replace existing tasks with a new task.
; Inputs:   TaskQueue
;           Task ID
; Outputs:  A register (task id or 0)
; -----------------------------------------------------------------------------
    MAC TSK_REPLACE
.QUE    SET {1}
.TSK    SET {2}
        lda #[.TSK << 4]
        sta .QUE
    ENDM
