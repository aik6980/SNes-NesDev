.segment "ZEROPAGE"
Var_test: .res 1

.segment "CODE"
.proc AppMain
    ; test constant
    HEALTH = 25

    ; check for game over
    lda #HEALTH ; current heath
    sta $00 ; store 
    lda #30 ; damage amount
    sta $01 ; store
    
    lda #<-10 ; store -10
    clc 
    adc $01
    
    lda #00 ; current game_over flag
    sta $02 ; store

    ; check if health <= 0 
    lda $00 ; load health
    cmp $01 ; compare to damage
    bpl NotGameOver
    
    lda #01 ; set game_over flag
    sta $02
    
    NotGameOver: 
    rts;
.endproc