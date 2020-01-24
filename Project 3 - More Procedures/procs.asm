;TITLE procs.asm
;Ian Nduhiu
;9/18/2019
;More Procedures!

INCLUDE CS240.inc

.data

;SaveMachineState Variables
origRegs WORD 20 DUP(?)


;CompareMachineState Variables
regNames BYTE "A", "X", "B", "P", "B", "X", "C", "X", "D" , "I", "D", "S",
	      "D", "X", "E", "S", "S", "I", "S", "P", "S", "S"
flagNames BYTE "O", "D", "I", "T", "S", "Z", "A",
	       "P", "C"

currRegs WORD 20 DUP(?)

regBegin BYTE "Register ",0
regMiddle BYTE "'s value has changed. Old value: ",0
regNexttoMid BYTE ", new value: ",0
regNull BYTE ".",0

flagBegin BYTE " flag value has changed. Old value: ",0
flagMiddle BYTE ", new value: ",0
flagEnd BYTE ".",0
setStr BYTE "set",0
clearStr BYTE "clear",0

randStr BYTE "hey!",0


;PrintInt variables
chars BYTE 48d, 49d, 50d, 51d, 52d,
	   53d, 54d, 55d, 56d, 57d
tmp WORD 0h
arr BYTE 5 DUP(0)
var SWORD 0ffffh
modNum WORD 10d
divInt WORD 01h
index WORD 04h


;general variables
dos = 21h
terminate = 4C00h


.code
SaveMachineState PROC
	mov	origRegs[16], si	;store si first to use later
	mov	si, OFFSET origRegs	;si as parameter
	call	SaveRegs
	mov	si, origRegs[16]	;restore si value
	ret
SaveMachineState ENDP


SaveRegs PROC
	mov	[si], ax
	mov	[si+2], bp
	mov	[si+4], bx
	mov	[si+6], cx
	mov	[si+8], di
	mov	[si+10], ds
	mov	[si+12], dx
	mov	[si+14], es	;skip [si+16]
	mov	[si+18], sp
	mov	[si+20], ss
	
	pushf			;save flag and register values
	push	dx
	push	cx
	push	ax

	pushf			;get flag values
	pop	ax		;save in ax register
	mov	dx, ax
	
	and	ax, 0800h	;get O flag
	mov	cl, 0Bh
	shr	ax, cl
	mov	[si+22], ax
	mov	ax, dx		;restore ax value

	and	ax, 0400h	;get D flag
	mov	cl, 0Ah
	shr	ax, cl
	mov	[si+24], ax
	mov	ax, dx		;restore ax value

	and	ax, 0200h	;get I flag
	mov	cl, 09h
	shr	ax, cl
	mov	[si+26], ax
	mov	ax, dx		;restore ax value

	and	ax, 0100h	;get T flag
	mov	cl, 08h
	shr	ax, cl
	mov	[si+28], ax
	mov	ax, dx		;restore ax value

	and	ax, 0080h	;get S flag
	mov	cl, 07h
	shr	ax, cl
	mov	[si+30], ax
	mov	ax, dx		;restore ax value

	and	ax, 0040h	;get Z flag
	mov	cl, 06h
	shr	ax, cl
	mov	[si+32], ax
	mov	ax, dx		;restore ax value

	and	ax, 0010h	;get A flag
	mov	cl, 04h
	shr	ax, cl
	mov	[si+34], ax
	mov	ax, dx		;restore ax value

	and	ax, 0004h	;get P flag
	mov	cl, 02h
	shr	ax, cl
	mov	[si+36], ax
	mov	ax, dx		;restore ax value

	and	ax, 0001h	;get C flag
	mov	[si+38], ax

	pop	ax		;restore register values
	pop	cx
	pop	dx
	popf			;restore flag values
	ret
SaveRegs ENDP


CompareMachineState PROC
	mov	currRegs[16], si
	mov	si, OFFSET currRegs
	call	SaveRegs	;get current machine state
	mov	si, currRegs[16]

	pushf			;save flag and register values
	push	si
	push	dx
	push	di
	push	ax
	
	mov	si, 0h		;set si to 0
	mov	di, 0h		;set di to 0 for flags iteration later on
	
RegCheck:
	mov	ax, origRegs[si]
	cmp	ax, currRegs[si]
	jne	RegPrint	;if not equal, print info message...
	add	si, 02h		;...else, inc si
	cmp	si, 16h		;check if we are checking flags
	je	FlagCheck	;if so, jump to flag check label
	jmp	RegCheck	;loop again

RegPrint:
	mov	dx, OFFSET regBegin
	call	WriteString	;"Register "
	mov	dl, regNames[si]
	call	WriteChar	;first char of register value
	mov	dl, regNames[si+1]
	call	WriteChar	;second char of register value
	mov	dx, OFFSET regMiddle
	call	WriteString	;"'s value has changed. Old value: "
	mov	dx, origRegs[si]
	call	WriteHexWord	;writes old value of register
	mov	dx, OFFSET regNexttoMid
	call	WriteString	;", new value: "
	mov	dx, currRegs[si]
	call	WriteHexWord	;new value of register
	mov	dx, OFFSET regNull
	call	WriteString	;".",0
	call	NewLine
	
	add	si, 02h
	cmp	si, 16h	
	je	FlagCheck
	jne	RegCheck

FlagCheck:
	mov	ax, origRegs[si]
	cmp	ax, currRegs[si]
	jne	FlagPrint	;if not equal, print info message
	add	si, 02h		;else, inc si
	inc	di
	cmp	si, 28h		;check if we are done with registers
	je	bottom		;if so, jump to bottom
	jne	FlagCheck	

FlagPrint:
	mov	dl, flagNames[di]
	call	WriteChar	;name of flag
	mov	dx, OFFSET flagBegin
	call	WriteString	;" flag value has changed. Old value: "
	cmp	ax, 00h		;check if original was set or clear
	je	PrintClearSet	;if set, jump to first label
	jne	PrintSetClear	;else, jump to the following one

PrintClearSet:
	mov	dx, OFFSET clearStr
	call	WriteString	;"clear"
	mov	dx, OFFSET flagMiddle
	call	WriteString	;", new value: "
	mov	dx, OFFSET setStr
	call	WriteString	;"set"
	mov	dx, OFFSET flagEnd
	call	WriteString	;".",0
	call	NewLine

	add	si, 02h
	inc	di
	cmp	si, 28h		;check if done with flags
	je	bottom		;jump to bottom
	jne	FlagCheck	;else restore loop

PrintSetClear:		
	mov	dx, OFFSET setStr
	call	WriteString	;"set"
	mov	dx, OFFSET flagMiddle
	call	WriteString	;", new value: "
	mov	dx, OFFSET clearStr
	call	WriteString	;"clear"
	mov	dx, OFFSET flagEnd
	call	WriteString	;".",0
	call	NewLine

	add	si, 02h
	inc	di
	cmp	si, 28h		;check if done with flags
	je	bottom		;jump to bottom
	jne	FlagCheck	;else restore loop	
	
bottom:
	pop	ax		;restore register values
	pop	di
	pop	dx
	pop	si		
	popf
	ret
CompareMachineState ENDP


HexOut PROC USES bx cx dx
	pushf			;save flag values

L1:
	mov	dx, [bx]	;mov byte from array into dx
	push	cx		;save cx value
	push	dx		;save dx value before first shift
	and	dx, 0F0h	;get the first nybble
	mov	cl, 04h
	shr	dx, cl		;shift to the right by 4 bits
	call	WriteHexDigit	;write digit in hex to stdout

	pop	dx		;restore original value
	and	dx, 0Fh		;get the last 4 bits
	call	WriteHexDigit	;write digit in hex to stdout

	pop	cx		;restore cx value
	cmp	cx, 00h		;check if we have to output a space
	je	bottom		;if we don't, jump to the end
	mov	dl, " "		;move space character into dl
	call	WriteChar	;write " " to std output
	inc	bx		;increment bx
	loop	L1

bottom:
	popf			;restore flag values
	ret

HexOut ENDP


PrintInt PROC USES ax bx cx dx si
	pushf			;save flag values

	mov	si, OFFSET arr
	mov	cx, 05h
	
	push	ax		;temporarily save ax value
	and	ax, 8000h	;get highest bit
	cmp	ax, 0h		;compare to zero
	pop	ax		;restore ax
	jz	L1		;if zero flag is set, number is positive
	mov	dx, 0ffffh
	dec	ax
	sub	dx, ax		;get unsigned complement
	mov	ax, dx
	mov	dl, "-"		;output sign character
	call	WriteChar

L1:
	push	ax		;save signed word
	mov	dx, 0h		;save dx
	mov	bx, modNum
	div	bx

	push	dx		;save quotient
	sub	dx, tmp		;sub from previous remainder
	mov	ax, dx		;mov into ax to make it dividend
	mov	dx, 0		;clear dx
	mov	bx, divInt	;divisor for remainder
	div	bx		;ax has our digit


	mov	si, index
	mov	arr[si], al	;mov our digit into last array spot	

	pop	dx		;restore dx
	mov	tmp, dx		;save new remainder

	mov	ax, index	;decrement index
	dec	ax
	mov	index, ax

	mov	ax, modNum	;modNum *10
	mov	bx, 10d
	mul	bx
	mov	modNum, ax

	mov	ax, divInt	;divInt * 10
	mov	bx, 10d
	mul	bx
	mov	divInt, ax

	pop	ax		;restore ax

	loop    L1
	mov	cx, 05h
	mov	si, 00h	

removeZeroes:
	mov	al, arr[si]
	cmp	al, 00h		;check for leading zeros
	jnz	writeTheChars	;jump to write char label if not zero...
	dec	cx		;...else, dec cx value
	inc	si		;inc si value

	cmp	cx, 00h		;check if the number is 0
	jz	zeroCase	;jump to the zeroCase

	jmp	removeZeroes	;loop again
	

writeTheChars:			
	mov	bx, 0h		;clear bx
	mov	bl, arr[si]
	mov	dl, chars[bx]	;mov into dl ascii value
	mov	ah, 02h
	int	dos
	inc	si
	loop	writeTheChars
	jmp	bottom

zeroCase:			;case for when array is filled with zeroes
	mov	dl, chars	;output 0
	mov	ah, 02h
	int	dos

bottom:
	popf			;restore flag values
	ret
	
PrintInt ENDP

END
