#if VIDEO_MODE == VIDEO_NTSC
Bank1_FGPalette
    ; row 0 ground
	dc.b $ca, $ca, $da, $00, $ca, $ca, $ca, $ca
    dc.b $da, $0a, $ca, $ca, $00, $da, $ca, $00
	dc.b $ca, $ca, $ca, $ca, $ca, $da, $00, $ca
    dc.b $da, $0a, $ca, $ca, $00, $da, $ca, $00

    ; row 1 ground
	dc.b $c8, $c8, $c8, $c8, $c8, $d8, $00, $c8
    dc.b $d8, $08, $c8, $c8, $00, $d8, $c8, $00
	dc.b $d8, $00, $c8, $c8, $c8, $c8, $c8, $c8
    dc.b $d8, $08, $c8, $c8, $00, $d8, $c8, $00

    ; row 2 ground
	dc.b $c6, $c6, $c6, $d6, $00, $c6, $c6, $c6
    dc.b $d6, $06, $c6, $c6, $00, $d6, $c6, $00
	dc.b $c6, $d6, $00, $c6, $c6, $c6, $c6, $c6
    dc.b $d6, $06, $c6, $c6, $00, $d6, $c6, $00

    ; row 3 ground
	dc.b $c4, $c4, $c4, $c4, $c4, $d4, $00, $c4
    dc.b $00, $d4, $c4, $00, $d4, $04, $c4, $c4
	dc.b $c4, $c4, $c4, $c4, $c4, $d4, $00, $c4
    dc.b $d4, $04, $c4, $c4, $00, $d4, $c4, $00

    ; row 4 horizon & hills
	dc.b $c2, $c2, $c4, $00, $c2, $d2, $00, $c2
    dc.b $d2, $04, $c2, $00, $c0, $00, $c0, $00
	dc.b $02, $04, $c8, $c6, $c8, $c6, $c6, $c4
    dc.b $c6, $c4, $c4, $c2, $c4, $c2, $c4, $c2

#if 0
Bank1_CasinoPal
    dc.b $00, $1a, $1a, $18, $14, $1a, $18, $18
	dc.b $14, $1a, $18, $14, $1a, $18, $14, $1a
    dc.b $18, $14, $1a, $1a, $04, $18, $18, $06
#endif
#endif

#if VIDEO_MODE == VIDEO_PAL
#endif
