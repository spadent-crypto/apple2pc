; SuperSprite demo for LinApple: eight TMS9918A sprites bounce over the
; Apple's own text screen, the AY-3-8912 bleeps at every bounce.
;   SPACE  Apple video in on/off (transparent VDP pixels show the Apple or black)
;   M      VDP mixed in / Apple only
;   S      sound on/off
; Card in slot 7: $C0F0-$C0FF.

VDP_DATA = $C0F0
VDP_CTRL = $C0F1
SW_IN_OFF = $C0F3
SW_IN_ON  = $C0F4
SW_APPLE  = $C0F5
SW_MIX    = $C0F6
AY_DATA   = $C0FC
AY_REG    = $C0FE

KBD    = $C000
KBDSTB = $C010
TXTSET = $C051
MIXCLR = $C052
PAGE1  = $C054

NSPR   = 8
MAXX   = 240
MAXY   = 176

ptr    = $06          ; zero page pointer
tmp    = $08



start:  sei
        cld
        bit TXTSET
        bit MIXCLR
        bit PAGE1
        jsr clear_text
        jsr print_lines
        jsr vdp_init
        jsr ay_init
        bit SW_IN_ON
        bit SW_MIX
        lda #1
        sta apple_in
        sta mixing
        sta sound

main:   jsr wait_frame
        jsr move_sprites
        jsr write_sprites
        jsr keys
        jmp main

; --- wait for the VDP frame flag (status bit 7; reading clears it) ----------
wait_frame:
        lda VDP_CTRL
        bpl wait_frame
        rts

; --- Apple text screen ------------------------------------------------------
clear_text:
        lda #$04
        sta ptr+1
        lda #0
        sta ptr
        ldy #0
        lda #$A0
@l:     sta (ptr),y
        iny
        bne @l
        inc ptr+1
        ldx ptr+1
        cpx #$08
        bne @l
        rts

; row in X, string pointer in ptr (high-bit ASCII, 0 terminated)
print_row:
        lda rowlo,x
        sta tmp
        lda rowhi,x
        sta tmp+1
        ldy #0
@l:     lda (ptr),y
        beq @d
        sta (tmp),y
        iny
        bne @l
@d:     rts

print_lines:
        ldx #0
@l:     lda lines,x
        cmp #$FF
        beq @d
        sta row
        lda lines+1,x
        sta ptr
        lda lines+2,x
        sta ptr+1
        stx save_x
        ldx row
        jsr print_row
        ldx save_x
        inx
        inx
        inx
        bne @l
@d:     rts

; --- VDP --------------------------------------------------------------------
; A = value, Y = register
vdp_reg:
        sta VDP_CTRL
        tya
        ora #$80
        sta VDP_CTRL
        rts

; write address in ptr (lo/hi)
vdp_waddr:
        lda ptr
        sta VDP_CTRL
        lda ptr+1
        ora #$40
        sta VDP_CTRL
        rts

vdp_init:
        ldy #0
@r:     lda vdp_regs,y
        jsr vdp_reg
        iny
        cpy #8
        bne @r
        ; clear all 16K
        lda #0
        sta ptr
        sta ptr+1
        jsr vdp_waddr
        ldx #$40
        ldy #0
        lda #0
@c:     sta VDP_DATA
        iny
        bne @c
        dex
        bne @c
        ; patterns 8,16,..,48: solid blocks
        ldx #1
@p:     txa             ; pattern 8x * 8 bytes = x * 64, 16 bits
        lsr
        lsr
        sta ptr+1
        txa
        and #$03
        asl
        asl
        asl
        asl
        asl
        asl
        sta ptr
        jsr vdp_waddr
        ldy #8
        lda #$FF
@pb:    sta VDP_DATA
        dey
        bne @pb
        inx
        cpx #7
        bne @p
        ; colour table $2000: group n = colour n on transparent
        lda #$00
        sta ptr
        lda #$20
        sta ptr+1
        jsr vdp_waddr
        ldx #0
@ct:    lda groupcolor,x
        sta VDP_DATA
        inx
        cpx #8
        bne @ct
        ; rainbow bars on rows 0 and 23 of the name table ($1800)
        lda #$00
        sta ptr
        lda #$18
        sta ptr+1
        jsr vdp_waddr
        jsr rainbow_row
        lda #$E0
        sta ptr
        lda #$1A
        sta ptr+1
        jsr vdp_waddr
        jsr rainbow_row
        ; sprite pattern 0 at $3800: a ball
        lda #$00
        sta ptr
        lda #$38
        sta ptr+1
        jsr vdp_waddr
        ldx #0
@b:     lda ball,x
        sta VDP_DATA
        inx
        cpx #8
        bne @b
        rts

rainbow_row:
        ldx #0
@l:     txa
        lsr
        lsr             ; 4 tiles per colour
        and #$07
        tay
        lda rainbow,y
        sta VDP_DATA
        inx
        cpx #32
        bne @l
        rts

; --- sprites ----------------------------------------------------------------
move_sprites:
        ldx #0
@s:     lda xpos,x
        clc
        adc dx,x
        ldy dx,x
        bmi @xneg
        cmp #MAXX+1
        bcs @xb
        bcc @xok
@xneg:  bcc @xb
@xok:   sta xpos,x
        jmp @y
@xb:    lda #0
        sec
        sbc dx,x
        sta dx,x
        jsr bleep
@y:     lda ypos,x
        clc
        adc dy,x
        ldy dy,x
        bmi @yneg
        cmp #MAXY+1
        bcs @yb
        bcc @yok
@yneg:  bcc @yb
@yok:   sta ypos,x
        jmp @n
@yb:    lda #0
        sec
        sbc dy,x
        sta dy,x
        jsr bleep
@n:     inx
        cpx #NSPR
        bne @s
        rts

write_sprites:
        lda #$00
        sta ptr
        lda #$1B
        sta ptr+1
        jsr vdp_waddr
        ldx #0
@w:     lda ypos,x
        sec
        sbc #1          ; the VDP draws from the line after Y
        sta VDP_DATA
        lda xpos,x
        sta VDP_DATA
        lda #0
        sta VDP_DATA
        lda color,x
        sta VDP_DATA
        inx
        cpx #NSPR
        bne @w
        lda #$D0
        sta VDP_DATA
        rts

; --- AY-3-8912 --------------------------------------------------------------
; A = value, Y = register
ay_write:
        sty AY_REG
        sta AY_DATA
        rts

ay_init:
        ldy #0
@r:     lda ay_regs,y
        jsr ay_write
        iny
        cpy #14
        bne @r
        rts

; X = sprite number: a decaying bleep at that sprite's pitch
bleep:  lda sound
        beq @q
        stx save_x
        lda pitch,x
        ldy #0
        jsr ay_write
        lda #0
        ldy #1
        jsr ay_write
        lda #$00        ; envelope shape 0: one decay
        ldy #13
        jsr ay_write
        ldx save_x
@q:     rts

; --- keys -------------------------------------------------------------------
keys:   lda KBD
        bpl @q
        bit KBDSTB
        and #$5F        ; upper case; space becomes 0
        beq @space
        cmp #'M'
        beq @m
        cmp #'S'
        beq @snd
@q:     rts
@space: lda apple_in
        eor #1
        sta apple_in
        beq @off
        bit SW_IN_ON
        rts
@off:   bit SW_IN_OFF
        rts
@m:     lda mixing
        eor #1
        sta mixing
        beq @ao
        bit SW_MIX
        rts
@ao:    bit SW_APPLE
        rts
@snd:   lda sound
        eor #1
        sta sound
        rts

; --- data -------------------------------------------------------------------
vdp_regs:
        .byte $00       ; R0 Graphics I, no external video bit needed
        .byte $C1       ; R1 16K, display on, 8x8 sprites magnified
        .byte $06       ; R2 names $1800
        .byte $80       ; R3 colours $2000
        .byte $00       ; R4 patterns $0000
        .byte $36       ; R5 sprite attributes $1B00
        .byte $07       ; R6 sprite patterns $3800
        .byte $00       ; R7 backdrop transparent

groupcolor:
        .byte $00, $80, $A0, $20, $50, $40, $D0, $00
rainbow:
        .byte 8, 16, 24, 32, 40, 48, 8, 16

ball:   .byte $3C, $7E, $FF, $FF, $FF, $FF, $7E, $3C

ay_regs:
        .byte 120, 0, 0, 0, 0, 0, 0   ; tone A, B, C, noise
        .byte $3E                      ; mixer: tone A only
        .byte $10, 0, 0                ; A follows the envelope
        .byte $00, $10                 ; envelope period
        .byte $09                      ; shape: decay, then hold silent

xpos:   .byte 10, 60, 110, 160, 200, 30, 90, 220
ypos:   .byte 20, 50, 80, 110, 140, 160, 30, 90
dx:     .byte 1, 2, $FF, $FE, 1, $FF, 2, $FE
dy:     .byte 1, $FF, 2, $FE, $FF, 1, $FE, 2
color:  .byte $08, $0A, $03, $05, $0D, $0F, $07, $09
pitch:  .byte 80, 95, 107, 120, 135, 160, 180, 214

apple_in: .byte 0
mixing:   .byte 0
sound:    .byte 0
save_x:   .byte 0
row:      .byte 0

rowlo:  .byte $00,$80,$00,$80,$00,$80,$00,$80
        .byte $28,$A8,$28,$A8,$28,$A8,$28,$A8
        .byte $50,$D0,$50,$D0,$50,$D0,$50,$D0
rowhi:  .byte $04,$04,$05,$05,$06,$06,$07,$07
        .byte $04,$04,$05,$05,$06,$06,$07,$07
        .byte $04,$04,$05,$05,$06,$06,$07,$07

.macro HIASC str
        .repeat .strlen(str), i
        .byte .strat(str, i) | $80
        .endrepeat
        .byte 0
.endmacro

lines:  .byte 2
        .word t0
        .byte 4
        .word t1
        .byte 5
        .word t2
        .byte 8
        .word t3
        .byte 9
        .word t3
        .byte 10
        .word t3
        .byte 11
        .word t3
        .byte 12
        .word t3
        .byte 13
        .word t3
        .byte 14
        .word t3
        .byte 15
        .word t3
        .byte 18
        .word t4
        .byte 19
        .word t5
        .byte 20
        .word t6
        .byte $FF

t0:     HIASC "   SUPERSPRITE DEMO  (LINAPPLE SLOT 7)"
t1:     HIASC "THESE LETTERS ARE THE APPLE II'S TEXT."
t2:     HIASC "THE BALLS ARE TMS9918A SPRITES."
t3:     HIASC "APPLE//E APPLE//E APPLE//E APPLE//E   "
t4:     HIASC "SPACE: APPLE VIDEO IN ON/OFF"
t5:     HIASC "M    : MIX VDP / APPLE ONLY"
t6:     HIASC "S    : SOUND ON/OFF"
