.model tiny,stdcall
.8086
.stack 200h

.code
	ORG	100h
start:
	jmp	setup

num_bytes = 10d

chars BYTE '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'

actualascii WORD 2e63h,2064h,246ah,2368h,326dh

readmacrosstatus WORD 0			;0 if normal, 1 if disabled

c_key WORD 2e63h,2064h
d_key WORD 2064h,1769h,1372h
j_key WORD 246ah,186fh,2f76h,1265h
h_key WORD 2368h,1265h,266ch,1970h
m_key WORD 326dh,256bh,2064h,1769h,1372h

len_c_key WORD 4
len_d_key WORD 6
len_j_key WORD 8
len_h_key WORD 8
len_m_key WORD 10

status WORD 0

mybufferptr WORD 0
readthebuffer WORD 0
mybuffer WORD 256 DUP(?)

incaseovewr WORD 12 DUP(?)

int9Stack WORD 400h DUP(?)
int9label LABEL WORD
oldSPint9 WORD ?
oldSSint9 WORD ?
tempDxHolder WORD ?

int16Stack WORD 400h DUP(?)
int16label LABEL WORD
oldSPint16 WORD ?
oldSSint16 WORD ?
tmpDxHolder WORD ?


int9handler PROC
	cli
	
	mov	cs:[oldSPint9], sp
	mov	cs:[oldSSint9], ss
	mov	cs:[tempDxHolder], dx
	mov	sp, OFFSET cs:[int9label]
	mov	dx, cs
	mov	ss, dx
	mov	dx, cs:[tempDxHolder]

	push	ax
	in	al, 60h
	and	al, 80h
	cmp	al, 80h
	jne	cs:[restoreax]
	pop	ax
	pushf
	call	cs:[old_interrupt9]
	jmp	cs:[bottomint9]

restoreax:
	pop	ax
	
normalInt:
	pushf
	call	cs:[old_interrupt9]
	cli

	pushf
	push	si
	push	es
	push	cx
	push	bx
	push	ax

;	mov	ax, cs:readmacrosstatus
;	cmp	ax, 01h
;	je	cs:[restoreregs]

	mov	bx, 40h
	mov	es, bx
	mov	bx, es:[1ch]
	sub	bx, 02h
	cmp	bx, 1eh
	jae	cs:[bxisnormal]
	mov	bx, 3ch
bxisnormal:
	mov	ax, es:[bx]
	mov	bx, cs:readmacrosstatus

;	cmp	ax, 0231h
;	je	cs:[disablemacros]
;	cmp	ax, 0b30h
;	je	cs:[enablemacros]
;	push	ax
;	mov	ax, cs:readmacrosstatus
;	cmp	ax, 01h
;	je	cs:[restoreregs]
;	pop	ax

	cmp	bx, 01h
	je	cs:[checkifenable]
	cmp	ax, 0231h
	je	cs:[disablemacros]
	
	mov	cx, 10h
	mov	si, 00h
	jmp	cs:[keylookup]

checkifenable:
	cmp	ax, 0b30h
	je	cs:[enablemacros]
	jmp	cs:[restoreregs]

enablemacros:
	push	ax
	mov	ax, 00h
	mov	cs:readmacrosstatus, ax
	pop	ax
	jmp	cs:[restoreregs]

disablemacros:
	push	ax
	mov	ax, 01h
	mov	cs:readmacrosstatus, ax
	pop	ax
	jmp	cs:[restoreregs]

keylookup:
	cmp	cx, 00h
	je	cs:[restoreregs]

	cmp	ax, cs:actualascii[si]
	je	cs:[foundourkey]
	add	si, 02h
	sub	cx, 02h
	jmp	cs:[keylookup]

foundourkey:
	mov	si, 40h
	mov	es, si
	mov	si, es:[1ch]
	sub	si, 02h
	cmp	si, 1eh
	jae	cs:[siisnormal]
	mov	si, 3ch
siisnormal:
	mov	es:[1ch], si

	mov	si, 00

	cmp	ax, 2e63h					;c_key
	je	cs:[c_keylabel]

	cmp	ax, 2064h					;d_key
	je	cs:[d_keylabel]

	cmp	ax, 2368h					;h
	je	cs:[h_keylabel]

	cmp	ax, 246ah					;j
	je	cs:[j_keylabel]


	mov	cx, cs:len_m_key
;	mov	bx, cs:mybufferptr
;	add	bx, cx
	mov	cs:mybufferptr, cx
	mov	bx, offset cs:m_key
	jmp	cs:[loadmacrointobuffer]

c_keylabel:
	mov	cx, cs:len_c_key
;	mov	bx, cs:mybufferptr
;	add	bx, cx
	mov	cs:mybufferptr, cx
	mov	bx, offset cs:c_key
	jmp	cs:[loadmacrointobuffer]

d_keylabel:
	mov	cx, cs:len_d_key
;	mov	bx, cs:mybufferptr
;	add	bx, cx
	mov	cs:mybufferptr, cx
	mov	bx, offset cs:d_key
	jmp	cs:[loadmacrointobuffer]

h_keylabel:
	mov	cx, cs:len_h_key
;	mov	bx, cs:mybufferptr
;	add	bx, cx
	mov	cs:mybufferptr, cx
	mov	bx, offset cs:h_key
	jmp	cs:[loadmacrointobuffer]

j_keylabel:
	mov	cx, cs:len_j_key
;	mov	bx, cs:mybufferptr
;	add	bx, cx
	mov	cs:mybufferptr, cx
	mov	bx, offset cs:j_key
	jmp	cs:[loadmacrointobuffer]

loadmacrointobuffer:
	cmp	si, cx
	je	cs:[restoreregs]

	mov	ax, cs:[bx]
	mov	cs:mybuffer[si], ax
	add	si, 02h
	add	bx, 02h
	jmp	cs:[loadmacrointobuffer]

restoreregs:
	pop	ax
	pop	bx
	pop	cx
	pop	es
	pop	si
	popf
		
bottomint9:
	mov	ss, cs:[oldSSint9]
	mov	sp, cs:[oldSPint9]

	iret

old_interrupt9 DWORD ?

int9handler ENDP

int16handler PROC
	cli

	mov	cs:[oldSPint16], sp
	mov	cs:[oldSSint16], ss
	mov	cs:[tmpDxHolder], dx
	mov	sp, OFFSET cs:[int16label]
	mov	dx, cs
	mov	ss, dx
	mov	dx, cs:[tmpDxHolder]

	pushf
	push	si
	push	es
	push	cx
	push	bx
	push	ax

	mov	cx, cs:mybufferptr
	cmp	cx, 00
	je	cs:[restorereadthebuffer]
	mov	si, 00
	add	si, cs:readthebuffer
	sub	cx, 02h
	mov	cs:mybufferptr, cx
	mov	ax, cs:readthebuffer
	add	ax, 02h
	mov	cs:readthebuffer, ax

	mov	bx, 40h
	mov	es, bx
	mov	bx, es:[1ch]
	mov	ax, cs:mybuffer[si]
	mov	es:[bx], ax

	mov	ax, 02h
	add	es:[1ch], ax
	mov	ax, 3ch
	cmp	es:[1ch], ax
	jbe	cs:[restoreint16regs]
	mov	ax, 1eh
	mov	es:[1ch], ax
	jmp	cs:[restoreint16regs]

restorereadthebuffer:
	mov	si, 00
	mov	cs:readthebuffer, si
	mov	cs:mybufferptr, si
	mov	cx, 256d
	mov	ax, 00

resetbuffer:
	cmp	cx, 00
	je	cs:[restoreint16regs]

	mov	cs:mybuffer[si], ax
	inc	si
	dec	cx
	jmp	cs:[resetbuffer]

restoreint16regs:
	pop	ax
	pop	bx
	pop	cx
	pop	es
	pop	si
	popf

	mov	ss, cs:[oldSSint16]
	mov	sp, cs:[oldSPint16]

	jmp	cs:[old_interrupt16]

old_interrupt16 DWORD ?

int16handler ENDP

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

	call	cs:[checkforClone]
	cmp	di, 01d
	je	cs:[uninstallMycode]

install:	
	mov	di, offset cs:old_interrupt9	;install int9 handler

	mov	bx, offset cs:int9handler
	call	cs:[installResCode]
	jmp	cs:[installint16]

installint16:
	mov	di, offset cs:old_interrupt16	;install int16 handler
	mov	si, 58h
	mov	bx, es:[si]
	mov	bp, bx
	add	si, 02h
	mov	ax, es:[si]
	mov	bx, offset cs:int16handler
	call	cs:[installResCode]
	jmp	cs:[bottom]

uninstallMycode:
	mov	es, ax	
	mov	si, 24h				;int num for 9 * 4
	mov	ax, 0045h			;offset for int9
	mov	dx, 0585h			;seg for int9
	call	cs:[uninstallResCode]

	mov	es, ax
	mov	si, 58h				;int num for 16h * 4
	mov	ax, 0e82eh			;offset for int 16h
	mov	dx, 0f000h			;seg for int 16h
	call	cs:[uninstallResCode]

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
