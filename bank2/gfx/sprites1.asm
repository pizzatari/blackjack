RANK_HEIGHT SET 8
SUIT_HEIGHT SET 12
BlankCard
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
RankSprites
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
AceSprite
    dc.b %11111111
    dc.b %10101111
    dc.b %10101111
    dc.b %10001111
    dc.b %10101111
    dc.b %10001111
    dc.b %11111111
TwoSprite
    dc.b %11111111
    dc.b %10001111
    dc.b %10111111
    dc.b %10001111
    dc.b %11101111
    dc.b %10001111
    dc.b %11111111
ThreeSprite
    dc.b %11111111
    dc.b %10001111
    dc.b %11101111
    dc.b %11001111
    dc.b %11101111
    dc.b %10001111
    dc.b %11111111
FourSprite
    dc.b %11111111
    dc.b %11101111
    dc.b %11101111
    dc.b %10001111
    dc.b %10101111
    dc.b %10101111
    dc.b %11111111
FiveSprite
    dc.b %11111111
    dc.b %10001111
    dc.b %11101111
    dc.b %10001111
    dc.b %10111111
    dc.b %10001111
    dc.b %11111111
SixSprite
    dc.b %11111111
    dc.b %10001111
    dc.b %10101111
    dc.b %10001111
    dc.b %10111111
    dc.b %10001111
    dc.b %11111111
SevenSprite
    dc.b %11111111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %10001111
    dc.b %11111111
EightSprite
    dc.b %11111111
    dc.b %10001111
    dc.b %10101111
    dc.b %10001111
    dc.b %10101111
    dc.b %10001111
    dc.b %11111111
NineSprite
    dc.b %11111111
    dc.b %10001111
    dc.b %11101111
    dc.b %10001111
    dc.b %10101111
    dc.b %10001111
    dc.b %11111111
TenSprite
    dc.b %11111111
    dc.b %10100011
    dc.b %10101011
    dc.b %10101011
    dc.b %10101011
    dc.b %10100011
    dc.b %11111111
JackSprite
    dc.b %11111111
    dc.b %10001111
    dc.b %10101111
    dc.b %11101111
    dc.b %11101111
    dc.b %10000111
    dc.b %11111111
QueenSprite
    dc.b %11111111
    dc.b %10001011
    dc.b %10100111
    dc.b %10110111
    dc.b %10110111
    dc.b %10000111
    dc.b %11111111
KingSprite
    dc.b %11111111
    dc.b %10110111
    dc.b %10101111
    dc.b %10011111
    dc.b %10101111
    dc.b %10110111
    dc.b %11111111
AceSprite14
    dc.b %11111111
    dc.b %10110111
    dc.b %10110111
    dc.b %10000111
    dc.b %10110111
    dc.b %10000111
SuitSprites
DiamondSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %11110111
    dc.b %11100011
    dc.b %11000001
    dc.b %10000000
    dc.b %11000001
    dc.b %11100011
    dc.b %11110111
    dc.b %11111111
    dc.b %11111111
ClubSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %11100011
    dc.b %11110111
    dc.b %10010100
    dc.b %10000000
    dc.b %10000000
    dc.b %11100011
    dc.b %11100011
    dc.b %11111111
    dc.b %11111111
HeartSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %11110111
    dc.b %11100011
    dc.b %11000001
    dc.b %10000000
    dc.b %10000000
    dc.b %10000000
    dc.b %11001001
    dc.b %11111111
    dc.b %11111111
SpadeSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %11000011
    dc.b %11100111
    dc.b %10000001
    dc.b %00000000
    dc.b %10000001
    dc.b %11000011
    dc.b %11100111
    dc.b %11111111
    dc.b %11111111
    dc.b %11111111
; Miscellaneous Sprites
BackCard
SuitBack
    dc.b %01010101
    dc.b %10101010
RankBack
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010

;#if 0
FlipSprite0
    dc.b %01101100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
    dc.b %00110100
    dc.b %00001100
FlipSprite1
FlipSprite2 SET FlipSprite1
    dc.b %00000000
    dc.b %00001100
    dc.b %00110100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
;FlipSprite1
;    dc.b %00000000
;    dc.b %00010000
;    dc.b %00010000
;    dc.b %00010000
;    dc.b %00010000
;    dc.b %00010000
;    dc.b %00010000
;    dc.b %00010000
;    dc.b %00010000
;    dc.b %00010000
;FlipSprite2
;    dc.b %00000000
;    dc.b %00110000
;    dc.b %00111100
;    dc.b %00111110
;    dc.b %00111110
;    dc.b %00111110
;    dc.b %00111110
;    dc.b %00111110
;    dc.b %00111100
;    dc.b %00110000
;#endif
Digit0
	dc.b %00000000
	dc.b %00001110
	dc.b %00001010
	dc.b %00001010
	dc.b %00001010
	dc.b %00001110
Digit1
	dc.b %00000000
	dc.b %00000100
	dc.b %00000100
	dc.b %00000100
	dc.b %00000100
	dc.b %00000100
Digit2
	dc.b %00000000
	dc.b %00001110
	dc.b %00001000
	dc.b %00001110
	dc.b %00000010
	dc.b %00001110
Digit3
	dc.b %00000000
	dc.b %00001110
	dc.b %00000010
	dc.b %00000110
	dc.b %00000010
	dc.b %00001110
Digit4
	dc.b %00000000
	dc.b %00000010
	dc.b %00000010
	dc.b %00001110
	dc.b %00001010
	dc.b %00001010
Digit5
	dc.b %00000000
	dc.b %00001110
	dc.b %00000010
	dc.b %00001110
	dc.b %00001000
	dc.b %00001110
Digit6
	dc.b %00000000
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
	dc.b %00001000
	dc.b %00001110
Digit7
	dc.b %00000000
	dc.b %00000010
	dc.b %00000010
	dc.b %00000010
	dc.b %00000010
	dc.b %00001110
Digit8
	dc.b %00000000
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
Digit9
	dc.b %00000000
	dc.b %00000010
	dc.b %00000010
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
    dc.b 0              ; a zero is needed to terminate the sprite
;#if 0
;SolidSprite
;	dc.b %11111111
;	dc.b %11111111
;	dc.b %11111111
;	dc.b %11111111
;	dc.b %11111111
;	dc.b %11111111
;	dc.b %11111111
;	dc.b %11111111
;#endif
;
;#if 0
;CursorUp
;    dc.b #%00000000
;    dc.b #%00000000
;    dc.b #%00000000
;    dc.b #%00010000
;    dc.b #%00111000
;    dc.b #%01111100
;CursorDown
;    dc.b #%00000000
;    dc.b #%00000000
;    dc.b #%00000000
;    dc.b #%01111100
;    dc.b #%00111000
;    dc.b #%00010000
;CursorLeft
;    dc.b %00000001
;    dc.b %00000011
;    dc.b %00000111
;    dc.b %00000111
;    dc.b %00000011
;    dc.b %00000001
;CursorRight
;    dc.b %10000000
;    dc.b %11000000
;    dc.b %11100000
;    dc.b %11100000
;    dc.b %11000000
;    dc.b %10000000
;#endif
