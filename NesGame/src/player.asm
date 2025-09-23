.zeropage ; shorthand for .segment "ZEROPAGE"
Var_player_sprite = $0200 + (4*10)

.data
Var_player_xpos: .res 1
Var_player_ypos: .res 1
Var_player_facing: .res 1

; store color palette for player status
Var_player_status: .res 1
; status timer
Var_player_status_timer: .res 1

.code ; shorthand for .segment "CODE"

PLAYER_FACE_RIGHT = $00
PLAYER_FACE_LEFT  = $40 ;H-Flip flag
PLAYER_SPEED = 2

.macro Reset_player_status_timer
  lda #10
  sta Var_player_status_timer
.endmacro

.proc Init_player
  INIT_X = 128
  INIT_Y = 134

  NUM_SPRITES = 4

  lda #INIT_X
  sta Var_player_xpos
  lda #INIT_Y
  sta Var_player_ypos

  lda #PLAYER_FACE_RIGHT
  sta Var_player_facing

  rts
.endproc

.proc Update_player_sprite
  NUM_SPRITES = 4

  ldx #0
@loop:
  lda Player_walk + 0, x
  bit Var_player_facing
  beq :+
    eor #$FF ; negate using 2s compliment
    clc
    adc #1
  :
  clc
  adc Var_player_xpos
  sta Var_player_sprite + OAM_X, x

  lda Var_player_ypos
  clc
  adc Player_walk + 1, x
  sta Var_player_sprite + OAM_Y, x

  lda Player_walk + 2, x
  sta Var_player_sprite + OAM_TILE, x

  lda Player_walk + 3, x
  ora Var_player_facing ; Var_player_facing stored H-Flip flag
  ora Var_player_status
  sta Var_player_sprite + OAM_ATTR, x

  
  txa
  clc 
  adc #4
  tax

  cpx #NUM_SPRITES*4
  bne @loop
.endproc

.proc Update_player_position
  LEFT_WALL_POS = (5*8 + 8)
  RIGHT_WALL_POS = (28*8 - 8)

  lda Buttons
  and #BUTTON_LEFT
  bne @move_left
  lda Buttons
  and #BUTTON_RIGHT
  bne @move_right
  rts

@move_left:

  ; check left wall
  lda #LEFT_WALL_POS
  cmp Var_player_xpos
  bcs :+ ; if plus, allow to walk 
  lda #<-PLAYER_SPEED
  sta Var_temp0
  jmp :++
  : ; set speed to 0
  lda #0
  sta Var_temp0
  :

  lda Var_player_xpos
  clc
  adc Var_temp0
  sta Var_player_xpos

  lda #PLAYER_FACE_LEFT
  sta Var_player_facing

  rts
@move_right:

  ; check right wall
  lda #RIGHT_WALL_POS
  cmp Var_player_xpos
  bcc :+ ; if plus, allow to walk 
  lda #PLAYER_SPEED
  sta Var_temp0 
  jmp :++
  : ; set speed to 0
  lda #0
  sta Var_temp0
  :

  lda Var_player_xpos
  clc
  adc Var_temp0
  sta Var_player_xpos

  lda #PLAYER_FACE_RIGHT
  sta Var_player_facing

  rts
.endproc

.proc Update_player_status
  LEFT_ITEM_POS = (5*8 + 8)
  RIGHT_ITEM_POS = (28*8 - 8)

  LEFT_ITEM_COL_PAL = 3
  RIGHT_ITEM_COL_PAL = 1

  ; check touch left item
  lda #LEFT_ITEM_POS
  cmp Var_player_xpos
  bcc :+ ; no touch
  lda #LEFT_ITEM_COL_PAL
  sta Var_player_status
  Reset_player_status_timer
  :

  ; check touch right item
  lda #RIGHT_ITEM_POS
  cmp Var_player_xpos
  bcs :+ ; no touch
  lda #RIGHT_ITEM_COL_PAL
  sta Var_player_status
  Reset_player_status_timer
  :

  lda Var_player_status_timer
  cmp #0
  bne :+
  lda #0
  sta Var_player_status
  :

  rts
.endproc

.proc Update_player_status_timer
  lda Var_player_status
  cmp #0
  beq :+
  
  lda Var_player_status_timer
  cmp #0
  beq :+
  sbc #1
  :
  sta Var_player_status_timer
  :
  rts
.endproc



