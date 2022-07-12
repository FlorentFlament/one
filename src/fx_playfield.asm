fx_init:	SUBROUTINE
	;; Copy 6 pointers i.e 12 bytes to pfpic memory address
	ldy #11
.loop:
	lda pfpic_circles_40x40_ptr,Y
	sta pfpic_p0,Y
	dey
	bpl .loop
fx_overscan:
	rts

fx_vblank: SUBROUTINE
	lda framecnt
	REPEAT 2
	lsr
	REPEND
	and #$07
	tax
	lda pf_motion,X
	sta pf_height
	rts

	MAC CHOOSE_COLOR
	clc
	sty ptr
	lda framecnt
	adc ptr
	sta COLUPF
	ENDM


fx_kernel:	SUBROUTINE
	;; Intialize colors
	lda #$fe
	sta COLUPF

	lda pf_height
	bne .draw_picture

	;; If pf_height == 0, just draw lines
	ldy #39
.empty_pic:
	sta WSYNC
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	CHOOSE_COLOR
	REPEAT 5
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
	ldy #39			; 30 lines. Y can be used to indirect fetch
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
	ldx #3
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
	dc.b 0, 1, 2, 3, 3, 2, 1, 0

pf_40x40_credits_p0:
	dc.b $00, $00, $00, $60, $f0, $30, $70, $60
	dc.b $c0, $80, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $f0, $30, $30, $90
	dc.b $90, $10, $10, $10, $10, $30, $30, $70
	dc.b $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0
pf_40x40_credits_p1:
	dc.b $00, $00, $01, $12, $9b, $d8, $9b, $19
	dc.b $cc, $cc, $0c, $00, $00, $22, $22, $2a
	dc.b $2a, $14, $00, $00, $ff, $ff, $fc, $f8
	dc.b $f1, $73, $33, $93, $f3, $f3, $33, $11
	dc.b $99, $ff, $ff, $ff, $ff, $ff, $ff, $ff
pf_40x40_credits_p2:
	dc.b $00, $00, $03, $27, $37, $36, $b2, $f1
	dc.b $70, $e0, $c0, $80, $00, $53, $54, $22
	dc.b $51, $56, $00, $00, $ff, $cf, $86, $e2
	dc.b $f3, $f3, $e3, $83, $f3, $f3, $c7, $8f
	dc.b $ff, $ff, $d9, $ae, $ae, $ae, $d9, $ff
pf_40x40_credits_p3:
	dc.b $00, $00, $00, $80, $c0, $c0, $d0, $80
	dc.b $00, $20, $70, $30, $00, $c0, $00, $90
	dc.b $40, $80, $00, $00, $f0, $f0, $b0, $90
	dc.b $10, $10, $10, $50, $d0, $d0, $c0, $c0
	dc.b $c0, $f0, $90, $a0, $90, $b0, $b0, $f0
pf_40x40_credits_p4:
	dc.b $00, $00, $00, $c0, $a0, $2e, $af, $ed
	dc.b $cd, $0c, $00, $00, $00, $22, $a2, $b1
	dc.b $a2, $9a, $00, $00, $ff, $f5, $70, $70
	dc.b $34, $25, $a5, $a5, $a7, $22, $22, $32
	dc.b $7f, $ff, $9f, $7f, $1f, $5f, $bf, $ff
pf_40x40_credits_p5:
	dc.b $00, $00, $00, $cc, $6c, $3c, $1c, $3d
	dc.b $59, $99, $18, $00, $00, $01, $01, $00
	dc.b $01, $01, $00, $00, $ff, $ff, $d7, $c7
	dc.b $86, $a6, $a2, $aa, $aa, $ba, $b2, $92
	dc.b $92, $ff, $ff, $ff, $ff, $ff, $ff, $ff
pf_40x40_credits_ptr:
	dc.w pf_40x40_credits_p0
	dc.w pf_40x40_credits_p1
	dc.w pf_40x40_credits_p2
	dc.w pf_40x40_credits_p3
	dc.w pf_40x40_credits_p4
	dc.w pf_40x40_credits_p5

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
