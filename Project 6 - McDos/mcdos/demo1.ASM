
.model tiny,stdcall
.8086
.stack 200h

.code
	ORG	100h
start:
	jmp	setup

num_bytes = 10d

chars BYTE '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'

actualascii WORD 1E61h,3062h,2e63h,2064h,1265h,2166h,2267h,2368h,1769h,246ah,
		 256bh,266ch,326dh,316eh,186fh,1970h,1071h,1372h,1f73h,1474h,
		 1675h,2f76h,1177h,2d78h,1579h,2c7ah

readmacrosstatus WORD 0

int9Stack WORD 400h DUP(?)
int9label LABEL WORD
oldSPint9 WORD ?
oldSSint9 WORD ?
tempDxHolder WORD ?


int9handler PROC
	cli
	
	mov	cs:[oldSPint9], sp
	mov	cs:[oldSSint9], ss
	mov	cs:[tempDxHolder], dx
	mov	sp, OFFSET cs:[int9label]
	mov	dx, cs
	mov	ss, dx
	mov	dx, cs:[tempDxHolder]

	
normalInt:
	pushf
	call	cs:[old_interrupt9]
	cli

	pushf
	push	si
	push	es
	push	dx
	push	cx
	push	bx
	push	ax


	mov	bx, 40h
	mov	es, bx
	mov	bx, es:[1ch]
	sub	bx, 02h
	cmp	bx, 1eh
	jae	cs:[bxisnormal]
	mov	bx, 3ch
bxisnormal:
	mov	ax, es:[bx]

	mov	cx, cs:readmacrosstatus
	cmp	cx, 01
	je	cs:[checkifenable]
	cmp	ax, 0231h
	je	cs:[disablemacro]
	
	cmp	al, 61h
	jb	cs:[restorefunregs]
	cmp	al, 7ah
	ja	cs:[restorefunregs]
	push	bx

	mov	ah, 00h
	sti
	int	1Ah
	cli
	mov	ah, 00h
	mov	al, dl
	mov	bl, 26d
	div	bl
	and	al, 00
	mov	cl, 8
	shr	ax, cl
	mov	si, ax
	add	si, ax

;	pop	bx
	mov	bx, offset cs:actualascii
	add	bx, si
	mov	ax, cs:[bx]

	pop	bx
	
	mov	es:[bx], ax
	jmp	cs:[restorefunregs]

checkifenable:
	cmp	ax, 0b30h
	jne	cs:[restorefunregs]
	mov	cx, 00h
	mov	cs:readmacrosstatus, cx
	jmp	cs:[restorefunregs]

disablemacro:
	mov	cx, 01h
	mov	cs:readmacrosstatus, cx

restorefunregs:
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	es
	pop	si
	popf
		
bottom:
	mov	ss, cs:[oldSSint9]
	mov	sp, cs:[oldSPint9]

	sti
	iret

old_interrupt9 DWORD ?

int9handler ENDP

;-------------------------------------------
BiosOutputChar PROC
	push	ax
	pushf
	mov	ah, 0eh
	int	16
	pop	ax
	popf	
	ret	
BiosOutputChar ENDP


end_ISR LABEL BYTE


installResCode PROC
	pushf
	push	si
	push	es
	push	di
	push	cx
	push	bx
	push	bp
	push	ax

	mov	cs:[di], bp	;offset
	mov	cs:[di + 2], ax	;segment
	mov	cx, cs
	cli
	mov	es:[si], cx	;code segment
	mov	es:[si-2], bx	;new handler offset
	sti

	pop	ax
	pop	bp
	pop	bx
	pop	cx
	pop	di
	pop	es
	pop	si
	popf
	ret
installResCode ENDP

;-------------------------------------------

uninstallResCode PROC 
	mov	cx, 0
	mov	es, cx
	cli
	mov	es:[si], ax
	mov	es:[si+2], dx
	sti
	
	ret	
uninstallResCode ENDP

;-------------------------------------------

checkForClone PROC			;returns boolean value in bp
	pushf
	push	si
	push	es
	push	dx
	push	cx
	push	bx
	push	ax

	mov	es, ax
	mov	si, offset int9handler
	mov	cx, num_bytes
	mov	di, 1d			;assume I have installed myself

Clone:
	cmp	cx, 00
	je	bottomend

	push	ax
	mov	ah, 0eh
	mov	al, '-'
	int	16
	pop	ax

	mov	dx, cs:[si]
	cmp	es:[bx], dx
	jne	cleardi
	inc	si
	inc	bx
	dec	cx
	jmp	Clone

cleardi:
	mov	di, 0h

bottomend:
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	es
	pop	si
	popf
	ret	
checkForClone ENDP

;-------------------------------------------

setup:
	mov	cx, 0
	mov	es, cx
	mov	si, 24h
	mov	bx, es:[si]	;offset
	mov	bp, bx		;temp storage
	add	si, 02h
	mov	ax, es:[si]	;segment

	call	checkforClone
	cmp	di, 01d
	je	uninstallMycode
	jmp	install

install:	
	mov	di, offset old_interrupt9	;install int9 handler

	mov	bx, offset int9handler
	call	installResCode

	jmp	bottom

uninstallMycode:
	mov	es, ax	
	mov	si, 24h				;int num for 9 * 4
	mov	ax, 0045h			;offset for int9
	mov	dx, 0585h			;seg for int9
	call	uninstallResCode

	mov	ax, 4c00h
	int	21h
	
bottom:
	mov	ax, 3100h
	mov	dx, offset end_ISR
	mov	cl, 4
	shr	dx, cl
	inc	dx
	int	21h
	
END start
