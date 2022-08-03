;;;-----------------------------------------------------------------------------
;;; Header

	PROCESSOR 6502
	INCLUDE "vcs.h"		; Provides RIOT & TIA memory map
	INCLUDE "macro.h"	; This file includes some helper macros

;;;-----------------------------------------------------------------------------
;;; RAM segment

	SEG.U   ram
	ORG     $0080

	echo ""
	echo "-RAM-"
framecnt	DS.B	2	; 2 bytes rolling frame counter
        INCLUDE "zik_variables.asm"
ptr = tt_ptr			; Reusing tt_ptr as temporary pointer
	INCLUDE "fx_pfram_vars.asm"
        echo "Used RAM:", (* - $0080)d, "bytes"

;;;-----------------------------------------------------------------------------
;;; Code segment

	SEG code
	ORG $F000

	;; Loading aligned (and non-aligned) data
	echo ""
	echo "-DATA-"

        INCLUDE "zik_trackdata.asm"

	echo ""
	echo "-CODE-"

MAIN_CODE_START equ *

zik_player:
        INCLUDE "zik_player.asm"
	rts

init:   CLEAN_START		; Initializes Registers & Memory
        INCLUDE "zik_init.asm"
	jsr fx_init

main_loop:	SUBROUTINE
	VERTICAL_SYNC		; 4 scanlines Vertical Sync signal

.vblank:
	;; 76 cycles/line
	;; 38 lines
	lda #48
	sta TIM64T
	lda fx_state
	beq .no_zik		; No music on state 0
	cmp #15
	bpl .no_zik
.do_play:
	jsr zik_player
	jmp .continue_vblank
.no_zik:
	lda #$00
	sta AUDV0
	sta AUDV1

.continue_vblank:
	jsr fx_vblank
	jsr wait_timint

.kernel:
	;; 256 lines
	lda #19
	sta T1024T
	jsr fx_kernel		; scanline 33 - cycle 23
	jsr wait_timint		; scanline 289 - cycle 30

.overscan:
	;; 18 lines
	lda #13			; (/ (* 26.0 76) 64) = 30.875
	sta TIM64T
	;; Update counters
	inc framecnt
	bne .continue
	inc framecnt + 1 	; if framecnt drops to 0
.continue:
	jsr fx_overscan
	jsr wait_timint

	jmp main_loop		; main_loop is far - scanline 308 - cycle 15


; X register must contain the number of scanlines to skip
; X register will have value 0 on exit
wait_timint:
	lda TIMINT
	beq wait_timint
	rts
	echo "Main size:", (* - MAIN_CODE_START)d, "bytes (including music player)"

FX_START equ *
	INCLUDE "fx_pfram.asm"
	echo "FX size:", (* - FX_START)d, "bytes (including fx data)"

	echo ""
	echo "-TOTAL-"
	echo "Used ROM:", (* - $F000)d, "bytes"
	echo "Remaining ROM:", ($FFFC - *)d, "bytes"

;;;-----------------------------------------------------------------------------
;;; Reset Vector

	SEG reset
	ORG $FFFC
	DC.W init
	DC.W init
