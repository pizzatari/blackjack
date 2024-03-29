; -----------------------------------------------------------------------------
; Author:   Edward Gilmour
; Date:     July 2018
; Version:  0.95 (beta)
; Game:     Black Jack Theta VIII for the Atari 2600
;
; 4 banks (4 KB each):
;   Bank 0:     title vertical blank & overscan
;              *title kernel & data
;              *betting kernel & data
;   Bank 1:     sound driver & data
;               cutscene vertical blank & overscan
;              *cutscene kernel & data
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
; Landing & take off screen sections:
;   --------------------------------------
;   | Atmsophere                         |
;   | Background Hills                   |
;   |                                    |
;   |                                    |
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

    include "sys/video.h"
    include "atarilib.h"
    include "include/defines.h"
    include "include/menu.h"
    include "include/screen.h"

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

PIP_COLORS                  = 0

NEW_PLAYER_CHIPS            = $1000     ; BCD value

; TEST_RAND_ON:
;   0 = off
;   1 = non-random numbers
;   2 = non-random cards
TEST_RAND_ON                = 0
; TEST_ENABLE_SPLIT: split is always enabled
;   0 = off
;   1 = on
TEST_ENABLE_SPLIT           = 0

FILLER_CHAR                 = $4f; $00

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
TIME_CARD_SETUP             = 8*76/8    ; TIM8T 
TIME_CARD_HOLE_SETUP        = 2*76/8    ; TIM8T (19)
TIME_CARD_FLIP_SETUP        = 3*76/8    ; TIM8T (19)
TIME_CHIP_MENU_SETUP        = 3*76/8    ; TIM8T (19)
TIME_CHIP_DENOM             = 6*76/8    ; TIM8T (57)
TIME_STATUS_BAR             = 4*76/8    ; TIM8T (38)

INPUT_DELAY                 = 30
INPUT_DELAY_TITLE           = 20
INPUT_DELAY_BETTING         = 10
INPUT_DELAY_WIN             = 255
INPUT_DELAY_LOSE            = 255
INPUT_DELAY_FREQ            = %00010000

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
TITLE_CARDS_HEIGHT          = 16
TITLE_EDITION_HEIGHT        = 8
TITLE_MENU_HEIGHT           = 13
TITLE_COPY_HEIGHT           = 16

; Playfield and sprite options
MSG_BAR_IDX                 = 0
POPUP_BAR_IDX               = 1
COLOR_TABLE_IDX             = 2
COLOR_CARDS_IDX             = 3
COLOR_CHIPS_IDX             = 4
OPT_BAR_IDX                 = 5

; Sprite indexes: Playfield and sprite options
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

; Player hand selector
PLAYER1_IDX                 = 0         ; player's 1st hand
PLAYER2_IDX                 = 1         ; player's second split hand
DEALER_IDX                  = 2

PLAYER1_CARDS_OFFSET        = NUM_VISIBLE_CARDS * PLAYER1_IDX
PLAYER2_CARDS_OFFSET        = NUM_VISIBLE_CARDS * PLAYER2_IDX
DEALER_CARDS_OFFSET         = NUM_VISIBLE_CARDS * DEALER_IDX

; Variables
; -----------------------------------------------------------------------------
    SEG.U ram
    ORG $80

; Index into Bank*_KernelTable
KN_TITLE                    = 0
KN_BETTING                  = 1
KN_INTRO                    = 2
KN_LOSE                     = 3
KN_WIN                      = 4
KN_PLAY                     = 5
      
; Variables global to the all banks
GlobalVars

; Game state selects which handler is executed on the current frame.
GS_NONE                     = 0
GS_NEW_GAME                 = 1     ;-----
GS_PLAYER_BET               = 2     ; Betting kernel states
GS_PLAYER_BET_DOWN          = 3     ;
GS_PLAYER_BET_UP            = 4     ;-----

GS_OPEN_DEAL1               = 5     ; Play kernel states
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
GS_DEALER_TURN              = 26    ;-----
GS_DEALER_PRE_HIT           = 27    ; Dealer game states must be sorted and
GS_DEALER_HIT               = 28    ; positioned after player game states.
GS_DEALER_POST_HIT          = 29    ;
GS_DEALER_HAND_OVER         = 30    ;-----

GS_GAME_OVER                = 31    ;-----
GS_GAME_OVER_WAIT           = 32    ; Game over states
GS_BROKE_PLAYER             = 33    ;
GS_BROKE_BANK               = 34    ;
GS_LOSE_KERNEL              = 35    ;
GS_WIN_KERNEL               = 36    ;-----

GS_MAX                      = GS_WIN_KERNEL
GS_START_STATE              = GS_NONE
GameState                   ds.b 1

; Game states equal to or below will execute the betting kernel. The play
; kernel executes for the remaining.
BETTING_KERNEL_GS           = GS_PLAYER_BET_UP

; Game state flags affect how some graphic elements are displayed.
GS_SHOW_DASHBOARD_FLAG      = %10000000 ;
GS_SHOW_DEALER_SCORE_FLAG   = %01000000 ;
GS_PROMPT_IDX_MASK          = %00000111 ;
; Bank3_GameStateFlags

; Ephemeral values
FrameCtr                    ds.b 1
RandNum                     ds.b 1
RandAlt                     ds.b 1
InputTimer                  ds.b 1

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
; Bits 0-3: scan code (0=none, 1-12=key)
KeyPress                    ds.b 1

; Previous values of of SWCHA and INPT4
JoySWCHA                    ds.b 1
JoySWCHB                    ds.b 1
JoyINPT4                    ds.b 1

JOY_REL_FIRE                = %00001000

; Sound effect queue:
; Byte 0:       channel 0
; Byte 1:       channel 1
SOUND_QUEUE_LEN             = 2
SoundQueue                  ds.b SOUND_QUEUE_LEN
SoundCtrl                   ds.b SOUND_QUEUE_LEN

;
; Variables shared between multiple banks
; -----------------------------------------------------------------------------
BankVars

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
CurrBet                     ds.b 3
; Currently selected player
CurrPlayer                  ds.b 1

; GameOpts bit flags (options can only be changed on the betting screen)
; Bit 7:    hit/stand on soft 17:   left difficulty (1 = hit)
; Bit 6:    early/late surrender:   right difficulty (1 = late surrender)
; Bit 2-5:  unused
; Bit 0-1:  number of decks - 1:    incremented by game select button
FLAGS_HIT_SOFT17            = #%10000000
FLAGS_LATE_SURRENDER        = #%01000000
NUM_DECKS_MASK              = #%00000011
GameOpts                    ds.b 1

; 3 BCD bytes per player (big endian)
PlayerChips                 ds.b 3

; Bitmap various state values
; Bit 7:    show hole card face up or down (1 = face down, 0 = face up)
; Bit 6:    unused
; Bit 3-5:  currently selected dashboard menu item
; Bit 0-2:  currently selected betting menu item
CURR_HOLE_CARD_MASK         = %10000000
CURR_DASH_MENU_MASK         = %00111000
CURR_BET_MENU_MASK          = %00000111
CurrState                   ds.b 1

; Stores a bitmap of all the cards. Discarded cards are flagged as a 1 bit.
DiscardPile                 ds.b NUM_DISCARD_BYTES
DealDepth                   ds.b 1

SpritePtrs                  ds.w NUM_VISIBLE_CARDS

; -----------------------------------------------------------------------------
; Variables within this block are reset to zero upon starting a new game.
MemBlockStart

; Variables local the current bank or subroutine
; -----------------------------------------------------------------------------
LocalVars

#if 1
FLIP_PLAYER_MASK            = %11000000
FLIP_CARD_MASK              = %00111000
FLIP_FRAME_MASK             = %00000111
; Flip card animation state
FLIP_FREQ                   = %00000111
FLIP_NUM_FRAMES             = 4
FLIP_END                    = 0

FlipFrame                   ds.b 1

#else
; Animation state
;
; The animation driver idenfies animation objects as a grid of col x row
; sprites. Currently the grid is 6x7, but expandable up to 6x15.
;
; The animation queue is a list of currently animating sprites. Currently
; only 2 sprites can be simultaneously animated.
;
ANIM_ROW_MASK               = %11111000
ANIM_COL_MASK               = %00000111
ANIM_LOOP_MASK              = %11100000
ANIM_FRAME_MASK             = %00011111

ANIM_QUEUE_LEN              = 2
AnimID                      ds.b ANIM_QUEUE_LEN ; (animation id)
AnimPosition                ds.b ANIM_QUEUE_LEN ; (row, column)
AnimConfig                  ds.b ANIM_QUEUE_LEN ; (loops, frames)

ANIM_ID_NONE                = 0
ANIM_ID_FLIP_CARD           = 1
ANIM_ID_FLIP_SUIT           = 2
;ANIM_ID_CHIP_STACK         = 3
;ANIM_ID_CHIP_SHINE         = 4
#endif

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
FLAGS_BROKE_BANK            = %10000000    ; valid only for the dealer
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

TempPtr                     ds.w 1
TempPtr2                    ds.w 1

TempInt                     = TempPtr
Arg1                        = TempPtr2
Arg2                        = TempPtr2+1

; Variables local to a subroutine
; -----------------------------------------------------------------------------
TempVars
MemBlockEnd
BankVarsEnd

    RAM_BYTES_USAGE

; For scaline debugging
ScanDebug                   SET PlayerCards+#5

    SEG rom
PAGE_CURR_BANK SET 0
    include "bank0/bank0.asm"

PAGE_CURR_BANK SET 1
    include "bank1/bank1.asm"

PAGE_CURR_BANK SET 2
    include "bank2/bank2.asm"

PAGE_CURR_BANK SET 3
    include "bank3/bank3.asm"

    IFCONST TEST_RAND_ON
        IF TEST_RAND_ON > 0
            ECHO ""
            ECHO "** Test cards enabled (", (TEST_RAND_ON)d, ") **"
        ENDIF
    ENDIF

    IFCONST TEST_ENABLE_SPLIT
        IF TEST_ENABLE_SPLIT > 0
            ECHO "** Test split enabled (", (TEST_ENABLE_SPLIT)d, ") **"
        ENDIF
    ENDIF

