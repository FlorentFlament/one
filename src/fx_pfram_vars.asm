;;; Buffers for inverted picture
inv_p0		DS.B	1
inv_p1		DS.B	1

prng		DS.B	1
pf_height	DS.B	1

fb_p0	DS.B	30
fb_p1	DS.B	30

cur_p0	DS.B	1
cur_p1	DS.B	1

x_shift	DS.B	1
y_shift	DS.B	1
x_step	DS.B	1
y_step	DS.B	1

fx_state	DS.B	1
flags		DS.B	1	; bit 0 -> clear frame buffer
				; bit 1 -> Random height
pixels_cnt	DS.B	1	; moving pixels count
