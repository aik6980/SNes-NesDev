;.segment "CODE"
.export AppMain
.segment "CODE"

.proc AppMain
    ; check for game over
    lda #25 ; current heath
    sta $00 ; store 
    lda #30 ; damage amount
    sta $01 ; store
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