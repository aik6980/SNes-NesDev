.import AppMain

.segment "HEADER"
  .byte $4E, $45, $53, $1A  ; iNES header identifier
  .byte 2                   ; 2x 16KB PRG-ROM Banks
  .byte 1                   ; 1x  8KB CHR-ROM
  .byte $01, $00            ; mapper 0, vertical mirroring

.segment "VECTORS"
  .addr nmi
  .addr reset
  .addr 0

.segment "STARTUP"

.segment "ZEROPAGE"

; 16 bit address Ptr
PtrLo: .res 1 ;reserve 1 byte
PtrHi: .res 1
; Controller
Buttons: .res 1 ; we reserve one byte for storing the data that is read from controller


.segment "CODE"

.include "controller.asm"

.proc nmi     ; game loop goes here
  jsr ReadController
  jsr UpdateSprites

  ; https://www.nesdev.org/wiki/PPU_OAM
  ; activate OAM DMA at $2000, 256 times
  lda #$02
  sta $4014

  bit $2002
  lda #0
  sta $2006
  sta $2006
  rti
.endproc

; todo: add comments
.proc UpdateSprites
  ldx #6
  lda #%10000000
  sta $00
@loop:
  lda Buttons
  and $00
  beq @not_pressed
@pressed:
  lda $0200, x
  ora #%00000001
  sta $0200, x
  lda $0204, x
  ora #%00000001
  sta $0204, x
  lda $0208, x
  ora #%00000001
  sta $0208, x
  lda $020C, x
  ora #%00000001
  sta $020C, x
  jmp @done
@not_pressed:
  lda $0200, x
  and #%11111100
  sta $0200, x
  lda $0204, x
  and #%11111100
  sta $0204, x
  lda $0208, x
  and #%11111100
  sta $0208, x
  lda $020C, x
  and #%11111100
  sta $020C, x
@done:
  txa
  clc
  adc #$10
  tax
  clc
  ror $00
  bcc @loop
  rts
.endproc

.proc LoadPalettes
  bit $2002
  lda #$3f    ; set PPUADDR to $3f00 
  sta $2006
  lda #$00
  sta $2006

  ldx #0  ; loop 
@loop:
  lda paletteData, x
  sta $2007
  inx
  ;cpx #16 ; loop 16 bytes (1 sub palette)
  cpx #32
  bne @loop

  rts
.endproc

.proc LoadSprites
  ldx #0 
@loop:
  lda spriteData, x
  sta $0200, x
  inx
  bne @loop ; loop 256 times
  
  rts
.endproc

.proc LoadBackground
  bit $2002
  lda #$20    ; set PPUADDR to $2000 
  sta $2006
  lda #$00
  sta $2006

  ; init Ptr
  lda #<bgData ; shift right
  sta PtrLo
  lda #>bgData
  sta PtrHi

  ; load 4 pages of 256 bytes
  ldx #4
@LoadLoop4:
  ldy #0  ; loop
@LoadLoop256:
  lda (PtrLo),y
  sta $2007
  iny
  bne @LoadLoop256

  inc PtrHi ; advance pointer by 256
  dex
  bne @LoadLoop4

  rts
.endproc

.proc reset
  sei
  cld
  ldx #%01000000
  stx $4017
  ldx #$ff
  txs
  ldx #0
  stx $2000 ; disable nmi
  stx $2001 ; disable rendering
  stx $4010
  bit $2002

@vblankWait1:
  bit $2002
  bpl @vblankWait1

@clearMemory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne @clearMemory

@vblankWait2:
  bit $2002
  bpl @vblankWait2

  jsr LoadPalettes
  jsr LoadSprites
  jsr LoadBackground
main:
  jsr AppMain

  lda #0
  sta $2003 ; OAMADDR <= 0

  lda #$02
  sta $4014
  
  ;lda #%00001010 ; enable background/show first column
  lda #%00011110 ; enable background/sprites/show first column
  sta $2001

  lda #0    ; reset scrolling x/y position
  sta $2005
  sta $2005

  lda #%10001000 ; enable NMI
  sta $2000
endlessLoop:
  jmp endlessLoop
.endproc

; Data
.segment "CHARS"
  ; Tile page $0000, 1K
  .incbin "tiles.chr"
  
  ; Tile page start at $1000 - use for sprite
  ; Tile 0: Blank
  .byte $00, $00, $00, $00, $00, $00, $00, $00
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; Tile 1: D-PAD Arrow [1/2]
  .byte %00000001
  .byte %00000010
  .byte %00000100
  .byte %00001000
  .byte %00010000
  .byte %00111100
  .byte %00000100
  .byte %00000100

  .byte %00000000
  .byte %00000001
  .byte %00000011
  .byte %00000111
  .byte %00001111
  .byte %00000011
  .byte %00000011
  .byte %00000011

  ; Tile 2: D-PAD Arrow [2/2]
  .byte %00000100
  .byte %00000100
  .byte %00000111
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  .byte %00000011
  .byte %00000011
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000

  ; Tile 3: D-PAD Arrow (LR) [1/2]
  .byte %00000000
  .byte %00000000
  .byte %00000100
  .byte %00001100
  .byte %00010100
  .byte %00100111
  .byte %01000000
  .byte %10000000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00001000
  .byte %00011000
  .byte %00111111
  .byte %01111111

  ; Tile 4: D-PAD Arrow (LR) [2/2]
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11100000
  .byte %00100000
  .byte %00100000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %11000000
  .byte %11000000

  ; Tile 5: Select / Start Button
  .byte %00000000
  .byte %00000000
  .byte %00011111
  .byte %00100000
  .byte %00100000
  .byte %00100000
  .byte %00011111
  .byte %00000000

  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00011111
  .byte %00011111
  .byte %00011111
  .byte %00000000
  .byte %00000000

  ; Tile 6: A/B Buttons
  .byte %00000000
  .byte %00000111
  .byte %00011000
  .byte %00100000
  .byte %00100000
  .byte %01000000
  .byte %01000000
  .byte %01000000

  .byte %00000000
  .byte %00000000
  .byte %00000111
  .byte %00011111
  .byte %00011111
  .byte %00111111
  .byte %00111111
  .byte %00111111

.segment "RODATA"

paletteData: 
  ; sub palette for tile map
  .incbin "palettes.pal"
  ; sub palette for sprite
  .byte $0F, $10, $00, $0F
  .byte $0F, $10, $29, $0F
  .byte $0F, $10, $00, $0F
  .byte $0F, $10, $00, $0F

;paletteData:
;  .byte $0F, $10, $00, $0F
;  .byte $0F, $20, $19, $0F
;  .byte $0F, $10, $00, $0F
;  .byte $0F, $10, $00, $0F
;
;  .byte $0F, $10, $00, $0F
;  .byte $0F, $10, $29, $0F
;  .byte $0F, $10, $00, $0F
;  .byte $0F, $10, $00, $0F

OFFSET_Y = 45

spriteData:
  .byte 0, 0, %00000000, 0

  ; A [25-28]
  .byte 104+OFFSET_Y, 6, %00000000, 194
  .byte 104+OFFSET_Y, 6, %01000000, 202
  .byte 112+OFFSET_Y, 6, %10000000, 194
  .byte 112+OFFSET_Y, 6, %11000000, 202

  ; B [29-32]
  .byte 104+OFFSET_Y, 6, %00000000, 170
  .byte 104+OFFSET_Y, 6, %01000000, 178
  .byte 112+OFFSET_Y, 6, %10000000, 170
  .byte 112+OFFSET_Y, 6, %11000000, 178

  ; Select
  .byte 121+OFFSET_Y, 5, %00000000, 112
  .byte 121+OFFSET_Y, 5, %01000000, 120
  .byte 000+OFFSET_Y, 0, %00000000, 0
  .byte 000+OFFSET_Y, 0, %00000000, 0

  ; Start
  .byte 121+OFFSET_Y, 5, %00000000, 132
  .byte 121+OFFSET_Y, 5, %01000000, 140
  .byte 000+OFFSET_Y, 0, %00000000, 0
  .byte 000+OFFSET_Y, 0, %00000000, 0

  ; Up
  .byte 88+OFFSET_Y, 1, %00000000, 56
  .byte 96+OFFSET_Y, 2, %00000000, 56
  .byte 88+OFFSET_Y, 1, %01000000, 64
  .byte 96+OFFSET_Y, 2, %01000000, 64

  ; Down
  .byte 120+OFFSET_Y, 2, %10000000, 56
  .byte 128+OFFSET_Y, 1, %10000000, 56
  .byte 120+OFFSET_Y, 2, %11000000, 64
  .byte 128+OFFSET_Y, 1, %11000000, 64

  ; Left
  .byte 104+OFFSET_Y, 3, %00000000, 40
  .byte 104+OFFSET_Y, 4, %00000000, 48
  .byte 112+OFFSET_Y, 3, %10000000, 40
  .byte 112+OFFSET_Y, 4, %10000000, 48

  ; Right
  .byte 104+OFFSET_Y, 4, %01000000, 72
  .byte 104+OFFSET_Y, 3, %01000000, 80
  .byte 112+OFFSET_Y, 4, %11000000, 72
  .byte 112+OFFSET_Y, 3, %11000000, 80

  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0
  .byte 0, 0, %00000000, 0

bgData:
  .incbin "bg.nam"


