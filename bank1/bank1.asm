; -----------------------------------------------------------------------------
; Start of bank 1
; -----------------------------------------------------------------------------
    SEG bank1

    ORG BANK1_ORG, FILLER_CHAR
    RORG BANK1_RORG

DELTA_HEIGHT        = 64
ATMOS_HEIGHT        = 64 + DELTA_HEIGHT
HILLS_HEIGHT        = 8
UPPER_FG_HEIGHT     = 24
LOWER_FG_HEIGHT     = SCREEN_HEIGHT-ATMOS_HEIGHT-HILLS_HEIGHT-UPPER_FG_HEIGHT-5

; atmosphere height goes from 128 to 64
; lower foreground height goes from 24 to 88

HORIZON_COLOR       = COLOR_LLGREEN
HILLS_COLOR         = COLOR_MGREEN

; ship positions
SHIP_Y_POS          = UPPER_FG_HEIGHT + SHIP_HEIGHT + 4
SHIP_X_END          = 86

CASINO_Y_POS        = 22

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
AtmosHeight     SET LocalVars
FgHeight        SET LocalVars+1
TempHeight      SET LocalVars+2
ShipPosX        SET LocalVars+3
ShipPosY        SET LocalVars+4
DoorPosX        SET LocalVars+5
DoorEnable      SET LocalVars+6
CasinoColor     SET LocalVars+7
CasinoPtr0      SET LocalVars+8
CasinoPtr1      SET LocalVars+10
FlamePtr        SET LocalVars+12

Bank1_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank1_Init
    ; joystick delay
    lda #JOY_TIMER_DELAY
    sta JoyTimer

    lda #ATMOS_HEIGHT-1
    sta AtmosHeight
    lda #LOWER_FG_HEIGHT
    sta FgHeight

    lda #SHIP_Y_POS
    sta ShipPosY

    lda #%00001000
    sta REFP0
    sta REFP1

    ldx #0
    stx NUSIZ0
    stx NUSIZ1
    stx CasinoColor
    stx DoorEnable

    ; position player 0
    ; X = 0
    lda #158
    sta ShipPosX
    jsr Bank1_HorizPosition

    ; position player 1
    ldx #P1_OBJ
    lda #151
    jsr Bank1_HorizPosition

    ; position door
    ldx #M1_OBJ
    lda #151
    jsr Bank1_HorizPosition

    sta WSYNC
    sta HMOVE

    lda #SOUND_ID_CRASH_LANDING
    sta Arg1
    jsr SoundQueuePlay

    ; wait for overscan to finish
    TIMER_WAIT
    sta WSYNC

Bank1_FrameStart
    jsr Bank1_VerticalSync
    TIMED_JSR Bank1_VerticalBlank, TIME_VBLANK_TITLE+1, TIM64T ; +1 to fix timing issue
    jsr Bank1_LandingKernel
    TIMED_JSR Bank1_Overscan, TIME_OVERSCAN, TIM64T
    jmp Bank1_FrameStart

Bank1_VerticalSync
    VERTICAL_SYNC
    rts

Bank1_VerticalBlank SUBROUTINE
    ; update animations every 4 frames
    lda #%00000011
    bit FrameCtr
    bne .Return

    ; shrink atmosphere, expand foreground
    ldy AtmosHeight
    cpy #ATMOS_HEIGHT-DELTA_HEIGHT+1
    bcc .Skip
    dec AtmosHeight
    inc FgHeight
.Skip

    ; check if the ship reached the stopping point
    ldx ShipPosX
    cpx #SHIP_X_END
    beq .AtRest

    ; ship is in flight
    jsr Bank1_MoveShip
    jsr Bank1_AnimateFlames
    lda #<Bank1_BlankSprite
    sta CasinoPtr0
    sta CasinoPtr1
    lda #>Bank1_BlankSprite
    sta CasinoPtr0+1
    sta CasinoPtr1+1
    jmp .Return

.AtRest
    ; set to fixed Y position in sub-divided foreground
    jsr Bank1_FadeInCasino
    jsr Bank1_AnimateFlames
    lda #<Bank1_CasinoGfx0
    sta CasinoPtr0
    lda #>Bank1_CasinoGfx0
    sta CasinoPtr0+1
    lda #<Bank1_CasinoGfx1
    sta CasinoPtr1
    lda #>Bank1_CasinoGfx1
    sta CasinoPtr1+1
    lda #2
    sta DoorEnable

.Return
    sta WSYNC
    lda #0
    sta VBLANK
    rts

Bank1_LandingKernel SUBROUTINE
    ; set up graphics config
    lda #%00110001          ; pf reflected; ballsize = 8
    ldy #COLOR_DGREEN

    sta WSYNC
    sta CTRLPF
    sty COLUPF
    ldy #0
    sty PF0
    sty PF1
    sty PF2

    jsr Bank1_DrawAtmosphere
    jsr Bank1_DrawBgHills

    ; transition hills to foreground
    lda #%00110000          ; pf mirrored; ballsize = 8
    sta WSYNC
    sta CTRLPF

    ; do some set up for the foreground
    lda #0
    ldx #$e0
    sta WSYNC
    sta COLUBK
    sta NUSIZ0
    sta NUSIZ1
    stx COLUPF

    jsr Bank1_DrawUpperFg

    sta HMCLR
    jsr Bank1_DrawLowerFg

    ; clear graphics
    lda #0
    sta WSYNC
    sta COLUPF
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    rts

; variable height
Bank1_DrawAtmosphere SUBROUTINE
    ldy AtmosHeight
.Atmosphere
    tya
    ; 8 bands x 8 height: 64 total height
    and #%01110000
    lsr
    lsr
    lsr
    lsr
    tax
    lda Bank1_AtmosPalette,x
    sta WSYNC
    sta COLUBK
    dey
    bne .Atmosphere
    rts

Bank1_DrawBgHills SUBROUTINE
    lda #HORIZON_COLOR
    ldx #HILLS_COLOR
    ldy #HILLS_HEIGHT
    sta WSYNC
    sta COLUPF
.Hills
    sta WSYNC
    stx COLUBK
    lda Bank1_Horizon-1,y
    sta PF0
    sta PF1
    sta PF2
    dey
    bne .Hills
    rts

#if 1
; drawing foreground on even lines and ship on odd lines
Bank1_DrawUpperFg SUBROUTINE
    ldy CasinoColor                 ; 3 (32)
    lda Bank1_CasinoPalette,y       ; 4 (36)
    sta COLUP0                      ; 3 (39)
    sta COLUP1                      ; 3 (42)

    ldx #0                          ; 2 (2)
.FgCasino
    ; even scan line
    txa                             ; 2 (48)
    and #%00011110                  ; 2 (50)
    lsr                             ; 2 (2)
    tay                             ; 2 (52)
    lda Bank1_ForegroundPalette,y   ; 4 (56)
    sta WSYNC                       ; 3 (59)

    ; --------------------------------------
    sta COLUPF                      ; 3 (3)
    lda Bank1_Foreground,y          ; 4 (7)
    sta PF0                         ; 3 (10)
    sta PF1                         ; 3 (13)
    sta PF2                         ; 3 (16)

    ; odd scan line
    inx                             ; 2 (18)
    ldy #COLOR_BLACK                ; 2 (20)
    txa                             ; 2 (22)
    sec                             ; 2 (24)
    sta WSYNC                       ; 3 (27)

    ; --------------------------------------
    sty COLUPF                      ; 3 (3)
    txa                             ; 2 (2)
    lsr                             ; 2 (11)
    tay                             ; 2 (13)
    lda (CasinoPtr0),y              ; 5 (18)
    sta GRP0                        ; 3 (21)
    lda (CasinoPtr1),y              ; 5 (26)
    sta GRP1                        ; 3 (29)
    ;lda DoorEnable                  ; 3 (3)
    ;sta ENAM1                       ; 3 (3)

.skipCasino

    inx                             ; 2 (44)
    cpx #UPPER_FG_HEIGHT            ; 2 (46)
    bcc .FgCasino                   ; 3 (49)
    rts
#else
; drawing foreground on even lines and ship on odd lines
Bank1_DrawUpperFg SUBROUTINE
    ldx #0                          ; 2 (2)
.FgCasino
    ; even scan line
    txa                             ; 2 (48)
    and #%00011110                  ; 2 (50)
    lsr                             ; 2 (2)
    tay                             ; 2 (52)
    lda Bank1_ForegroundPalette,y   ; 4 (56)
    sta WSYNC                       ; 3 (59)

    ; --------------------------------------
    sta COLUPF                      ; 3 (3)
    lda Bank1_Foreground,y          ; 4 (7)
    sta PF0                         ; 3 (10)
    sta PF1                         ; 3 (13)
    sta PF2                         ; 3 (16)

    ; odd scan line
    inx                             ; 2 (18)
    ldy #COLOR_BLACK                ; 2 (20)
    txa                             ; 2 (22)
    sec                             ; 2 (24)
    sta WSYNC                       ; 3 (27)

    ; --------------------------------------
    sty COLUPF                      ; 3 (3)
    sbc #CASINO_Y_POS               ; 2 (5)
    adc #CASINO_HEIGHT*2            ; 2 (7)
    bcc .skipCasino                 ; 2 (9)
    lsr                             ; 2 (11)
    tay                             ; 2 (13)
    lda (CasinoPtr0),y              ; 5 (18)
    sta GRP0                        ; 3 (21)
    lda (CasinoPtr1),y              ; 5 (26)
    sta GRP1                        ; 3 (29)
    ;lda DoorEnable                  ; 3 (3)
    ;sta ENAM1                       ; 3 (3)

.skipCasino
    ldy CasinoColor                 ; 3 (32)
    lda Bank1_CasinoPalette,y       ; 4 (36)
    sta COLUP0                      ; 3 (39)
    sta COLUP1                      ; 3 (42)

    inx                             ; 2 (44)
    cpx #UPPER_FG_HEIGHT            ; 2 (46)
    bcc .FgCasino                   ; 3 (49)
    rts
#endif

Bank1_DrawLowerFg SUBROUTINE
    lda #UPPER_FG_HEIGHT            ; 2 (2)
    clc                             ; 2 (2)
    adc FgHeight                    ; 3 (3)
    sta TempHeight                  ; 3 (3)

    ldx #UPPER_FG_HEIGHT            ; 2 (2)
.FgTerrain
    ; even scan line
    txa                             ; 2 (44)
    and #%00011110                  ; 2 (50)
    lsr                             ; 2 (2)
    tay                             ; 2 (48)
    lda Bank1_ForegroundPalette,y   ; 4 (52)

    ; --------------------------------------
    sta WSYNC
    sta COLUPF                      ; 3 (3)
    lda Bank1_Foreground,y          ; 4 (7)
    sta PF0                         ; 3 (10)
    sta PF1                         ; 3 (13)
    sta PF2                         ; 3 (16)

    ; odd scan line
    inx                             ; 2 (18)
    ldy #COLOR_BLACK                ; 2 (20)
    sec                             ; 2 (22)
    txa                             ; 2 (24)
    sbc ShipPosY                    ; 3 (27)
    adc #SHIP_HEIGHT*2              ; 2 (29)

    ; --------------------------------------
    sta WSYNC
    sty COLUPF                      ; 3 (3)

    bcc .SkipDraw                   ; 2 (5)
    lsr                             ; 2 (7)
    tay                             ; 2 (9)
    lda (FlamePtr),y                ; 5 (14)
    sta GRP0                        ; 3 (17)
    lda Bank1_ShipGfx,y             ; 4 (21)
    sta GRP1                        ; 3 (24)
    lda Bank1_ShipPalette,y         ; 4 (28)
    sta COLUP0                      ; 3 (31)
    sta COLUP1                      ; 3 (34)
.SkipDraw

    inx                             ; 2 (36)
    cpx TempHeight                  ; 3 (39)
    bcc .FgTerrain                  ; 3 (42)

    ; the scanline count alternates between even and odd whereas the kernel
    ; increments by 2, so force the line count to be a multiple of 2
    lda #1
    bit TempHeight
    bne .Skip
    sta WSYNC
.Skip
    rts

Bank1_Overscan SUBROUTINE
    sta WSYNC
    lda #%00000010
    sta VBLANK
    inc FrameCtr

    jsr SoundQueueTick
    jsr Bank1_ReadSwitches

    ; update joystick timer
    ldx JoyTimer
    bne .DecReturn
    jsr Bank1_ReadJoystick
    rts
.DecReturn
    dex
    stx JoyTimer
    rts

#if 0
    ; update joystick timer
    ldx JoyTimer
    beq .NoUpdate
    dex
    stx JoyTimer
.NoUpdate

    ; joystick delay
    lda JoyTimer
    beq .DoJoystick
    cmp #JOY_TIMER_DELAY
    bcc .SkipJoystick
.DoJoystick
    jsr Bank1_ReadJoystick
.SkipJoystick
#endif
    rts

Bank1_MoveShip SUBROUTINE
    ; move the ship horizontally
    dec ShipPosX
    lda #1<<4               ; move left 1 pixel
    sta HMP0
    sta HMP1
    sta HMM1
    sta WSYNC
    sta HMOVE

    ; move the ship vertically
    lda FrameCtr
    and #%00011110
    lsr
    tax

    ; using a table for vertical motion jitter
    clc
    lda ShipPosY
    adc Bank1_MotionJitterY,x
    sta ShipPosY
    rts

Bank1_FadeInCasino
    lda FrameCtr
    and #%00000111      ; update every 8 frames
    bne .Return
    lda CasinoColor
    cmp #CASINO_NUM_COLORS-1
    beq .Return
    inc CasinoColor
.Return
    rts

Bank1_AnimateFlames SUBROUTINE
    ; alternate the flame graphics
    lda FrameCtr
    and #%00011000
    lsr
    lsr
    lsr
    tay
    lda Bank1_FlamesLo,y
    sta FlamePtr
    lda Bank1_FlamesHi,y
    sta FlamePtr+1
    rts

; -----------------------------------------------------------------------------
; Desc:     Reads the console switches and assigns state variables.
; Inputs:
; Ouputs:
; -----------------------------------------------------------------------------
Bank1_ReadSwitches SUBROUTINE
    lda SWCHB
    ora #~SWITCH_RESET_MASK
    cmp #$FF
    beq .Return
    jmp Bank1_Reset
.Return
    rts

; -----------------------------------------------------------------------------
; Desc:     Reads the joystick and takes action.
; Inputs:
; Ouputs:
; Notes:
; -----------------------------------------------------------------------------
Bank1_ReadJoystick SUBROUTINE
    lda INPT4
    and #JOY_FIRE_MASK              ; check for 0
    bne .Return

    jsr SoundQueueClear

    ; reset stack
    pla
    pla
    pla
    pla

    JUMP_BANK PROC_BANK2_INIT, 2

.Return
    rts

; -----------------------------------------------------------------------------
; GRAPHICS DATA
; -----------------------------------------------------------------------------
    include "sys/bank1_palette.asm"

Bank1_Horizon
    dc.b %00000000, %10000000, %11000000, %11100000, %11110000
    dc.b %11111000, %11111100, %11111110, %11111111

Bank1_Foreground
    dc.b %01001000
    dc.b %00100011
    dc.b %10011100
    dc.b %01100011
    dc.b %01010100
    dc.b %10011110
    dc.b %10100101
    dc.b %01001010
    dc.b %10110001
    dc.b %10000100
    dc.b %01111011
    dc.b %10000100
    dc.b %01010011
    dc.b %00101100
    dc.b %11001010
    dc.b %00110001

Bank1_FlameGfx0
    dc.b %10101000
    dc.b %01011100
    dc.b %00010110
    dc.b %00000011
    ds.b 4, 0
Bank1_FlameGfx1
    dc.b %01010000
    dc.b %11011010
    dc.b %00101100
    dc.b %00000110
    ds.b 4, 0
Bank1_FlameGfx2
    dc.b %11000000
    dc.b %01110100
    dc.b %01011000
    dc.b %00101010
    ds.b 4, 0
Bank1_FlameGfx3
    dc.b %10010000
    dc.b %10101000
    dc.b %11110010
    dc.b %00010110
Bank1_ShipGfx
    ds.b 4, 0
    dc.b %10110000
    dc.b %01011110
    dc.b %11111111
    dc.b 0
SHIP_HEIGHT = . - Bank1_ShipGfx

Bank1_FlamesLo
    dc.b <Bank1_FlameGfx0, <Bank1_FlameGfx1, <Bank1_FlameGfx2, <Bank1_FlameGfx3
Bank1_FlamesHi
    dc.b >Bank1_FlameGfx0, >Bank1_FlameGfx1, >Bank1_FlameGfx2, >Bank1_FlameGfx3

#if 0
Bank1_CasinoGfx0
    dc.b %00000111
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
    dc.b %11100011
    dc.b %11100011
    dc.b %11100011
    dc.b %11111111
    dc.b 0
CASINO_HEIGHT = . - Bank1_CasinoGfx0
Bank1_CasinoGfx1
    dc.b %11100000
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
    dc.b %01000101
    dc.b %01000101
    dc.b %01000101
    dc.b %11111111
Bank1_BlankSprite
    ds.b 20, 0
#endif

    include "bank1/gen/casino.sp"

CASINO_HEIGHT = . - Bank1_CasinoGfx1


; these have to be multiples of 2
Bank1_MotionJitterY
    dc.b 2, 0, 2, 2, 2, 0, -2, 0
    dc.b 0, 2, 0, 2, 2, 0, -2, 0

; -----------------------------------------------------------------------------
; Sound
; -----------------------------------------------------------------------------
    include "bank1/lib/sound.asm"
    include "sys/bank1_sound_data.asm"

    IF BALLAST_ON == 1
        ; ballast code
        LIST OFF
        REPEAT [$3fc0 - $31b0] / 10
            lda $f000  ; 3
            sta $f000  ; 3
            inc $f000  ; 3
            tax        ; 1
        REPEND
        LIST ON
    ENDIF

    ALIGN 256, FILLER_CHAR

    INCLUDE_POSITIONING_SUBS Bank1_

; -----------------------------------------------------------------------------
; Shared procedures
; -----------------------------------------------------------------------------
PROC_BANK2_INIT             = 0

Bank1_ProcTableLo
    dc.b <Bank2_Init

Bank1_ProcTableHi
    dc.b >Bank2_Init

    ORG BANK1_ORG + $ff6-BS_SIZEOF
    RORG BANK1_RORG + $ff6-BS_SIZEOF

    INCLUDE_BANKSWITCH_SUBS 1, BANK1_HOTSPOT

	; bank switch hotspots
    ORG BANK1_ORG + $ff6
    RORG BANK1_RORG + $ff6
    ds.b 4, 0

    ; interrupts
    ORG BANK1_ORG + $ffa
    RORG BANK1_RORG + $ffa

Bank1_Interrupts
    .word Bank1_Reset       ; NMI    $*ffa, $*ffb
    .word Bank1_Reset       ; RESET  $*ffc, $*ffd
    .word Bank1_Reset       ; IRQ    $*ffe, $*fff
