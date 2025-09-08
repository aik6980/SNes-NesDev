; https://www.nesdev.org/wiki/Standard_controller
; https://www.nesdev.org/wiki/Controller_reading_code

JOYPAD0 = $4016
JOYPAD1 = $4017

BUTTON_A      = 1 << 7
BUTTON_B      = 1 << 6
BUTTON_SELECT = 1 << 5
BUTTON_START  = 1 << 4
BUTTON_UP     = 1 << 3
BUTTON_DOWN   = 1 << 2
BUTTON_LEFT   = 1 << 1
BUTTON_RIGHT  = 1 << 0

; At the same time that we strobe bit 0, we initialize the ring counter
; so we're hitting two birds with one stone here
.proc ReadController

    ; While the strobe bit is set, buttons will be continuously reloaded.
    ; This means that reading from JOYPAD0 will only return the state of the
    ; first button: button A.
    lda #1 ; 
    sta Buttons
    sta JOYPAD0
    ; By storing 0 into JOYPAD0, the strobe bit is cleared and the reloading stops.
    ; This allows all 8 buttons (newly reloaded) to be read from JOYPAD0.
    lda #0
    sta JOYPAD0

    ; read buttons from the data lines
    @loop:
    lda JOYPAD0
    lsr a           ; bit0 -> Carry
    rol Buttons     ; Carry -> bit 0
    bcc @loop

    rts
.endproc

