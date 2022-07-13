;;; 4x slower counter
slow4x_cnt	DS.B	1

;;; Sprites pointers
sprite_a_ptr	DS.B	2
sprite_b_ptr	DS.B	2

;;; 40x40 playfield picture
pfpic_p0	DS.B	2
pfpic_p1	DS.B	2
pfpic_p2	DS.B	2
pfpic_p3	DS.B	2
pfpic_p4	DS.B	2
pfpic_p5	DS.B	2

;;; Buffers for inverted picture
inv_p0		DS.B	1
inv_p1		DS.B	1
inv_p2		DS.B	1
inv_p3		DS.B	1
inv_p4		DS.B	1
inv_p5		DS.B	1

pf_height	DS.B	1
