#if VIDEO_MODE == VIDEO_NTSC
Bank1_AtmosPalette
    dc.b $cc, $ca, $c8, $c6, $c4, $c2, $c0, $c0
Bank1_ForegroundPalette
    dc.b $16, $16, $e8, $e8, $f4, $f4, $14, $14
    dc.b $e8, $e8, $d4, $d4, $14, $14, $f4, $f4
Bank1_ShipPalette
    dc.b $1a, $2a, $3a, $4a, $0e, $08, $04, $00
Bank1_CasinoPalette
   dc.b $00, $00, $00, $00, $00, $14, $16, $16
   dc.b $18, $18, $1a, $1a, $1c, $1c, $1e, $1e
CASINO_NUM_COLORS = . - Bank1_CasinoPalette
#endif

#if VIDEO_MODE == VIDEO_PAL
#endif
