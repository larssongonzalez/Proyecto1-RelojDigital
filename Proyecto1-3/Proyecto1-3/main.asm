//*********************************************************************
// Universidad del Valle de Guatemala
// Proyecto1-3.asm
// Autor: Larsson Gonzalez
// Proyecto: Reloj Digital
// Hardware: ATMega328p
// Created: 11/3/2024 12:20:35
// Descripcion: Un reloj digital multifuncional con 6 modos diferentes.
//*********************************************************************
// CONFIGURACION GENERAL
//*********************************************************************
.include "M328PDEF.inc"
.cseg
.org 0x0000
	JMP MAIN		;Configuraciones Generales
.org 0x0006
	JMP ISR_PCINT0		;Interrupcion para los push
.org 0x001A
	JMP ISR_TIMER1		;Interrupcion timer 1
.org 0x0020
	JMP ISR_TIMER0		;Interrupcion timer 0

MAIN:
	//*****************************************************************
	// STACK POINTER
	//*****************************************************************
	LDI R16, LOW(RAMEND)
	OUT SPL , R16
	LDI R17, HIGH(RAMEND)
	OUT SPH, R17

//*********************************************************************
// SETUP - CONFIGURACIONES I/O
//*********************************************************************
SETUP:
	LDI R16, 0b1000_0000		;Frecuencia de reloj = 16MHz
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16

	LDI R16, 0b0000_0001
	STS CLKPR, R16

	/*SBI PORTB, PB4		;Habilitando PULL-UP en PB4
	CBI DDRB, PB4		;Habilidando PB4 como entrada

	SBI PORTB, PB3		;Habilitando PULL-UP en PB3
	CBI DDRB, PB3		;Habilidando PB3 como entrada

	SBI PORTB, PB2		;Habilitando PULL-UP en PB2
	CBI DDRB, PB2		;Habilidando PB2 como entrada

	SBI PORTB, PB1		;Habilitando PULL-UP en PB1
	CBI DDRB, PB1		;Habilidando PB1 como entrada

	SBI PORTB, PB0		;Habilitando PULL-UP en PB0
	CBI DDRB, PB0		;Habilidando PB0 como entrada*/

	LDI R16, 0b1111_1111		;Habilitando PULL-UP en el puerto B
	OUT PORTB, R16
	LDI R16, 0b0000_0000		;Habilitando puerto B como entrada
	OUT DDRB, R16

	LDI R16, 0b0011_1111		;Habilitando puerto C como salida
	OUT DDRC, R16

	LDI R16, 0b1111_1111		;Habilidando puerto D como salida
	OUT DDRD, R16

	LDI R16, (1<<PCINT0)|(1<<PCINT1)|(1<<PCINT2)|(1<<PCINT3)|(1<<PCINT4)
	STS PCMSK0, R16

	LDI R16, (1<<PCIE0)
	STS PCICR, R16

	SEI		;Habilitamos las interrupciones globales

	LDI R17, 0x05
	LDI R18, 0x01		;UDia
	LDI R19, 0x00		;ESTADO
	LDI R20, 0x00		;MODO 
	LDI R21, 0x09		;UMIN
	LDI R22, 0x05		;DMIN
	LDI R23, 0x03		;UHORA
	LDI R24, 0x02		;DHORA
	LDI R26, 0x00		;DDia
	LDI R27, 0x00		;DMes
	LDI R28, 0x00		;SEGUNDO - TIMER1
	LDI R29, 0x01		;UMes
	LDI R30, 0x08

	CALL INICIO_T1
	CALL INICIO_T0

	

//****************************************************************************
// LOOP
//****************************************************************************
LOOP:
	CPI R20, 0
	BREQ M0		;Modo Hora
	CPI R20, 1		
	BREQ M1			;Modo Fecha
	CPI R20, 2
	BREQ M2			;Modo Conf. Hora
	CPI R20, 3		
	BREQ M3			;Modo Conf. Fecha
	CPI R20, 4
	BREQ M00
	JMP LOOP

M0:
	JMP MODO0
M1:
	JMP MODO1
M2:
	JMP MODO2
M3:
	JMP MODO3
M00:
	JMP MODORESET
;********************************MODO HORA************************************************
MODO0:		;MODO HORA
	CPI R28, 60
	BREQ MIN1
	CPI R21, 10		;UMIN
	BREQ MIN2
	CPI R22, 6		;DMIN
	BREQ HORA1
	CPI R23, 10		;UHORA
	BREQ HORA2
	CPI R24, 2		;DHORA
	CALL REST

	LDI R16, 0b0000_1000
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)  
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R21		;Incrmenta UMIN
	LPM R25, Z
	OUT PORTD, R25  
	
	CALL DELAY
	
	LDI R16, 0b0000_0100
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)  
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R22		;Incrementa DMIN
	LPM R25, Z
	OUT PORTD, R25 

	CALL DELAY
	
	LDI R16, 0b0000_0010
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)   
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R23		;Incrementa UHORA
	LPM R25, Z
	OUT PORTD, R25 
	
	CALL DELAY

	LDI R16, 0b0000_0001
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)  
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R24		;Incrementa DHORA
	LPM R25, Z
	OUT PORTD, R25 
	
	;CALL REST
	JMP LOOP
MIN1:                ;UMIN
	LDI R28, 0
	INC R21
	JMP MODO0
MIN2:                ;DMIN
	LDI R21, 0
	INC R22
	JMP MODO0
HORA1: 				 ;UHORA
	LDI R22, 0
	INC R23
	JMP MODO0
HORA2:				 ;DHORA 
	LDI R23, 0
	INC R24
	JMP MODO0
REST:
	CPI R23, 4
	BREQ RESET
	RET
RESET: 
	LDI R21, 0
	LDI R22, 0
	LDI R23, 0
	LDI R24, 0
	INC R18
	RET
;******************************MODO FECHA***********************************
MODO1:	;MODO FECHA
	CBI PORTC, PC4
	SBI PORTC, PC5

	CPI R18, 10		;UDIA
	BREQ DIA1
	CPI R26, 3		;DDIA
	BREQ DIA2
	CPI R29, 10		;UMES1
	BREQ MES1
	CPI R27, 1		;DMES2
	BREQ MES2


	LDI R16, 0b0000_0010
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)  
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R18		;Incrementa UDIA
	LPM R25, Z
	OUT PORTD, R25 

	CALL DELAY

	LDI R16, 0b0000_0001
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)  
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R26		;Incrementa DDIA
	LPM R25, Z
	OUT PORTD, R25 

	CALL DELAY
	
	LDI R16, 0b0000_1000
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)   
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R29		;Incrementa UMES1
	LPM R25, Z
	OUT PORTD, R25 
	
	CALL DELAY

	LDI R16, 0b0000_0100
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)  
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R27		;Incrementa DMES2
	LPM R25, Z
	OUT PORTD, R25 

	RJMP LOOP

DIA1:                
	LDI R18, 0	;Reseteamos Unidades de dias
	INC R26		;Incrementamos Decenas de los Dias
	JMP MODO1
DIA2:                
	CPI R18, 2	;Comparamos si Decenas de dias llego a 30
	BREQ OVER	;Reset de dias
	JMP MODO1
OVER:
	LDI R18, 1	;Reseteamos UDia a 1
	LDI R26, 0	;Reseteamos DDia a 0
	INC R29		;Incrementamos UMes
MES1: 				 
	LDI R29, 0	;Reseteamos UMES
	INC R27		;Incrementamos DMES
	JMP MODO1
MES2:
	CPI R29, 3		;En la segunda vuelta UMES = 3?
	BREQ OVERMES	;Reset de meses
	JMP MODO1
OVERMES:
	LDI R29, 1		;Reseteamos UMES a 1
	LDI R27, 0		;Reseteamos DMES a 0
	JMP MODO1

;********************************MODO CONF. HORA***************************************************
MODO2:	;MODO CONF.HORA
	SBI PORTC, PC4
	CBI PORTC, PC5

	/*IN R17, PINB

	SBRS R17, PB3
	INC R21

	SBRS R17, PB2
	DEC R21

	SBRS R17, PB1
	INC R23

	SBRS R17, PB0
	DEC R23

	CPI R21, 10
	BREQ RES1

	CPI R22, 2
	BREQ RES11

	CPI R23, 10
	BREQ RES2

	BREQ R24, 5
	BREQ RES22

RES1:
	LDI R21, 0
	INC R22
	RJMP MODO2

RES11:
	CPI R21, 4
	BREQ RES111
	RJMP MODO2

RES111:
	LDI R21, 1
	LDI R22, 0
	RJMP MODO2

RES2:
	LDI R23, 0
	INC R24
	RJMP MODO2

RES22:
	CPI R23, 10
	BREQ RES222
	RJMP MODO2

RES222:
	LDI R23, 1
	LDI R24, 0
	RJMP MODO2*/

	

	RJMP LOOP
;*****************************MODO CONF. FECHA*******************************************************
MODO3:	;MODO CONF.FECHA
	SBI PORTC, PC4
	SBI PORTC, PC5

	LDI R16, 0b0000_0100
	OUT PORTC, R16

	LDI ZH, HIGH(TABLA7SEG << 1)  
	LDI ZL, LOW(TABLA7SEG << 1)
	ADD ZL, R30		;Incrementa UMIN
	LPM R25, Z
	OUT PORTD, R25 
	RJMP LOOP

MODORESET:
	LDI R20,0 
	RJMP LOOP



//****************************************************************************
// SUBRUTINAS NORMALES
//****************************************************************************
INICIO_T0:
	LDI R16, 0
	OUT TCCR0A, R16

	LDI R16, (1<<CS02)|(1<<CS00)
	OUT TCCR0B, R16

	LDI R16, 100
	OUT TCNT0, R16

	LDI R16, (1<<TOIE0)
	STS TIMSK0, R16

	RET

INICIO_T1:
	LDI R16, 0
	STS TCCR1A, R16

	LDI R16, (1<<CS12)|(1<<CS10)
	STS TCCR1B, R16

	LDI R16, 0xE1		;E1
	STS TCNT1H, R16
	LDI R16, 0x7B		;7B
	STS TCNT1L, R16

	LDI R16, (1<<TOIE1)
	STS TIMSK1, R16

	RET



DELAY:               
	LDI R19, 255
	DELAY1:
		DEC R19
		BRNE DELAY1 
		LDI R19, 255
	DELAY2:
		DEC R19
		BRNE DELAY2
		LDI R19, 255
	DELAY3:
		DEC R19
		BRNE DELAY3
		LDI R19, 255
	DELAY4:
		DEC R19
		BRNE DELAY4
	RET

//************************************************************************************
// SUBRUTINAS DE INTERRUPCION
//************************************************************************************
ISR_PCINT0:
	PUSH R16
	IN R16, SREG
	PUSH R16

	IN R19, PINB		
	SBRS R19, PB4
	INC R20		;Incrementamos MODO

	SBI PCIFR, PCIF0

	POP R16
	OUT SREG, R16
	POP R16

	RETI

ISR_TIMER1:
	PUSH R16
	IN R16, SREG
	PUSH R16

	LDI R17, 0xE1
	STS TCNT1H, R17
	LDI R17, 0x7B
	STS TCNT1L, R17
	SBI TIFR1, TOV1

	INC R28

	POP R16
	OUT SREG, R16
	POP R16

	RETI

ISR_TIMER0:
	PUSH R16
	IN R16, SREG
	PUSH R16

	LDI R17, 100
	OUT TCNT0, R17
	SBI TIFR0, TOV0

	INC R2

	POP R16
	OUT SREG, R16
	POP R16

	RETI

//****************************************************************************
TABLA7SEG: .DB 0x7E, 0x0C, 0xB6, 0x9E, 0xCC, 0xDA, 0xFA, 0x0E, 0xFE, 0xDE
//****************************************************************************

