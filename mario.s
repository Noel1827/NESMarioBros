.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

clear_memory:
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
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
load_palettes:
  lda $2002
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
  ldx #$00

@loop:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne @loop


LoadBackground:
  LDA $2002           ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006           ; write the high byte ($20) of $2000 address
  LDA #$00
  STA $2006           ; write the low byte ($00) of $2000 address
  LDX #$00            ; start out at 0

LoadBackgroundLoop:
  LDA background, x   ; load data from address (background + the value in x)
  STA $2007           ; write to PPU
  INX                 ; X++
  BNE LoadBackgroundLoop ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                          ; if compare was equal to 0, keep going down
  LDX #$00            ; start out at 0

LoadBackgroundLoop2:
  LDA background+256, x
  STA $2007
  INX
  BNE LoadBackgroundLoop2
  LDX #$00

LoadBackgroundLoop3:
  LDA background+512, x
  STA $2007
  INX
  BNE LoadBackgroundLoop3
  LDX #$00

LoadBackgroundLoop4:
  LDA background+768, x
  STA $2007
  INX
  BNE LoadBackgroundLoop4



LoadAttribute:
  LDA $2002
  LDA #$23
  STA $2006
  LDA #$C2
  STA $2006
  LDA #$00
LoadAttributeLoop:
  LDA attributes, x
  STA $2007
  INX
  CPX #$08
  BNE LoadAttributeLoop



enable_rendering:
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00010000	; Enable Sprites
  sta $2001

forever:
  jmp forever

nmi:
  LDA #$00
  STA $2003    ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014    ; set the high byte (02) of the RAM address, start the transfer
  LDA #$00
  STA $2005
  STA $2005

;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10010000
  STA $2000    ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  LDA #%00011110
  STA $2001    ; enable sprites, enable background, no clipping on left side

  RTI           ; return from interrupt


palettes:
  ; Background Palette
  .byte $0f, $1A, $11, $2D
  .byte $0f, $27, $30, $30
  .byte $0f, $15, $16, $15
  .byte $0f, $15, $15, $15

  ; Sprite Palette
  .byte $0f, $20, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  .byte $0f, $00, $00, $00
  

background:
	.byte $16,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$16,$16,$00,$00,$00,$12,$13,$00,$00,$16,$00,$00,$16,$00,$16
	.byte $00,$00,$00,$00,$16,$00,$16,$16,$00,$00,$00,$14,$15,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$12,$11,$11,$13,$00,$00,$00,$00,$00,$00,$00
	.byte $16,$16,$16,$ee,$ee,$00,$00,$00,$16,$00,$00,$24,$25,$16,$16,$00
	.byte $16,$00,$16,$00,$00,$22,$11,$11,$23,$00,$16,$00,$00,$00,$16,$00
	.byte $00,$00,$00,$00,$16,$00,$16,$00,$16,$00,$00,$16,$00,$00,$00,$00
	.byte $00,$00,$16,$00,$16,$00,$22,$23,$00,$00,$00,$16,$16,$00,$00,$00
	.byte $00,$00,$16,$16,$16,$00,$00,$00,$16,$16,$00,$00,$16,$00,$00,$00
	.byte $00,$16,$00,$00,$00,$00,$00,$00,$00,$16,$00,$00,$00,$16,$16,$16
	.byte $00,$00,$00,$00,$00,$16,$00,$16,$00,$16,$16,$00,$16,$00,$16,$00
	.byte $00,$16,$16,$00,$16,$16,$00,$16,$00,$00,$00,$00,$00,$00,$17,$18
	.byte $00,$00,$00,$00,$00,$00,$16,$00,$00,$00,$00,$16,$00,$16,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$16,$00,$00,$16,$00,$16,$27,$28
	.byte $00,$16,$00,$00,$16,$00,$00,$00,$16,$00,$00,$00,$00,$00,$00,$00
	.byte $16,$00,$00,$00,$00,$16,$00,$00,$00,$00,$00,$16,$00,$00,$00,$16
	.byte $00,$00,$00,$16,$00,$00,$16,$00,$00,$00,$00,$00,$16,$00,$16,$00
	.byte $00,$00,$00,$16,$00,$16,$16,$16,$16,$00,$00,$16,$16,$16,$00,$00
	.byte $00,$00,$16,$00,$00,$16,$00,$16,$00,$00,$16,$00,$00,$00,$00,$00
	.byte $00,$16,$16,$00,$00,$00,$00,$16,$00,$00,$00,$16,$16,$00,$00,$00
	.byte $16,$00,$16,$00,$00,$00,$16,$00,$00,$00,$16,$16,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$16,$16,$00,$00,$16,$16,$00,$00,$00
	.byte $16,$00,$16,$16,$16,$16,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$16,$16,$00,$00,$16,$16,$00,$16,$00,$00,$00,$16,$00
	.byte $00,$00,$00,$16,$16,$00,$00,$16,$16,$00,$00,$16,$00,$16,$00,$00
	.byte $16,$00,$16,$00,$16,$00,$00,$00,$00,$00,$16,$00,$00,$00,$16,$00
	.byte $16,$00,$16,$00,$00,$00,$00,$00,$00,$00,$00,$16,$00,$16,$00,$00
	.byte $00,$00,$00,$00,$16,$00,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$00,$16,$00,$16,$00,$00,$00,$00
	.byte $00,$16,$00,$00,$00,$00,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$16,$16,$16,$16,$00,$00,$22,$23,$22,$23,$22,$23,$22,$23,$22
	.byte $23,$22,$23,$22,$23,$22,$23,$00,$00,$16,$00,$16,$16,$00,$16,$00
	.byte $00,$16,$00,$00,$16,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$16,$00,$00,$16,$00,$16,$00,$00
	.byte $00,$16,$00,$00,$00,$00,$16,$00,$00,$00,$00,$00,$00,$16,$16,$00
	.byte $00,$00,$00,$00,$00,$00,$16,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$16,$16,$00,$16,$00,$16,$16,$00,$00,$16,$00,$00,$00
	.byte $16,$16,$00,$00,$00,$00,$00,$00,$00,$16,$00,$16,$00,$16,$00,$00
	.byte $00,$16,$16,$00,$16,$16,$16,$00,$00,$00,$00,$00,$16,$16,$16,$00
	.byte $00,$16,$16,$16,$00,$16,$00,$16,$00,$00,$16,$16,$16,$00,$16,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$16,$00,$00,$16,$00
	.byte $00,$00,$16,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11,$11
	.byte $55,$54,$54,$55,$55,$55,$54,$51,$55,$55,$55,$15,$55,$55,$55,$15
	.byte $55,$55,$55,$55,$55,$55,$54,$05,$15,$15,$05,$05,$05,$05,$55,$01
	.byte $55,$59,$5a,$5a,$5a,$5a,$55,$55,$05,$05,$05,$05,$05,$05,$05,$05
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00


attributes:
.byte $55,$55,$55,$55,$55,$55,$55,$55  ;%01010101
.byte $55,$55,$55,$15,$55,$55,$55,$55
.byte $55,$55,$55,$55,$55,$55,$55,$55



.segment "CHARS"
.incbin "background.chr"

