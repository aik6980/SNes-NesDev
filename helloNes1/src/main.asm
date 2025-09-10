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
  jsr UpdateDebugControllerSprites

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

; Update each entities (1 entity = 1 sprites) to show different color if Buttons are pressed
.proc UpdateDebugControllerSprites
  ldx #4+2          ; offset=6 to 1st entity - Byte 2 (Attributes) 
  lda #%10000000    ; button to check - use ror to loop until it reached 0
  sta $00
@loop:
  lda Buttons
  and $00           ; check if the button is pressed
  beq @not_pressed
@pressed:
  lda $0200, x      ; each entity contains 1 sprite, set each of them to SpritePalette 1
  ora #%00000010    ; set bit 0 and 1 to use different SpritePalette, logical-or to keep the rest
  sta $0200, x
  jmp @done
@not_pressed:
  lda $0200, x
  and #%11111100    ; clr bit 0 and 1 to SpritePalette 0, logical-and to keep the rest
  sta $0200, x
@done:
  txa         ; increase the X by 4, by using A
  clc
  adc #4
  tax
  clc
  ror $00     ; shift right, prepare to test next button
  bcc @loop   ; loop until Carry is set to 1
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

  lda #%10000000 ; enable NMI, both BG/Sprite use CHR0
  sta $2000
endlessLoop:
  jmp endlessLoop
.endproc

; Data
.segment "CHARS"
  ; Tile page $0000, 1K
  .incbin "tiles.chr"

.segment "RODATA"

paletteData: 
  ; sub palette for tile map
  .incbin "palettes.pal"
  ; sub palette for sprite
  .incbin "palettes.pal"

spriteData:
  .byte 0, 0, %00000000, 0 ; preserve Sprite 0

  ; 256 bytes sprite data
  .incbin "debug_controller.oam"

bgData:
  .incbin "bg.nam"


