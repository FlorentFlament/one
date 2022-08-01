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

;;; Does rough positioning of sprite
;;; Argument: Id for the sprite (0 or 1)
;;; A : must contain Horizontal position
;;; To be used in conjunction with FINE_POSITION_SPRITE
    MAC ROUGH_POSITION_SPRITE
	sec
	; Beware ! this loop must not cross a page !
	echo "[FX position sprite Loop] P", ({1})d, "start :", *
.rough_loop:
	; The rough_loop consumes 15 (5*3) pixels
	sbc #$0f	      ; 2 cycles
	bcs .rough_loop ; 3 cycles
	echo "[FX position sprite Loop] P", ({1})d, "end :", *
	sta RESP{1}
    ENDM

;;; Fine position sprite passed as argument
;;; Argument: Id for the sprite (0 or 1)
;;; A: must contain the remaining value of rough positioning
;;; At the end:
;;; A: is destroyed
    MAC FINE_POSITION_SPRITE
	;; A register has value in [-15 .. -1]
	clc
	adc #$07 ; A in [-8 .. 6]
	eor #$ff ; A in [-7 .. 7]
    REPEAT 4
	asl
    REPEND
	sta HMP{1} ; Fine position of missile or sprite
    ENDM

;;; Position a sprite
;;; Argument: Id for the sprite (0 or 1)
;;; A : must contain Horizontal position
;;; At the end:
;;; A: is destroyed
    MAC POSITION_SPRITE
	sta WSYNC
	SLEEP 14
	ROUGH_POSITION_SPRITE {1}
	FINE_POSITION_SPRITE {1}
    ENDM

;;; Position both sprites 0 and 1
;;; X contains sprite 0 position
;;; Y contains sprite 1 position
    MAC POSITION_BOTH_SPRITES
	txa
	POSITION_SPRITE 0
	tya
	POSITION_SPRITE 1
	sta WSYNC
	sta HMOVE		; Commit sprites fine tuning
    ENDM	

    MAC SET_SPRITE
	ldx #3
.init_sprite_ptr:
	lda {1},X
	sta sprite_ptr0,X
	dex
	bpl .init_sprite_ptr
    ENDM	
	
fx_init:	SUBROUTINE
	lda #$00
	sta CTRLPF	; Don't reflect playfield to start with
	lda #$01
	sta prng	; random number generator seed

	lda #$00
	sta pixels_cnt	; moving pixels count - start with 1 pixel
	sta flags	; start without tracing trajectories

	lda #0
	sta fx_state

	lda #$fa
	sta COLUP0
	sta COLUP1

	lda #$07
	sta NUSIZ0
	sta NUSIZ1

	;; Compute sprites position
	ldx #48
	ldy #80
	POSITION_BOTH_SPRITES

	SET_SPRITE sp_empty_ptr
	rts

fx_state0:	SUBROUTINE
	lda framecnt
	cmp #$38		; 1 second (50 frames) delay
	bmi .end
	lda #$00
	sta framecnt		; Reset framecounter
	inc fx_state
.end:
	rts

fx_state1:	SUBROUTINE
	lda framecnt
	cmp #$38
	bmi .end
	lda #$00
	sta framecnt		; Reset framecounter
	lda #$01
	sta CTRLPF		; Reflect playfield to start with
	lda flags
	ora #$01		; Turn on trajectory
	sta flags
	inc fx_state
.end:
	rts


fx_state2:	SUBROUTINE
	lda framecnt+1
	cmp #1
	bcc .end
	lda flags
	and #$fe		; Remove traces
	sta flags
	inc fx_state
.end:
	rts

fx_state3:	SUBROUTINE
	inc fx_state
	rts

fx_state4:	SUBROUTINE
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

fx_state5:	SUBROUTINE
	lda framecnt+1
	cmp #$0c
	bcc .end
	inc fx_state
.end:
	rts

fx_state6:	SUBROUTINE
	;; Alternate tracing and no tracing
	;; End of fx ?
	lda framecnt+1
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

fx_state7:	SUBROUTINE
	lda #$1			; don't clear screen anymore
	sta flags
	inc fx_state
	rts

fx_state8:	SUBROUTINE
	lda framecnt+1
	cmp #$1e
	bcc .end
	lda framecnt
	cmp #$80
	bcc .end
	inc fx_state
.end:
	rts
	
fx_state9:	SUBROUTINE	; Static for a quarter cycle
	lda framecnt+1
	cmp #$1e
	bcc .end
	lda framecnt
	cmp #$c0
	bcc .end
	SET_SPRITE sp_g_16x16_ptr
	inc fx_state
.end:	
	rts

fx_state10:	SUBROUTINE	; Atari logo blinking for a half cycle
	lda framecnt+1
	cmp #$1f
	bcc .end
	lda framecnt
	cmp #$40
	bcc .end
	SET_SPRITE sp_empty_ptr
	inc fx_state
.end:	
	rts

fx_state11:	SUBROUTINE	; Static for a quarter cycle
	lda framecnt+1
	cmp #$1f
	bcc .end
	lda framecnt
	cmp #$80
	bcc .end
	SET_SPRITE sp_f_16x16_ptr
	inc fx_state
.end:	
	rts

fx_state12:	SUBROUTINE	; Atari logo blinking for a half cycle
	lda framecnt+1
	cmp #$20
	bcc .end
	lda framecnt
	cmp #$00
	bcc .end
	SET_SPRITE sp_empty_ptr
	inc fx_state
.end:	
	rts
	
fx_state13:	SUBROUTINE	; Static for a quarter cycle
	lda framecnt+1
	cmp #$20
	bcc .end
	lda framecnt
	cmp #$40
	bcc .end
	SET_SPRITE sp_atari_logo_16x16_ptr
	inc fx_state
.end:	
	rts

fx_state14:	SUBROUTINE	; Atari logo blinking for a half cycle
	lda framecnt+1
	cmp #$20
	bcc .end
	lda framecnt
	cmp #$a0
	bcc .end
	SET_SPRITE sp_empty_ptr
	inc fx_state
.end:
fx_state15:
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
	.word fx_state9 - 1
	.word fx_state10 - 1
	.word fx_state11 - 1
	.word fx_state12 - 1
	.word fx_state13 - 1
	.word fx_state14 - 1
	.word fx_state15 - 1

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
	cmp #8
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

;;; Uses ptr
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
	cmp #5
	bpl .second_half
	cmp #4
	bpl .glitchy
	cmp #2
	bmi fx_kernel_intro
	jmp fx_kernel_blocks

.second_half:
	cmp #7
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
	lda fx_state
	bne .blink_color
	lda #$fe
	sta COLUPF
	bne .continue
.blink_color:
	ldx framecnt
	lda intro_color,X
	sta COLUPF
.continue:
	ldx #29
.outer:
	ldy #3
.inner_loop:
	sta WSYNC
	lda pf_one_40x30_0,X
	sta PF0
	lda pf_one_40x30_1,X
	sta PF1
	lda pf_one_40x30_2,X
	sta PF2
	SLEEP 10
	lda pf_one_40x30_3,X
	sta PF0
	lda pf_one_40x30_4,X
	sta PF1
	lda pf_one_40x30_5,X
	sta PF2
	sta WSYNC
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	dey
	bpl .inner_loop
	dex
	bpl .outer

	sta WSYNC
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	sta COLUPF
	rts

fx_kernel_bars:	SUBROUTINE
	;; Mask for sprites
	lda flags
	and #$04
	beq .draw_sprites
	lda #$00
	beq .continue_sprites
.draw_sprites:
	lda #$ff
.continue_sprites:
	sta ptr+1		; Used as mask for sprites

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
	sta GRP0
	sta GRP1
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
	lda (sprite_ptr0),Y
	and ptr+1
	sta GRP0
	lda (sprite_ptr1),Y
	and ptr+1
	sta GRP1
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

pf_one_40x30_0:
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00
pf_one_40x30_1:
	dc.b $00, $00, $00, $00, $3d, $00, $20, $20
	dc.b $00, $20, $20, $20, $37, $00, $00, $00
	dc.b $0f, $00, $00, $00, $20, $20, $20, $28
	dc.b $20, $20, $2c, $00, $00, $00
pf_one_40x30_2:
	dc.b $00, $00, $00, $00, $13, $12, $12, $02
	dc.b $12, $12, $10, $12, $73, $00, $00, $00
	dc.b $ff, $00, $00, $00, $4d, $41, $41, $41
	dc.b $41, $41, $41, $00, $00, $00
pf_one_40x30_3:
	dc.b $00, $00, $00, $00, $80, $00, $80, $80
	dc.b $80, $80, $00, $80, $f0, $00, $00, $00
	dc.b $f0, $00, $00, $00, $30, $20, $20, $20
	dc.b $20, $20, $20, $00, $00, $00
pf_one_40x30_4:
	dc.b $00, $00, $00, $00, $2f, $20, $00, $20
	dc.b $37, $20, $20, $20, $3b, $00, $00, $00
	dc.b $ff, $00, $00, $00, $f2, $02, $12, $f2
	dc.b $02, $82, $f2, $00, $00, $00
pf_one_40x30_5:
	dc.b $00, $00, $00, $00, $02, $00, $00, $00
	dc.b $03, $02, $00, $02, $03, $00, $00, $00
	dc.b $00, $00, $00, $00, $02, $02, $02, $03
	dc.b $02, $02, $02, $00, $00, $00

intro_color:
	dc.b $fe, $00, $00, $00, $fe, $fe, $fe
	dc.b $fe, $fe, $fe, $fe, $fe, $fe, $fe
	dc.b $fe, $00, $00, $00, $fe, $fe, $fe
	dc.b $fe, $fe, $fe, $fe, $fe, $fe, $fe
	dc.b $fe, $00, $00, $00, $fe, $fe, $fe
	dc.b $fe, $00, $00, $00, $fe, $fe, $fe
	dc.b $fe, $00, $00, $00, $fe, $fe, $fe
	dc.b $fe, $fe, $fe, $fe, $fe, $fe, $fe

sp_empty_0:
	dc.b $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00
sp_empty_ptr:
	dc.w sp_empty_0
	dc.w sp_empty_0

sp_atari_logo_16x16_0:
	dc.b $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $c1, $31, $19, $0d, $05, $05
	dc.b $05, $05, $05, $05, $05, $05, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00
sp_atari_logo_16x16_1:
	dc.b $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $83, $8c, $98, $b0, $a0, $a0
	dc.b $a0, $a0, $a0, $a0, $a0, $a0, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $00
sp_atari_logo_16x16_ptr:
	dc.w sp_atari_logo_16x16_0
	dc.w sp_atari_logo_16x16_1


sp_g_16x16_0:
	dc.b $00, $00, $00, $00, $00, $00, $00
	dc.b $3f, $3f, $fc, $fc, $fc, $fc, $fc, $fc
	dc.b $fc, $fc, $fc, $fc, $fc, $fc, $3f, $3f
	dc.b $00, $00, $00, $00, $00, $00, $00
sp_g_16x16_1:
	dc.b $00, $00, $00, $00, $00, $00, $00
	dc.b $ff, $ff, $3f, $3f, $3f, $3f, $ff, $ff
	dc.b $ff, $00, $00, $00, $00, $00, $ff, $ff
	dc.b $00, $00, $00, $00, $00, $00, $00
sp_g_16x16_ptr:
	dc.w sp_g_16x16_0
	dc.w sp_g_16x16_1

sp_f_16x16_0:
	dc.b $00, $00, $00, $00, $00, $00, $00
	dc.b $78, $78, $78, $78, $78, $78, $7f, $7f
	dc.b $7f, $78, $78, $78, $78, $7f, $1f, $1f
	dc.b $00, $00, $00, $00, $00, $00, $00
sp_f_16x16_1:
	dc.b $00, $00, $00, $00, $00, $00, $00
	dc.b $00, $00, $00, $00, $00, $00, $c0, $c0
	dc.b $c0, $00, $00, $00, $00, $fe, $fe, $fe
	dc.b $00, $00, $00, $00, $00, $00, $00
sp_f_16x16_ptr:
	dc.w sp_f_16x16_0
	dc.w sp_f_16x16_1
