fx_init:	SUBROUTINE
	;; Copy 6 pointers i.e 12 bytes to pfpic memory address
	ldy #11
.loop:
	lda pfpic_atari_40x30_ptr,Y
	sta pfpic_p0,Y
	dey
	bpl .loop
fx_overscan:
	rts

fx_vblank: SUBROUTINE
	lda framecnt
	lsr
	and #$0f
	tax
	lda pf_motion,X
	sta pf_height
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
	lda (pfpic_p0),Y
	eor #$ff
	sta inv_p0
	lda (pfpic_p1),Y
	eor #$ff
	sta inv_p1
	lda (pfpic_p2),Y
	eor #$ff
	sta inv_p2
	lda (pfpic_p3),Y
	eor #$ff
	sta inv_p3
	lda (pfpic_p4),Y
	eor #$ff
	sta inv_p4
	lda (pfpic_p5),Y
	eor #$ff
	sta inv_p5
	;; 4 lines remaining
	ldx #5
.inner_loop:
	cpx pf_height		; value is in [1..3] included
	sta WSYNC
	bne .blank_line
	;; skipping
	;; 4th lines normal pixels
	lda (pfpic_p0),Y
	sta PF0
	lda (pfpic_p1),Y
	sta PF1
	lda (pfpic_p2),Y
	sta PF2
	lda (pfpic_p3),Y
	sta PF0
	lda (pfpic_p4),Y
	sta PF1
	lda (pfpic_p5),Y
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
	lda inv_p0
	sta PF0
	lda inv_p1
	sta PF1
	lda inv_p2
	sta PF2
	SLEEP 14
	lda inv_p3
	sta PF0
	lda inv_p4
	sta PF1
	lda inv_p5
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

pfpic_circles_40x40_p0:
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $80, $80, $c0, $c0, $e0, $e0, $e0
	dc.b $e0, $f0, $f0, $f0, $f0, $f0, $f0, $e0
	dc.b $e0, $e0, $e0, $c0, $c0, $80, $80, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
pfpic_circles_40x40_p1:
	dc.b $00, $00, $01, $07, $0f, $1f, $3e, $7c
	dc.b $f8, $f0, $e0, $c0, $c0, $80, $80, $80
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $80, $80, $80, $c0, $c0, $e0, $f0, $f8
	dc.b $7c, $3e, $1f, $0f, $07, $01, $00, $00
pfpic_circles_40x40_p2:
	dc.b $e0, $fe, $ff, $ff, $0f, $01, $00, $00
	dc.b $00, $c0, $e0, $f0, $f8, $fc, $fc, $fc
	dc.b $fc, $fc, $fc, $fc, $fc, $f8, $f8, $f0
	dc.b $e0, $80, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $01, $0f, $ff, $ff, $fe, $c0
pfpic_circles_40x40_p3:
	dc.b $70, $f0, $f0, $f0, $00, $00, $00, $00
	dc.b $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0
	dc.b $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0
	dc.b $f0, $f0, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $f0, $f0, $f0, $30
pfpic_circles_40x40_p4:
	dc.b $00, $e0, $f8, $fe, $ff, $1f, $07, $03
	dc.b $81, $e0, $f8, $fc, $fc, $fe, $fe, $ff
	dc.b $ff, $ff, $ff, $fe, $fe, $fe, $fc, $f8
	dc.b $f0, $c0, $00, $00, $00, $00, $00, $01
	dc.b $03, $07, $1f, $ff, $fe, $f8, $e0, $00
pfpic_circles_40x40_p5:
	dc.b $00, $00, $00, $00, $00, $01, $03, $07
	dc.b $0f, $1f, $1e, $3c, $3c, $78, $78, $78
	dc.b $70, $f0, $f0, $f0, $f0, $f0, $f0, $70
	dc.b $78, $78, $78, $3c, $3c, $1e, $1f, $0f
	dc.b $07, $03, $01, $00, $00, $00, $00, $00
pfpic_circles_40x40_ptr:
	dc.w pfpic_circles_40x40_p0
	dc.w pfpic_circles_40x40_p1
	dc.w pfpic_circles_40x40_p2
	dc.w pfpic_circles_40x40_p3
	dc.w pfpic_circles_40x40_p4
	dc.w pfpic_circles_40x40_p5


pfpic_atari_40x30_p0:
	dc.b $e0, $e0, $e0, $e0, $80, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
pfpic_atari_40x30_p1:
	dc.b $80, $e0, $f8, $fc, $fe, $7f
	dc.b $1f, $0f, $07, $03, $01, $01, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
pfpic_atari_40x30_p2:
	dc.b $c0, $c0, $c0, $c0, $c0, $c0
	dc.b $c1, $c3, $c3, $c7, $c7, $c7, $cf, $cf
	dc.b $ce, $ce, $dc, $dc, $dc, $dc, $dc, $d8
	dc.b $d8, $d8, $d8, $d8, $d8, $d8, $d8, $d8
pfpic_atari_40x30_p3:
	dc.b $30, $30, $30, $30, $30, $30
	dc.b $30, $30, $30, $30, $30, $30, $30, $30
	dc.b $30, $30, $b0, $b0, $b0, $b0, $b0, $b0
	dc.b $b0, $b0, $b0, $b0, $b0, $b0, $b0, $b0
pfpic_atari_40x30_p4:
	dc.b $00, $00, $01, $03, $07, $0f
	dc.b $1f, $3f, $3e, $7c, $78, $78, $f0, $f0
	dc.b $e0, $e0, $c0, $c0, $c0, $c0, $c0, $80
	dc.b $80, $80, $80, $80, $80, $80, $80, $80
pfpic_atari_40x30_p5:
	dc.b $78, $7e, $7f, $7f, $1f, $07
	dc.b $01, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
pfpic_atari_40x30_ptr:
	dc.w pfpic_atari_40x30_p0
	dc.w pfpic_atari_40x30_p1
	dc.w pfpic_atari_40x30_p2
	dc.w pfpic_atari_40x30_p3
	dc.w pfpic_atari_40x30_p4
	dc.w pfpic_atari_40x30_p5
