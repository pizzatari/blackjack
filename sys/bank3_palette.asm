#if VIDEO_MODE == VIDEO_NTSC

DEF_BG_COLOR                = COLOR_BLACK
BG_COLOR                    = COLOR_GREEN
PF_COLOR                    = COLOR_DGREEN
CHIP_COLOR                  = COLOR_YELLOW
CHIP_MENU_COLOR             = $0e
CARD_COLOR                  = COLOR_WHITE
CARD_INACTIVE_COLOR         = COLOR_LGRAY

Bank3_MessagePalette
    dc.b $3e, $3c, $ee, $ee, $ee, $ec, $ea
    dc.b $2e, $3e, $3c, $3a, $fe, $ee, $1e, $de
;Bank3_CardPalette
;    dc.b $00, $06, $08, $08, $0a, $0a, $0c, $0c
;    dc.b $0e, $0e, $0a, $0a, $08, $08, $06, $06
Bank3_ChipPalette
    dc.b $fe, $fc, $1c, $1c, $1c, $1c, $1c, $1e, $fe, $ee
;Bank3_TextPalette
;    dc.b $3e, $3c, $ee, $ee, $ee, $ec, $ea
;    dc.b $2e, $3e, $3c, $3a, $fe, $ee, $1e, $de
Bank3_MsgPalette
    ; background, foreground
    dc.b COLOR_DRED, COLOR_YELLOW
    dc.b COLOR_GRAY, COLOR_WHITE

    ; diamonds, clubs hearts, spades
    ;dc.b $42, $00, $42, $00
#endif

#if VIDEO_MODE == VIDEO_PAL
#endif
