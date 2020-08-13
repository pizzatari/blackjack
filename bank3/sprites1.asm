RANK_HEIGHT = 8
SUIT_HEIGHT = 8

Bank3_BlankSprite
BlankCard
    ds.b 9, 0
Bank3_Digit0
	dc.b %00000000
	dc.b %00001110
	dc.b %00001010
	dc.b %00001010
	dc.b %00001010
	dc.b %00001110
Bank3_Digit1
	dc.b %00000000
	dc.b %00000100
	dc.b %00000100
	dc.b %00000100
	dc.b %00000100
	dc.b %00000100
Bank3_Digit2
	dc.b %00000000
	dc.b %00001110
	dc.b %00001000
	dc.b %00001110
	dc.b %00000010
	dc.b %00001110
Bank3_Digit3
	dc.b %00000000
	dc.b %00001110
	dc.b %00000010
	dc.b %00000110
	dc.b %00000010
	dc.b %00001110
Bank3_Digit4
	dc.b %00000000
	dc.b %00000010
	dc.b %00000010
	dc.b %00001110
	dc.b %00001010
	dc.b %00001010
Bank3_Digit5
	dc.b %00000000
	dc.b %00001110
	dc.b %00000010
	dc.b %00001110
	dc.b %00001000
	dc.b %00001110
Bank3_Digit6
	dc.b %00000000
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
	dc.b %00001000
	dc.b %00001110
Bank3_Digit7
	dc.b %00000000
	dc.b %00000010
	dc.b %00000010
	dc.b %00000010
	dc.b %00000010
	dc.b %00001110
Bank3_Digit8
	dc.b %00000000
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
Bank3_Digit9
	dc.b %00000000
	dc.b %00000010
	dc.b %00000010
	dc.b %00001110
	dc.b %00001010
	dc.b %00001110
    dc.b 0
Bank3_Ranks
Bank3_Rank0
	dc.b %11111111
	dc.b %11111111
	dc.b %10001111
	dc.b %10101111
	dc.b %10101111
	dc.b %10101111
	dc.b %10001111
Bank3_Rank1
	dc.b %11111111
	dc.b %11111111
	dc.b %11011111
	dc.b %11011111
	dc.b %11011111
	dc.b %11011111
	dc.b %11011111
Bank3_Rank2
	dc.b %11111111
	dc.b %11111111
	dc.b %10001111
	dc.b %10111111
	dc.b %10001111
	dc.b %11101111
	dc.b %10001111
Bank3_Rank3
	dc.b %11111111
	dc.b %11111111
	dc.b %10001111
	dc.b %11101111
	dc.b %11001111
	dc.b %11101111
	dc.b %10001111
Bank3_Rank4
	dc.b %11111111
	dc.b %11111111
	dc.b %11101111
	dc.b %11101111
	dc.b %10001111
	dc.b %10101111
	dc.b %10101111
Bank3_Rank5
	dc.b %11111111
	dc.b %11111111
	dc.b %10001111
	dc.b %11101111
	dc.b %10001111
	dc.b %10111111
	dc.b %10001111
Bank3_Rank6
	dc.b %11111111
	dc.b %11111111
	dc.b %10001111
	dc.b %10101111
	dc.b %10001111
	dc.b %10111111
	dc.b %10001111
Bank3_Rank7
	dc.b %11111111
	dc.b %11111111
	dc.b %11101111
	dc.b %11101111
	dc.b %11101111
	dc.b %11101111
	dc.b %10001111
Bank3_Rank8
	dc.b %11111111
	dc.b %11111111
	dc.b %10001111
	dc.b %10101111
	dc.b %10001111
	dc.b %10101111
	dc.b %10001111
Bank3_Rank9
	dc.b %11111111
	dc.b %11111111
	dc.b %11101111
	dc.b %11101111
	dc.b %10001111
	dc.b %10101111
	dc.b %10001111
	dc.b %11111111
Bank3_Rank10
    dc.b %11111111
    dc.b %11111111
    dc.b %10100011
    dc.b %10101011
    dc.b %10101011
    dc.b %10101011
    dc.b %10100011
RankSprites
AceSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %10101111
    dc.b %10101111
    dc.b %10001111
    dc.b %10101111
    dc.b %10001111
JackSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %10001111
    dc.b %10101111
    dc.b %11101111
    dc.b %11101111
    dc.b %10000111
QueenSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %10001011
    dc.b %10100111
    dc.b %10110111
    dc.b %10110111
    dc.b %10000111
KingSprite
    dc.b %11111111
    dc.b %11111111
    dc.b %10110111
    dc.b %10101111
    dc.b %10011111
    dc.b %10101111
    dc.b %10110111
SuitSprites
DiamondSprite
    dc.b %11111111
    dc.b %11110111
    dc.b %11100011
    dc.b %11000001
    dc.b %10000000
    dc.b %11000001
    dc.b %11100011
    dc.b %11110111
ClubSprite
    dc.b %11111111
    dc.b %11100011
    dc.b %11110111
    dc.b %10010100
    dc.b %10000000
    dc.b %10000000
    dc.b %11100011
    dc.b %11100011
HeartSprite
    dc.b %11111111
    dc.b %11110111
    dc.b %11100011
    dc.b %11000001
    dc.b %10000000
    dc.b %10000000
    dc.b %10000000
    dc.b %11001001
SpadeSprite
    dc.b %11111111
    dc.b %11100011
    dc.b %11110111
    dc.b %11000001
    dc.b %10000000
    dc.b %11000001
    dc.b %11100011
    dc.b %11110111
BackCard
SuitBack
Bank3_FlipSuit0
    dc.b %11111111
    dc.b %01010101
Bank3_FlipRank0
RankBack
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %01010101
    dc.b %10101010
    dc.b %11111111
Bank3_FlipSuit1
    dc.b %00000000
    dc.b %00001100
    dc.b %00110100
    dc.b %01010100
Bank3_FlipRank1
    dc.b %01101100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
    dc.b %01101100
    dc.b %01010100
    dc.b %00110100
    dc.b %00001100
Bank3_FlipSuit2
    dc.b %00000000
Bank3_FlipRank2
    dc.b %00010000
    dc.b %00010000
    dc.b %00010000
    dc.b %00010000
    dc.b %00010000
    dc.b %00010000
    dc.b %00010000
    dc.b %00010000
Bank3_FlipSuit3
    dc.b %00000000
    dc.b %00110000
    dc.b %00111100
    dc.b %00110110
    dc.b %00100010
    dc.b %00100010
    dc.b %00100010
    dc.b %00110110
Bank3_FlipRank3
    dc.b %00111110
    dc.b %00111110
    dc.b %00100110
    dc.b %00101110
    dc.b %00100110
    dc.b %00101110
    dc.b %00111100
    dc.b %00110000

