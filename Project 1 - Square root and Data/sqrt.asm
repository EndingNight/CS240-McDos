;TITLE sqrt.asm
;Ian Nduhiu
;Assignment 1
;9/7/2019

INCLUDE CS240.inc

.data
tmpVal WORD ?
startVal BYTE 00h
saveflags BYTE ?
prevLow WORD ?

.code
sqrt PROC
	mov	tmpVal, dx		;placeholder for dx
	push	cx
	push	bx
	push	ax
	lahf				;load flags values into ah
	mov	saveflags, ah
	mov	cx, tmpVal		;set the counter

top:
	mov	al, startVal
	mov	bl, startVal
	mul	bl		;multiply start number by itself
	sub	dx, ax		;subtract from dx
	JE	bottom		;jump to bottom if zero flag is set
	JS	findClosest	;jump to findClosest if sign flag is set
	mov	dx, tmpVal	;reset dx value
	mov	prevLow, ax	;set previous value of ax
	inc	startVal	;inc y
	loop	top		;loop again

findClosest:
	sub	ax, tmpVal	;sub higher val from current
	mov	bx, prevLow
	sub	tmpVal, bx	;sub current from lower value
	sub	ax, tmpVal	;determine the distance
	JS	bottom		;if sign flag set, use curr value of y...
	dec	startVal	;...else, decrease by one...
	JMP	bottom		;...then jump to bottom
		
bottom:
	mov	dx, 0h		;clear dx register
	mov	dl, startVal	;move into dl our answer
	mov	ah, saveflags	;move into ah earlier saved flag values
	sahf			;load into flags reg
	pop	ax		;restore ax value
	pop	bx		;restore bx value
	pop	cx		;restore cx value
	ret

sqrt ENDP

main PROC
	mov	ax, @data
	mov	ds, ax

	call    ReadUInt	;get user input
	call	sqrt		;call sqrt function
	call	WriteUInt	;write answer to std output
	mov	ax, 4C00h
	int	21h		;wake up DOS
main ENDP
END main
