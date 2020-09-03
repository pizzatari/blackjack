; -----------------------------------------------------------------------------
; Start of bank 1
; -----------------------------------------------------------------------------
    SEG bank1

    ORG BANK1_ORG, FILLER_CHAR
    RORG BANK1_RORG

JOY_TIMER_DELAY             = 60    ; frames (1 second)

PLANET_ANIM_FRAMES          = 255
ANIM_CLOCK_TICK             = %00000011
ATMOS_HEIGHT                = 64
PLANET_TOP_MARGIN           = ATMOS_HEIGHT

HORIZON_COLOR               = $ce
HILLS_COLOR                 = $c6
HILLS_HEIGHT                = 8

; foreground height: -8 to account for synchronizing WSYNCs
FOREGROUND_MAX_HEIGHT       = SCREEN_HEIGHT-PLANET_TOP_MARGIN-HILLS_HEIGHT-8
FOREGROUND_CASINO_HEIGHT    = 64
FOREGROUND_SHIP_HEIGHT      = 48

; ship ending position
SHIP_Y_START                = 32
SHIP_X_END                  = 86
SHIP_Y_END                  = 110
SHIP_Y_END2                 = 22

CASINO_Y_POS                = 30

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
AtmosHeight     SET MemBlockStart
FgHeight        SET MemBlockStart+1
ShipPosX        SET MemBlockStart+2
ShipPosY        SET MemBlockStart+3
JoyTimer        SET MemBlockStart+4
FlamePosY       SET MemBlockStart+5
FlamePtr        SET MemBlockStart+6
TempHeight      SET MemBlockStart+8
ShipPtr         SET MemBlockStart+10
CasinoColor     SET MemBlockStart+12
SoundLoops      SET MemBlockStart+13

    MAC UPPER_ATMOSPHERE
        ; upper atmosphere: fixed height; cycles colors upward
        ; 64 pixels tall: y iterates 128 to 64
        lda #PLANET_TOP_MARGIN
        clc
        adc AtmosHeight
        tay
.TopMargin
        tya
        and #ATMOS_UPPER_MASK
        lsr
        lsr
        lsr
        lsr
        tax
        sta WSYNC
        lda AtmosUpperPalette,x
        sta COLUBK
        dey
        cpy AtmosHeight
        bne .TopMargin
    ENDM

    MAC LOWER_ATMOSPHERE
        ; lower atmosphere; variable height; cycles colors upward
        ; 64 pixels max height: y iterates  64 -> 0
        ldy AtmosHeight
.Atmosphere
        tya
        and #ATMOS_LOWER_MASK
        lsr
        lsr
        lsr
        lsr
        tax
        lda AtmosLowerPalette,x
        sta WSYNC
        sta COLUBK
        dey
        bpl .Atmosphere
    ENDM

    MAC BACKGROUND_HILLS
        lda #HORIZON_COLOR
        ldx #HILLS_COLOR
        ldy #HILLS_HEIGHT
        sta WSYNC
        sta COLUPF

        ; hills: fixed height; moves upward
        ; 8 pixels tall
.Hills
        sta WSYNC
        stx COLUBK
        lda Bank1_Horizon-1,y
        sta PF0
        sta PF1
        sta PF2
        dey
        bne .Hills
    ENDM

    MAC FOREGROUND_CASINO
        ; skip draw version
        ; foreground: two sections
        ;   top section:    fixed height
        ;   bottom section: variable height; expands upward
        ; drawing foreground on even lines and ship on odd lines
        ; 64 pixels tall: x = 48 to (48+64)
        ldx #0                          ; 2
.FgCasino
        ; even scan line
        txa                             ; 2 (48)
        and #FOREGROUND_MASK            ; 2 (50)
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
        adc #CASINO_HEIGHT              ; 2 (7)
        bcc .skipCasino                 ; 2 (9)
        tay                             ; 2 (11)
        lda Bank1_CasinoGfx1,y          ; 5 (16)
        sta GRP0                        ; 3 (19)
        lda Bank1_CasinoGfx2,y          ; 5 (25)
        sta GRP1                        ; 3 (28)
.skipCasino

        ;lda FrameCtr                    ; 3 (31)
        ;and #%11111000                  ; 2 (33)
        ;sta COLUP0                      ; 3 (36)
        ;sta COLUP1                      ; 3 (39)
        ;lda Bank1_CasinoPalette,y       ; 4 (32)
        ldy CasinoColor                 ; 3 (31)
        lda Bank1_CasinoPalette,y       ; 4 (32)
        sta COLUP0                      ; 3 (35)
        sta COLUP1                      ; 3 (38)

        inx                             ; 2 (41)
        cpx #FOREGROUND_CASINO_HEIGHT   ; 2 (43)
        bcc .FgCasino                   ; 3 (46)
    ENDM

    MAC FOREGROUND_TERRAIN
        ; skip draw version
        ; foreground: variable height; expands upward
        ; drawing foreground on even lines and ship on odd lines
        ; 112 max pixels tall: x = 48 to (48+64)
        ldx #0                          ; 2
.FgTerrain
        ; even scan line
        txa                             ; 2 (46)
        and #FOREGROUND_MASK            ; 2 (48)
        tay                             ; 2 (50)
        lda Bank1_ForegroundPalette,y   ; 4 (54)
        sta WSYNC                       ; 3 (57)

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
        sbc ShipPosY                    ; 3 (6)
        adc #SHIP_HEIGHT                ; 2 (8)
        bcc .skipDraw                   ; 2 (10)
        tay                             ; 2 (12)
        lda (FlamePtr),y                ; 4 (16)
        sta GRP0                        ; 3 (19)
        lda Bank1_ShipGfx,y             ; 4 (23)
        sta GRP1                        ; 3 (26)
.skipDraw

        lda Bank1_ShipPalette,y         ; 4 (30)
        sta COLUP0                      ; 3 (33)
        sta COLUP1                      ; 3 (36)

        inx                             ; 2 (38)
        cpx FgHeight                    ; 3 (41)
        bcc .FgTerrain                  ; 3 (44)

        ; the scanline count alternates between even and odd, so force it
        ; to be even and stable
        lda #1
        bit FgHeight
        bne .SkipExtraLine
        sta WSYNC
.SkipExtraLine
    ENDM

Bank1_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank1_Init
    ; joystick delay
    lda #1
    sta JoyTimer

    lda #ATMOS_HEIGHT-1
    sta AtmosHeight

    lda #%00001000
    sta REFP0
    sta REFP1
    lda #0
    sta NUSIZ0
    sta NUSIZ1

    ; position player 0
    ldx #0
    lda #158
    sta ShipPosX
    jsr Bank1_PosObject

    ; position player 1
    ldx #1
    lda #151
    jsr Bank1_PosObject

    lda #SHIP_Y_START
    sta ShipPosY

    lda #SHIP_HEIGHT-FLAME_HEIGHT
    sta FlamePosY

    lda #0
    sta CasinoColor

    lda #SOUND_ID_CRASH_LANDING
    sta Arg1
    jsr SoundQueuePlay

    ; wait for overscan to finish
    TIMER_WAIT
    sta WSYNC

Bank1_FrameStart
    ; -------------------------------------------------------------------------
    ; vertical sync
    ; -------------------------------------------------------------------------
    VERTICAL_SYNC
    lda #0
    sta VBLANK
    ; -------------------------------------------------------------------------

    ; -------------------------------------------------------------------------
    ; vertical blank
    ; -------------------------------------------------------------------------
    lda #TIME_VBLANK_TITLE+1        ; +1 to fix timing issue
    sta TIM64T

    ; update animations every N frames
    lda FrameCtr
    and #ANIM_CLOCK_TICK
    bne .Continue

    ; move the scene
    jsr Bank1_MoveScene

    lda ShipPosX
    cmp #SHIP_X_END
    beq .SplitFg

    ; move the ship
    jsr Bank1_MoveShip
    jmp .Continue

.Continue
    lda ShipPosX
    cmp #SHIP_X_END
    beq .SplitFg

.NonSplitFg
    ; update scene heights (foreground not sub-divided)
    sec
    lda #FOREGROUND_MAX_HEIGHT
    sbc AtmosHeight
    sta FgHeight
    jmp .UpdatePtrs

.SplitFg
    ; update scene heights (sub-divided foreground)
    sec
    lda #FOREGROUND_MAX_HEIGHT
    sbc #FOREGROUND_CASINO_HEIGHT
    sbc AtmosHeight
    sta FgHeight

    ; set to fixed Y position in sub-divided foreground
    lda #SHIP_Y_END2
    sta ShipPosY

    ; cycle casino color
    lda FrameCtr
    and #%00000111
    bne .SkipColor
    lda CasinoColor
    cmp #CASINO_NUM_COLORS-1
    beq .SkipColor
    inc CasinoColor
.SkipColor

.UpdatePtrs
    ;jsr Bank1_UpdateShipPointers
    ; alternate the flame graphics
    lda FrameCtr
    and #%00011000
    asl                 ; x4
    clc
    adc #<Bank1_FlameGfx1
    sta FlamePtr
    lda #>Bank1_FlameGfx1
    adc #0
    sta FlamePtr+1

    TIMER_WAIT
    ; -------------------------------------------------------------------------

    ; -------------------------------------------------------------------------
    ; kernel
    ; -------------------------------------------------------------------------
    sta WSYNC
    ; set up graphics
    lda #1
    sta CTRLPF
    ldy #COLOR_DGREEN
    sty COLUPF
    ldy #0
    sty PF0
    sty PF1
    sty PF2

    UPPER_ATMOSPHERE
    LOWER_ATMOSPHERE
    BACKGROUND_HILLS

    ; transition hills to foreground
    sta WSYNC
    lda #0
    sta CTRLPF

    ; do some set up for the foreground
    lda #0
    ldx #$e0
    sta WSYNC
    sta COLUBK
    sta NUSIZ0
    sta NUSIZ1
    stx COLUPF

    sta WSYNC

    ; when ship comes to a stop, show split foreground kernel
    lda ShipPosX
    cmp #SHIP_X_END
    bne .ShipInFlight

    FOREGROUND_CASINO

.ShipInFlight
    FOREGROUND_TERRAIN

.TerrainDone
    ; clear graphics
    sta WSYNC
    lda #0
    sta COLUPF
    sta COLUBK
    sta PF0
    sta PF1
    sta PF2
    sta GRP0
    sta GRP1
    ; -------------------------------------------------------------------------

    ; -------------------------------------------------------------------------
    ; overscan
    ; -------------------------------------------------------------------------
    lda #TIME_OVERSCAN
    sta TIM64T

    lda #%00000010
    sta VBLANK
    sta WSYNC
    inc FrameCtr

    jsr SoundQueueTick
    jsr Bank1_ReadSwitches

    ; update joystick timer
    ldx JoyTimer
    beq .SkipTimer
    inx
    stx JoyTimer
.SkipTimer

    ; joystick delay
    lda JoyTimer
    beq .DoJoystick
    cmp #JOY_TIMER_DELAY
    bcc .SkipJoystick
.DoJoystick
    jsr Bank1_ReadJoystick
.SkipJoystick

    TIMER_WAIT
    sta WSYNC
    ; -------------------------------------------------------------------------

    jmp Bank1_FrameStart

Bank1_MoveShip SUBROUTINE
    ; move the ship horizontally
    dec ShipPosX
    lda #1<<4               ; move left 1 pixel
    sta HMP0
    sta HMP1
    sta WSYNC
    sta HMOVE

    ; move the ship vertically
    lda FrameCtr
    and #%00011110
    lsr
    tax

    ; using a table for vertical motion
    clc
    lda ShipPosY
    adc Bank1_ShipMotionY,x
    sta ShipPosY
    sta FlamePosY
    rts

Bank1_MoveScene SUBROUTINE
    ; move atmosphere up
    lda AtmosHeight
    beq .Return
    dec AtmosHeight
.Return
    rts

#if 0
Bank1_UpdatePositions SUBROUTINE
    ; move the ship
    lda ShipPosX
    cmp #SHIP_X_END
    beq .ShipAtRest

    ; horizontal motion
    dec ShipPosX
    lda #1<<4
    sta HMP0
    sta HMP1
    sta WSYNC
    sta HMOVE

    lda ShipPosY
    cmp #SHIP_Y_END
    bcs .ShipAtRest

    ; vertical motion
    lda FrameCtr
    and #%00011110
    lsr
    tax

    lda ShipPosY
    clc
    adc Bank1_ShipMotionY,x
    sta ShipPosY

    lda FlamePosY
    clc
    adc Bank1_ShipMotionY,x
    sta FlamePosY

    ; update foreground height: remove height of atmosphere
    sec
    lda #FOREGROUND_MAX_HEIGHT
    sbc AtmosHeight
    sta FgHeight
    rts

.ShipAtRest
    ; adjust heights to accomodate casino kernel
    sec
    lda #SHIP_Y_END
    sbc #FOREGROUND_CASINO_HEIGHT
    sta ShipPosY

    lda #FOREGROUND_MAX_HEIGHT
    sbc #FOREGROUND_CASINO_HEIGHT
    sta FgHeight

    ; update foreground height: remove height of casino and height of atmosphere
    sec
    lda #FOREGROUND_MAX_HEIGHT
    sbc #FOREGROUND_CASINO_HEIGHT
    sbc AtmosHeight
    sta FgHeight
    rts
#endif

Bank1_UpdateShipPointers SUBROUTINE
    ; alternate the flame graphics
    lda FrameCtr
    and #%00011000
    asl                 ; x4
    clc
    adc #<Bank1_FlameGfx1
    sta FlamePtr
    lda #>Bank1_FlameGfx1
    adc #0
    sta FlamePtr+1

#if 0
    lda #<Bank1_CasinoGfx1
    sta CasinoPtr1
    lda #<Bank1_CasinoGfx2
    sta CasinoPtr2
    lda #>Bank1_CasinoGfx1
    sta CasinoPtr1+1
    sta CasinoPtr2+1
#endif

.Return
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

    lda #GS_NEW_GAME
    sta GameState
    JUMP_BANK PROC_BANK2_INIT, 2

.Return
    rts

; -----------------------------------------------------------------------------
; GRAPHICS DATA
; -----------------------------------------------------------------------------
; 8 bands x 8 pixel color bands: 64 pixels tall
ATMOS_LOWER_MASK    = %01110000
AtmosLowerPalette
    dc.b $cc, $ca, $c8, $c6, $c4, $c2, $c0, $c0

ATMOS_UPPER_MASK    = %01110000
AtmosUpperPalette
    dc.b $cc, $ca, $c8, $c6, $c4, $c2, $c0, $c0

Bank1_Horizon
    dc.b %00000000, %10000000, %11000000, %11100000, %11110000
    dc.b %11111000, %11111100, %11111110, %11111111

Bank1_ForegroundPalette
    dc.b $16, $e8, $f4, $14, $e8, $d4, $14, $f4
    dc.b $16, $e8, $f4, $14, $e8, $d4, $14, $f4

FOREGROUND_MASK     = %00001111
Bank1_Foreground
    dc.b %01001000, $0
    dc.b %00100011, $0
    dc.b %10011100, $0
    dc.b %01100011, $0
    dc.b %01010100, $0
    dc.b %10011110, $0
    dc.b %10100101, $0
    dc.b %01001010, $0
    dc.b %10110001, $0
    dc.b %10000100, $0
    dc.b %01111011, $0
    dc.b %10000100, $0
    dc.b %01010011, $0
    dc.b %00101100, $0
    dc.b %11001010, $0
    dc.b %00110001, $0

Bank1_FlameGfx1
    dc.b 0, %10101000
    dc.b 0, %01011100
    dc.b 0, %00010110
    dc.b 0, %00000011
    ds.b 8, 0
FLAME_HEIGHT = . - Bank1_FlameGfx1

Bank1_FlameGfx2
    dc.b 0, %01010000
    dc.b 0, %11011010
    dc.b 0, %00101100
    dc.b 0, %00000110
    ds.b 8, 0

Bank1_FlameGfx3
    dc.b 0, %11000000
    dc.b 0, %01110100
    dc.b 0, %01011000
    dc.b 0, %00101010
    ds.b 8, 0

Bank1_FlameGfx4
    dc.b 0, %10010000
    dc.b 0, %10101000
    dc.b 0, %11110010
    dc.b 0, %00010110
    ds.b 8, 0

Bank1_ShipGfx
    ds.b 8, 0
    dc.b 0, %10110000
    dc.b 0, %01011110
    dc.b 0, %11111111
    dc.b 0, 0
SHIP_HEIGHT = . - Bank1_ShipGfx

Bank1_ShipPalette
    dc.b 0, $1a, 0, $2a, 0, $3a, 0, $4a
    dc.b 0, $0e, 0, $08, 0, $04, 0, 0

Bank1_CasinoGfx1
    dc.b 0, %00000111
    dc.b 0, %11111111
    dc.b 0, %10000000
    dc.b 0, %10000000
    dc.b 0, %10111111
    dc.b 0, %10100010
    dc.b 0, %10100010
    dc.b 0, %10100010
    dc.b 0, %11111111
    dc.b 0, 0
CASINO_HEIGHT = . - Bank1_CasinoGfx1

Bank1_CasinoGfx2
    dc.b 0, %11100000
    dc.b 0, %11111111
    dc.b 0, %00000001
    dc.b 0, %00000001
    dc.b 0, %11111101
    dc.b 0, %01000101
    dc.b 0, %01000101
    dc.b 0, %01000101
    dc.b 0, %11111111
    dc.b 0, 0

Bank1_CasinoPalette
    dc.b $00, $00, $00, $00, $00, $e0, $e0, $e0
    dc.b $e0, $e2, $e4, $e6, $e8, $ea, $ec, $ee
CASINO_NUM_COLORS = . - Bank1_CasinoPalette

Bank1_ShipMotionY
    dc.b 2, 0, 2, 2, 2, 0, -2, 0
    dc.b 2, 2, 0, 2, 2, 0, -2, 0

; -----------------------------------------------------------------------------
; Sound
; -----------------------------------------------------------------------------
    include "bank1/lib/sound.asm"
    include "bank1/snd/ntsc_snd.asm"
    include "bank1/snd/pal_snd.asm"

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

    HORIZ_POS_TABLE 1

; -----------------------------------------------------------------------------
; Desc:     Positions an object horizontally using the divide by 15 method
;           with a table lookup for fine adjustments.
; Inputs:   A register (horizontal position)
;           X register (sprite to position : 0 to 4)
; Outputs:  A = fine adjustment value
;           Y = the remainder minus an additional 15
; -----------------------------------------------------------------------------
Bank1_PosObject SUBROUTINE
    HORIZ_POS_OBJECT2 Bank1_fineAdjustTable
    sta WSYNC
    sta HMOVE
    rts

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

    BANKSWITCH_ROUTINES 1, BANK1_HOTSPOT

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
