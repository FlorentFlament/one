fx_init:	SUBROUTINE
	lda #$01		; Reflect playfield
	sta CTRLPF

	lda #$80
	sta fb_p1+15
	sta fb_p1+16
fx_overscan:
	rts

	MAC UPDATE_FRAMEBUFFER
	lda framecnt
	and #$7f
	tax
	lda sin_table,X
	sta ptr
	;; X coordinate
	lda #32		; Quarter table
	clc
	adc framecnt
	and #$7f
	tax
	lda sin_table,X
	tax

	;; update appropriate bit in cur_p0 cur_p1
	lda #$40
	sta cur_p0
	lda #$00
	sta cur_p1

	cpx #0
	beq .end
.shift_loop:	
	lsr cur_p0		; P0 7 -> 0
	rol cur_p1		; P1 0 <- 7
	dex
	bne .shift_loop

	ldx ptr
	lda fb_p0,X
	ora cur_p0
	sta fb_p0,X
	lda fb_p1,X
	ora cur_p1
	sta fb_p1,X
.end:	
	ENDM
	
fx_vblank: SUBROUTINE
	;; Height of bars
	lda framecnt
	lsr
	and #$0f
	tax
	lda pf_motion,X
	lda #5
	sta pf_height

	UPDATE_FRAMEBUFFER
	rts

	MAC CHOOSE_COLOR
	lda framecnt+1
	sta ptr
	lda framecnt
	lsr ptr
	ror			; A
	lsr ptr
	ror
	clc
	sty ptr
	adc ptr
	lsr
	lsr
	lsr
	and #$1f
	tax
	lda pf_colors,X
	sta COLUPF
	ENDM


fx_kernel:	SUBROUTINE
	;; Intialize colors
	lda #$fe
	sta COLUPF

	lda pf_height
	bne .draw_picture

	;; If pf_height == 0, just draw lines
	ldy #29
.empty_pic:
	sta WSYNC
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	CHOOSE_COLOR
	REPEAT 7
	sta WSYNC
	REPEND
	lda #$ff
	sta PF0
	sta PF1
	sta PF2
	dey
	bpl .empty_pic
	jmp .end

.draw_picture:
	ldy #29			; 30 lines. Y can be used to indirect fetch
.outer:
	;; 6 lines thick graphic lines (40 graphic lines)
	;; 1st and 2nd line to clear playfields + precompute inverted pixels
	sta WSYNC
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	CHOOSE_COLOR
	sta WSYNC
	lda fb_p0,Y
	eor #$ff
	sta inv_p0
	lda fb_p1,Y
	eor #$ff
	sta inv_p1
	;; 4 lines remaining
	ldx #5
.inner_loop:
	cpx pf_height		; value is in [1..3] included
	sta WSYNC
	bne .blank_line
	;; skipping
	;; 4th lines normal pixels
	lda #$00
	sta PF0
	lda fb_p0,Y
	sta PF1
	lda fb_p1,Y
	sta PF2
	bcs .next_inner
.blank_line:
	lda #$00
	sta PF0
	sta PF1
	sta PF2
.next_inner:
	dex
	bne .inner_loop

	;; 6th line inverted pixels
	sta WSYNC
	lda #$f0
	sta PF0
	lda inv_p0
	sta PF1
	lda inv_p1
	sta PF2

	dey
	bmi .end
	jmp .outer

.end:
	sta WSYNC
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	sta COLUPF
	rts

;;;
;;; DATA
;;;

pf_motion:
	dc.b 0, 1, 2, 3, 3, 4, 4, 5
	dc.b 5, 5, 4, 4, 3, 3, 2, 1

pf_colors:
	dc.b $06, $08, $0a, $0c, $0e ; blank
	dc.b $0e, $0c, $0a, $08, $06 ; blank
	dc.b $64, $66, $68, $6a, $6c, $6e ; rouge
	dc.b $6c, $6a, $68, $66, $64 ; rouge
	dc.b $94, $96, $98, $9a, $9c, $9e ; bleu
	dc.b $9c, $9a, $98, $96, $94 ; bleu

sin_table:
	dc.b $0f, $10, $10, $11, $12, $13, $13, $14
	dc.b $15, $15, $16, $17, $17, $18, $19, $19
	dc.b $1a, $1a, $1b, $1b, $1b, $1c, $1c, $1d
	dc.b $1d, $1d, $1d, $1e, $1e, $1e, $1e, $1e
	dc.b $1e, $1e, $1e, $1e, $1e, $1e, $1d, $1d
	dc.b $1d, $1d, $1c, $1c, $1b, $1b, $1b, $1a
	dc.b $1a, $19, $19, $18, $17, $17, $16, $15
	dc.b $15, $14, $13, $13, $12, $11, $10, $10
	dc.b $0f, $0e, $0e, $0d, $0c, $0b, $0b, $0a
	dc.b $09, $09, $08, $07, $07, $06, $05, $05
	dc.b $04, $04, $03, $03, $03, $02, $02, $01
	dc.b $01, $01, $01, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $01, $01
	dc.b $01, $01, $02, $02, $03, $03, $03, $04
	dc.b $04, $05, $05, $06, $07, $07, $08, $09
	dc.b $09, $0a, $0b, $0b, $0c, $0d, $0e, $0e
