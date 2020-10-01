; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     July 2018
; Version:  0.92 (beta)
; Game:     Black Jack Theta VIII for the Atari 2600
;
; 4 banks (4 KB each):
;   Bank 0:     title vertical blank & overscan
;              *title kernel & data
;              *betting kernel & data
;   Bank 1:     sound routines & data
;               intermission vertical blank & overscan
;              *intermission kernel & data
;   Bank 2:     game vertical blank & overscan
;               game logic & data
;   Bank 3:    *game kernel & data
;
; Each bank has duplicated sections:
;   $*000:      reset handler
;   $*ff6:      bankswitching hot spots
;   $*ffa:      interrupt handlers
;
; Betting screen sections:
;   --------------------------------------
;   | Top section:       Message bar     |
;   |                    Dashboard       |
;   |                    (blank)         |
;   | Bet section:       Betting bar     |
;   |                    (blank)         |
;   | Chip section:      Chip menu bar   |
;   | Bot section:       Status bar      |
;   --------------------------------------
;
; Game screen sections:
;   --------------------------------------
;   | Top section:       Message bar     |
;   |                    Dashboard       |
;   | Dealer row:        Cards           |
;   | Pot row:           Chips           |
;   | Player split hand: Cards           |
;   | Player main hand:  Cards           |
;   | Chip section:      Chip menu bar   |
;   | Bot section:       Status bar      |
;   --------------------------------------
;
; -----------------------------------------------------------------------------
    processor 6502

VIDEO_MODE                  = VIDEO_NTSC
NO_ILLEGAL_OPCODES          = 1
POSITION_OBJECT_VERS        = 1
BANKSWITCH_VERS             = 1

PIP_COLORS                  = 0

; TEST_RAND_ON:
;   0 = off
;   1 = non-random numbers
;   2 = random cards
TEST_RAND_ON                = 0
TEST_TIME_ON                = 0
TEST_TIMING_ON              = 0
TEST_STACK_DEBUG            = 0

FILLER_CHAR                 = $4f ; $ea
BALLAST_ON                  = 0

    IFCONST AFP_TARGET
        IF AFP_TARGET != 0
BALLAST_ON                  = 1
        ELSE
BALLAST_ON                  = 0
        ENDIF
    ENDIF

    LIST OFF
    include "include/debug.h"
    include "include/defines.h"
    include "include/draw.h"
    include "include/macro.h"
    include "include/position.h"
    include "include/screen.h"
    include "include/time.h"
    include "include/util.h"
    include "include/vcs.h"
    include "sys/colors.h"
    include "lib/macros.asm"
    include "lib/bankswitch.asm"
    include "lib/bankprocs.asm"
    include "lib/horizpos.asm"
    LIST ON

; -----------------------------------------------------------------------------
; Constants
; -----------------------------------------------------------------------------
; F6 bank switching (16KB)
BANK0_ORG                   = $1000
BANK0_RORG                  = $9000

BANK1_ORG                   = $2000
BANK1_RORG                  = $b000

BANK2_ORG                   = $3000
BANK2_RORG                  = $d000

BANK3_ORG                   = $4000
BANK3_RORG                  = $f000

BANK0_HOTSPOT               = $fff6
BANK1_HOTSPOT               = BANK0_HOTSPOT+1
BANK2_HOTSPOT               = BANK0_HOTSPOT+2
BANK3_HOTSPOT               = BANK0_HOTSPOT+3

; offscreen timings
TIME_VBLANK                 = 37*76/64  ; TIM64T (43.9375)
TIME_VBLANK_TITLE           = 37*76/64  ; TIM64T (43.9375)
TIME_VBLANK_GAME            = 30*76/64  ; TIM64T (35.625) -7 for kernel setup
TIME_OVERSCAN               = 31*76/64  ; TIM64T (35.625)

TIME_MSG_BAR                = 5*76/8    ; TIM8T (47.5)
TIME_DISPLAY_OPT            = 4*76/8    ; TIM8T (38)
TIME_DASH_SETUP             = 2*76/8    ; TIM8T (19)
TIME_DASH_DRAW              = 8*76/8    ; TIM8T (76)
TIME_CHIPS_POT              = 3*76/8    ; TIM8T (28.5)
TIME_CARD_SETUP             = 72        ; TIM8T
TIME_CARD_HOLE_SETUP        = 2*76/8    ; TIM8T (19)
TIME_CARD_FLIP_SETUP        = 3*76/8    ; TIM8T (19)
TIME_CHIP_MENU_SETUP        = 2*76/8    ; TIM8T (19)
TIME_CHIP_DENOM             = 6*76/8    ; TIM8T (57)
TIME_STATUS_BAR             = 4*76/8    ; TIM8T (38)

NUSIZE_3_MEDIUM             = %00000110
NUSIZE_3_CLOSE              = %00000011

; Dimensions
SPRITE_WIDTH                = 8

; Game sections
MSG_ROW_HEIGHT              = 23
DLR_ROW_HEIGHT              = 50


; Objects
MESSAGE_TEXT_HEIGHT         = 7
STATUS_TEXT_HEIGHT          = 6
DASHOPTS_HEIGHT             = 6
CARDS_HEIGHT                = 10
CHIPS_HEIGHT                = 10
TIMES_HEIGHT                = 4
DENOMS_HEIGHT               = 6
POPUP_HEIGHT                = 14

; Title screen sprite height
TITLE_LOGO_HEIGHT           = 42
TITLE_EDITION_HEIGHT        = 12; 7
TITLE_CARDS_HEIGHT          = 15
TITLE_MENU_HEIGHT           = 12
TITLE_COPY_HEIGHT           = 10; 7
TITLE_NAME_HEIGHT           = 8; 5

; Playfield and sprite options
MSG_BAR_IDX                 = 0
POPUP_BAR_IDX               = 1
COLOR_TABLE_IDX             = 2
COLOR_CARDS_IDX             = 3
COLOR_CHIPS_IDX             = 4
OPT_BAR_IDX                 = 5

; SpriteSize, SpriteDelay, SpritePositions*, SpriteAdjust*
SPRITE_GRAPHICS_IDX         = 0
SPRITE_CARDS_IDX            = 1
SPRITE_BET_IDX              = 2
SPRITE_STATUS_IDX           = 3
SPRITE_HELP_IDX             = 4

; Score limits (BCD)
BUST_SCORE                  = $22
BLACKJACK_SCORE             = $21
STAND_SCORE                 = $17

NUM_DECKS                   = 4
NUM_CARDS                   = NUM_DECKS * 52
NUM_DISCARD_BYTES           = NUM_CARDS / 8
NUM_VISIBLE_CARDS           = 6
NUM_SPRITES                 = NUM_VISIBLE_CARDS

DEAL_PENETRATION            = NUM_DECKS * 52 / 4 * 3

; Sprite indexes
CHIPS_IDX                   = 0
DENOMS_IDX                  = 1

; Betting chips selector
DENOM_START_SELECTION       = 2

; Dashboard selector
DASH_HIT_IDX                = 0
DASH_STAY_IDX               = 1
DASH_DOUBLEDOWN_IDX         = 2
DASH_SURRENDER_IDX          = 3
DASH_INSURANCE_IDX          = 4
DASH_SPLIT_IDX              = 5
DASH_MAX                    = DASH_SPLIT_IDX
DASH_START_SELECTION        = DASH_HIT_IDX

NUM_PLAYERS                 = 2
NUM_HANDS                   = 3
NUM_CHIP_BYTES              = 3
NUM_BET_BYTES               = 2

; Player hand selector
PLAYER1_IDX                 = 0         ; player's 1st hand
PLAYER2_IDX                 = 1         ; player's second split hand
DEALER_IDX                  = 2

PLAYER1_CARDS_OFFSET        = NUM_VISIBLE_CARDS * PLAYER1_IDX
PLAYER2_CARDS_OFFSET        = NUM_VISIBLE_CARDS * PLAYER2_IDX
DEALER_CARDS_OFFSET         = NUM_VISIBLE_CARDS * DEALER_IDX
PLAYER1_CHIPS_OFFSET        = NUM_CHIP_BYTES * PLAYER1_IDX

NEW_PLAYER_CHIPS            = $1000     ; BCD value

; -----------------------------------------------------------------------------
; Macros
; -----------------------------------------------------------------------------
    MAC DIVIDER_LINE
.COLOR  SET {1}
        ; draw divider line
        lda #.COLOR
        sta COLUBK
        sta WSYNC
    ENDM

    MAC CLEAR_GRAPHICS
        sta WSYNC
        lda #0
        sta GRP0
        sta GRP1
    ENDM

; -----------------------------------------------------------------------------
; Returns the current dashboard menu selection.
; Inputs:
; Outputs:      A register (menu selection)
; -----------------------------------------------------------------------------
    MAC GET_DASH_MENU
        lda CurrState
        and #CURR_DASH_MENU_MASK
        lsr
        lsr
        lsr
    ENDM

; -----------------------------------------------------------------------------
; Sets the current dashboard menu selection.
; Inputs:       Y register (menu selection)
; Outputs:
; -----------------------------------------------------------------------------
    MAC SET_DASH_MENU
        lda CurrState
        and #~CURR_DASH_MENU_MASK
        sta CurrState
        tya
        asl
        asl
        asl
        ora CurrState
        sta CurrState
    ENDM

#if 0
; -----------------------------------------------------------------------------
; Returns the current bet menu selection.
; Inputs:
; Outputs:      A register (menu selection)
; -----------------------------------------------------------------------------
    MAC GET_BET_MENU
        lda CurrState
        and #~CURR_BET_MENU_MASK
    ENDM

; -----------------------------------------------------------------------------
; Sets the current dashboard menu selection.
; Inputs:       Y register (menu selection)
; Outputs:
; -----------------------------------------------------------------------------
    MAC SET_BET_MENU
        lda CurrState
        and #~CURR_BET_MENU_MASK
        sta CurrState
        tya
        ora CurrState
        sta CurrState
    ENDM

; -----------------------------------------------------------------------------
; Returns the current player.
; Inputs:
; Outputs:      A register (current player)
; -----------------------------------------------------------------------------
    MAC GET_CURR_PLAYER
        lda CurrState
        and #CURR_PLAYER_MASK
    ENDM

; -----------------------------------------------------------------------------
; Sets the current player.
; Inputs:       X register (current player)
; Outputs:      
; -----------------------------------------------------------------------------
    MAC SET_CURR_PLAYER
        lda #~CURR_PLAYER_MASK
        and CurrState
        sta CurrState
        txa
        ora CurrState
        sta CurrState
    ENDM

; -----------------------------------------------------------------------------
; Decrements the current player.
; Inputs:
; Outputs       A register (current player):      
; -----------------------------------------------------------------------------
    MAC DEC_CURR_PLAYER
        lda CurrState
        and #CURR_PLAYER_MASK
        beq .Zero
        lda CurrState
        sec
        sbc #1
        sta CurrState
        and #CURR_PLAYER_MASK
.Zero
    ENDM
#endif

; Variables
; -----------------------------------------------------------------------------
    SEG.U ram
    ORG $80

; Variables global to the all banks
GlobalVars

; Game state selects which handler is executed on the current frame.
GS_TITLE_SCREEN             = 0
GS_NEW_GAME                 = 1
GS_PLAYER_BET               = 2
GS_PLAYER_BET_DOWN          = 3
GS_PLAYER_BET_UP            = 4
GS_OPEN_DEAL1               = 5
GS_OPEN_DEAL2               = 6
GS_OPEN_DEAL3               = 7
GS_OPEN_DEAL4               = 8
GS_OPEN_DEAL5               = 9
GS_DEALER_SET_FLAGS         = 10
GS_PLAYER_SET_FLAGS         = 11
GS_PLAYER_TURN              = 12
GS_PLAYER_STAY              = 13
GS_PLAYER_PRE_HIT           = 14
GS_PLAYER_HIT               = 15
GS_PLAYER_POST_HIT          = 16
GS_PLAYER_SURRENDER         = 17
GS_PLAYER_DOUBLEDOWN        = 18
GS_PLAYER_SPLIT             = 19
GS_PLAYER_SPLIT_DEAL        = 20
GS_PLAYER_INSURANCE         = 21
GS_PLAYER_BLACKJACK         = 22
GS_PLAYER_WIN               = 23
GS_PLAYER_PUSH              = 24
GS_PLAYER_HAND_OVER         = 25
GS_DEALER_TURN              = 26    ; ----
GS_DEALER_PRE_HIT           = 27    ; Dealer game states must be ordered
GS_DEALER_HIT               = 28    ; after player game states.
GS_DEALER_POST_HIT          = 29    ;
GS_DEALER_HAND_OVER         = 30    ; ----
GS_GAME_OVER                = 31
GS_INTERMISSION             = 32
GS_MAX                      = GS_INTERMISSION
GS_START_STATE              = GS_TITLE_SCREEN
GameState                   ds.b 1

; GameStateFlags
GS_SHOW_BETTING_FLAG        = %10000000
GS_SHOW_DASHBOARD_FLAG      = %01000000
GS_SHOW_HOLE_CARD_FLAG      = %00100000
GS_SHOW_DEALER_SCORE_FLAG   = %00010000
GS_FLICKER_FLAG             = %00001000
GS_PROMPT_IDX_MASK          = %00000111

; Task work is a request to interrupt the game to perform ancillary side work
; such as shuffling the deck or entering an animation loop.
TSK_NONE                    = 0
TSK_DEAL_CARD               = 1
TSK_FLIP_CARD               = 2
TSK_SHUFFLE                 = 3
TSK_DEALER_DISCARD          = 4
TSK_PLAYER1_DISCARD         = 5
TSK_PLAYER2_DISCARD         = 6
TSK_BLACKJACK               = 7
TSK_POPUP_OPEN              = 8
TSK_MAX                     = TSK_POPUP_OPEN
TaskQueue                   ds.b 2
TaskArg                     ds.b 2

;ARG_CARD_FLIP_DURATION      = 30
ARG_POPUP_OPEN              = POPUP_HEIGHT

; Current bet amount: BCD (big endian): [MSB, LSB]
CurrBet                     ds.w 1
; Currently selected player
CurrPlayer                  ds.b 1

; Bitmap various state values
; Bit 7:    show hole card face up or down (1 = face down, 0 = face up)
; Bit 6:    unused
; Bit 3-5:  currently selected dashboard menu item
; Bit 0-2:  currently selected betting menu item
CURR_HOLE_CARD_MASK         = %10000000
CURR_DASH_MENU_MASK         = %00111000
CURR_BET_MENU_MASK          = %00000111
CurrState                   ds.b 1

; GameOpts bit flags (options can only be changed on the betting screen)
; Bit 7:    hit/stand on soft 17:   left difficulty (1 = hit)
; Bit 6:    early/late surrender:   right difficulty (1 = late surrender)
; Bit 2-5:  unused
; Bit 0-1:  number of decks - 1:    incremented by game select button
FLAGS_HIT_SOFT17            = #%10000000
FLAGS_LATE_SURRENDER        = #%01000000
NUM_DECKS_MASK              = #%00000011
GameOpts                    ds.b 1

; Stores a bitmap of all the cards. Discarded cards are flagged as a 1 bit.
DiscardPile                 ds.b NUM_DISCARD_BYTES
DealDepth                   ds.b 1

; 3 BCD bytes per player (big endian)
PlayerChips                 ds.b NUM_CHIP_BYTES;  NUM_PLAYERS*NUM_CHIP_BYTES

; Some ephemeral variables
FrameCtr                    ds.b 1
RandNum                     ds.b 1
RandAlt                     ds.b 1

; Previous values of of SWCHA and INPT4
JoySWCHA                    ds.b 1
JoySWCHB                    ds.b 1
; TODO: store bit 7 of JoyINPT4 in JoySWCHB to save a byte
JoyINPT4                    ds.b 1

; Sound effect ID for the sound effect queue
SOUND_ID_NONE               = 0
SOUND_ID_ERROR              = 1
SOUND_ID_NAVIGATE           = 2
SOUND_ID_CARD_FLIP          = 3
SOUND_ID_CHIPS              = 4
SOUND_ID_HIT                = 5
SOUND_ID_STAND              = 6
SOUND_ID_DOUBLEDOWN         = 7
SOUND_ID_SURRENDER          = 8
SOUND_ID_INSURANCE          = 9
SOUND_ID_SPLIT              = 10
SOUND_ID_HAND_OVER          = 11
SOUND_ID_SHUFFLE0           = 12
SOUND_ID_SHUFFLE1           = 13
SOUND_ID_NO_CHIPS           = 14
SOUND_ID_PUSH               = 15
SOUND_ID_WIN0               = 16
SOUND_ID_WIN1               = 17
SOUND_ID_LOST               = 18
SOUND_ID_CRASH_LANDING      = 19
;SOUND_ID_BANK_BROKE        = 20

; Sound effect queue:
; Byte 0:       channel 0
; Byte 1:       channel 1
SOUND_QUEUE_LEN             = 2
SoundQueue                  ds.b SOUND_QUEUE_LEN

SOUND_CURR_NOTE_MASK        = %11110000
SOUND_LOOPS_MASK            = %00001111
SoundCtrl                   ds.b SOUND_QUEUE_LEN

;
; Sprite animation queue
;
ANIM_QUEUE_LEN              = 2
AnimID                      ds.b ANIM_QUEUE_LEN ; (animation id)
AnimPosition                ds.b ANIM_QUEUE_LEN ; (row, column)
AnimConfig                  ds.b ANIM_QUEUE_LEN ; (loops, frames)

ANIM_ID_NONE                = 0
ANIM_ID_FLIP_CARD           = 1
ANIM_ID_FLIP_SUIT           = 2

ANIM_ROW_MASK               = %11111000
ANIM_COL_MASK               = %00000111
ANIM_LOOP_MASK              = %11100000
ANIM_FRAME_MASK             = %00011111

#if 0
; Sprite animation queue
;
; The sprites that can be animated are identified by a grid of
; NUM_SPRITES x N sprites. Specific sprites are identified by column and row
; pairs. Currently, the grid is 6x7, but expandable up to 6x15.
;
; The animation queue is a list of sprites that are currently being animated.
; Each queue element is a column and row pair identifying which sprite is being
; currently animated. Currently 2 sprites can be simultaneously animated.
;
; Byte 0:               column and row
; Byte 1:               column and row
; Column and row bits:
;   Column:             7 6 5 4   
;   Row:                3 2 1 0
;
; Sprite animation queue
;
ANIM_ID_NONE                = -1
ANIM_ID_CHIP_STACK          = 0
ANIM_ID_CHIP_SHINE          = 1
ANIM_ID_FLIP_CARD           = 2
ANIM_ID_FLIP_SUIT           = 3
ANIM_QUEUE_LEN              = 2
AnimID                      ds.b ANIM_QUEUE_LEN ; animation id
AnimColumn                  ds.b ANIM_QUEUE_LEN ; position on screen
AnimRow                     ds.b ANIM_QUEUE_LEN ; position on screen
AnimCurrFrame               ds.b ANIM_QUEUE_LEN ; current frame
;AnimDuration                ds.b ANIM_QUEUE_LEN ; duration of a frame
;AnimLoops                   ds.b ANIM_QUEUE_LEN ; number of loops
#endif

; -----------------------------------------------------------------------------
; Variables within this block are reset to zero upon starting a new game.
MemBlockStart

; 1 = release event; 0 = no event
; Bit 7:    right
; Bit 6:    left
; Bit 5:    down
; Bit 4:    up
; Bit 3:    fire
; Bit 2:    (unused)
; Bit 1:    select
; Bit 0:    (unused)
JoyRelease                  ds.b 1

; GameFlags bit flags
; Bit 7:    split taken
; Bit 5-6:  unused
; Bit 4:    hit allowed
; Bit 3:    double down allowed
; Bit 2:    surrender allowed
; Bit 1:    insurance allowed
; Bit 0:    split allowed
FLAGS_NONE                  = 0
FLAGS_SPLIT_TAKEN           = #%10000000
FLAGS_HIT_ALLOWED           = #%00010000
FLAGS_DOUBLEDOWN_ALLOWED    = #%00001000
FLAGS_SURRENDER_ALLOWED     = #%00000100
FLAGS_INSURANCE_ALLOWED     = #%00000010
FLAGS_SPLIT_ALLOWED         = #%00000001
FLAGS_ALLOWED_MASK          = #%00011111
GameFlags                   ds.b 1

; PlayerFlags bit flags
; Bit 7:    double down taken
; Bit 6:    insurance taken
; Bit 5:    has blackjack    ---.
; Bit 4:    has winning hand    | Indicate the player's hand is over.
; Bit 3:    has 21              | 21 and blackjack are tenative since
; Bit 2:    has pushed          | the dealer may push upon completing
; Bit 1:    has busted          | its turn. The rest are settled results.
; Bit 0:    has lost         ---'
FLAGS_DOUBLEDOWN_TAKEN      = %10000000    ; not used for dealer
FLAGS_INSURANCE_TAKEN       = %01000000    ; not used for dealer
FLAGS_BLACKJACK             = %00100000
FLAGS_WIN                   = %00010000    ; not used for dealer
FLAGS_PUSH                  = %00001000
FLAGS_21                    = %00000100
FLAGS_BUST                  = %00000010    ; not used for dealer
FLAGS_LOST                  = %00000001    ; not used for dealer
FLAGS_HANDOVER              = %00111111
PlayerFlags                 ds.b NUM_HANDS

CARD_NULL                   = 0
CARD_RANK_ACE               = 1
CARD_RANK_MAX               = 13
CARD_DECK_MASK              = %11000000
CARD_SUIT_MASK              = %00110000
CARD_RANK_MASK              = %00001111
CARD_DECK_ROW               = %10000000
PlayerCards                 ds.b NUM_VISIBLE_CARDS*NUM_HANDS
PlayerNumCards              ds.b NUM_HANDS
PlayerScore                 ds.b NUM_HANDS      ; total score
PlayerPileScore             ds.b NUM_HANDS      ; score of off screen cards

; Rendering variables
SpritePtrs                  ds.w NUM_VISIBLE_CARDS

; Variables local to the current bank
LocalVars                   dc.b 7

MemBlockEnd

; Temporary variables and arguments
TempPtr                     SET LocalVars
Arg1                        SET LocalVars+2
Arg2                        SET LocalVars+3
Arg3                        SET LocalVars+4
Arg4                        SET LocalVars+5
Arg5                        SET LocalVars+6

; For scaline debugging
ScanDebug SET PlayerCards+#5

    RAM_BYTES_USAGE

    SEG rom

    include "bank0/bank0.asm"
    include "bank1/bank1.asm"
    include "bank2/bank2.asm"
    include "bank3/bank3.asm"

    ;echo "ROM has", (ROM_BYTES_REMAINING)d, "bytes remaining"
