; test.asm (v1)
; 
; Generates a simple 12bit pattern consisting of an 8bit counter
; and a "fast" 4 bit pulse sequence
;
; target: ATmega8L
; port D: counter
; port C: short pulses
;
; For more information go to:
; http://sump.org/projects/analyzer/

.equ	PORTD = 0x12
.equ	DDRD = 0x11 
.equ	PORTC = 0x15
.equ	DDRC = 0x14

.def	a = r16
.def	h0011 = r17
.def	h0110 = r18
.def	h1001 = r19
.def	h1100 = r20
.def	h1111 = r21

;===== program =========================================================

	ldi	a, 0b11111111
	out	DDRD, a
	out	DDRC, h1111
	ldi	a, 0
	ldi	h0011, 0x03
	ldi	h0110, 0x06
	ldi	h1001, 0x09
	ldi	h1100, 0x0c
	ldi	h1111, 0x0f
	out	PORTC, h0011

loop:	out	PORTD, a
	inc	a
	brne	loop

	out	PORTC, h0110
	out	PORTC, h1001
	out	PORTC, h0011
	out	PORTC, h0011
	out	PORTC, h1100
	out	PORTC, h0011
	out	PORTC, h1111
	out	PORTC, h0011
	
	rjmp	loop

;===== eof =============================================================
