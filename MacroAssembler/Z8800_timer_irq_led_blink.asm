        cpu Z88C00

	include "include/regz8.inc"

CTVAL_H	equ	0FFh	; 19660800 / 4 / 8000 = 
CTVAL_L	equ	0FFh	; 

; --------------------------------------------------------------------------------------------------------------
; Interrupt vector
; --------------------------------------------------------------------------------------------------------------
INTR0:	DW	BADIRQV
INTR1:	DW	BADIRQV
INTR2:	DW	BADIRQV
INTR3:	DW	BADIRQV
INTR4:	DW	BADIRQV
INTR5:	DW	BADIRQV
INTR6:	DW	TIMER0
INTR7:	DW	BADIRQV
INTR8:	DW	BADIRQV
INTR9:	DW	BADIRQV
INTR10:	DW	BADIRQV
INTR11:	DW	BADIRQV
INTR12:	DW	BADIRQV
INTR13:	DW	BADIRQV
INTR14:	DW	BADIRQV
INTR15:	DW	BADIRQV

; --------------------------------------------------------------------------------------------------------------
; main routine (loop)
; --------------------------------------------------------------------------------------------------------------
	ORG	0020H
	JR	START1

START1:
	DI	; disable interrupt
	SB0

; Port init
	LD	P4, #10101010B
	LD	P4D, #00000000B
	LD	P4OD, #00000000B

	CLR	P2AM
	CLR	P2BM
	CLR	P2CM
	CLR	P2DM

; General settings
	LD	EMT, #00000000B	; P34 = normal I/O, Slow memory timing = disabled, ROM no wait, RAM no wait, stack = register, DMA = register

; Set Reg. pointer
	LD	RP0, #0C0H
	LD	RP1, #0C8H

; Set stack
	LD	SPH, #00h
	LD	SPL, #0FFh

; Clear stack
	LD	SPH, #0FFH
CSZ:
	CLR	@SPH
	DEC	SPH
	JR	NZ, CSZ
	CLR	@SPH

; Set interrupt
	LD	SYM, #00000000B	; all interrupt disable
	LD	IPR, #00000010B	; Set priority, B > C > A, IRQ(2 > 3 > 4) > (5 > 6 > 7) > (0 > 1)
	LD	IMR, #00000100B	; Level 2 irq enable
	
; Set Timer
	SB1
	LD	C0TCH, #CTVAL_H	; Set counter val
	LD	C0TCL, #CTVAL_L
	LD	C0M, #00000100B	; Set no-capture
	
	SB0
	LD	C0CT, #10100101B	; Continuous, count-down, load counter, zero count irq enable, enable counter

; Enable interrupt
	EI

	COM	P4	; debug

	LDW	RR0, #0000h

loop:
	NOP
	JR	loop

TIMER0:
	INC	P4
	OR	C0CT, #00000010B	; Reset overflow interrupt flag
INTRET:
	IRET

BADIRQV:
	LD	P4, #11110000B
	IRET


	END
	
