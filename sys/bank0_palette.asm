#if VIDEO_MODE == VIDEO_NTSC
    PAGE_BOUNDARY_SET

Bank0_MessagePalette
    dc.b $3e, $3c, $ee, $ee, $ee, $ec, $ea
    dc.b $2e, $3e, $3c, $3a, $fe, $ee, $1e, $de
Bank0_CardPalette
    dc.b $00, $06, $08, $08, $0a, $0a, $0c, $0c
    dc.b $0e, $0e, $0a, $0a, $08, $08, $06, $06
Bank0_EditionPalette
    dc.b $00, $90, $92, $94, $96, $98, $98, $98
    dc.b $fe, $fe, $98, $98, $98, $96, $94, $92, $90
Bank0_MenuPalette
    dc.b $00, $06, $08, $0a, $0c, $0e, $44, $06, $06, $06, $06, $06, $06
Bank0_CopyPalette
    dc.b $00, $90, $90, $90, $92, $92, $92, $94
    dc.b $94, $94, $96, $96, $96, $98, $98, $98
    dc.b $fe, $fe, $98, $98, $98, $96, $96, $96
    dc.b $94, $94, $94, $92, $92, $92, $90, $90, $90

    PAGE_BOUNDARY_CHECK "(1) Sprite data"
#endif

#if VIDEO_MODE == VIDEO_PAL
#endif
