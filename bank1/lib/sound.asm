; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     Feb 2019
; Version:  1.0
; Project:  Simple Sound 2600
; Desc:     Simple sound driver for Atari 2600. This plays basic sound clips
;           or short tunes.
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Clears and initializes the queue.
; Inputs:    
; Ouputs:
; -----------------------------------------------------------------------------
SoundQueueClear SUBROUTINE
    ldx #SOUND_QUEUE_LEN-1
    lda #SOUND_ID_NONE
    ldy #0
.Loop
    sta SoundQueue,x        ; -1
    sty SoundCtrl,x         ;  0
    ;sty SoundCurrNote,x    ;  0
    ;sty SoundLoops,x       ;  0
    dex
    bpl .Loop
    rts

; -----------------------------------------------------------------------------
; Play two sounds.
; Inputs:   Arg1 (sound id)
;           Arg2 (sound id)
; Ouputs:
; -----------------------------------------------------------------------------
SoundQueuePlay2 SUBROUTINE
    jsr SoundQueuePlay
    lda Arg2
    sta Arg1
    jsr SoundQueuePlay
    rts

; -----------------------------------------------------------------------------
; Play a sound.
; Inputs:   Arg1 (sound id)
; Ouputs:
; -----------------------------------------------------------------------------
SoundQueuePlay SUBROUTINE
    lda Arg1
    ;cmp #SOUND_ID_NONE
    beq .Return

    ; get an offset into the SoundTable
    tax                         ; save A
    asl
    tay

    ; initialize pointer to sound data
    lda SoundTable,y
    sta TempPtr
    lda SoundTable+1,y
    sta TempPtr+1               ; TempPtr = SoundTable[id]

    ; loops must be > 0
    ldy #1                      ; select first byte
    lda (TempPtr),y
    beq .Return

    ; search for an empty spot
    txa                         ; restore A
    ldx #SOUND_QUEUE_LEN-1
.Loop
    ldy SoundQueue,x
    bmi .FoundEmptyChannel
    cmp SoundQueue,x
    beq .FoundEmptyChannel      ; reuse channel playing the same sound
    dex
    bpl .Loop

    ; queue is full, replace last element
    ldx #SOUND_QUEUE_LEN-1
.FoundEmptyChannel

    ; add id to the queue
    sta SoundQueue,x

    ; initialize current note
    ;ldy #0
    ;sty SoundCurrNote,x
    lda #0
    SET_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl

    ; initialize loops
    ldy #1                      ; select second byte
    lda (TempPtr),y
    ;sta SoundLoops,x
    SET_BITS_X SOUND_LOOPS_MASK, SoundCtrl

.Return
    rts

; -----------------------------------------------------------------------------
; Play the next sound sample.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
SoundQueueTick SUBROUTINE
    ldx #SOUND_QUEUE_LEN-1      ; X = current queue index
.Loop
    ; check if there's a sound effect in the queue
    lda SoundQueue,x
    ;cmp #SOUND_ID_NONE
    beq .Mute

    ; get offset into SoundTable
    asl
    tay

    ; get a pointer to the sound data
    lda SoundTable,y
    sta TempPtr
    lda SoundTable+1,y
    sta TempPtr+1               ; TempPtr = &SoundTable[id]

    ; 1st byte is the playback tempo
    ldy #0                      ; Y -> start of sound data
    lda (TempPtr),y
    ; skip if this is not a play tick
    and FrameCtr
    bne .NextNote

    ; seek to next note: 1 + ticks
    ;lda SoundCurrNote,x
    GET_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl

    asl                         ; A = A * 2
    tay
    iny
    iny                         ; skip 2 byte header

    ; check for the end of the clip
    lda (TempPtr),y
    beq .EndOfClip

    ; next byte is volume and control
    sta AUDC0,x                 ; write to channel
    ; get the volume
    lsr
    lsr
    lsr
    lsr
    sta AUDV0,x                 ; write to channel

    ; next byte is the audio frequency
    iny
    lda (TempPtr),y
    sta AUDF0,x                 ; write to channel
    
    ; advance the current note
    ;inc SoundCurrNote,x
    INC_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl
    jmp .NextNote

.EndOfClip
    ; rewind
    lda #0
    ;sta SoundCurrNote,x
    SET_BITS_X SOUND_CURR_NOTE_MASK, SoundCtrl
    ; check for remaining loops
    ;dec SoundLoops,x
    DEC_BITS_X SOUND_LOOPS_MASK, SoundCtrl
    lda SoundCtrl,x
    and #SOUND_LOOPS_MASK
    bne .NextNote

.RemoveElement
    ; end of the sound clip: erase the queue entry
    lda #SOUND_ID_NONE
    sta SoundQueue,x

.Mute
    lda #0
    ; mute any current playing notes
    sta AUDV0,x                 
    sta AUDC0,x
    sta AUDF0,x

.NextNote
    dex
    bpl .Loop

    rts
