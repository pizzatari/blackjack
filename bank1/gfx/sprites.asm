Bank1_BlankSprite
Bank1_ShipGfx
    dc.b 0
    dc.b %01111110
    dc.b %00011111
    dc.b %11111111
    dc.b %00111010
    dc.b %11110100
    dc.b %11111000
    dc.b %11000000
SHIP_HEIGHT = . - Bank1_ShipGfx

    ds.b ROW_HEIGHT, 0
    ds.b ROW_HEIGHT, 0

Bank1_CasinoGfx
    dc.b 0
    dc.b %11111111
    dc.b %10100101
    dc.b %10100101
    dc.b %10100101
    dc.b %11111111
    dc.b %11111111
    dc.b %11011011
    dc.b %11011011
    dc.b %11111111
    dc.b %11011011
    dc.b %11011011
    dc.b %11111111
    dc.b %11011011
    dc.b %11011011
    dc.b %11111111
    dc.b %11011011
    dc.b %11011011
    dc.b %11111111
    dc.b %11111111
    dc.b %00111100
    dc.b %00111100
    dc.b %00111100
    dc.b %00111100
CASINO_HEIGHT = * - Bank1_CasinoGfx

    ds.b ROW_HEIGHT, 0

;    ds.b ROW_HEIGHT - CASINO_HEIGHT + 1, 0
