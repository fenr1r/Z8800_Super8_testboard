        cpu Z88C00

	include "include/regz8.inc"

CTVAL0_H	equ	000h	; 19660800 / 4 / 8000 = 
CTVAL0_L	equ	013h	; 

CTVAL1_H	equ	0FFh	; 19660800 / 4 / 8000 = 
CTVAL1_L	equ	0FFh	; 

MPTR	equ	RR8

RAMVAL1	equ	0A000h	; RAM address is from 0x8000 to 0xFFFF

RAM_SMPCNT	equ	0B000h	; RAM address is from 0x8000 to 0xFFFF


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
INTR7:	DW	TIMER1
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

; General settings
	LD	EMT, #00000001B	; P34 = normal I/O, Slow memory timing = disabled, ROM no wait, RAM no wait, stack = register, DMA = RAM

; Port 0 set as address
	LD	P0, #00H
	LD	P0M, #11111111B	; All address (not I/O)
	LD	PM, #00110000B	; Port 1 = Address/data, disable DM (P3_5), port 0 and 1 = push-pull, port 0 = output
	LD	H1C, #00000000B	; Handshake disabled at port 0

; Port init
	LD	P4, #10101010B
	LD	P4D, #00000000B
	LD	P4OD, #00000000B

	; Port 2 is all output
	CLR	P2

	LD	P2AM, #10001010B	; P31 = output (UART_TX), P30 = input (UART_RX)
	LD	P2BM, #00001010B
	LD	P2CM, #00001010B
	LD	P2DM, #00001010B

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
	LD	IMR, #00100100B	; Level 2 (timer 0) & level 5 (timer 1) irq enable
	
; Set Timer 0
	SB1
	LD	C0TCH, #CTVAL0_H	; Set counter val
	LD	C0TCL, #CTVAL0_L
	LD	C0M, #00000100B	; Set no-capture
	
	SB0
	LD	C0CT, #10100101B	; Continuous, count-down, load counter, zero count irq enable, enable counter	

; Set Timer 1
	SB1
	LD	C1TCH, #CTVAL1_H	; Set counter val
	LD	C1TCL, #CTVAL1_L
	LD	C1M, #00000100B	; Set no-capture
	
	SB0
	LD	C1CT, #10100101B	; Continuous, count-down, load counter, zero count irq enable, enable counter

; Set UART
	SB1
	LD	UMA, #01110000B	; /16, 8bits, no-parity, tr&rcv wake-up value = 0
	LD	UBGH,	#00h		; Time constant = 19,660,800 / 4 / 16 / 9600 / 2 - 1 = 15
	LD	UBGL, 	#0Fh		; Time constant
	LD	UMB, #00111110B	; P21 = P21 data, auto-echo off, receive clock is baud rate generator output, 

	SB0
	LD	UTC, #10001000B	; enable transmit
	LD	UIE, #00000000B	; disable all interrupts, no DMA
	LD	URC, #00000010B	; enable receive

; Enable interrupt
	EI

	COM	P4	; debug

	LDW	RR0, #0000h

; Print message
	LDW	MPTR, #MSG
	CALL	SENDM

; RAM clear
	CLR	R0
	LDE	RAMVAL1, R0
	LDE	RAM_SMPCNT, R0

loop:
	nop
	JR	loop
; --------------------------------------------------------------------------------------------------------------
; sub routines
; --------------------------------------------------------------------------------------------------------------
SENDM:	
	LDCI	R0, @MPTR
	CP	R0, #'$'
	JR	EQ, SENDM_END
	CALL	SENDC
	JR	SENDM
SENDM_END:
	RET

; sendc : send one char
SENDC:
	TM	UTC, #00000010B	; is transmit buffer empty
	JR	Z, SENDC			; if not empty, wait
	LD	UIO, R0
	RET

; --------------------------------------------------------------------------------------------------------------
; interrupt routines
; --------------------------------------------------------------------------------------------------------------

; ADC output
TIMER0:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	;PUSH	R3
	PUSH	R5

	LDW	RR0, #SINTABLE

	LDE	R3, RAM_SMPCNT
	INC	R3
	LDE	RAM_SMPCNT, R3

	ADD	R1, R3
	
	LDE	R2, @RR0

	; bit reverse
	CLR	R5

	TM	R2, #00000001B
	JR	Z, BRV1
	BITS	R5, #7
BRV1:
	TM	R2, #00000010B
	JR	Z, BRV2
	BITS	R5, #6
BRV2:
	TM	R2, #00000100B
	JR	Z, BRV3
	BITS	R5, #5
BRV3:
	TM	R2, #00001000B
	JR	Z, BRV4
	BITS	R5, #4
BRV4:
	TM	R2, #00010000B
	JR	Z, BRV5
	BITS	R5, #3
BRV5:
	TM	R2, #00100000B
	JR	Z, BRV6
	BITS	R5, #2
BRV6:
	TM	R2, #01000000B
	JR	Z, BRV7
	BITS	R5, #1
BRV7:
	TM	R2, #10000000B
	JR	Z, BRV8
	BITS	R5, #0
BRV8:

	LD	P2, R5

	OR	C0CT, #00000010B	; Reset overflow interrupt flag

	POP	R5
	;POP	R3
	POP	R2
	POP	R1
	POP	R0
	IRET

; LED count-up
TIMER1:
	PUSH	R0
	PUSH	R1
	PUSH	R2
	;PUSH	R3
	PUSH	R5

	LDC	R1, RAMVAL1	; R1 <- RAM
	INC	R1
	JR	NOV, TIMER1IRQ_END
	
	INC	P4
TIMER1IRQ_END:
	LDC	RAMVAL1, R1
	OR	C1CT, #00000010B	; Reset overflow interrupt flag

	POP	R5
	;POP	R3
	POP	R2
	POP	R1
	POP	R0
	IRET

BADIRQV:
	LD	P4, #11110000B
	IRET

MSG:
	DB	'Hello World\r\n$'

	ORG	0200H

SINTABLE:
	DB	080H, 083H, 086H, 089H, 08CH, 090H, 093H, 096H, 099H, 09CH, 09FH, 0A2H
	DB	0A5H, 0A8H, 0ABH, 0AEH, 0B1H, 0B3H, 0B6H, 0B9H, 0BCH, 0BFH, 0C1H, 0C4H
	DB	0C7H, 0C9H, 0CCH, 0CEH, 0D1H, 0D3H, 0D5H, 0D8H, 0DAH, 0DCH, 0DEH, 0E0H
	DB	0E2H, 0E4H, 0E6H, 0E8H, 0EAH, 0EBH, 0EDH, 0EFH, 0F0H, 0F1H, 0F3H, 0F4H
	DB	0F5H, 0F6H, 0F8H, 0F9H, 0FAH, 0FAH, 0FBH, 0FCH, 0FDH, 0FDH, 0FEH, 0FEH
	DB	0FEH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FEH, 0FEH, 0FEH, 0FDH
	DB	0FDH, 0FCH, 0FBH, 0FAH, 0FAH, 0F9H, 0F8H, 0F6H, 0F5H, 0F4H, 0F3H, 0F1H
	DB	0F0H, 0EFH, 0EDH, 0EBH, 0EAH, 0E8H, 0E6H, 0E4H, 0E2H, 0E0H, 0DEH, 0DCH
	DB	0DAH, 0D8H, 0D5H, 0D3H, 0D1H, 0CEH, 0CCH, 0C9H, 0C7H, 0C4H, 0C1H, 0BFH
	DB	0BCH, 0B9H, 0B6H, 0B3H, 0B1H, 0AEH, 0ABH, 0A8H, 0A5H, 0A2H, 09FH, 09CH
	DB	099H, 096H, 093H, 090H, 08CH, 089H, 086H, 083H, 080H, 07DH, 07AH, 077H
	DB	074H, 070H, 06DH, 06AH, 067H, 064H, 061H, 05EH, 05BH, 058H, 055H, 052H
	DB	04FH, 04DH, 04AH, 047H, 044H, 041H, 03FH, 03CH, 039H, 037H, 034H, 032H
	DB	02FH, 02DH, 02BH, 028H, 026H, 024H, 022H, 020H, 01EH, 01CH, 01AH, 018H
	DB	016H, 015H, 013H, 011H, 010H, 00FH, 00DH, 00CH, 00BH, 00AH, 008H, 007H
	DB	006H, 006H, 005H, 004H, 003H, 003H, 002H, 002H, 002H, 001H, 001H, 001H
	DB	001H, 001H, 001H, 001H, 002H, 002H, 002H, 003H, 003H, 004H, 005H, 006H
	DB	006H, 007H, 008H, 00AH, 00BH, 00CH, 00DH, 00FH, 010H, 011H, 013H, 015H
	DB	016H, 018H, 01AH, 01CH, 01EH, 020H, 022H, 024H, 026H, 028H, 02BH, 02DH
	DB	02FH, 032H, 034H, 037H, 039H, 03CH, 03FH, 041H, 044H, 047H, 04AH, 04DH
	DB	04FH, 052H, 055H, 058H, 05BH, 05EH, 061H, 064H, 067H, 06AH, 06DH, 070H
	DB	074H, 077H, 07AH, 07DH

	END
	
