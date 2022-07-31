; TIATracker music player
; Copyright 2016 Andre "Kylearan" Wichmann
; Website: https://bitbucket.org/kylearan/tiatracker
; Email: andre.wichmann@gmx.de
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;   http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

; Song author: Glafouk
; Song name: Ngingedwa ebumnyameni

; @com.wudsn.ide.asm.hardware=ATARI2600

; =====================================================================
; TIATracker melodic and percussion instruments, patterns and sequencer
; data.
; =====================================================================
tt_TrackDataStart:

; =====================================================================
; Melodic instrument definitions (up to 7). tt_envelope_index_c0/1 hold
; the index values into these tables for the current instruments played
; in channel 0 and 1.
; 
; Each instrument is defined by:
; - tt_InsCtrlTable: the AUDC value
; - tt_InsADIndexes: the index of the start of the ADSR envelope as
;       defined in tt_InsFreqVolTable
; - tt_InsSustainIndexes: the index of the start of the Sustain phase
;       of the envelope
; - tt_InsReleaseIndexes: the index of the start of the Release phase
; - tt_InsFreqVolTable: The AUDF frequency and AUDV volume values of
;       the envelope
; =====================================================================

; Instrument master CTRL values
tt_InsCtrlTable:
        dc.b $06, $07, $0f


; Instrument Attack/Decay start indexes into ADSR tables.
tt_InsADIndexes:
        dc.b $00, $04, $0a


; Instrument Sustain start indexes into ADSR tables
tt_InsSustainIndexes:
        dc.b $00, $05, $0a


; Instrument Release start indexes into ADSR tables
; Caution: Values are stored with an implicit -1 modifier! To get the
; real index, add 1.
tt_InsReleaseIndexes:
        dc.b $01, $06, $0b


; AUDVx and AUDFx ADSR envelope values.
; Each byte encodes the frequency and volume:
; - Bits 7..4: Freqency modifier for the current note ([-8..7]),
;       8 means no change. Bit 7 is the sign bit.
; - Bits 3..0: Volume
; Between sustain and release is one byte that is not used and
; can be any value.
; The end of the release phase is encoded by a 0.
tt_InsFreqVolTable:
; 0: bass
        dc.b $8f, $00, $8f, $00
; 1: bassMel2
        dc.b $87, $87, $00, $87, $87, $00
; 2: bassMel
        dc.b $87, $00, $87, $00



; =====================================================================
; Percussion instrument definitions (up to 15)
;
; Each percussion instrument is defined by:
; - tt_PercIndexes: The index of the first percussion frame as defined
;       in tt_PercFreqTable and tt_PercCtrlVolTable
; - tt_PercFreqTable: The AUDF frequency value
; - tt_PercCtrlVolTable: The AUDV volume and AUDC values
; =====================================================================

; Indexes into percussion definitions signifying the first frame for
; each percussion in tt_PercFreqTable.
; Caution: Values are stored with an implicit +1 modifier! To get the
; real index, subtract 1.
tt_PercIndexes:
        dc.b $01, $05, $14


; The AUDF frequency values for the percussion instruments.
; If the second to last value is negative (>=128), it means it's an
; "overlay" percussion, i.e. the player fetches the next instrument note
; immediately and starts it in the sustain phase next frame. (Needs
; TT_USE_OVERLAY)
tt_PercFreqTable:
; 0: HH
        dc.b $00, $02, $00, $00
; 1: KickRegular
        dc.b $03, $01, $03, $04, $04, $05, $05, $06
        dc.b $06, $07, $08, $0a, $0e, $14, $00
; 2: Snare
        dc.b $07, $09, $0b, $0d, $0f, $11, $13, $15
        dc.b $17, $19, $1b, $1d, $1e, $1f, $00


; The AUDCx and AUDVx volume values for the percussion instruments.
; - Bits 7..4: AUDC value
; - Bits 3..0: AUDV value
; 0 means end of percussion data.
tt_PercCtrlVolTable:
; 0: HH
        dc.b $85, $83, $82, $00
; 1: KickRegular
        dc.b $ef, $ee, $ed, $ec, $eb, $ea, $e9, $e8
        dc.b $e7, $e6, $e5, $e4, $e3, $e2, $00
; 2: Snare
        dc.b $8f, $8e, $8d, $8c, $8b, $8a, $89, $88
        dc.b $87, $86, $85, $84, $83, $82, $00


        
; =====================================================================
; Track definition
; The track is defined by:
; - tt_PatternX (X=0, 1, ...): Pattern definitions
; - tt_PatternPtrLo/Hi: Pointers to the tt_PatternX tables, serving
;       as index values
; - tt_SequenceTable: The order in which the patterns should be played,
;       i.e. indexes into tt_PatternPtrLo/Hi. Contains the sequences
;       for all channels and sub-tracks. The variables
;       tt_cur_pat_index_c0/1 hold an index into tt_SequenceTable for
;       each channel.
;
; So tt_SequenceTable holds indexes into tt_PatternPtrLo/Hi, which
; in turn point to pattern definitions (tt_PatternX) in which the notes
; to play are specified.
; =====================================================================

; ---------------------------------------------------------------------
; Pattern definitions, one table per pattern. tt_cur_note_index_c0/1
; hold the index values into these tables for the current pattern
; played in channel 0 and 1.
;
; A pattern is a sequence of notes (one byte per note) ending with a 0.
; A note can be either:
; - Pause: Put melodic instrument into release. Must only follow a
;       melodic instrument.
; - Hold: Continue to play last note (or silence). Default "empty" note.
; - Slide (needs TT_USE_SLIDE): Adjust frequency of last melodic note
;       by -7..+7 and keep playing it
; - Play new note with melodic instrument
; - Play new note with percussion instrument
; - End of pattern
;
; A note is defined by:
; - Bits 7..5: 1-7 means play melodic instrument 1-7 with a new note
;       and frequency in bits 4..0. If bits 7..5 are 0, bits 4..0 are
;       defined as:
;       - 0: End of pattern
;       - [1..15]: Slide -7..+7 (needs TT_USE_SLIDE)
;       - 8: Hold
;       - 16: Pause
;       - [17..31]: Play percussion instrument 1..15
;
; The tracker must ensure that a pause only follows a melodic
; instrument or a hold/slide.
; ---------------------------------------------------------------------
TT_FREQ_MASK    = %00011111
TT_INS_HOLD     = 8
TT_INS_PAUSE    = 16
TT_FIRST_PERC   = 17

; drum0e
tt_pattern0:
        dc.b $11, $11, $11, $11, $11, $11, $11, $11
        dc.b $00

; bass0a
tt_pattern1:
        dc.b $31, $08, $08, $08, $10, $08, $31, $08
        dc.b $28, $08, $08, $08, $10, $08, $31, $08
        dc.b $10, $08, $31, $08, $10, $08, $31, $08
        dc.b $28, $08, $08, $08, $29, $08, $28, $08
        dc.b $00

; bass0b
tt_pattern2:
        dc.b $2e, $08, $08, $08, $10, $08, $31, $08
        dc.b $2e, $08, $08, $08, $10, $08, $2e, $08
        dc.b $10, $08, $2e, $08, $10, $08, $2e, $08
        dc.b $2f, $08, $08, $08, $2e, $08, $31, $08
        dc.b $00

; bass0c
tt_pattern3:
        dc.b $29, $08, $08, $08, $10, $08, $2b, $08
        dc.b $29, $08, $08, $08, $10, $08, $2e, $08
        dc.b $10, $08, $2e, $08, $10, $08, $2e, $08
        dc.b $2f, $08, $08, $08, $2e, $08, $28, $08
        dc.b $00

; bass0d
tt_pattern4:
        dc.b $29, $08, $08, $08, $10, $08, $2b, $08
        dc.b $29, $08, $08, $08, $10, $08, $28, $08
        dc.b $10, $08, $28, $08, $10, $08, $29, $08
        dc.b $28, $08, $08, $08, $29, $08, $28, $08
        dc.b $00

; bass0a+mel0a
tt_pattern5:
        dc.b $31, $08, $08, $08, $47, $45, $31, $48
        dc.b $28, $08, $42, $43, $45, $44, $31, $08
        dc.b $40, $08, $31, $08, $42, $41, $31, $08
        dc.b $28, $08, $42, $08, $29, $42, $28, $48
        dc.b $00

; bass0b+mel0a
tt_pattern6:
        dc.b $2e, $08, $08, $08, $45, $49, $31, $48
        dc.b $2e, $08, $41, $42, $48, $49, $2e, $08
        dc.b $40, $08, $2e, $08, $40, $08, $2e, $08
        dc.b $2f, $08, $41, $08, $2e, $42, $31, $43
        dc.b $00

; bass0c+mel0a
tt_pattern7:
        dc.b $29, $08, $08, $08, $40, $08, $2b, $41
        dc.b $29, $08, $44, $43, $45, $08, $2e, $08
        dc.b $42, $08, $2e, $08, $42, $08, $2e, $08
        dc.b $2f, $08, $41, $42, $2e, $44, $28, $40
        dc.b $00

; bass0d+mel0a
tt_pattern8:
        dc.b $29, $08, $08, $08, $40, $08, $2b, $40
        dc.b $29, $08, $41, $42, $41, $43, $28, $08
        dc.b $48, $45, $28, $08, $49, $4b, $29, $49
        dc.b $28, $08, $40, $41, $29, $44, $28, $42
        dc.b $00

; vide
tt_pattern9:
        dc.b $08, $08, $08, $08, $08, $08, $08, $08
        dc.b $00

; intro
tt_pattern10:
        dc.b $12, $08, $12, $08, $12, $12, $12, $08
        dc.b $00

; drum0a
tt_pattern11:
        dc.b $12, $12, $11, $11, $13, $08, $11, $12
        dc.b $11, $11, $12, $11, $13, $08, $11, $11
        dc.b $12, $12, $11, $11, $13, $08, $11, $12
        dc.b $11, $11, $12, $11, $13, $12, $11, $13
        dc.b $00

; drum0b
tt_pattern12:
        dc.b $12, $12, $11, $11, $13, $08, $11, $12
        dc.b $11, $11, $12, $11, $13, $08, $11, $11
        dc.b $12, $12, $11, $11, $13, $08, $11, $12
        dc.b $11, $11, $12, $11, $13, $12, $12, $12
        dc.b $00

; drum0c
tt_pattern13:
        dc.b $12, $12, $11, $11, $13, $08, $11, $12
        dc.b $11, $11, $12, $11, $13, $08, $11, $11
        dc.b $11, $11, $11, $11, $11, $11, $11, $12
        dc.b $11, $11, $12, $11, $13, $12, $12, $12
        dc.b $00

; drum0a+mel0a
tt_pattern14:
        dc.b $12, $12, $63, $64, $13, $69, $68, $12
        dc.b $22, $61, $12, $62, $13, $60, $62, $61
        dc.b $12, $12, $68, $67, $13, $08, $69, $12
        dc.b $25, $62, $12, $63, $13, $12, $60, $13
        dc.b $00

; drum0b+mel0a
tt_pattern15:
        dc.b $12, $12, $63, $64, $13, $69, $68, $12
        dc.b $22, $61, $12, $62, $13, $60, $62, $61
        dc.b $12, $12, $68, $67, $13, $08, $69, $12
        dc.b $25, $62, $12, $63, $13, $12, $60, $12
        dc.b $00

; drum0b+mel0b
tt_pattern16:
        dc.b $12, $12, $60, $61, $13, $62, $61, $12
        dc.b $22, $61, $12, $64, $13, $65, $64, $67
        dc.b $12, $12, $61, $60, $13, $08, $62, $12
        dc.b $25, $61, $12, $63, $13, $12, $60, $12
        dc.b $00

; drum0c+mel0b
tt_pattern17:
        dc.b $12, $12, $60, $61, $13, $62, $61, $12
        dc.b $22, $61, $12, $64, $13, $65, $64, $11
        dc.b $11, $11, $11, $60, $66, $65, $62, $12
        dc.b $25, $61, $12, $63, $13, $12, $60, $12
        dc.b $00

; drum0d+mela
tt_pattern18:
        dc.b $63, $11, $63, $11, $11, $63, $62, $11
        dc.b $62, $08, $08, $11, $11, $11, $11, $11
        dc.b $60, $62, $61, $11, $65, $08, $64, $12
        dc.b $11, $11, $12, $11, $13, $12, $12, $12
        dc.b $00

; drum0d+melaOutro
tt_pattern19:
        dc.b $63, $11, $63, $11, $11, $63, $62, $11
        dc.b $62, $08, $08, $11, $11, $11, $11, $11
        dc.b $60, $62, $61, $11, $65, $08, $64, $08
        dc.b $08, $08, $12, $12, $12, $31, $20, $31
        dc.b $00




; Individual pattern speeds (needs TT_GLOBAL_SPEED = 0).
; Each byte encodes the speed of one pattern in the order
; of the tt_PatternPtr tables below.
; If TT_USE_FUNKTEMPO is 1, then the low nibble encodes
; the even speed and the high nibble the odd speed.
    IF TT_GLOBAL_SPEED = 0
tt_PatternSpeeds:
%%PATTERNSPEEDS%%
    ENDIF


; ---------------------------------------------------------------------
; Pattern pointers look-up table.
; ---------------------------------------------------------------------
tt_PatternPtrLo:
        dc.b <tt_pattern0, <tt_pattern1, <tt_pattern2, <tt_pattern3
        dc.b <tt_pattern4, <tt_pattern5, <tt_pattern6, <tt_pattern7
        dc.b <tt_pattern8, <tt_pattern9, <tt_pattern10, <tt_pattern11
        dc.b <tt_pattern12, <tt_pattern13, <tt_pattern14, <tt_pattern15
        dc.b <tt_pattern16, <tt_pattern17, <tt_pattern18, <tt_pattern19

tt_PatternPtrHi:
        dc.b >tt_pattern0, >tt_pattern1, >tt_pattern2, >tt_pattern3
        dc.b >tt_pattern4, >tt_pattern5, >tt_pattern6, >tt_pattern7
        dc.b >tt_pattern8, >tt_pattern9, >tt_pattern10, >tt_pattern11
        dc.b >tt_pattern12, >tt_pattern13, >tt_pattern14, >tt_pattern15
        dc.b >tt_pattern16, >tt_pattern17, >tt_pattern18, >tt_pattern19
        


; ---------------------------------------------------------------------
; Pattern sequence table. Each byte is an index into the
; tt_PatternPtrLo/Hi tables where the pointers to the pattern
; definitions can be found. When a pattern has been played completely,
; the next byte from this table is used to get the address of the next
; pattern to play. tt_cur_pat_index_c0/1 hold the current index values
; into this table for channels 0 and 1.
; If TT_USE_GOTO is used, a value >=128 denotes a goto to the pattern
; number encoded in bits 6..0 (i.e. value AND %01111111).
; ---------------------------------------------------------------------
tt_SequenceTable:
        ; ---------- Channel 0 ----------
        dc.b $00, $01, $01, $02, $03, $01, $01, $02
        dc.b $04, $01, $01, $02, $03, $01, $01, $02
        dc.b $04, $05, $05, $06, $07, $05, $05, $06
        dc.b $08, $05, $05, $06, $07, $05, $05, $06
        dc.b $08, $05, $05, $06, $07, $05, $05, $06
        dc.b $08, $09, $a9

        
        ; ---------- Channel 1 ----------
        dc.b $0a, $0b, $0c, $0b, $0c, $0b, $0c, $0b
        dc.b $0d, $0e, $0f, $0e, $10, $0e, $0f, $0e
        dc.b $11, $0e, $0f, $0e, $10, $0e, $0f, $0e
        dc.b $11, $0e, $0e, $0f, $11, $0e, $0f, $10
        dc.b $12, $0b, $0c, $0b, $0d, $00, $00, $00
        dc.b $00, $00, $00, $00, $00, $00, $00, $00
        dc.b $00, $13, $09, $dd


        echo "Track size: ", *-tt_TrackDataStart
