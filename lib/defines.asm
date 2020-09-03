VIDEO_NTSC                  = 1
VIDEO_PAL                   = 2
VIDEO_PAL60                 = 3
VIDEO_SECAM                 = 4
VIDEO_MODE                  = VIDEO_NTSC

#if VIDEO_MODE == VIDEO_NTSC
; total 262
NUM_VBLANK                  = 37        ; 40 including vsync
NUM_OVERSCAN                = 30
SCREEN_WIDTH                = 160
SCREEN_HEIGHT               = 192
#endif

#if VIDEO_MODE == VIDEO_PAL || VIDEO_MODE == VIDEO_PAL60 || VIDEO_MODE == VIDEO_SECAM
; total 312
NUM_VBLANK                  = 45        ; 48 including vysnc
NUM_OVERSCAN                = 36
SCREEN_WIDTH                = 160
SCREEN_HEIGHT               = 228
#endif

; IO
SWITCH_DIFF1_MASK           = %10000000
SWITCH_DIFF0_MASK           = %01000000
SWITCH_BW_MASK              = %00001000
SWITCH_SELECT_MASK          = %00000010
SWITCH_RESET_MASK           = %00000001

JOY_FIRE_MASK               = %10000000

JOY0_BITS                   = %11110000
JOY1_BITS                   = %00001111

JOY0_RIGHT_MASK             = %10000000
JOY0_LEFT_MASK              = %01000000
JOY0_DOWN_MASK              = %00100000
JOY0_UP_MASK                = %00010000

JOY1_RIGHT_MASK             = %00001000
JOY1_LEFT_MASK              = %00000100
JOY1_DOWN_MASK              = %00000010
JOY1_UP_MASK                = %00000001

JOY0_FIRE_MASK              = %00000001
JOY_FIRE_PACKED_MASK        = %00001000
