;
; Layout of kernel rows (32 pixels tall).
;
;   .----------------------.
;   |                     B| 7 :
; 0 | .................... |   : top (shrink/expand)
;   |                     B| 6 :
;   |______________________|
; 1 |S1S2                 B| 5 : sky
;   |______________________|
; 2 |S1S2 ___.---.___.- PFB| 4 : horizon/casino
;   |______________________|
; 3 |S1(S2) . ' .  . '  PFB| 3 : foreground
;   |______________________|
; 4 |S1(S2) ' . '  . '  PFB| 2 : foreground
;   |______________________|
;   |                    FB| 1 :
; 5 | .................... |   : bottom (expand/shrink)
;   |                    FB| 0 :
;   '----------------------'

; -----------------------------------------------------------------------------
; Start of bank 1
; -----------------------------------------------------------------------------
    SEG Bank1

    ORG BANK1_ORG, FILLER_CHAR
    RORG BANK1_RORG

; Kernel row extents (starting positions)
ROW_HEIGHT      = 32
ROW6            = 252
ROW5            = 256-[ROW_HEIGHT*2]
ROW4            = ROW5-ROW_HEIGHT-1
ROW3            = ROW4-ROW_HEIGHT
ROW2            = ROW3-ROW_HEIGHT
ROW1            = ROW2-ROW_HEIGHT
ROW0            = ROW1-1
ROW_TOP         = ROW6
ROW_BOT         = ROW0

CASINO_POS_X    = 110
SHIP_BEG_X      = 23 + 137
SHIP_END_X      = 23 + 60
SHIP_TOP_Y      = 140

CASINO_BEG_COLOR= $10
CASINO_END_COLOR= $1e

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
ShipX           SET BankVars
ShipY           SET BankVars+1      ; bottom position
Direction       SET BankVars+2

ScreenBotY      SET BankVars+3
ScreenTopY      SET BankVars+4

CurrEnd         SET BankVars+5

FlamesGfx       SET BankVars+6
CasinoColor     SET BankVars+8

; bitmap rows: the bit positions indicate if there is a ship in the row
ROW1_MASK       SET %00000100   ; maps arithmatic row 2
ROW2_MASK       SET %00001000   ; maps arithmatic row 3
ROW3_MASK       SET %00010000   ; maps arithmatic row 4
ROW4_MASK       SET %00100000   ; maps arithmatic row 5
ShipBitmap      SET BankVars+9

Bank1_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank1_Init
    ; wait for overscan to finish
    TIMER_WAIT

Bank1_FrameLoop
    VERTICAL_SYNC

    lda #TIME_VBLANK_TITLE+1
    sta TIM64T
    jsr Bank1_VerticalBlank

    ; Create a tail call recursion stack by populating with
    ; subroutine addresses for rts to jump to.
    ;
    lda #>[Bank1_BottomKernel-1]
    pha
    lda #<[Bank1_BottomKernel-1]
    pha

    ; Foreground ---------------------------------
    ; row 1 (96->64)
    lda #ROW1                   ; pass Y ending coordinate
    pha
    ; detect if the ship is overlapping the row
    lda #ROW1_MASK
    bit ShipBitmap
    beq .NoShip4
    lda #>[Bank1_GroundKernelSprite-1]
    pha
    lda #<[Bank1_GroundKernelSprite-1]
    pha
    jmp .Continue4
.NoShip4
    lda #>[Bank1_GroundKernel-1]
    pha
    lda #<[Bank1_GroundKernel-1]
    pha
.Continue4

    ; row 2 (128->96)
    lda #ROW2                   ; pass Y ending coordinate
    pha

    ; determine if ship has stopped moving
    lda Direction
    bne .ShipKernel
    lda #>[Bank1_GroundKernelCasino-1]
    pha
    lda #<[Bank1_GroundKernelCasino-1]
    pha
    jmp .Continue3
.ShipKernel
    ; detect if the ship is overlapping the row
    lda #ROW2_MASK
    bit ShipBitmap
    beq .NoShip3
    lda #>[Bank1_GroundKernelSprite-1]
    pha
    lda #<[Bank1_GroundKernelSprite-1]
    pha
    jmp .Continue3
.NoShip3
    lda #>[Bank1_GroundKernel-1]
    pha
    lda #<[Bank1_GroundKernel-1]
    pha
.Continue3

    ; Horizon ------------------------------------
    ; row 3 (160->128)
    ; detect if the ship is overlapping the row
    lda #ROW3_MASK
    bit ShipBitmap
    beq .NoShip2
    lda #>[Bank1_HorizonKernelSprite-1]
    pha
    lda #<[Bank1_HorizonKernelSprite-1]
    pha
    jmp .Continue2
.NoShip2
    lda #>[Bank1_HorizonKernel-1]
    pha
    lda #<[Bank1_HorizonKernel-1]
    pha
.Continue2

    ; Sky ----------------------------------------
    ; row 4 (192->160)
    ; detect if the ship is overlapping the row
    lda #ROW4_MASK
    bit ShipBitmap
    beq .NoShip1
    lda #>[Bank1_SkyKernelSprite-1]
    pha
    lda #<[Bank1_SkyKernelSprite-1]
    pha
    jmp .Continue1
.NoShip1
    lda #>[Bank1_SkyKernel-1]
    pha
    lda #<[Bank1_SkyKernel-1]
    pha
.Continue1

    ldx ScreenTopY

    TIMER_WAIT

    lda #0
    sta WSYNC
    sta VBLANK

    jmp Bank1_TopKernel         ; subroutine call

Bank1_KernelReturn
    jsr Bank1_Overscan
    jmp Bank1_FrameLoop

Bank1_LandingInit
    lda #%00001000
    sta REFP0
    sta REFP1

    lda #0
    sta NUSIZ0
    sta NUSIZ1
    sta CasinoColor

    ; -----
    ; landing: -1, taking off: 1, full stop: 0
    lda #-1
    sta Direction

    ; joystick delay
    lda #INPUT_DELAY
    sta InputTimer

    lda #ROW_TOP
    sta ScreenTopY
    lda #ROW_BOT
    sta ScreenBotY
    lda #SHIP_TOP_Y
    sta ShipY
    lda #SHIP_BEG_X
    sta ShipX

    jsr Bank1_UpdateShip

    lda #SOUND_ID_CRASH_LANDING
    sta Arg1
    jsr SoundPlay

    lda #SOUND_ID_CRASH_LANDING
    sta Arg1
    jsr SoundPlay

    sta HMCLR

    SET_POINTER FlamesGfx, Bank1_FlamesGfx0
    jmp Bank1_Init

Bank1_VerticalBlank SUBROUTINE
    inc FrameCtr

    ; update animations every 4 frames
    lda #%00000011
    bit FrameCtr
    bne .NoUpdate1
    jsr Bank1_ScrollScreen
    jsr Bank1_UpdateShip
.NoUpdate1

    ; update every 32 frames
    lda FrameCtr
    and #%00011111
    bne .NoUpdate2
    jsr Bank1_UpdateCasino
.NoUpdate2

    jsr Bank1_SetupShipGfx

    ldx #OBJ_P0
    lda ShipX
    jsr Bank1_HorizPosition

    ldx #OBJ_P1
    lda ShipX
    clc
    adc #8
    jsr Bank1_HorizPosition

    lda #0
    ldx #DEF_BG_COLOR
    ldy #%00110001
    sta WSYNC
    sta HMOVE                       ; 3 (3)
    stx COLUBK                      ; 3 (9)
    sta GRP0                        ; 3 (12)
    sta GRP1                        ; 3 (15)
    ; pf reflected; ballsize = 8
    sty CTRLPF                      ; 2 (17)
    sty COLUPF                      ; 3 (20)
    ; turn on v. delay for casino
    sta VDELP1                      ; 3 (23)
    lda CasinoColor                 ; 3 (26)
    sta COLUP1                      ; 3 (29)

    sta HMCLR                       ; 3 (32)
    rts                             ; 6 (38)

    PAGE_BOUNDARY_SET

Bank1_TopKernel SUBROUTINE          ;   [34]
    ; prepare Y for Ship kernels
    sec                             ; 2 [36]
    lda #0                          ; 2 [38]
    sbc ShipY                       ; 3 [41]
    and #%00111111                  ; 2 [43]
    tay                             ; 2 [45]

.Kernel
    lda Bank1_BGPalette,x           ; 4 (14) [49]
    sta WSYNC                       ; 3 (17) [52]

    sta COLUBK                      ; 3 (3)
    dex                             ; 2 (5)
    cpx #ROW5+1                     ; 2 (7)
    bcs .Kernel                     ; 3 (10)

    rts                             ; 6 (15)

Bank1_SkyKernel SUBROUTINE
.Kernel
    dey                             ; 2 (12)
    lda Bank1_BGPalette,x           ; 4 (16)
    sta WSYNC                       ; 3 (19)

    sta COLUBK                      ; 3 (3)
    dex                             ; 2 (5)
    cpx #ROW4+1                     ; 2 (7)
    bcs .Kernel                     ; 3 (10)
    rts                             ; 6 (15)

Bank1_HorizonKernel SUBROUTINE
.Kernel
    ; odd scan line
    dey                             ; 2 (32)
    lda Bank1_BGPalette,x           ; 4 (36)
    sta WSYNC                       ; 3 (39)

    sta COLUBK                      ; 3 (3)
    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_Playfield,x           ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    dex                             ; 2 (25)
    cpx #ROW3+1                     ; 2 (27)
    bcs .Kernel                     ; 3 (30)
    rts                             ; 6 (35)

Bank1_GroundKernel SUBROUTINE       ;   [59]
    pla                             ; 4 [63]
    sta CurrEnd                     ; 3 [66]
.Kernel
    dey                             ; 2 (41) [68]

    lda Bank1_BGPalette,x           ; 4 (45) [72]
    sta WSYNC                       ; 3 (48) [75]

    sta COLUBK                      ; 3 (3)
    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_Playfield,x           ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    lda #0                          ; 2 (25)
    sta GRP1                        ; 3 (28)
    sta NUSIZ1                      ; 3 (31)

    dex                             ; 2 (33)
    cpx CurrEnd                     ; 3 (36)
    bne .Kernel                     ; 3 (39)

    rts                             ; 6 (45)

Bank1_SkyKernelSprite SUBROUTINE    ;        [15]
.Kernel
    ; calc ship index
    dey                             ; 2 (41) [17]
    tya                             ; 2 (43) [19]
    and #%00111111                  ; 2 (45) [21]   modulo 64
    tay                             ; 2 (47) [23]

    lda Bank1_BGPalette,x           ; 4 (51) [27]
    sta WSYNC                       ; 3 (54) [30]

    sta COLUBK                      ; 3 (3)
    lda Bank1_ShipGfx,y             ; 4 (7)
    sta GRP0                        ; 3 (10)
    lda Bank1_ShipPal,y             ; 4 (14)
    sta COLUP0                      ; 3 (17)
    lda (FlamesGfx),y               ; 5 (22)
    sta GRP1                        ; 3 (25)
    lda Bank1_FlamesPal,y           ; 4 (29)
    sta COLUP1                      ; 3 (32)

    dex                             ; 2 (34)
    cpx #ROW4+1                     ; 2 (36)
    bcs .Kernel                     ; 3 (39)
    rts                             ; 6 (45)

    PAGE_BOUNDARY_CHECK "Bank1 kernels (1)"

    ORG BANK1_ORG + $300, FILLER_CHAR
    RORG BANK1_RORG + $300

    PAGE_BOUNDARY_SET

; background resolution is 2 pixels for this kernel
Bank1_HorizonKernelSprite SUBROUTINE;        [45]
.Kernel
    ; odd scan line
    dey                             ; 2 (47) [47]
    tya                             ; 2 (49) [49]
    and #%00111111                  ; 2 (51) [51]    modulo 64
    tay                             ; 2 (53) [53]

    lda Bank1_BGPalette,x           ; 4 (57) [57]
    sta WSYNC                       ; 3 (60) [60]

    sta COLUBK                      ; 3 (3)
    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_Playfield,x           ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    lda Bank1_ShipGfx,y             ; 4 (27)
    sta GRP0                        ; 3 (30)

    lda Bank1_ShipPal,y             ; 4 (34)
    sta COLUP0                      ; 3 (37)
    lda (FlamesGfx),y               ; 4 (41)
    sta GRP1                        ; 3 (44)
    lda Bank1_FlamesPal,y           ; 4 (48)
    sta COLUP1                      ; 3 (51)

    ; even scan line
    dey                             ; 2 (53)
    tya                             ; 2 (55)
    and #%00111111                  ; 2 (57)    modulo 64
    tay                             ; 2 (59)
    dex                             ; 2 (61)

    lda Bank1_Playfield,x           ; 4 (65)
    sta PF2                         ; 3 (68)
    sta PF1                         ; 3 (71)
    sta WSYNC                       ; 3 (74)

    sta PF0                         ; 3 (3)

    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_ShipGfx,y             ; 4 (14)
    sta GRP0                        ; 3 (17)
    lda Bank1_ShipPal,y             ; 4 (21)
    sta COLUP0                      ; 3 (24)
    lda (FlamesGfx),y               ; 4 (28)
    sta GRP1                        ; 3 (31)
    lda Bank1_FlamesPal,y           ; 4 (35)
    sta COLUP1                      ; 3 (38)

    dex                             ; 2 (40)
    cpx #ROW3+1                     ; 2 (42)
    bcs .Kernel                     ; 3 (45)

    rts                             ; 6 (50)

Bank1_GroundKernelCasino SUBROUTINE ;   [35]
    pla                             ; 4 [39]
    sta CurrEnd                     ; 3 [42]
    lda #0                          ; 2 [44]
    sta VDELP1                      ; 3 [47]

.Kernel
    dey                             ; 2 (40) [49]
    lda Bank1_BGPalette,x           ; 4 (44) [53]
    sta WSYNC                       ; 3 (47) [56]

    sta COLUBK                      ; 3 (3)
    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_Playfield,x           ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    lda Bank1_CasinoGfx-ROW2-10,x   ; 5 (28)
    sta GRP1                        ; 3 (31)

    dex                             ; 2 (33)
    cpx #ROW2+1                     ; 2 (35)
    bcs .Kernel                     ; 3 (38)

    lda #1                          ; 2 (40)
    sta VDELP1                      ; 3 (43)
    rts                             ; 6 (48)

Bank1_GroundKernelSprite SUBROUTINE ;   [56]
    pla                             ; 4 [60]
    sta CurrEnd                     ; 3 [63]

.Kernel
    ; odd scan line
    dey                             ; 2 (49) [65]
    tya                             ; 2 (51) [67]
    and #%00111111                  ; 2 (53) [69]   modulo 64
    tay                             ; 2 (55) [71]
    sta WSYNC                       ; 3 (58) [74]

    lda Bank1_BGPalette,x           ; 4 (4)
    sta COLUBK                      ; 3 (7)
    lda Bank1_FGPalette,x           ; 4 (11)
    sta COLUPF                      ; 3 (14)
    lda Bank1_Playfield,x           ; 4 (18)
    sta PF0                         ; 3 (21)
    sta PF1                         ; 3 (24)
    sta PF2                         ; 3 (27)

    lda Bank1_ShipGfx,y             ; 4 (31)
    sta GRP0                        ; 3 (34)
    lda Bank1_ShipPal,y             ; 4 (38)
    sta COLUP0                      ; 3 (41)
    lda (FlamesGfx),y               ; 5 (46)
    sta GRP1                        ; 3 (49)
    lda Bank1_FlamesPal,y           ; 4 (53)
    sta COLUP1                      ; 3 (56)

    ; even scan line
    dex                             ; 2 (58)
    dey                             ; 2 (60)
    tya                             ; 2 (62)
    and #%00111111                  ; 2 (64)    modulo 64
    tay                             ; 2 (66)

    lda Bank1_Playfield,x           ; 4 (70)
    sta PF2                         ; 3 (73)
    sta PF1                         ; 3 (0)
    sta PF0                         ; 3 (3)
    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_ShipGfx,y             ; 4 (14)
    sta GRP0                        ; 3 (17)
    lda Bank1_ShipPal,y             ; 4 (21)
    sta COLUP0                      ; 3 (24)
    lda (FlamesGfx),y               ; 5 (29)
    sta GRP1                        ; 3 (32)
    lda Bank1_FlamesPal,y           ; 4 (36)
    sta COLUP1                      ; 3 (39)

    dex                             ; 2 (41)
    cpx CurrEnd                     ; 3 (44)
    bne .Kernel                     ; 3 (47)
    rts                             ; 6 (52)

    PAGE_BOUNDARY_CHECK "Bank1 kernels (2)"

Bank1_FlamesLo
    dc.b <Bank1_FlamesGfx0, <Bank1_FlamesGfx1, <Bank1_FlamesGfx2, <Bank1_FlamesGfx3
Bank1_FlamesHi
    dc.b >Bank1_FlamesGfx0, >Bank1_FlamesGfx1, >Bank1_FlamesGfx2, >Bank1_FlamesGfx3

Bank1_MotionJitterY
    dc.b -2, -1, -1,  2, -1,  1, -2, -1
    dc.b -1, -2,  1, -2,  2, -1, -2, -1

    INCLUDE_POWER_TABLE 1, 2, 8

    PAGE_BOUNDARY_SET
Bank1_BottomKernel SUBROUTINE       ;        [52]
    lda #0                          ; 2 (33) [54]
    sta GRP0                        ; 3 (36) [57]
    sta GRP1                        ; 3 (39) [60]
    sta VDELP1                      ; 3 (42) [63]

.Kernel
    lda Bank1_BGPalette,x           ; 4 (46) [67]
    sta WSYNC                       ; 3 (49) [70]

    sta COLUBK                      ; 3 (3)
    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_Playfield,x           ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    dex                             ; 2 (25)
    cpx ScreenBotY                  ; 3 (28)
    bne .Kernel                     ; 3 (31)

    ; clear graphics
    lda #0                          ; 2 (32)
    sta WSYNC                       ; 3 (35)

    sta PF2                         ; 3 (3)
    sta PF1                         ; 3 (6)
    sta PF0                         ; 3 (9)
    sta COLUBK                      ; 3 (12)
    sta COLUPF                      ; 3 (15)
    sta GRP0                        ; 3 (18)
    sta GRP1                        ; 3 (21)
    jmp Bank1_KernelReturn          ; 3 (24)

Bank1_DepartKernel SUBROUTINE
    txa                             ; 2 (2)
    sec                             ; 2 (4)
    sbc #ROW_HEIGHT                 ; 2 (6)
    sta CurrEnd                     ; 3 (9)
.Kernel
    sta WSYNC                       ; 3 (14)
    stx COLUBK                      ; 3 (3)
    dex                             ; 2 (5)
    cpx CurrEnd                     ; 3 (8)
    bne .Kernel                     ; 3 (11)

    rts                             ; 6 (6)

    PAGE_BOUNDARY_CHECK "Bank1 kernels (3)"

Bank1_Overscan SUBROUTINE           ; 6 (27)
    ldx #%00000010                  ; 2 (29)
    lda #TIME_OVERSCAN              ; 2 (31)
    sta TIM64T                      ; 4 (35)
    sta WSYNC                       ; 3 (38)

    stx VBLANK                      ; 3 (5)

    jsr SoundTick               
    jsr Bank1_ReadSwitches

    ; update joystick timer
    ldx InputTimer
    bne .DecReturn
    jsr Bank1_ReadJoystick
    jmp .Return
.DecReturn
    dex
    stx InputTimer
    jmp .Return

    ; update joystick timer
    ldx InputTimer
    beq .NoUpdate
    dex
    stx InputTimer
.NoUpdate

    ;CALL_BANK PROC_BANK1_GAMEIO, 0, 1
    CALL_BANK Bank0_GameIO

.Return
    TIMER_WAIT
    rts

Bank1_ScrollScreen SUBROUTINE
    ; do nothing when Direction == 0
    lda Direction
    beq .Return
    bmi .Down

    ; up
    lda ScreenTopY
    cmp #ROW_TOP
    beq .Return

    inc ScreenTopY
    inc ScreenBotY
    jmp .Return

    ; down
.Down
    lda ScreenTopY
    cmp #ROW5+1
    beq .Return

    dec ScreenTopY
    dec ScreenBotY

.Return
    rts

; * detect overlap for casino kernel and flames
; * move ship
; * move p1 object when it's rendering flames
; * position objects
Bank1_UpdateCasino SUBROUTINE
    lda Direction
    bne .Return

    lda CasinoColor
    bne .NoInit

    lda #CASINO_BEG_COLOR
    sta CasinoColor
    rts

.NoInit
    cmp #CASINO_END_COLOR
    beq .Return
    clc
    adc #2
    sta CasinoColor

.Return
    rts

Bank1_UpdateShip SUBROUTINE
    lda FrameCtr
    
    lda Direction
    beq .Return

    ; move the ship horizontally
    lda ShipX
    cmp #SHIP_END_X+1
    bcc .AtRest

    lda #1<<4
    sta HMP0
    dec ShipX

    ; move the ship vertically
    lda FrameCtr
    and #%00011110
    lsr
    tax

    ; using a table for vertical motion jitter
    clc
    lda ShipY
    adc Bank1_MotionJitterY,x
    sta ShipY

    ; update bitmap with bottom position
    and #%11100000
    lsr
    lsr
    lsr
    lsr
    lsr
    tax
    lda Bank1_Pow2,x
    sta ShipBitmap

    ; update bitmap with top position
    clc
    lda ShipY
    adc #SHIP_HEIGHT
    and #%11100000
    lsr
    lsr
    lsr
    lsr
    lsr
    tax
    lda Bank1_Pow2,x
    ora ShipBitmap
    sta ShipBitmap

    rts

.AtRest
.Return
    lda #0
    sta HMP0
    sta Direction

    rts

Bank1_SetupShipGfx SUBROUTINE
    ; normal width
    ldx #0
    stx NUSIZ1
    
    ; animate flames
    lda FrameCtr
    and #%00011000
    lsr
    lsr
    lsr
    tay
    lda Bank1_FlamesLo,y
    sta FlamesGfx
    lda Bank1_FlamesHi,y
    sta FlamesGfx+1

    ; set up mask table indexes
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
    and #JOY_FIRE           ; check for 0
    bne .Return

    jsr SoundClear

    lda #0
    sta InputTimer

    ; reset stack
    pla
    pla
    pla
    pla

    ;JUMP_BANK PROC_BANK1_INIT, 2, 1
    JUMP_BANK Bank2_Init

.Return
    rts

    ; -------------------------------------------------------------------------
    include "../atarilib/lib/sound.asm"
    include "sys/bank1_audio.asm"

    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $b00, FILLER_CHAR
    RORG BANK1_RORG + $b00

    include "bank1/gfx/flames.asm"

    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $c00, FILLER_CHAR
    RORG BANK1_RORG + $c00

    include "bank1/gfx/foreground.asm"

    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $d00, FILLER_CHAR
    RORG BANK1_RORG + $d00

    include "sys/bank1_bg_palette.asm"

    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $e00, FILLER_CHAR
    RORG BANK1_RORG + $e00

    include "sys/bank1_fg_palette.asm"

    ; -------------------------------------------------------------------------
    ; Shared procedures
    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $f00, FILLER_CHAR
    RORG BANK1_RORG + $f00

    INCLUDE_POSITIONING_SUBS 1
    include "bank1/gfx/sprites.asm"
    include "sys/bank1_ship_palette.asm"

PROC_BANK1_GAMEIO 	= 0
PROC_BANK1_INIT 	= 1

Bank1_ProcTableLo
    dc.b <Bank0_GameIO
    dc.b <Bank2_Init
Bank1_ProcTableHi
    dc.b >Bank0_GameIO
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
