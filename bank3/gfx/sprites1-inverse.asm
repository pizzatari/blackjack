RANK_HEIGHT = 8
SUIT_HEIGHT = 8

; bank3/bank3.asm relies on all of these being in the same page.

Bank3_BlankSprite
    dc.b %00000000
    dc.b %00000000
BlankCard
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
    dc.b %00000000
Bank3_Digits
Bank3_Digit0
	dc.b %00000000
	dc.b %00000000
	dc.b %01110000
	dc.b %01010000
	dc.b %01010000
	dc.b %01010000
	dc.b %01110000
Bank3_Digit1
	dc.b %00000000
	dc.b %00000000
	dc.b %00100000
	dc.b %00100000
	dc.b %00100000
	dc.b %00100000
	dc.b %00100000
Bank3_Digit2
	dc.b %00000000
	dc.b %00000000
	dc.b %01110000
	dc.b %01000000
	dc.b %01110000
	dc.b %00010000
	dc.b %01110000
Bank3_Digit3
	dc.b %00000000
	dc.b %00000000
	dc.b %01110000
	dc.b %00010000
	dc.b %00110000
	dc.b %00010000
	dc.b %01110000
Bank3_Digit4
	dc.b %00000000
	dc.b %00000000
	dc.b %00010000
	dc.b %00010000
	dc.b %01110000
	dc.b %01010000
	dc.b %01010000
Bank3_Digit5
	dc.b %00000000
	dc.b %00000000
	dc.b %01110000
	dc.b %00010000
	dc.b %01110000
	dc.b %01000000
	dc.b %01110000
Bank3_Digit6
	dc.b %00000000
	dc.b %00000000
	dc.b %01110000
	dc.b %01010000
	dc.b %01110000
	dc.b %01000000
	dc.b %01110000
Bank3_Digit7
	dc.b %00000000
	dc.b %00000000
	dc.b %00010000
	dc.b %00010000
	dc.b %00010000
	dc.b %00010000
	dc.b %01110000
Bank3_Digit8
	dc.b %00000000
	dc.b %00000000
	dc.b %01110000
	dc.b %01010000
	dc.b %01110000
	dc.b %01010000
	dc.b %01110000
Bank3_Digit9
	dc.b %00000000
	dc.b %00000000
	dc.b %00010000
	dc.b %00010000
	dc.b %01110000
	dc.b %01010000
	dc.b %01110000
	dc.b %00000000
Bank3_Digit10
    dc.b %00000000
    dc.b %00000000
    dc.b %01011100
    dc.b %01010100
    dc.b %01010100
    dc.b %01010100
    dc.b %01011100
RankSprites
AceSprite
    dc.b %00000000
    dc.b %00000000
    dc.b %01010000
    dc.b %01010000
    dc.b %01110000
    dc.b %01010000
    dc.b %01110000
JackSprite
    dc.b %00000000
    dc.b %00000000
    dc.b %01110000
    dc.b %01010000
    dc.b %00010000
    dc.b %00010000
    dc.b %01111000
QueenSprite
    dc.b %00000000
    dc.b %00000000
    dc.b %01110100
    dc.b %01011000
    dc.b %01001000
    dc.b %01001000
    dc.b %01111000
KingSprite
    dc.b %00000000
    dc.b %00000000
    dc.b %01001000
    dc.b %01010000
    dc.b %01100000
    dc.b %01010000
    dc.b %01001000
    dc.b %00000000
SuitSprites
DiamondSprite
    dc.b %00000000
    dc.b %00001000
    dc.b %00011100
    dc.b %00111110
    dc.b %01111111
    dc.b %00111110
    dc.b %00011100
    dc.b %00001000
ClubSprite
    dc.b %00000000
    dc.b %00011100
    dc.b %00001000
    dc.b %01101011
    dc.b %01111111
    dc.b %01111111
    dc.b %00011100
    dc.b %00011100
HeartSprite
    dc.b %00000000
    dc.b %00001000
    dc.b %00011100
    dc.b %00111110
    dc.b %01111111
    dc.b %01111111
    dc.b %01111111
    dc.b %00110110
SpadeSprite
    dc.b %00000000
    dc.b %00011100
    dc.b %00001000
    dc.b %00111110
    dc.b %01111111
    dc.b %00111110
    dc.b %00011100
    dc.b %00001000
SolidCard
	dc.b %11111111
	dc.b %11111111
	dc.b %11111111
	dc.b %11111111
	dc.b %11111111
	dc.b %11111111
	dc.b %11111111
	dc.b %11111111
	dc.b %11111111
RankBack
    dc.b %11111111
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    ;dc.b %00000000
SuitBack
    dc.b %00000000
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %11111111
BackCard
FlipSuit0
FlipRank0
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
FlipSuit1
    dc.b %11111111
    dc.b %11110011
    dc.b %11001011
    dc.b %10101011
    dc.b %10010011
    dc.b %10101011
    dc.b %10010011
    dc.b %10101011
FlipRank1
    dc.b %10010011
    dc.b %10101011
    dc.b %10010011
    dc.b %10101011
    dc.b %10010011
    dc.b %10101011
    dc.b %11001011
    dc.b %11110011
FlipSuit2
    dc.b %11111111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
FlipRank2
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
    dc.b %11101111
FlipSuit3
    dc.b %11111111
    dc.b %11001111
    dc.b %11000011
    dc.b %11000001
    dc.b %11001001
    dc.b %11011101
    dc.b %11011101
    dc.b %11011101
    dc.b %11001001
    dc.b %11000001
    dc.b %11000001
    dc.b %11000001
FlipRank3
    dc.b %11000001
    dc.b %11000001
    dc.b %11011001
    dc.b %11010001
    dc.b %11011001
    dc.b %11010001
    dc.b %11000011
    dc.b %11001111
;FlipSprite0
;    dc.b %01101100
;    dc.b %01010100
;    dc.b %01101100
;    dc.b %01010100
;    dc.b %01101100
;    dc.b %01010100
;    dc.b %00110100
;    dc.b %00001100
;FlipSprite1
;    dc.b %00000000
;    dc.b %00001100
;    dc.b %00110100
;    dc.b %01010100
;    dc.b %01101100
;    dc.b %01010100
;    dc.b %01101100
;    dc.b %01010100
;    dc.b %01101100
;    dc.b %01010100
;    dc.b %01101100
;    dc.b %01010100
;FlipSprite2 SET FlipSprite1
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

Bank3_Gap
    dc.b %11111110
    dc.b %11100101
    dc.b %00000000
    dc.b %10100111
    dc.b %01111111
