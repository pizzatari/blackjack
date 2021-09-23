#if VIDEO_MODE == VIDEO_NTSC
; Background is 2 pixel resolution for some of the kernels:
;    Bank1_HorizonKernelSprite
;    Bank1_GroundKernelSprite
; 1 pixel resolution for the remaining kernels.
Bank1_BGPalette
    ; row 0 ground 
    dc.b $c8, $c8, $c8, $c8, $c8, $c8, $c8, $c8
    dc.b $c8, $c8, $c8, $c8, $c8, $c8, $c8, $c8
    dc.b $c8, $c8, $c8, $c8, $c6, $c6, $c8, $c8
    dc.b $c6, $c6, $c8, $c8, $c6, $c6, $c8, $c8

    ; row 1 ground
    dc.b $c6, $c6, $c8, $c8, $c6, $c6, $c6, $c6
    dc.b $c6, $c6, $c6, $c6, $c6, $c6, $c6, $c6
    dc.b $c6, $c6, $c6, $c6, $c4, $c4, $c6, $c6
    dc.b $c4, $c4, $c6, $c6, $c4, $c4, $c6, $c6

    ; row 2 ground
    dc.b $c4, $c4, $c6, $c6, $c4, $c4, $c4, $c4
    dc.b $c4, $c4, $c4, $c4, $c4, $c4, $c4, $c4
    dc.b $c4, $c4, $c4, $c4, $c2, $c2, $c4, $c4
    dc.b $c2, $c2, $c4, $c4, $c2, $c2, $c4, $c4

    ; row 3 ground
    dc.b $c2, $c2, $c4, $c4, $c2, $c2, $c2, $c2
    dc.b $c2, $c2, $c2, $c2, $c2, $c2, $c2, $c2
    dc.b $c2, $c2, $c2, $c2, $c0, $c0, $c2, $c2
    dc.b $c0, $c0, $c2, $c2, $c0, $c0, $c2, $c2

    ; row 4 horizon & hills
	dc.b $c0, $c0, $c0, $c0, $c0, $c0, $c0, $c0
    dc.b $c0, $c0, $c0, $c0, $c0, $c0, $00, $00
    dc.b $ca, $ca, $ca, $ca, $ca, $ca, $ca, $ca
    dc.b $ca, $ca, $ca, $ca, $ca, $ca, $ca, $ca

    ; row 5 sky
    dc.b $c8, $ca, $c8, $c8, $c8, $c8, $c8, $c8
    dc.b $c8, $c8, $c8, $c8, $c8, $c8, $c8, $c8
    dc.b $c8, $c8, $c8, $c8, $c8, $c8, $c8, $c8
    dc.b $c8, $c8, $c8, $c8, $c8, $c8, $c6, $c8

    ; row 6 sky
    dc.b $c6, $c8, $c6, $c6, $c6, $c6, $c6, $c6
    dc.b $c6, $c6, $c6, $c6, $c6, $c6, $c6, $c6
    dc.b $c6, $c6, $c6, $c6, $c6, $c6, $c6, $c6
    dc.b $c6, $c6, $c6, $c6, $c6, $c6, $c4, $c6

    ; row 7 sky
    dc.b $c4, $c6, $c4, $c6, $c4, $c4, $c4, $c4
    dc.b $c4, $c4, $c4, $c4, $c4, $c4, $c4, $c4
    dc.b $c4, $c4, $c4, $c4, $c4, $c4, $c4, $c4
    dc.b $c4, $c4, $c4, $c4, $c4, $c4, $c4, $c4

#endif ; if VIDEO_MODE == VIDEO_NTSC

#if VIDEO_MODE == VIDEO_PAL
#endif
