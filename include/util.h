; -----------------------------------------------------------------------------
; Desc:     Sets an array of six pointers to six static data blocks.
; Params:   Vars (array of 6 words)
;           Addr (array of 6 data blocks)
; Ouputs:
; Notes:    All data blocks must reside in the same page.
; -----------------------------------------------------------------------------
    MAC SET_6_PAGE_POINTERS
.Vars   SET {1}
.Addr0  SET {2}0
.Addr1  SET {2}1
.Addr2  SET {2}2
.Addr3  SET {2}3
.Addr4  SET {2}4
.Addr5  SET {2}5

        lda #>.Addr0
        sta .Vars+1
        sta .Vars+3
        sta .Vars+5
        sta .Vars+7
        sta .Vars+9
        sta .Vars+11

        lda #<.Addr0
        sta .Vars
        lda #<.Addr1
        sta .Vars+2
        lda #<.Addr2
        sta .Vars+4
        lda #<.Addr3
        sta .Vars+6
        lda #<.Addr4
        sta .Vars+8
        lda #<.Addr5
        sta .Vars+10
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sets an array of six pointers to six static data blocks.
; Params:   Vars (array of 6 words)
;           Addr (array of 6 data blocks)
; Ouputs:
; Notes:    All data blocks must reside in the same page.
; -----------------------------------------------------------------------------
    MAC SET_6_POINTERS
.Vars   SET {1}
.Addr0  SET {2}0
.Addr1  SET {2}1
.Addr2  SET {2}2
.Addr3  SET {2}3
.Addr4  SET {2}4
.Addr5  SET {2}5

        lda #>.Addr0
        sta .Vars+1
        lda #>.Addr1
        sta .Vars+3
        lda #>.Addr2
        sta .Vars+5
        lda #>.Addr3
        sta .Vars+7
        lda #>.Addr4
        sta .Vars+9
        lda #>.Addr5
        sta .Vars+11

        lda #<.Addr0
        sta .Vars
        lda #<.Addr1
        sta .Vars+2
        lda #<.Addr2
        sta .Vars+4
        lda #<.Addr3
        sta .Vars+6
        lda #<.Addr4
        sta .Vars+8
        lda #<.Addr5
        sta .Vars+10
    ENDM

; -----------------------------------------------------------------------------
; Desc:     Sets low byte of an array of six pointers to static data blocks.
; Params:   Vars (array of 6 words)
;           Addr (array of 6 data blocks)
; Ouputs:
; -----------------------------------------------------------------------------
    MAC SET_6_LOW_POINTERS
.Vars   SET {1}
.Addr0  SET {2}0
.Addr1  SET {2}1
.Addr2  SET {2}2
.Addr3  SET {2}3
.Addr4  SET {2}4
.Addr5  SET {2}5

        lda #<.Addr0
        sta .Vars
        lda #<.Addr1
        sta .Vars+2
        lda #<.Addr2
        sta .Vars+4
        lda #<.Addr3
        sta .Vars+6
        lda #<.Addr4
        sta .Vars+8
        lda #<.Addr5
        sta .Vars+10
    ENDM
