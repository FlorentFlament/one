; A must contain the previous value of the xor_shift
; A contains the new xor_shift value on return
; Note: ptr is overwritten
    MAC XOR_SHIFT
	sta ptr
	asl
	eor ptr
	sta ptr
	lsr
	eor ptr
	sta ptr
	asl
	asl
	eor ptr
    ENDM

fx_init:	SUBROUTINE
	lda #$01
	sta CTRLPF	; Reflect playfield
	sta prng	; random number generator seed

	lda #$00
	sta pixels_cnt	; moving pixels count - start with 1 pixel
	lda #$00	; start without tracing trajectories
	sta flags
	rts

fx_state0:	SUBROUTINE
	lda framecnt
	cmp #$38
	bmi .end
	lda #$00
	sta framecnt		; Reset framecounter
	lda flags
	ora #$01		; Turn on trajectory
	sta flags
	inc fx_state
.end:
	rts


fx_state1:	SUBROUTINE
	lda framecnt+1
	cmp #1
	bcc .end
	lda flags
	and #$fe		; Remove traces
	sta flags
	inc fx_state
.end:
	rts

fx_state2:	SUBROUTINE
	inc fx_state
	rts

fx_state3:	SUBROUTINE
	lda pixels_cnt
	cmp #11
	bne .more_pixels
	lda flags
	ora #$02		; Ramdom height
	sta flags
	inc fx_state
	beq .end		; inconditional
.more_pixels:
	lda framecnt
	and #$7f
	bne .end
	inc pixels_cnt
.end:
	rts

fx_state4:	SUBROUTINE
	lda framecnt+1
	cmp #$0c
	bcc .end
	lda framecnt
	cmp #$00
	bcc .end
	inc fx_state
.end:
	rts

fx_state5:	SUBROUTINE
	;; Alternate tracing and no tracing
	;; End of fx ?
	lda framecnt+1
	and #$1f
	cmp #$1e
	bne .continue
	inc fx_state
	lda #$1			; Only one pixel
	sta pixels_cnt		;
	lda #$0			; ensure screen is cleared
	bne .end
.continue:
	lda framecnt+1
	and #$01
	beq .no_traces
	lda flags
	ora #$01		; bit0 (clear fb)->1
	bne .end		; inconditional
.no_traces:
	lda flags
	and #$fe		; bit0 ->0
.end:
	sta flags
	rts

fx_state6:	SUBROUTINE
	lda #$1			; don't clear screen anymore
	sta flags
	inc fx_state
	rts

fx_state7:	SUBROUTINE
	lda framecnt+1
	cmp #$1e
	bcc .end
	lda framecnt
	cmp #$80
	bcc .end
	inc fx_state
.end:
fx_state8:	SUBROUTINE
	rts

fx_state_ptrs:
	.word fx_state0 - 1
	.word fx_state1 - 1
	.word fx_state2 - 1
	.word fx_state3 - 1
	.word fx_state4 - 1
	.word fx_state5 - 1
	.word fx_state6 - 1
	.word fx_state7 - 1
	.word fx_state8 - 1

call_current_state:	SUBROUTINE
	lda fx_state
	asl
	tax
	lda fx_state_ptrs+1,X
	pha
	lda fx_state_ptrs,X
	pha
	rts

fx_overscan:
	;; update random number
	lda prng
	XOR_SHIFT
	sta prng

	;;  Choose kernel to display
	lda framecnt
	and #$3
	bne .skip_kernel_update
	lda prng		; Update flag randomly
	and #$03
	bne .most_probable
.less_probable:
	lda flags
	and #$fb		; bit2->0
	sta flags
	jmp .skip_kernel_update
.most_probable:
	lda flags
	ora #$04		; bit2->1
	sta flags
.skip_kernel_update:

	;; Clear framebuffer or not
	lda flags
	and #$01
	bne .end_clear
	lda #$00
	ldx #29
.clear_loop:
	sta fb_p0,X
	sta fb_p1,X
	dex
	bpl .clear_loop
.end_clear:

	;; Shape of trajectory
	lda fx_state
	cmp #7
	bpl .final_state
	lda framecnt+1
	jmp .state_set
.final_state:
	lda #0
.state_set:
	and #$1f
	tax
	lda x_step_table,X
	sta x_step
	lda y_step_table,X
	sta y_step

	;; Height of bars
	lda flags
	and #$02
	bne .random_height
	lda #3
	sta pf_height
	bne .skip		; unconditional
.random_height:
	lda framecnt
	and #$03
	bne .skip
	lda prng
	and #$07
	sta pf_height
.skip:

	jsr call_current_state
	rts

;;; X and Y shift should be in ptr and ptr+1 respectively
;;; At the end X and Y coordinante are in ptr and ptr+1
    MAC FB_FETCH_POINT
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
    ENDM

;;; X and Y coordinante are in ptr and ptr+1
    MAC FB_DRAW_POINT
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
    ENDM

;;; Updates ptr, ptr+1
;;; And cur_p0, cur_p1
    MAC FETCH_N_DRAW
	lda {1}
	sta ptr
	lda {2}
	sta ptr+1
	FB_FETCH_POINT
	FB_DRAW_POINT
    ENDM

    MAC FB_ROTATING_POINTS
	lda #0
	sta x_shift
	lda #32
	sta y_shift

	ldy pixels_cnt		; up to #11
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
    ENDM

fx_vblank: SUBROUTINE
	FB_ROTATING_POINTS
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
	lda fx_state
	cmp #4
	bpl .second_half
	cmp #3
	bpl .glitchy
	cmp #1
	bmi fx_kernel_intro
	jmp fx_kernel_blocks

.second_half:
	cmp #6
	bmi .glitchest
.end_one:
	jmp fx_kernel_bars
.glitchest:
	lda flags
	and #$04
	bne fx_kernel_bars
	jmp fx_kernel_blocks
.glitchy:
	lda flags
	and #$04
	bne .trick
	beq fx_kernel_bars	; unconditional
.trick:
	jmp fx_kernel_blocks

fx_kernel_intro:	SUBROUTINE
	rts

fx_kernel_bars:	SUBROUTINE
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

fx_kernel_blocks:	SUBROUTINE
	ldy #29			; 30 lines. Y can be used to indirect fetch
.outer:
	sta WSYNC
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	CHOOSE_COLOR
	ldx #6
.inner_loop:
	sta WSYNC
	lda #$00
	sta PF0
	lda fb_p0,Y
	sta PF1
	lda fb_p1,Y
	sta PF2
	dex
	bpl .inner_loop
	dey
	bpl .outer

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
	dc.b  4,  4,  5,  6,  7,  8,  9, 10, 11 ; avoid double screen
	dc.b 12, 11, 10,  9,  8,  7,  6

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
