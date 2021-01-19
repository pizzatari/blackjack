#if VIDEO_MODE == VIDEO_NTSC

BG_COLOR                    = COLOR_GREEN
PF_COLOR                    = COLOR_DGREEN
CHIP_COLOR                  = COLOR_YELLOW
CARD_COLOR                  = COLOR_WHITE
CARD_INACTIVE_COLOR         = COLOR_LGRAY

Bank3_MessagePalette
    dc.b $3e, $3c, $ee, $ee, $ee, $ec, $ea
    dc.b $2e, $3e, $3c, $3a, $fe, $ee, $1e, $de

Bank3_TextPalette
    dc.b $3e, $3c, $ee, $ee, $ee, $ec, $ea
    dc.b $2e, $3e, $3c, $3a, $fe, $ee, $1e, $de

Bank3_MsgPalette
    ; background, foreground
    dc.b COLOR_DRED, COLOR_YELLOW
    dc.b COLOR_GRAY, COLOR_WHITE

Bank3_CardPalette
    ; diamonds, clubs hearts, spades
    dc.b $42, $00, $42, $00
#endif

#if VIDEO_MODE == VIDEO_PAL
#endif
