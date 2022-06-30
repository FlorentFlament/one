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
	rts
    ENDM	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Functions used in main ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
fx_init:	SUBROUTINE
	;; Sprites size
	lda #$07
	sta NUSIZ0
	sta NUSIZ1
	;; no reflection
	lda #$00
	sta REFP0
	sta REFP1
	;; no playfield
	lda #$00
	sta PF0
	sta PF1
	sta PF2
	;; Set colors
	lda #$00
	sta COLUPF		; in case
	lda #$00
	sta COLUP0
	lda #$fe
	sta COLUP1
	rts

fx_vblank:	SUBROUTINE
	;; Choose Lemming sprite to display
	lda framecnt
	REPEAT 3
	lsr
	REPEND
	and #$03
	tax
	lda lemming_sprite_timeline_lb,X
	sta sprite_a_ptr
	lda lemming_sprite_timeline_hb,X
	sta sprite_a_ptr+1
	lda lemming_sprite_timeline_lw,X
	sta sprite_b_ptr
	lda lemming_sprite_timeline_hw,X
	sta sprite_b_ptr+1

	;; Compute sprites position
	lda framecnt
	lsr
	tax
	tay
	POSITION_BOTH_SPRITES
	rts

fx_kernel:	SUBROUTINE
	sta WSYNC
	lda #$96
	sta COLUBK

	ldy #15
.loop_middle_ext:
	lda #7
	sta ptr
.loop_middle_int:
	sta WSYNC
	lda (sprite_a_ptr),Y
	sta GRP0
	lda (sprite_b_ptr),Y
	sta GRP1
	inx
	dec ptr
	bpl .loop_middle_int
	dey
	bpl .loop_middle_ext

	sta WSYNC
	lda #$00
	sta COLUBK
	sta COLUPF
	rts

fx_overscan:	SUBROUTINE
	rts

;;; Lemming sprites animation
lemming_sprite_timeline_lb:
	dc.b #<sprite_lemming_1b
	dc.b #<sprite_lemming_2b
	dc.b #<sprite_lemming_3b
	dc.b #<sprite_lemming_4b
lemming_sprite_timeline_hb:
	dc.b #>sprite_lemming_1b
	dc.b #>sprite_lemming_2b
	dc.b #>sprite_lemming_3b
	dc.b #>sprite_lemming_4b
lemming_sprite_timeline_lw:
	dc.b #<sprite_lemming_1w
	dc.b #<sprite_lemming_2w
	dc.b #<sprite_lemming_3w
	dc.b #<sprite_lemming_4w
lemming_sprite_timeline_hw:
	dc.b #>sprite_lemming_1w
	dc.b #>sprite_lemming_2w
	dc.b #>sprite_lemming_3w
	dc.b #>sprite_lemming_4w

sprite_lemming_1b:
	dc.b $00, $00, $00, $00, $00, $30, $18, $18
	dc.b $18, $08, $00, $30, $38, $14, $00, $00
sprite_lemming_1w:
	dc.b $00, $00, $00, $00, $30, $04, $02, $22
	dc.b $20, $10, $1c, $08, $00, $00, $00, $00
sprite_lemming_2b:
	dc.b $00, $00, $00, $00, $00, $3c, $1c, $18
	dc.b $08, $00, $10, $38, $28, $00, $00, $00
sprite_lemming_2w:
	dc.b $00, $00, $00, $00, $66, $00, $60, $20
	dc.b $30, $1c, $08, $00, $00, $00, $00, $00
sprite_lemming_3b:
	dc.b $00, $00, $00, $00, $00, $3c, $18, $18
	dc.b $08, $08, $20, $34, $18, $00, $00, $00
sprite_lemming_3w:
	dc.b $00, $00, $00, $00, $4c, $40, $00, $20
	dc.b $10, $10, $1c, $08, $00, $00, $00, $00
sprite_lemming_4b:
	dc.b $00, $00, $00, $00, $00, $18, $18, $08
	dc.b $08, $08, $00, $30, $3c, $00, $00, $00
sprite_lemming_4w:
	dc.b $00, $00, $00, $00, $18, $20, $00, $10
	dc.b $10, $10, $1c, $08, $00, $00, $00, $00
