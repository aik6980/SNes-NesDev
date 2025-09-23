.zeropage


.data
TXT_LENGTH = 11
; Text in tile space
Var_tile_text: .res 11

Var_decimal_string: .res 4 ; 3 digits + null terminator
Var_decimal_tile_str: .res 4 ; 3 digits + null terminator

.code
; This might change depended on the CHR Tileset
; https://www.ascii-code.com/
CHAR_0_TILE_IDX = $10
ASCII_0 = $30

; Test print text
Var_text0: .asciiz "Hello world"
Var_text1: .asciiz "Bye bye bye"

; Input: A = 0–255
; Output: Buffer = "000".."255"
.proc Decimal_to_string
    ; use temp0-3 to store result
    ldx #0

    ; 100s
    ldy #ASCII_0
@loop100s:
    cmp #100
    bcc @done100s
    sbc #100
    iny
    bne @loop100s
@done100s:
    sty Var_temp0, x
    inx
    ; 10s
    ldy #ASCII_0
@loop10s:
    cmp #10
    bcc @done10s
    sbc #10
    iny
    bne @loop10s
@done10s:
    sty Var_temp0, x
    inx
    ; 1s
    clc
    adc #ASCII_0 ; turn remainder into ASCII
    sta Var_temp0, x
    inx
    ; null terminator
    lda #0
    sta Var_temp0, x

    ; move the result into memory
    ldx #0
    :
    lda Var_temp0, x
    sta Var_decimal_string, x
    inx
    cpx #4
    bne :-

    rts
.endproc

; Expect Char to convert to store in A
.macro Map_ascii_to_tile
    sec
    sbc #ASCII_0 - CHAR_0_TILE_IDX
.endmacro

.proc Print_text
    lda Buttons
    and #BUTTON_A
    bne :+
    lda #<Var_text0
    sta PtrLo
    lda #>Var_text0
    sta PtrHi
    jmp :++
    :
    lda #<Var_text1
    sta PtrLo
    lda #>Var_text1
    sta PtrHi
    :

    ldy #0
@loop:
    lda (PtrLo), y
    Map_ascii_to_tile
    sta Var_tile_text, y
    iny
    cpy #TXT_LENGTH
    bne @loop
    rts
.endproc

.proc Draw_text
    lda #$20    ; set PPUADDR to $2000 
    sta $2006
    lda #$00 + $70 - 5
    sta $2006

    ldx #0
@loop:
    lda Var_tile_text,x
    sta $2007
    inx
    cpx #TXT_LENGTH
    bne @loop
    rts
.endproc


.proc Print_decimal
    ldy #0
@loop:
    lda Var_decimal_string, y
    Map_ascii_to_tile
    sta Var_decimal_tile_str, y
    iny
    cpy #4
    bne @loop
    rts
.endproc

.proc Draw_decimal
    lda #$20    ; set PPUADDR to $2000 
    sta $2006
    lda #$00 + $90
    sta $2006

    ldx #0
@loop:
    lda Var_decimal_tile_str,x
    sta $2007
    inx
    cpx #4
    bne @loop
    rts
.endproc
