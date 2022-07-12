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
framecnt	DS.B	1	; Rolling frame counter from 0 to 255
        INCLUDE "zik_variables.asm"
ptr = tt_ptr			; Reusing tt_ptr as temporary pointer
	INCLUDE "variables.asm"
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
init:   CLEAN_START		; Initializes Registers & Memory
        INCLUDE "zik_init.asm"
	jsr fx_init

main_loop:	SUBROUTINE
	VERTICAL_SYNC		; 4 scanlines Vertical Sync signal

.vblank:
	; 34 VBlank lines (76 cycles/line)
	lda #39			; (/ (* 34.0 76) 64) = 40.375
	sta TIM64T
        INCLUDE "zik_player.asm"
	jsr fx_vblank
	jsr wait_timint

.kernel:
	; 248 Kernel lines
	lda #19			; (/ (* 248.0 76) 1024) = 18.40
	sta T1024T
	jsr fx_kernel		; scanline 33 - cycle 23
	jsr wait_timint		; scanline 289 - cycle 30

.overscan:
	; 26 Overscan lines
	lda #22			; (/ (* 26.0 76) 64) = 30.875
	sta TIM64T
	;; Update counters
	inc framecnt
	jsr fx_overscan
	jsr wait_timint

	jmp main_loop		; main_loop is far - scanline 308 - cycle 15


; X register must contain the number of scanlines to skip
; X register will have value 0 on exit
wait_timint:
	lda TIMINT
	beq wait_timint
	rts
	echo "Main   size:", (* - MAIN_CODE_START)d, "bytes - Music player size"

FX_START equ *
	INCLUDE "fx_playfield.asm"
	echo "FX     size:", (* - FX_START)d, "bytes"

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
