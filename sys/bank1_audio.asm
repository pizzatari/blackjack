; -----------------------------------------------------------------------------
; SOUND DATA
; -----------------------------------------------------------------------------
; Variable length sound clip data: each note is 2 bytes
;
; Header data:
;   tempo mask, number of loops, number of notes
; Note data:
;  2 bytes per note: [volume << 4 | control], [frequency]
;

#if VIDEO_MODE == VIDEO_NTSC

; Sound effect ID for the sound effect queue
SOUND_ID_NONE           = 0
SOUND_ID_ERROR          = 1
SOUND_ID_CHIRP          = 2
SOUND_ID_CARD_FLIP      = 3
SOUND_ID_CHIPS          = 4
SOUND_ID_HAND_OVER      = 5
SOUND_ID_SHUFFLE0       = 6
SOUND_ID_SHUFFLE1       = 7
SOUND_ID_PUSH           = 8
SOUND_ID_WIN0           = 9
SOUND_ID_WIN1           = 10
SOUND_ID_LOST           = 11
SOUND_ID_CRASH_LANDING  = 12
SOUND_ID_FLYING         = 13
;SOUND_ID_NO_CHIPS      = 14
;SOUND_ID_BANK_BROKE    = 15

SOUND_ID_NAVIGATE       = SOUND_ID_CHIRP
SOUND_ID_HIT            = SOUND_ID_CHIRP
SOUND_ID_STAND          = SOUND_ID_CHIRP
SOUND_ID_DOUBLEDOWN     = SOUND_ID_CHIRP
SOUND_ID_SURRENDER      = SOUND_ID_CHIRP
SOUND_ID_INSURANCE      = SOUND_ID_CHIRP
SOUND_ID_SPLIT          = SOUND_ID_CHIRP

; tempo mask
SoundTempo
    dc.b 0                          ; SOUND_ID_NONE
    dc.b %00000001                  ; SOUND_ID_ERROR
    dc.b 0                          ; SOUND_ID_CHIRP
    dc.b 0                          ; SOUND_ID_CARD_FLIP
    dc.b 0                          ; SOUND_ID_CHIPS
    dc.b 0                          ; SOUND_ID_HAND_OVER
    dc.b %00000011                  ; SOUND_ID_SHUFFLE0
    dc.b %00000001                  ; SOUND_ID_SHUFFLE1
    dc.b %00000011                  ; SOUND_ID_PUSH
    dc.b %00000011                  ; SOUND_ID_WIN0
    dc.b %00000011                  ; SOUND_ID_WIN1
    dc.b %00000011                  ; SOUND_ID_LOST
    dc.b %00000111                  ; SOUND_ID_CRASH_LANDING
    dc.b %00000111                  ; SOUND_ID_FLYING

; number of loops (increments up to 0)
SoundLoops
    dc.b  0                         ; SOUND_ID_NONE
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_ERROR
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_CHIRP
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_CARD_FLIP
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_CHIPS
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_HAND_OVER
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_SHUFFLE0
    dc.b -2 << SOUND_LOOPS_POS      ; SOUND_ID_SHUFFLE1
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_PUSH
    dc.b -3 << SOUND_LOOPS_POS      ; SOUND_ID_WIN0
    dc.b -3 << SOUND_LOOPS_POS      ; SOUND_ID_WIN1
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_LOST
    dc.b -13 << SOUND_LOOPS_POS     ; SOUND_ID_CRASH_LANDING
    dc.b -1 << SOUND_LOOPS_POS      ; SOUND_ID_FLYING

; starting note index (increments up to 0)
SoundNumNotes
    dc.b  0                                 ; SOUND_ID_NONE
    dc.b (-SoundErrorSize/2) & $0f          ; SOUND_ID_ERROR
    dc.b (-SoundChirpSize/2) & $0f          ; SOUND_ID_CHIRP
    dc.b (-SoundCardFlipSize/2) & $0f       ; SOUND_ID_CARD_FLIP
    dc.b (-SoundChipsSize/2) & $0f          ; SOUND_ID_CHIPS
    dc.b (-SoundHandOverSize/2) & $0f       ; SOUND_ID_HAND_OVER
    dc.b (-SoundShuffle0Size/2) & $0f       ; SOUND_ID_SHUFFLE0
    dc.b (-SoundShuffle1Size/2) & $0f       ; SOUND_ID_SHUFFLE1
    dc.b (-SoundPushSize/2) & $0f           ; SOUND_ID_PUSH
    dc.b (-SoundWin0Size/2) & $0f           ; SOUND_ID_WIN0
    dc.b (-SoundWin1Size/2) & $0f           ; SOUND_ID_WIN1
    dc.b (-SoundLostSize/2) & $0f           ; SOUND_ID_LOST
    dc.b (-SoundCrashLandingSize/2) & $0f   ; SOUND_ID_CRASH_LANDING
    dc.b (-SoundFlyingSize/2) & $0f         ; SOUND_ID_FLYING

; note data pointers (offset -1 page for negative indexing)
SoundTableLo
    dc.b 0                          ; SOUND_ID_NONE
    dc.b <(SoundError-256)          ; SOUND_ID_ERROR
    dc.b <(SoundChirp-256)          ; SOUND_ID_CHIRP
    dc.b <(SoundCardFlip-256)       ; SOUND_ID_CARD_FLIP
    dc.b <(SoundChips-256)          ; SOUND_ID_CHIPS
    dc.b <(SoundHandOver-256)       ; SOUND_ID_HAND_OVER
    dc.b <(SoundShuffle0-256)       ; SOUND_ID_SHUFFLE0
    dc.b <(SoundShuffle1-256)       ; SOUND_ID_SHUFFLE1
    dc.b <(SoundPush-256)           ; SOUND_ID_PUSH
    dc.b <(SoundWin0-256)           ; SOUND_ID_WIN0
    dc.b <(SoundWin1-256)           ; SOUND_ID_WIN1
    dc.b <(SoundLost-256)           ; SOUND_ID_LOST
    dc.b <(SoundCrashLanding-256)   ; SOUND_ID_CRASH_LANDING
    dc.b <(SoundFlying-256)         ; SOUND_ID_FLYING
SoundTableHi
    dc.b 0                          ; SOUND_ID_NONE
    dc.b >(SoundError-256)          ; SOUND_ID_ERROR
    dc.b >(SoundChirp-256)          ; SOUND_ID_CHIRP
    dc.b >(SoundCardFlip-256)       ; SOUND_ID_CARD_FLIP
    dc.b >(SoundChips-256)          ; SOUND_ID_CHIPS
    dc.b >(SoundHandOver-256)       ; SOUND_ID_HAND_OVER
    dc.b >(SoundShuffle0-256)       ; SOUND_ID_SHUFFLE0
    dc.b >(SoundShuffle1-256)       ; SOUND_ID_SHUFFLE1
    dc.b >(SoundPush-256)           ; SOUND_ID_PUSH
    dc.b >(SoundWin0-256)           ; SOUND_ID_WIN0
    dc.b >(SoundWin1-256)           ; SOUND_ID_WIN1
    dc.b >(SoundLost-256)           ; SOUND_ID_LOST
    dc.b >(SoundCrashLanding-256)   ; SOUND_ID_CRASH_LANDING
    dc.b >(SoundFlying-256)         ; SOUND_ID_FLYING

; notes are played in forward order
SoundStart SET .
    dc.b $8c, 11        ; note 1    [AUDV, AUDC], AUDF
    dc.b $8c, 21        ; note 2    [AUDV, AUDC], AUDF
    dc.b $8c, 31        ; note 3    [AUDV, AUDC], AUDF
SoundErrorSize = . - SoundStart
SoundError = .

SoundStart SET .
    dc.b $85, 6
SoundChirpSize = . - SoundStart
SoundChirp = .

SoundStart SET .
    dc.b $1f, 20
    dc.b $2f, 14
    dc.b $5f, 20
    dc.b $5f, 14
    dc.b $8f, 20
    dc.b $5f, 14
    dc.b $5f, 20
    dc.b $2f, 14
    dc.b $1f, 10
SoundCardFlipSize = . - SoundStart
SoundCardFlip = .

SoundStart SET .
    dc.b $85, 22
    dc.b $2c, 8
    dc.b $65, 18
    dc.b $2c, 6
    dc.b $45, 14
    dc.b $2c, 4
    dc.b $25, 10
    dc.b $2c, 2
    dc.b $15, 6
    dc.b $2c, 1
SoundChipsSize = . - SoundStart
SoundChips = .

SoundStart SET .
    dc.b $85, 6
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
SoundHandOverSize = . - SoundStart
SoundHandOver = .

SoundStart SET .
    dc.b $68, 9
    dc.b $a8, 8
    dc.b $c8, 7
SoundShuffle0Size = . - SoundStart
SoundShuffle0 = .

SoundStart SET .
    dc.b $79, 18
    dc.b $89, 16
    dc.b $99, 14
    dc.b $a9, 12
    dc.b $b9, 10
    dc.b $c9, 8
SoundShuffle1Size = . - SoundStart
SoundShuffle1 = .

SoundStart SET .
    dc.b $8d, 12
    dc.b $8d, 10
    dc.b $8d, 14
    dc.b $8d, 12
    dc.b $8d, 10
    dc.b $8d, 14
SoundPushSize = . - SoundStart
SoundPush = .

SoundStart SET .
    dc.b $85, 14
    dc.b $85, 17
    dc.b $85, 14
    dc.b $85, 19
    dc.b $85, 14
    dc.b $85, 11
    dc.b $85, 19
SoundWin0 = .
SoundWin0Size = . - SoundStart

SoundStart SET .
    dc.b $85, 22
    dc.b $85, 14
    dc.b $85, 15
    dc.b $85, 16
    dc.b $85, 15
    dc.b $85, 16
SoundWin1Size = . - SoundStart
SoundWin1 = .

SoundStart SET .
    dc.b $a7, 20
    dc.b $01, 0 
    dc.b $87, 25
    dc.b $01, 0 
    dc.b $87, 30
    dc.b $01, 0 
    dc.b $67, 28
    dc.b $57, 28
    dc.b $47, 28
    dc.b $47, 28
    dc.b $47, 28
    dc.b $47, 28
SoundLostSize = . - SoundStart
SoundLost = .

SoundStart SET .
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
SoundCrashLandingSize = . - SoundStart
SoundCrashLanding = .

SoundStart SET .
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
    dc.b $a8, 8
SoundFlyingSize = . - SoundStart
SoundFlying = .

#endif

#if VIDEO_MODE == VIDEO_PAL
#endif
