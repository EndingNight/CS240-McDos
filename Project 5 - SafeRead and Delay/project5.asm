;TITLE Stack Procedures
;Ian Nduhiu
;Oct 13, 2019

INCLUDE CS240.inc

.data
testbuffer BYTE 5 DUP(?)
errorMsg BYTE "Ctrl-c pressed. Program terminated",0
diffHM WORD 0
diffSmS WORD 0
targetHM WORD 0
targetSmS WORD 0

.code
;------------------------------
SafeRead PROC
;
;Implements a safe-read type of input
;where the user can only write a limited number of characters
;The number of characters is determined by the size of the 
;input buffer - 1 to allow space for the null termination
;Registers modified are flags, bp, si, dx, cx, bx and ax
;bp is used for stack parameters access
;si is used as a counter
;dx and ax are used for output
;ax is also used for interrupt calling
;bx is used for memory referencing
;No value is returned
;-----------------------------
	push	bp				;create activation frame
	mov	bp, sp

	pushf					;save flags and registers
	push	si
	push	dx
	push	cx
	push	bx
	push	ax

	mov	cx, [bp + 4]			;size
	cmp	cx, 00				;check if buffer is empty
	je	bottom				;if so, jump to bottom
	dec	cx				;otherwise, dec cx

	mov	bx, [bp + 6]			;buffer offset
	mov	si, 00				;counter

cond:
	cmp	si, cx				;check if buffer is full
	je	bufferfull

cond2:
	mov	ah, 00h				;wait for character
	int	16h
	cmp	al, 03				;ctrl-c		
	je	terminate
	cmp	al, 0dh				;enter
	je	nullTerminate
	cmp	al, 08				;backspace
	je	reduceBuffer

ioStuff:
	mov	dl, al				;outputting to screen
	mov	ah, 02h				;output function 02h
	int	21h				;call dos
	mov	[bx], al			;mov character into buffer
	inc	bx				;increase buffer offset
	inc	si				;increase buffer chars
	jmp	cond				;jump back to cond

terminate:
	mov	dx, OFFSET errorMsg		;informative error message
	call	WriteString
	jmp	bottom				;jump to the bottom

reduceBuffer:
	dec	bx				;reduce offset
	dec	si				;reduce number of chars in buf

;Implementing visualization of backspace
	mov	dl, al				;backspace character
	mov	ah, 02h
	int	21h
	mov	dl, 20h				;space character
	int	21h
	mov	dl, 08h				;backspace character
	int	21h
	jmp	cond2				;go to cond2 and wait for char

bufferfull:
;if buffer is full, wait for backspace, enter or terminate
	cmp	al, 03				;ctrl-c is pressed
	je	terminate
	cmp	al, 0dh				;enter is pressed
	je	nullTerminate
	cmp	al, 08				;backspace is pressed
	je	reduceBuffer
	mov	ah, 00h				;otherwise, wait for char
	int	16h
	jmp	bufferfull			;repeat loop

nullTerminate:
	mov	ax, 0
	mov	[bx], ax			;null terminate buffer

bottom:
	pop	ax				;restore registers and flags
	pop	bx
	pop	cx
	pop	dx
	pop	si
	popf
	pop	bp
	ret
SafeRead ENDP


;----------------------------------
Delay PROC
;
;Implementation of a delay of x milliseconds
;the number of milliseconds is passed as a parameter
;on the stack
;Registers modified are flags, dx, cx, bx, ax and bp
;bp is used to access stack parameters
;dx and cx are used to get time using 2ch function call
;ax, dx and bx are used in division arithmetic
;these registers are also used as temporary storage of
;immediate operands
;no value is returned
;----------------------------------
	push	bp				;create activation frame
	mov	bp, sp

	pushf					;save flags and registers
	push	dx
	push	cx
	push	bx
	push	ax
	
	mov	dx, 0				;clear dx
	mov	ax, [bp + 4]			;milliseconds from stack
	mov	bx, 60000			;convert ms to min
	div	bx
	mov	diffHM, ax			;difference in hours and mins
	
	mov	ax, dx				;move remainder into ax
	mov	dx, 0				;clear dx
	mov	bx, 1000			;convert ms to sec
	div	bx
	mov	cl, 8
	shl	ax, cl				;shift to the left ax by 8
	mov	cx, ax

	mov	ax, dx				;move remainder into ax
	mov	dx, 0
	mov	bx, 10				;convert ms to 1/100 sec
	div	bx
	mov	cl, al
	mov	diffSmS, cx			;difference in seconds

;Setting up the time
;-------------------
	mov	ah, 2ch				;get current time
	int	21h

;add the two times to get target time
	mov	bx, diffSms
	add	dl, bl
	cmp	dl, 100				;compare if above 100
	jb	addSec
	sub	dl, 100
	add	dh, 1				;if above or equal, add 1 to seconnds

addSec:
	add	dh, bh
	cmp	dh, 60				;compare if above 60 secs
	jb	addMin				
	sub	dh, 60
	add	cl, 01				;add 1 to minutes if above or equal

addMin:
	mov	targetSms, dx			;set target seconds

	mov	bx, diffHM
	add	cl, bl
	cmp	cl, 60				;compare if above 60 mins
	jb	addHour
	sub	cl, 60
	add	ch, 01				;add 1 hour if above or equal

addHour:
	add	ch, bh
	cmp	ch, 24d				;check if midnight
	jne	setTHM
	mov	ch, 00				;set to 00

setTHM:
	mov	targetHM, cx			;set target hours and minutes
	
;-----Get time------
	mov	ah, 2ch				;get time before looping
	int	21h

;Delay loop
;-------------------------
cond:
	cmp	cx, targetHM
	jb	timerFunc			;if below, go to timerfunc
	cmp	dx, targetSmS			;otherwise, check seconds
	jae	bottom				;if above or equal, we are done

timerFunc:
	mov	ah, 2ch				;get system time function
	int	21h
	jmp	cond				;jump to condition
	
bottom:
	mov	ax, 0				;restore variables
	mov	diffHM, ax
	mov	diffSmS, ax
	mov	targetHM, ax
	mov	targetSmS, ax

	pop	ax				;restore registers and flags
	pop	bx
	pop	cx
	pop	dx
	popf
	pop	bp
	ret
Delay ENDP

;------------------------
tests PROC
;
;------------------------
	mov	ax, @data
	mov	ds, ax

;----testing SafeRead--------
;Cases tested for:
;buffer length: 5 (works)
;buffer length: 1 (works)
;buffer length: 0 (works)
;buffer length: 10 (works)
;buffer length: 20 (works)
;strings match with no backspace: (works)
;strings match after several backspaces: (works)
;empty string: (works)
;preserves machine state: (works)
;gets rid of enter: (works)
;supports backspace character: (works)
;-------------------------

;	mov	dx, OFFSET testbuffer
;	mov	cx, LENGTHOF testbuffer
;	push	dx
;	push	cx
;	call	SafeRead
;	add	sp, 4
;	call	NewLine
;	mov	dx, OFFSET testbuffer
;	mov	cx, LENGTHOF testbuffer
;	call	DumpMem

;----testing delay-----------
;preserves machine state: (yes)
;can be called more than once: (yes)
;1 second delay: (yes)
;5 second delay: (yes)
;maximum delay 65535 seconds: (yes)
;0 seconds delay: (yes)
;30 seconds delay: (yes)
;can carry over from secs to mins: (yes)
;can carry over from hundredths of secs to secs: (yes)
;1222 milliseconds delay: (yes)
;42231 milliseconds delay: (yes)
;midnight clock delay: (yes)
;----------------------------

;	mov	ax, 1222d		;number of milliseconds
;	push	ax
;	call	Delay


;--terminate program---
	mov	ax, 4c00h
	int	21h
tests ENDP
END ;tests
