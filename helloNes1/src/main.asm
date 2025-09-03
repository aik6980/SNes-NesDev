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

.segment "CHARS"
  .org $0000
  .incbin "tiles.chr"

.segment "RODATA"

palleteData: 
  .incbin "palettes.pal"

bgData:
  .incbin "bg.nam"
bgDataSize = * - bgData

.segment "CODE"

.proc nmi     ; game loop goes here
  bit $2002
  lda #0
  sta $2006
  sta $2006
  rti
.endproc

.proc LoadPalettes
  bit $2002
  lda #$3f    ; set PPUADDR to $3f00 
  sta $2006
  lda #$00
  sta $2006

  ldx #0  ; loop 
@LoadLoop:
  lda palleteData, x
  sta $2007
  inx
  cpx #32 ; 4(sets) * 4(colors) * 2(bytes) = 32 times
  bne @LoadLoop

  rts
.endproc

.proc LoadBackground
  bit $2002
  lda #$20    ; set PPUADDR to $2000 
  sta $2006
  lda #$00
  sta $2006

  ldx #0  ; loop 
@LoadLoop:
  lda bgData, x
  sta $2007
  inx
  cpx #bgDataSize
  bne @LoadLoop

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
  jsr LoadBackground
main:
  jsr AppMain
  lda #%00001000
  sta $2001
endlessLoop:
  jmp endlessLoop
.endproc