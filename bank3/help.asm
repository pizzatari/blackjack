HelpBlank
    ds.b 7, 0           ; using overlap with HelpGuide1: 10, 0
HelpCancel
	dc.b %00000000
	dc.b %00000000
	dc.b %00000000
	dc.b %01000100
	dc.b %00101000
	dc.b %00010000
	dc.b %00101000
	dc.b %01000100
	dc.b %00000000
	dc.b %00000000
HelpHit
	dc.b %00101000
	dc.b %01010100
	dc.b %00101000
	dc.b %01010100
	dc.b %00101000
	dc.b %01010100
	dc.b %00101000
	dc.b %01010100
	dc.b %00101000
	dc.b %01010100
HelpDoubledown
	dc.b %01100000
	dc.b %01010000
	dc.b %01010000
	dc.b %01010110
	dc.b %01100101
	dc.b %00000101
	dc.b %00000101
	dc.b %00000110
	dc.b %00000000
	dc.b %00000000
HelpSurrender
	dc.b %00100000
	dc.b %00100000
	dc.b %00100000
	dc.b %00100000
	dc.b %00110000
	dc.b %00111000
	dc.b %00111100
	dc.b %00111000
	dc.b %00110000
	dc.b %00100000
HelpInsurance
SelectedInsurance
	dc.b %00000000
	dc.b %00010000
	dc.b %00111000
	dc.b %01010100
	dc.b %00011100
	dc.b %00111000
	dc.b %01110000
	dc.b %01010100
	dc.b %00111000
	dc.b %00010000
HelpSplit
	dc.b %00001010
	dc.b %00010101
	dc.b %00001010
	dc.b %00010101
	dc.b %00001010
	dc.b %01010100
	dc.b %00101000
	dc.b %01010100
	dc.b %00101000
	dc.b %01010100
SelectedDoubledown
	dc.b %00000000
	dc.b %01100000
	dc.b %01010000
	dc.b %01010000
	dc.b %01010110
	dc.b %01100101
	dc.b %00000101
	dc.b %00000101
	dc.b %00000110
	dc.b %00000000
HelpLeft
	dc.b %00000000
	dc.b %00000000
    dc.b %00000001
    dc.b %00000011
    dc.b %00000111
    dc.b %00000111
    dc.b %00000011
    dc.b %00000001
	dc.b %00000000
	dc.b %00000000
HelpRight
	dc.b %00000000
	dc.b %00000000
    dc.b %10000000
    dc.b %11000000
    dc.b %11100000
    dc.b %11100000
    dc.b %11000000
    dc.b %10000000
	dc.b %00000000
	dc.b %00000000
HelpDown
    dc.b %00000000
    dc.b %00010000
    dc.b %00111000
    dc.b %01111100
    dc.b %00000000
    dc.b %00000000
HelpUp
    dc.b %00000000
    dc.b %01111100
    dc.b %00111000
    dc.b %00010000
    dc.b %00000000
    dc.b %00000000
#if 0
SelectedInsurance
	dc.b #%00001000
	dc.b #%00011100
	dc.b #%00111110
	dc.b #%00101010
	dc.b #%00001110
	dc.b #%00011100
	dc.b #%00111000
	dc.b #%00101010
	dc.b #%00111110
	dc.b #%00011100
	dc.b #%00001000
#endif
