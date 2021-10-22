; -----------------------------------------------------------------------------
; Start of bank 1
; -----------------------------------------------------------------------------
    SEG Bank1

    ORG BANK1_ORG, FILLER_CHAR
    RORG BANK1_RORG

; Kernel row extents (starting positions)
ROW_HEIGHT          = 32
ROW6                = 252
ROW5                = 256-[ROW_HEIGHT*2]
ROW4                = ROW5-ROW_HEIGHT-1
ROW3                = ROW4-ROW_HEIGHT
ROW2                = ROW3-ROW_HEIGHT
ROW1                = ROW2-ROW_HEIGHT
ROW0                = ROW1-1
ROW_TOP             = ROW6
ROW_BOT             = ROW0

SCR_BEG_TOP         = ROW6
SCR_BEG_BOT         = ROW0
SCR_END_TOP         = ROW5+1
SCR_END_BOT         = 3

CASINO_POS_X        = 110
SHIP_BEG_X          = 23 + 137
SHIP_END_X          = 23 + 61
SHIP_BEG_Y          = 140
SHIP_END_Y          = 84

SHIP_ZOOM_Y         = ROW4-16       ; Y coordinate when zooming is triggered
SHIP_WIN_END_X      = SCREEN_WIDTH-8; X coordinate when departing ship stops
SHIP_WIN_END_Y      = ROW5          ; Y coordinate when departing ship stops

SHIP_UPDATE_FREQ    = %00000011
FAST_UPDATE_FREQ    = %00000001
FLAMES_UPDATE_FREQ  = %00011000
SCROLL_UPDATE_FREQ  = %00000011
CASINO_UPDATE_FREQ  = %00011111
MSGTEXT_UPDATE_FREQ = %00000011

CASINO_BEG_COLOR    = $10
CASINO_END_COLOR    = $1e

MSGTXT_BEG_COLOR   = COLOR_DGRAY
MSGTXT_END_COLOR   = COLOR_WHITE

; -----------------------------------------------------------------------------
; Local Variables
; -----------------------------------------------------------------------------
ShipX               SET BankVars
ShipY               SET BankVars+1      ; bottom position
Direction           SET BankVars+2

ScreenBotY          SET BankVars+3
ScreenTopY          SET BankVars+4

CurrEnd             SET BankVars+5

FlamesGfx           SET BankVars+6
CasinoColor         SET BankVars+8

; bitmap rows: the bit positions indicate if there is a ship in the row
ROW1_MASK           SET %00000100   ; maps arithmatic row 2
ROW2_MASK           SET %00001000   ; maps arithmatic row 3
ROW3_MASK           SET %00010000   ; maps arithmatic row 4
ROW4_MASK           SET %00100000   ; maps arithmatic row 5
ShipBitmap          SET BankVars+9

ShipUpdateFreq      SET BankVars+10

MsgTextColor        SET BankVars+11

INTRO_KERNEL_FLAG   = %00000001
LOSE_KERNEL_FLAG    = %00000010
WIN_KERNEL_FLAG     = %00000100
SHIP_ZOOMING        = %00001000
SHIP_DEPARTED_FLAG  = %00010000
SceneState          SET BankVars+12

ReturnAddr          SET BankVars+13

Bank1_Reset
    ; switch to bank 0 if we start here
    bit BANK0_HOTSPOT

Bank1_Init
    lda #0
    sta NUSIZ0
    sta NUSIZ1
    sta CasinoColor
    sta JoyRelease
    sta HMCLR

    ; wait for overscan to finish
    TIMER_WAIT

; -----------------------------------------------------------------------------
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
Bank1_CutSceneLoop
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

Debug

    lda #LOSE_KERNEL_FLAG
    bit SceneState
    bne MsgKernels

    lda #SHIP_DEPARTED_FLAG
    bit SceneState
    bne MsgKernels

IntroKernels
    jmp Bank1_SetupForeground
    jmp Bank1_SetupGround
    jmp Bank1_SetupHorizon
    jmp Bank1_SetupSky

MsgKernels
    jmp Bank1_SetupForeground
    jmp Bank1_SetupMsg
    jmp Bank1_SetupSky

Bank1_ReturnAddr
    ldx ScreenTopY

    TIMER_WAIT

    lda #0
    sta WSYNC
    sta VBLANK

    jmp Bank1_TopKernel         ; subroutine call

Bank1_CutSceneReturn
    jsr Bank1_Overscan
    jmp Bank1_CutSceneLoop

Bank1_IntroInit
    lda #INTRO_KERNEL_FLAG
    sta SceneState
    
    lda #%00001000
    sta REFP0
    sta REFP1

    lda #SHIP_UPDATE_FREQ
    sta ShipUpdateFreq

    ; joystick delay
    lda #INPUT_DELAY
    sta InputTimer

    ; -----
    ; landing: -1, taking off: 1, full stop: 0
    lda #-1
    sta Direction

    lda #SCR_BEG_TOP
    sta ScreenTopY
    lda #SCR_BEG_BOT
    sta ScreenBotY
    lda #SHIP_BEG_Y
    sta ShipY
    lda #SHIP_BEG_X
    sta ShipX

    jsr Bank1_UpdateShip

    lda #SOUND_ID_CRASH_LANDING
    sta Arg1
    sta Arg2
    jsr SoundPlay2

    SET_POINTER FlamesGfx, Bank1_FlamesGfx0
    jmp Bank1_Init

Bank1_LoseInit
    lda #LOSE_KERNEL_FLAG
    sta SceneState

    lda #SHIP_UPDATE_FREQ
    sta ShipUpdateFreq

    ; -----
    ; landing: -1, taking off: 1, full stop: 0
    lda #0
    sta FrameCtr
    sta VDELP0
    sta VDELP1
    sta Direction

    IF MSGTXT_BEG_COLOR != 0
    lda #MSGTXT_BEG_COLOR
    ENDIF
    sta MsgTextColor

    ; joystick delay
    lda #INPUT_DELAY_LOSE
    sta InputTimer

    lda #SCR_BEG_TOP
    sta ScreenTopY
    lda #SCR_BEG_BOT
    sta ScreenBotY
    lda #SHIP_BEG_Y
    sta ShipY
    lda #SHIP_BEG_X
    sta ShipX

    SET_POINTER FlamesGfx, Bank1_FlamesGfx0
    jmp Bank1_Init

Bank1_WinInit
    lda #WIN_KERNEL_FLAG
    sta SceneState

    lda #SHIP_UPDATE_FREQ
    sta ShipUpdateFreq

    lda #0
    sta REFP0
    sta REFP1
    sta VDELP0
    sta VDELP1
    sta NUSIZ0
    sta NUSIZ1

    IF MSGTXT_BEG_COLOR != 0
    lda #MSGTXT_BEG_COLOR
    ENDIF
    sta MsgTextColor

    ; joystick delay
    lda #INPUT_DELAY_WIN
    sta InputTimer

    ; -----
    ; landing: -1, taking off: 1, full stop: 0
    lda #1
    sta Direction

    lda #SCR_END_TOP
    sta ScreenTopY
    lda #SCR_END_BOT
    sta ScreenBotY
    lda #SHIP_END_Y
    sta ShipY
    cmp #SHIP_END_X+10
    sta ShipX

    lda #SOUND_ID_CRASH_LANDING
    sta Arg1
    jsr SoundPlay

    SET_POINTER FlamesGfx, Bank1_ExhaustGfx
    jmp Bank1_Init

Bank1_VerticalBlank SUBROUTINE
    inc FrameCtr

    jsr Bank1_ScrollScreen
    jsr Bank1_UpdateCasino
    jsr Bank1_UpdateMsgText
    jsr Bank1_UpdateShip
    jsr Bank1_SetupShipGfx

    lda Direction
    beq .Flipped
    bmi .Flipped
    ldx #OBJ_P1
    lda ShipX
    jsr Bank1_HorizPosition
    ldx #OBJ_P0
    lda ShipX
    clc
    adc #8
    jsr Bank1_HorizPosition
    jmp .Continue
.Flipped
    ldx #OBJ_P0
    lda ShipX
    jsr Bank1_HorizPosition
    ldx #OBJ_P1
    lda ShipX
    clc
    adc #8
    jsr Bank1_HorizPosition
.Continue

    lda #0
    sta VDELP0
    sta VDELP1
    sta NUSIZ0
    sta NUSIZ1

    sta WSYNC
    sta HMOVE                       ; 3 (3)

    sta GRP0                        ; 3 (6)
    sta GRP1                        ; 3 (9)

    ldx #DEF_BG_COLOR               ; 2 (11)
    ldy #%00110001                  ; 2 (13)
    stx COLUBK                      ; 3 (16)

    ; pf reflected; ballsize = 8
    sty CTRLPF                      ; 2 (18)
    sty COLUPF                      ; 3 (21)

    lda CasinoColor                 ; 3 (24)
    sta COLUP1                      ; 3 (27)

    sta HMCLR                       ; 3 (30)
    rts                             ; 6 (36)

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

    PAGE_BOUNDARY_CHECK "Bank1 kernels (1)"

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

Bank1_SetupWinTextGfx SUBROUTINE    ; 6 (6)
    lda #<Bank1_WinText0            ; 2 (8)
    sta SpritePtrs                  ; 3 (11)
    lda #<Bank1_WinText1            ; 2 (13)
    sta SpritePtrs+2                ; 3 (16)
    lda #<Bank1_WinText2            ; 2 (18)
    sta SpritePtrs+4                ; 3 (21)
    lda #<Bank1_WinText3            ; 2 (23)
    sta SpritePtrs+6                ; 3 (26)
    lda #<Bank1_WinText4            ; 2 (28)
    sta SpritePtrs+8                ; 3 (31)
    lda #<Bank1_WinText5            ; 2 (33)
    sta SpritePtrs+10               ; 3 (36)

    lda #>Bank1_WinText0            ; 2 (38)
    sta SpritePtrs+1                ; 3 (41)
    sta SpritePtrs+3                ; 3 (44)
    sta SpritePtrs+5                ; 3 (47)
    sta SpritePtrs+7                ; 3 (50)
    sta SpritePtrs+9                ; 3 (53)
    sta SpritePtrs+11               ; 3 (56)
    rts                             ; 6 (62)

Bank1_SetupLoseTextGfx SUBROUTINE   ; 6 (6)
    lda #<Bank1_LoseText0           ; 2 (8)
    sta SpritePtrs                  ; 3 (11)
    lda #<Bank1_LoseText1           ; 2 (13)
    sta SpritePtrs+2                ; 3 (16)
    lda #<Bank1_LoseText2           ; 2 (18)
    sta SpritePtrs+4                ; 3 (21)
    lda #<Bank1_LoseText3           ; 2 (23)
    sta SpritePtrs+6                ; 3 (26)
    lda #<Bank1_LoseText4           ; 2 (28)
    sta SpritePtrs+8                ; 3 (31)
    lda #<Bank1_LoseText5           ; 2 (33)
    sta SpritePtrs+10               ; 3 (36)

    lda #>Bank1_LoseText0           ; 2 (38)
    sta SpritePtrs+1                ; 3 (41)
    sta SpritePtrs+3                ; 3 (44)
    sta SpritePtrs+5                ; 3 (47)
    sta SpritePtrs+7                ; 3 (50)
    sta SpritePtrs+9                ; 3 (53)
    sta SpritePtrs+11               ; 3 (56)
    rts                             ; 6 (62)

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

Bank1_SetupForeground SUBROUTINE
    ; Foreground ---------------------------------
    ; row 1 (96->64)
    lda #ROW1                   ; pass Y ending coordinate
    pha

    ; detect if the ship is overlapping the row
    lda #ROW1_MASK
    bit ShipBitmap
    beq .NoShip
    lda #>[Bank1_GroundKernelSprite-1]
    pha
    lda #<[Bank1_GroundKernelSprite-1]
    pha
    jmp .Continue
.NoShip
    lda #>[Bank1_GroundKernel-1]
    pha
    lda #<[Bank1_GroundKernel-1]
    pha
.Continue

    lda #LOSE_KERNEL_FLAG | SHIP_DEPARTED_FLAG
    bit SceneState
    bne .Msg

    lda #<[IntroKernels+3]
    sta ReturnAddr
    lda #>[IntroKernels+3]
    sta ReturnAddr+1
    jmp (ReturnAddr)

.Msg
    lda #<[MsgKernels+3]
    sta ReturnAddr
    lda #>[MsgKernels+3]
    sta ReturnAddr+1
    jmp (ReturnAddr)

Bank1_SetupGround SUBROUTINE
    ; row 2 (128->96)
    lda #ROW2                   ; pass Y ending coordinate
    pha

    ; Ground ------------------------------------
    ; determine if ship has stopped moving
    lda Direction
    bne .ShipKernel
    lda #>[Bank1_GroundKernelCasino-1]
    pha
    lda #<[Bank1_GroundKernelCasino-1]
    pha
    jmp .Return

.ShipKernel
    ; detect if the ship is overlapping the row
    lda #ROW2_MASK
    bit ShipBitmap
    beq .NoShip
    lda #>[Bank1_GroundKernelSprite-1]
    pha
    lda #<[Bank1_GroundKernelSprite-1]
    pha
    jmp .Return

.NoShip
    lda #>[Bank1_GroundKernel-1]
    pha
    lda #<[Bank1_GroundKernel-1]
    pha

.Return
    lda #LOSE_KERNEL_FLAG | SHIP_DEPARTED_FLAG
    bit SceneState
    bne .Msg

    lda #<[IntroKernels+6]
    sta ReturnAddr
    lda #>[IntroKernels+6]
    sta ReturnAddr+1
    jmp (ReturnAddr)

.Msg
    lda #<[MsgKernels+6]
    sta ReturnAddr
    lda #>[MsgKernels+6]
    sta ReturnAddr+1
    jmp (ReturnAddr)

Bank1_SetupHorizon SUBROUTINE
    ; Horizon ------------------------------------
    ; row 3 (160->128)
    ; detect if the ship is overlapping the row
    lda #ROW3_MASK
    bit ShipBitmap
    beq .NoShip
    lda #>[Bank1_HorizonKernelSprite-1]
    pha
    lda #<[Bank1_HorizonKernelSprite-1]
    pha
    jmp .Continue
.NoShip
    lda #>[Bank1_HorizonKernel-1]
    pha
    lda #<[Bank1_HorizonKernel-1]
    pha
.Continue

    lda #LOSE_KERNEL_FLAG | SHIP_DEPARTED_FLAG
    bit SceneState
    bne .Msg

    lda #<[IntroKernels+9]
    sta ReturnAddr
    lda #>[IntroKernels+9]
    sta ReturnAddr+1
    jmp (ReturnAddr)

.Msg
    lda #<[MsgKernels+6]
    sta ReturnAddr
    lda #>[MsgKernels+6]
    sta ReturnAddr+1
    jmp (ReturnAddr)

Bank1_SetupMsg SUBROUTINE
    ; Message ------------------------------------
    lda #>[Bank1_MsgKernel-1]
    pha
    lda #<[Bank1_MsgKernel-1]
    pha

    lda #<[MsgKernels+6]
    sta ReturnAddr
    lda #>[MsgKernels+6]
    sta ReturnAddr+1
    jmp (ReturnAddr)

Bank1_SetupSky SUBROUTINE
    ; Sky ----------------------------------------
    ; row 4 (192->160)
    ; detect if the ship is overlapping the row
    lda #ROW4_MASK
    bit ShipBitmap
    beq .NoShip
    lda #>[Bank1_SkyKernelSprite-1]
    pha
    lda #<[Bank1_SkyKernelSprite-1]
    pha
    jmp .Continue
.NoShip
    lda #>[Bank1_SkyKernel-1]
    pha
    lda #<[Bank1_SkyKernel-1]
    pha
.Continue
    jmp Bank1_ReturnAddr

Bank1_FlamesLo
    dc.b <Bank1_FlamesGfx0, <Bank1_FlamesGfx1, <Bank1_FlamesGfx2, <Bank1_FlamesGfx3
Bank1_FlamesHi
    dc.b >Bank1_FlamesGfx0, >Bank1_FlamesGfx1, >Bank1_FlamesGfx2, >Bank1_FlamesGfx3

Bank1_MotionJitterY
    dc.b -2, -1, -1,  2, -1,  1, -2, -1
    dc.b -1, -2,  1, -2,  2, -1, -2, -1

    INCLUDE_POWER_TABLE 1, 2, 8

    PAGE_BOUNDARY_SET
Bank1_MsgKernel SUBROUTINE          ; 56 (56)
    ; expects to consume row 2 and row 3 (128->96) (160->128)
    ldy #SPRITE_GRAPHICS_IDX        ; 2 (2)
    jsr Bank1_SetSpriteOptions
    jsr Bank1_PositionSprites

    lda #COLOR_BLACK                ; 2 (2)
    sta COLUBK                      ; 3 (5)

    lda #COLOR_WHITE                ; 2 (2)
    ldx #0                          ; 2 (4)
    ldy #3                          ; 2 (6)     3 copies close
    sta WSYNC

    sta COLUBK                      ; 3 (3)
    stx COLUPF                      ; 3 (6)
    stx REFP0                       ; 3 (9)
    stx REFP1                       ; 3 (12)
    sty VDELP0                      ; 3 (15)
    sty VDELP1                      ; 3 (18)
    sty NUSIZ0                      ; 3 (21)
    sty NUSIZ1                      ; 3 (24)

    lda #COLOR_DGRAY                ; 2 (26)
    sta WSYNC
    sta COLUBK                      ; 3 (3)

    lda MsgTextColor                ; 3 (6)
    sta COLUP0                      ; 3 (9)
    sta COLUP1                      ; 3 (12)

    sta WSYNC

    ldy #Bank1_WinText_Height-1
    DRAW_48_SPRITE SpritePtrs

    sta WSYNC
    sta WSYNC

    lda #COLOR_WHITE                ; 2 (58)
    ldx #0                          ; 2 (2)
    sta WSYNC
    sta COLUBK                      ; 3 (3)
    stx GRP0                        ; 3 (5)
    stx GRP1                        ; 3 (8)
    stx NUSIZ0                      ; 3 (31)
    stx NUSIZ1                      ; 3 (31)
    stx VDELP0                      ; 3 (3)
    stx VDELP1                      ; 3 (3)

    lda #COLOR_BLACK                ; 2 (2)
    sta WSYNC
    sta COLUBK                      ; 3 (3)

    ldx #ROW4-ROW_HEIGHT            ; 2 (7)
.Kernel
    lda Bank1_BGPalette,x           ; 4 (42)
    sta WSYNC                       ; 3 (45)

    sta COLUBK                      ; 3 (3)
    lda Bank1_FGPalette,x           ; 4 (7)
    sta COLUPF                      ; 3 (10)

    lda Bank1_Playfield,x           ; 4 (14)
    sta PF0                         ; 3 (17)
    sta PF1                         ; 3 (20)
    sta PF2                         ; 3 (23)

    dex                             ; 2 (33)
    cpx #ROW2+1                     ; 2 (35)
    bcs .Kernel                     ; 3 (38)

    rts                             ; 6 (43)

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
    jmp Bank1_CutSceneReturn        ; 3 (24)

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
    beq .Read
    dex
    stx InputTimer
    jmp .Return
.Read
    jsr Bank1_ReadJoystick

.Return
    TIMER_WAIT
    rts

Bank1_ScrollScreen SUBROUTINE
    lda #SCROLL_UPDATE_FREQ
    bit FrameCtr
    bne .Return

    ; do nothing when Direction == 0
    lda Direction
    beq .Return
    bmi .Down

    ; up
    lda ScreenTopY
    cmp #SCR_BEG_TOP
    beq .Return

    inc ScreenTopY
    inc ScreenBotY
    jmp .Return

    ; down
.Down
    lda ScreenTopY
    cmp #SCR_END_TOP
    beq .Return

    dec ScreenTopY
    dec ScreenBotY

.Return
    rts

Bank1_UpdateMsgText SUBROUTINE
    ; update wintext color cycle
    lda FrameCtr
    and #MSGTEXT_UPDATE_FREQ
    bne .Return

    lda #LOSE_KERNEL_FLAG
    bit SceneState
    beq .CheckDeparted

    jsr Bank1_SetupLoseTextGfx
    jmp .UpdateColor
    
.CheckDeparted
    lda #SHIP_DEPARTED_FLAG
    bit SceneState
    beq .Return

    jsr Bank1_SetupWinTextGfx

.UpdateColor
    ldx MsgTextColor
    cpx #MSGTXT_END_COLOR
    bcs .Return

    inx
    stx MsgTextColor

.Return
    rts

; * detect overlap for casino kernel and flames
; * move ship
; * move p1 object when it's rendering flames
; * position objects
Bank1_UpdateCasino SUBROUTINE
    ; update casino color cycle
    lda FrameCtr
    and #CASINO_UPDATE_FREQ
    bne .Return

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
    and ShipUpdateFreq
    beq .Continue1
    rts
    
.Continue1
    lda #SHIP_DEPARTED_FLAG
    bit SceneState
    beq .Continue2
    rts

.Continue2
    ; check if ship is at rest
    lda Direction
    bne .Move
    rts

.Move
    bpl .MoveUp
    jsr Bank1_MoveDown
    jmp .Update
.MoveUp
    jsr Bank1_MoveUp

.Update
    lda #SHIP_DEPARTED_FLAG
    bit SceneState
    beq .Map
    lda #0
    sta ShipBitmap
    rts

.Map
    ; update bitmap with bottom position
    lda ShipY
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

Bank1_MoveDown SUBROUTINE
    ; move the ship left until the stopping point
    lda ShipX
    cmp #SHIP_END_X
    bcs .MoveDown
    lda #0
    sta Direction
    rts

.MoveDown
    ; move the ship down
    dec ShipX

    ; apply motion jitter in Y direction
    lda FrameCtr
    and #%00011110
    lsr
    tax
    ;clc        ; carry is already 0
    lda ShipY
    adc Bank1_MotionJitterY,x
    sta ShipY
    rts

Bank1_MoveUp SUBROUTINE
    ; move ship up
    ldy ShipY
    cpy #SHIP_WIN_END_Y
    bcs .AtRest
    inc ShipY

    cpy #SHIP_ZOOM_Y
    bcc .Return

    ; move ship right
    ldy ShipX
    cpy #SHIP_WIN_END_X
    bcs .AtRest
    inc ShipX

    lda #SHIP_ZOOMING
    bit SceneState
    bne .Return

    ora SceneState
    sta SceneState

    lda #FAST_UPDATE_FREQ
    sta ShipUpdateFreq

    lda #SOUND_ID_FLYING
    sta Arg1
    sta Arg2
    jsr SoundPlay2

.Return
    rts

.AtRest
    lda #SHIP_DEPARTED_FLAG
    ora SceneState
    sta SceneState
    lda #0
    sta Direction
    rts

Bank1_SetupShipGfx SUBROUTINE
    ; normal width
    ldx #0
    stx NUSIZ1
    
    lda Direction
    beq .Animate
    bpl .Return

.Animate
    ; animate flames
    lda FrameCtr
    and #FLAMES_UPDATE_FREQ
    lsr
    lsr
    lsr
    tay
    lda Bank1_FlamesLo,y
    sta FlamesGfx
    lda Bank1_FlamesHi,y
    sta FlamesGfx+1

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
    and #JOY_FIRE           ; check for 0
    bne .Return

    jsr SoundClear

    ; reset stack
    pla
    pla
    pla
    pla

    lda GameState
    cmp #GS_LOSE_KERNEL
    beq .GotoTitle
    JUMP_BANK Bank2_Init

.Return
    rts

.GotoTitle
    lda #GS_NONE
    sta GameState
    JUMP_BANK Bank0_ResetLostGame

    ; -------------------------------------------------------------------------
    include "../atarilib/lib/sound.asm"
    include "sys/bank1_audio.asm"

; -----------------------------------------------------------------------------
; Desc:     Sets the sprite pointers to the same sprite character given by the
;           16 bit address.
; Inputs:   Y register
; (SPRITE_GRAPHICS_IDX, SPRITE_CARDS_IDX, SPRITE_BET_IDX, SPRITE_STATUS_IDX)
; Ouputs:
; -----------------------------------------------------------------------------
Bank1_SetSpriteOptions SUBROUTINE
    lda Bank1_SpriteSize,y
    sta NUSIZ0
    sta NUSIZ1
    lda Bank1_SpriteDelay,y
    sta VDELP0
    sta VDELP1
    rts

    INCLUDE_SPRITE_OPTIONS 1
    include "bank1/gen/lose-text.sp"

    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $a00, FILLER_CHAR
    RORG BANK1_RORG + $a00

    include "bank1/gen/win-text.sp"
    INCLUDE_SPRITE_POSITIONING 1

    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $b00, FILLER_CHAR
    RORG BANK1_RORG + $b00

    include "bank1/gfx/flames.asm"

    ; -------------------------------------------------------------------------
    ORG BANK1_ORG + $c00, FILLER_CHAR
    RORG BANK1_RORG + $c00

    include "bank1/gfx/foreground.asm"
    include "bank1/gfx/exhaust.asm"

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
