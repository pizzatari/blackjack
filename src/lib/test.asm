    IF TEST_RAND_ON == 1
    ; Spades, Hearts, Clubs, Diamonds
    ;  11      10       01       00
TestRandInts
    ; 5, A, A, 2, 3, 4, 8
    dc.b %00100110     ; deck 0, hearts
    dc.b %00000011     ; deck 0, diamonds
    dc.b %01010101     ; deck 1, clubs
    dc.b %01010011     ; deck 1, clubs
    dc.b %10100001     ; deck 2, hearts
    dc.b %11110001     ; deck 3, spades
    dc.b %11110010     ; deck 3, spades
    dc.b %10110011     ; deck 2, spades
    dc.b %10110100     ; deck 2, spades
    dc.b %11011000     ; deck 3, clubs
    dc.b %00110010     ; deck 0, spades
NUM_TEST_RAND SET * - TestRandInts
    ENDIF

    IF TEST_RAND_ON == 2
TestCards
    dc.b $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d
    dc.b $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d
    dc.b $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d
    dc.b $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d, $8d

    ; dealer blackjack
    dc.b $01, $18, $2a, $38

    ;
    dc.b $12        ; dealer
    dc.b $13        ; player
    dc.b $21        ; dealer
    dc.b $24        ; player

;    dc.b $01, $f4, $16, $12
;
;    ; A spades, 2 clubs, 10 hearts, 2 clubs, 2 clubs, 2 hearts
;    dc.b %00110001, %01010010, %11011010, %10010010, %00110010
;
;    dc.b $1c        ; dealer
;    dc.b $1c        ; player
;    dc.b $2d        ; dealer
;    dc.b $21        ; player
;
;    dc.b $12, $21
;    dc.b $3a, $47
;
;	dc.b $7a
;
;    dc.b $48
;    dc.b $58
;    dc.b $68
;    
;    ; 2 spades, 2 clubs, 2 hearts, 2 clubs, 2 clubs, 2 hearts
;    dc.b %00110010, %01010010, %11010010, %10010010, %00110010
;    ; 3 spades, 3 clubs, 3 hearts, 3 clubs, 3 clubs, 3 hearts
;    dc.b %00110011, %01010011, %11010011, %10010011, %00110011
;    ; 4 spades, 4 clubs, 4 hearts, 4 clubs, 4 clubs, 4 hearts
;    dc.b %00110100, %01010100, %11010100, %10010100, %00110100
;    ; 5 spades, 5 clubs, 5 hearts, 5 clubs, 5 clubs, 5 hearts
;    dc.b %00110101, %01010101, %11010101, %10010101, %00110101
;
;    dc.b $a8, $1a, $28, $aa
;    dc.b $01, $0a, $05, $04, $1a
;
;    ; A, 10, 10, 10, 3
;    dc.b %01110001, %1001010, %11001010, %00001010, %01000011
;
;    ; A spades, A clubs, 10 clubs, J clubs, 4 hearts, 2 hearts
;    dc.b %00110001, %01010001, %10011010, %11011011, %00110100
;    dc.b %01110010, %1000011, %11000011, %00000011, %01000011
;
;    ; BUG!! player score calculated to be 20
;    ; Dealer: $a3, $6b
;    ; Player: $02, $45, $76, $d2, $91, $d3, $c3
;    dc.b $a3, $02, $6b, $45, $76, $d2, $91, $d3, $c3
;
;    dc.b $02, $65, $42, $76, $d3, $93, $d4, $c4, $a2, $13
;
;    ; 10, 10, 10, 10, 3
;    dc.b %01111010, %1001010, %11001010, %00001010, %01000011
;
;    ; 2 spades, A clubs, 4 hearts, 10 clubs, J clubs, 2 hearts
;    dc.b %00110010, %01010001, %11011011, %10011010, %00110100
;
;    ; A clubs, 10 clubs, J clubs, A clubs
;    ;dc.b %01010001, %10011010, %11011011, %01010001,
;
;    ; A clubs, 3 hearts, 10 clubs, J clubs, A clubs
;    dc.b %01010001, %01000011, %10011010, %11011011, %01010001,

NUM_TEST_CARDS SET * - TestCards
    ENDIF

