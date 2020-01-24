;TITLE funcs.asm
;Ian Nduhiu
;9/15/2019

include CS240.inc

.data
;Polynomial variables
tmpPoly WORD ?
aPoly WORD ?
bPoly WORD ?
xPoly WORD ?
xSq WORD ?
answerPoly WORD ?


;Factorial variables
tmpFact WORD ?

;Fibonacci variables
tmpFib WORD ?


;PrintHexDigit variables
chars BYTE 48, 49, 50, 51, 52, 53, 54, 55,
	   56, 57, "A", "B", "C", "D", "E", "F"


;main varibales
terminate = 4C00h
dos = 21h


.code
Polynomial PROC
	pushf				;save flags values

	push	bx			;save register values...
	push	cx
	push	dx

	mov 	aPoly, ax
	mov	bPoly, bx
	mov	xPoly, dx
	
	mov	bx, xPoly		;getting the value of x squared
	mov	ax, bx
	mul	bx
	mov	xSq, ax			;storing x squared in variable
	
	mov	bx, bPoly		;multiplying b by x to get bx
	mov	ax, xPoly		
	mul	bx
	push	ax			;store (b*x) on stack

	mov	bx, xSq			;(a * (x ** 2))
	mov	ax, aPoly
	mul	bx
	pop	tmpPoly			;pop (b*x) into variable
	add	ax, tmpPoly			;add to ax
	add	ax, cx			;add c to ax

	pop	dx			;restore register values
	pop	cx
	pop	bx

	popf				;restore flag values

	ret
Polynomial ENDP


Fibonacci PROC
	pushf				;save flag values
	
	push	cx			;save register values ax, bx, cx
	push	bx
	mov	tmpFib, ax		;temporarily store ax

	cmp	ax, 00h			;testing for first base case(i==0)
	mov	ax, 00h			;set ax to zero
	jz	bottom
	mov	ax, tmpFib		;restore if no jump

	cmp	ax, 01h			;testing for second base case(i==1)
	mov	ax, 01h			;set ax to 1
	jz	bottom
	mov	ax, tmpFib		;restore if no jump

	cmp	ax, 02h			;testing for third base case(i==2)
	mov 	ax, 01h			;set ax to 1
	jz	bottom
	mov	ax, tmpFib		;restore if no jump
	
	mov	cx, ax			;mov loop counter into cx
	sub	cx, 02h			;2 first cases are taken care of
	mov	ax, 0001h		;mov 1st fib number
	mov	bx, 0001h		;mov 2nd fib number
	
fibLoop:
	push	ax			;store higher fib number
	add	ax, bx			;add the previous two
	pop	bx			;put lower fib back into bx
	loop	fibLoop

bottom:
	pop	bx			;restore register values...
	pop	cx

	popf				;restore flag values

	ret
Fibonacci ENDP


Factorial PROC
	pushf				;save flag values
	
	push	dx			;save register values
	push	cx
	push	bx
	mov	tmpFact, ax		;save ax value in tmpFact

	cmp	ax, 00h			;testing for base case(x==0)
	mov	ax, 00h
	jz	restoration
	mov	ax, tmpFact		;restore if no jump	

	mov	cx, ax
	mov	ax, 01h			;start value is 01h
	mov	bx, 01h			;next value is 01h

factLoop:
	push	bx			;store val into stack
	mul	bx
	pop	bx			;restore
	inc	bx			;bx++
	loop	factLoop
	
restoration:
	pop	bx			;restore bx value

	mov	tmpFact, ax		;save register value temporarily

	pushf				;push current flag values
	pop	ax			;pop them into ax
	and	ax, 0800h		;clear every bit but OF bit
	mov	cl, 0Bh			
	shr	ax, cl			;shift by 11 bits to the right

	pop	cx			;restore cx value
	pop	dx			;restore dx value

	cmp	ax, 01h			;if OF was set...
	jz	setOflow		;...change value of bit to 1...
	jmp	bottom			;...else, jump to the end

setOflow:
	pop	ax			;pop original flag values into ax
	or	ax, 0800h		;set OF to 1
	push	ax			;push modified flag values onto stack

bottom:
	mov	ax, tmpFact		;restore answer to ax
	popf				;restore flag values
	ret
Factorial ENDP


PrintString PROC
	pushf				;store current flag values

	push	si			;store current register values
	push	dx			
	push	ax			

	mov	si, dx			;move offset of string into si

top:
	mov	dl, [si]		;move char into dl
	mov	ah, 02h			;set ah to the dos code for write char
	int	dos			;wake up dos
	cmp	dl, 00h			;compare to null-terminate char
	jle	bottom			;jump to the end if zero
	inc	si			;increment si
	loop	top			;write next char

bottom:
	pop	ax			;restore register values...
	pop	dx
	pop	si
	
	popf				;restore flag values
	ret
PrintString ENDP


PrintHexDigit PROC
	pushf				;save flag values

	push	si			;save register values...
	push	dx
	push	ax

	and	dx, 000Fh		;clear every bit but the last four
	mov	si, dx			;...moving dx value to si
	mov	dl, chars[si]		;get corresponding character from array
	mov	ah, 02h			;set ah to the DOS code for write char
	int	dos			;wake Dos up!!!

	pop	ax			;restore register values...
	pop	dx
	pop	si

	popf				;restore flag values
	ret	
PrintHexDigit ENDP

END
