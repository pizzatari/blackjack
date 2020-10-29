; -----------------------------------------------------------------------------
; SOUND DATA
; -----------------------------------------------------------------------------
; Variable length sound clip data: each note is 2 bytes
;  tempo:       1 byte (bit mask)
;  config:      1 byte (bit mask)
;               bit 0-6:    loops (1-127) 0 disables sound
;               bit 7:      number of channels (0=1 channel; 1=2 channels)
;  note * N:    2 bytes per note: [volume:control], [frequency]
;  terminator:  1 byte (0)
;
;  2 byte note:
;    byte 1: 0000 0000
;      bits: 0-3    volume
;      bits: 4-7    control
;    byte 2: xxx 00000
;      bits: 0-5    freqency
;

#if VIDEO_MODE == VIDEO_NTSC

SoundNone       ; SoundNone is not used, but defined in case it's dereferenced
SoundNoChips
SoundBankBroke
    dc.b 0, 0, 0

SoundError
    dc.b %00000011      ; tempo mask (0 = frame rate; more 1's = slower)
    dc.b 1              ; config: (# channels, # loops)
    dc.b $8c, 11        ; note data: (AUDV, AUDC), (AUDF)
    dc.b $8c, 21
    dc.b $8c, 31
    dc.b 0              ; null terminator

SoundCardFlip
    dc.b 0
    dc.b 1
    dc.b $1f, 20
    dc.b $2f, 14
    dc.b $5f, 20
    dc.b $5f, 14
    dc.b $8f, 20
    dc.b $5f, 14
    dc.b $5f, 20
    dc.b $2f, 14
    dc.b $1f, 10
    dc.b 0

SoundChips
    dc.b 0
    dc.b 1
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
    dc.b 0

SoundNavigate
SoundHit
SoundStand
SoundDoubledown
SoundSurrender
SoundInsurance
SoundSplit
    dc.b 0
    dc.b 1
    dc.b $85, 6
    dc.b 0

SoundHandOver
    dc.b 0
    dc.b 1
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b $81, 16
    dc.b 0, 0

SoundShuffle0
    dc.b %00000111
    dc.b 1
    dc.b $a8, 9
    dc.b $b8, 8
    dc.b $c8, 7
    dc.b 0, 0

SoundShuffle1
    dc.b %00000001
    dc.b 2
    dc.b $79, 18
    dc.b $89, 16
    dc.b $99, 14
    dc.b $a9, 12
    dc.b $b9, 10
    dc.b $c9, 8
    dc.b 0, 0

;SoundNoChips
;    dc.b 0, 0, 0

SoundPush
    dc.b %00000111
    dc.b 1
    dc.b $8d, 12
    dc.b $8d, 10
    dc.b $8d, 14
    dc.b $8d, 12
    dc.b $8d, 10
    dc.b $8d, 14
    dc.b 0

SoundWin0
    dc.b %00000011
    dc.b 3
    dc.b $85, 14
    dc.b $85, 17
    dc.b $85, 14
    dc.b $85, 19
    dc.b $85, 14
    dc.b $85, 11
    dc.b $85, 19
    dc.b 0

SoundWin1
    dc.b %00000011
    dc.b 3
    dc.b $85, 22
    dc.b $85, 14
    dc.b $85, 15
    dc.b $85, 16
    dc.b $85, 15
    dc.b $85, 16
    dc.b 0

SoundLost
    dc.b %00000011
    dc.b 1
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
    dc.b 0

SoundCrashLanding
    dc.b %00000011
    dc.b 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b $88, 15
    dc.b 0

;SoundBankBroke
;    dc.b 0, 0, 0

; Sound effect lookup table
SoundTable
    dc.w SoundNone              ; SOUND_ID_NONE
    dc.w SoundError             ; SOUND_ID_ERROR
    dc.w SoundNavigate          ; SOUND_ID_NAVIGATE
    dc.w SoundCardFlip          ; SOUND_ID_CARD_FLIP
    dc.w SoundChips             ; SOUND_ID_CHIPS
    dc.w SoundHit               ; SOUND_ID_HIT
    dc.w SoundStand             ; SOUND_ID_STAND
    dc.w SoundDoubledown        ; SOUND_ID_DOUBLEDOWN
    dc.w SoundSurrender         ; SOUND_ID_SURRENDER
    dc.w SoundInsurance         ; SOUND_ID_INSURANCE
    dc.w SoundSplit             ; SOUND_ID_SPLIT
    dc.w SoundHandOver          ; SOUND_ID_HAND_OVER
    dc.w SoundShuffle0          ; SOUND_ID_SHUFFLE0
    dc.w SoundShuffle1          ; SOUND_ID_SHUFFLE1
    dc.w SoundNoChips           ; SOUND_ID_NO_CHIPS
    dc.w SoundPush              ; SOUND_ID_PUSH
    dc.w SoundWin0              ; SOUND_ID_WIN0
    dc.w SoundWin1              ; SOUND_ID_WIN1
    dc.w SoundLost              ; SOUND_ID_LOST
    dc.w SoundCrashLanding      ; SOUND_ID_CRASH_LANDING
    ;dc.w SoundBankBroke         ; SOUND_ID_BANK_BROKE

#endif

#if VIDEO_MODE == VIDEO_PAL
#endif
