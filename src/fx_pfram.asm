fx_init:	SUBROUTINE
	lda #$01		; Reflect playfield
	sta CTRLPF
	rts

fx_overscan:
	;; Clear framebuffer
	lda #$00
	ldx #29
.clear_loop:
	sta fb_p0,X
	sta fb_p1,X
	dex
	bpl .clear_loop

	lda framecnt+1
	and #$1f
	tax
	lda x_step_table,X
	sta x_step
	lda y_step_table,X
	sta y_step
.end:
	rts

;;; X and Y shift should be in ptr and ptr+1 respectively
;;; At the end X and Y coordinante are in ptr and ptr+1
fb_fetch_point:	SUBROUTINE
	;; X coordinate
	lda framecnt
	lsr
	clc
	adc ptr		; was 32
	and #127
	tax
	lda sin_table,X
	sta ptr
	;; Y coordinate
	lda framecnt
	lsr
	clc
	adc ptr+1	; was 64
	and #127
	tax
	lda sin_table,X
	sta ptr+1
	tax
	rts

;;; X and Y coordinante are in ptr and ptr+1
fb_draw_point:	SUBROUTINE
	;; update appropriate bit in cur_p0 cur_p1
	lda #$00
	sta cur_p0
	sta cur_p1

	lda ptr
	cmp #16
	bcc .no_mirror
	lda #29
	sec
	sbc ptr
.no_mirror:
	cmp #8
	bcc .first_byte
	sec
	sbc #8
	tax
	lda #$01
	cpx #0
	beq .second_byte_end
.second_byte_shift:
	asl
	dex
	bne .second_byte_shift
.second_byte_end:
	sta cur_p1
	beq .end
.first_byte:
	tax
	lda #$40
	cpx #0
	beq .first_byte_end
.first_byte_shift:
	lsr		; P0 7 -> 0
	dex
	bne .first_byte_shift
.first_byte_end:
	sta cur_p0

.end:
	ldx ptr+1
	lda fb_p0,X
	ora cur_p0
	sta fb_p0,X
	lda fb_p1,X
	ora cur_p1
	sta fb_p1,X
	rts

;;; Updates ptr, ptr+1
;;; And cur_p0, cur_p1
	MAC FETCH_N_DRAW
	lda {1}
	sta ptr
	lda {2}
	sta ptr+1
	jsr fb_fetch_point
	jsr fb_draw_point
	ENDM

fb_rotating_points:	SUBROUTINE
	lda #0
	sta x_shift
	lda #32
	sta y_shift

	ldy #9
.fetch_draw_loop:
	FETCH_N_DRAW x_shift, y_shift
	lda x_step
	clc
	adc x_shift
	sta x_shift
	lda y_step
	clc
	adc y_shift
	sta y_shift
	dey
	bpl .fetch_draw_loop
	rts

fx_vblank: SUBROUTINE
	;; Height of bars
	lda framecnt
	lsr
	and #$0f
	tax
	lda pf_motion,X
	lda #5
	sta pf_height

	jsr fb_rotating_points

	;; self
	lda #$80
	sta fb_p1+14
	sta fb_p1+15
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

x_step_table:
	dc.b  4,  4,  4,  4,  4,  4,  4,  4
	dc.b  4,  4,  4,  4,  4,  4,  4,  4
	dc.b  4,  5,  6,  7,  8,  9, 10, 11
	dc.b 12, 11, 10,  9,  8,  7,  6,  5

y_step_table:
	dc.b  4,  5,  6,  7,  8,  9, 10, 11
	dc.b 12, 11, 10,  9,  8,  7,  6,  5
	dc.b  4,  4,  4,  4,  4,  4,  4,  4
	dc.b  4,  4,  4,  4,  4,  4,  4,  4

pf_colors:
	dc.b $06, $08, $0a, $0c, $0e ; blank
	dc.b $0e, $0c, $0a, $08, $06 ; blank
	dc.b $64, $66, $68, $6a, $6c, $6e ; rouge
	dc.b $6c, $6a, $68, $66, $64 ; rouge
	dc.b $94, $96, $98, $9a, $9c, $9e ; bleu
	dc.b $9c, $9a, $98, $96, $94 ; bleu

sin_table:
	dc.b $0e, $0f, $10, $11, $11, $12, $13, $13
	dc.b $14, $15, $15, $16, $17, $17, $18, $18
	dc.b $19, $19, $1a, $1a, $1b, $1b, $1b, $1c
	dc.b $1c, $1c, $1c, $1d, $1d, $1d, $1d, $1d
	dc.b $1d, $1d, $1d, $1d, $1d, $1d, $1c, $1c
	dc.b $1c, $1c, $1b, $1b, $1b, $1a, $1a, $19
	dc.b $19, $18, $18, $17, $17, $16, $15, $15
	dc.b $14, $13, $13, $12, $11, $11, $10, $0f
	dc.b $0f, $0e, $0d, $0c, $0c, $0b, $0a, $0a
	dc.b $09, $08, $08, $07, $06, $06, $05, $05
	dc.b $04, $04, $03, $03, $02, $02, $02, $01
	dc.b $01, $01, $01, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $01, $01
	dc.b $01, $01, $02, $02, $02, $03, $03, $04
	dc.b $04, $05, $05, $06, $06, $07, $08, $08
	dc.b $09, $0a, $0a, $0b, $0c, $0c, $0d, $0e
