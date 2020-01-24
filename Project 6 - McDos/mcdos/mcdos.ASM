.model tiny,stdcall
.8086
.stack 200h

.code
	ORG	100h
start:
	jmp	setup

num_bytes = 10d

chars BYTE '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'

int9Stack WORD 400h DUP(?)
int9label LABEL WORD
oldSPint9 WORD ?
oldSSint9 WORD ?
tempDxHolder WORD ?

int16stack WORD 400h DUP(?)
int16label LABEL WORD
oldSPint16 WORD ?
oldSSint16 WORD ?
tmpDxHolder WORD ?

r_shift = 00				;1st bit
l_shift = 01				;2nd bit

DOS		= 21h
BIOS		= 10h
TERMINATE	= 4C00h
	
NUL	= 0
LF	= 10
CR	= 13

MacroFileName	BYTE "c:\macros.dat", NUL

AskUser BYTE "Load earlier saved macros? Press 'y' if so:  ",0

actualascii WORD 1E61h,3062h,2e63h,2064h,1265h,2166h,2267h,2368h,1769h,246ah,
		 256bh,266ch,326dh,316eh,186fh,1970h,1071h,1372h,1f73h,1474h,
		 1675h,2f76h,1177h,2d78h,1579h,2c7ah

filehandle WORD ?

tempMacroptr WORD 0			;pointer to point where in array we are
tempMacroArray WORD 512 DUP(?)		;to move into during macro assignment

MacroDBptr WORD 0 			;pointer to use for macroDB lookup
MacroDB WORD 150 DUP(?)			;triple word macro database

allMacrosPtr WORD 0
allMacros WORD 640 DUP(?)		;all macros got during user interaction

readmacrosstatus WORD 0

mybufferptr WORD 0
readthebuffer WORD 0
mybuffer WORD 256 DUP(?)

int9status BYTE ?			;0-normal,1-assign,2-sthfun
int16status BYTE ? 			;0-normal,1-readfromsecretbuffer

InfoMsg BYTE " - To begin macro assignment:hit the r-shift. ",0dh,0ah
FollowMsg BYTE " - If at any time you wish to disable macros, press 1.",0dh,0ah
OptionsMsg BYTE " - If you wish to do something fun, press 2",0dh,0ah
NoFunMsg BYTE " - To stop doing something fun, press 3",0dh,0ah
Uninstall BYTE " - To uninstall, run mcdos once more.",0dh,0ah,

HowMsg BYTE "To bind a macro, enter letter being bound to: ",0dh,0ah
How2Msg BYTE "Followed by a space:",0dh,0ah
How3Msg BYTE "Then the letters you are binding to: ",0dh,0ah
How4Msg BYTE "Once you are done, hit the l-shift!",0dh,0ah,0dh,0ah
How5Msg	BYTE "REMEMBER: ONCE DONE WITH ASSIGNMENT OF MACROS",0dh,0ah
FollowupMsg BYTE " - If you wish to disable all the macros, press 1.",0dh,0ah
EnableMsg BYTE " - If you wish to re-enable them, press 0.",0dh,0ah
OptionsupMsg BYTE " - If you wish to do something fun, press 2",0dh,0ah
NoFunupMsg BYTE " - To stop doing something fun, press 3",0dh,0ah,0

overflowbuff BYTE 30 DUP(?)

int9handler PROC
	cli
	
	mov	cs:[oldSPint9], sp
	mov	cs:[oldSSint9], ss
	mov	cs:[tempDxHolder], dx
	mov	sp, OFFSET cs:[int9label]
	mov	dx, cs
	mov	ss, dx
	mov	dx, cs:[tempDxHolder]

	pushf
	push	dx

	mov	dl, cs:int9status	
	cmp	dl, 1d
	je	cs:[assignment]

	cmp	dl, 2d
	je	cs:[sthfunbranch]

	pop	dx
	popf
	jmp	cs:[checkforRshift]

sthfunbranch:
	pop	dx

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
	jae	cs:[bxisnormalfun]
	mov	bx, 3ch
bxisnormalfun:
	mov	ax, es:[bx]

	mov	cx, cs:readmacrosstatus
	cmp	cx, 01
	je	cs:[checkifenablefun]
	cmp	ax, 0231h
	je	cs:[disablemacrofun]
	cmp	ax, 0433h
	je	cs:[stophavingfun]
	
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

checkifenablefun:
	cmp	ax, 0b30h
	jne	cs:[restorefunregs]
	mov	cx, 00h
	mov	cs:readmacrosstatus, cx
	jmp	cs:[restorefunregs]

stophavingfun:
	mov	dx, 00
	mov	cs:int9status, dl
	mov	cs:readmacrosstatus, dx
	jmp	cs:[restorefunregs]

disablemacrofun:
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

	jmp	cs:[interm1]

assignment:
	pop	dx
	popf

	pushf
	push	si
	push	es
	push	dx
	push	di
	push	cx
	push	bp
	push	bx
	push	ax

	mov	cx, 40h
	mov	es, cx
	mov	al, es:[17h]
	and	al, 02h
	mov	cl, 01
	shr	al, cl
	cmp	al, 1
;	jne	cs:[storekeys]
	jne	cs:[checkkybdportlshift]

;	mov	al, '1'
;	sti
;	call	cs:[biosoutputchar]
;	cli

	mov	dl, 00
	mov	cs:int9status, dl
		
	mov	bx, offset cs:tempMacroArray
	mov	di, offset cs:MacroDB
	mov	si, offset cs:allMacros

	;update the macroDB
	mov	cx, cs:tempMacroptr
	sub	cx, 02h					;skip first word
	add	bx, 02h					;skip first word
	
	mov	dx, cs:MacroDBptr
	add	di, dx					;update starting offset
	mov	bp, cs:[bx]				;current word
	mov	cs:[di], bp				;scan code, ascii code
	add	dx, 06h
	mov	cs:MacroDBptr, dx			;update macroDB ptr

	mov	dx, cs:allMacrosptr
	add	si, dx
	add	di, 02h					;move to next word
	mov	cs:[di], si				;MacroDb start offset
	push	si
	add	si, cx
	add	di, 02h
	mov	cs:[di], si				;MacroDB end offset
	pop	si
	add	dx, cx					;update all macros ptr
	mov	cs:allMacrosptr, dx

	;store macro in memory, start at cs:[si], stop at cs:[si+cx]
	add	bx, 04h
	sub	cx, 04h

movingtoallmacros:
	cmp	cx, 00h
	je	cs:[settempptr]

	mov	ax, cs:[bx]
	mov	cs:[si], ax
	add	si, 02h
	add	bx, 02h
	sub	cx, 02h
	jmp	cs:[movingtoallmacros]	

interm1:
	jmp	cs:[interm2]
	 	
settempptr:
	mov	cs:tempMacroptr, cx			;set temp ptr to zero

	mov	ah, 05h
	mov	al, 00h
	sti
	int	16
	cli

	jmp	cs:[restorelshiftregs]


checkkybdportlshift:
	in	al, 60h
	and	al, 80h
	cmp	al, 80h
	jne	cs:[storekeys]
	
	pop	ax
	pop	bx
	pop	bp
	pop	cx
	pop	di
	pop	dx
	pop	es
	pop	si
	popf

	pushf
	call	cs:[old_interrupt9]
	jmp	cs:[bottomint9]

storekeys:
	mov	bx, es:[1ch]
	sub 	bx, 02h
	cmp	bx, 1eh
	jae	cs:[bxisnormal]
	mov	bx, 3ch
bxisnormal:
	mov	si, offset cs:tempMacroArray
	mov	dx, cs:tempMacroptr
	add	si, dx
	mov	ax, es:[bx]
	mov	cs:[si], ax
	add	dx, 02h
	mov	cs:tempMacroptr, dx

restorelshiftregs:
	pop	ax
	pop	bx
	pop	bp
	pop	cx
	pop	di
	pop	dx
	pop	es
	pop	si
	popf

	jmp	cs:[normalInt]

interm2:
	jmp	cs:[interm3]

checkforRshift:
	pushf
	push	si
	push	es
	push	di
	push	dx
	push	cx
	push	bx
	push	ax

	mov	cx, 40h
	mov	es, cx
	mov	al, es:[17h]
	and	al, 01h
	cmp	al, 1h
	jne	cs:[restoreregs]

;	mov	al, '0'
;	sti
;	call	cs:[BiosOutputChar]
;	cli

	mov	ah, 05h
	mov	al, 05h
	sti
	int	16
	cli

	mov	cx, 30d

outputnewline:
	cmp	cx, 00
	je	cs:[donewithnewl]
	
	mov	al, 0dh
	mov	ah, 0eh
	sti
	int	16
	cli
	mov	al, 0ah
	mov	ah, 0eh
	sti
	int	16
	cli
	dec	cx
	jmp	cs:[outputnewline]

interm3:
	jmp	cs:[interm4]

donewithnewl:
	mov	dx, 0
	mov	ah, 02h
	mov	bh, 05h
	sti
	int	16
	cli

	mov	si, offset cs:HowMsg
	mov	cx, 177h

l2:
	cmp	cx, 00
	je	cs:[newl2]

	mov	al, cs:[si]
	mov	ah, 0eh
	int	16
	inc	si
	dec	cx
	jmp	cs:[l2]

newl2:
	mov	al, 0dh
	sti
	call	cs:[biosoutputchar]
	cli
	mov	al, 0ah
	sti
	call	cs:[biosoutputchar]
	cli
	mov	al, 0dh
	sti
	call	cs:[biosoutputchar]
	cli
	mov	al, 0ah
	sti
	call	cs:[biosoutputchar]
	cli

	mov	dl, 1d
	mov	cs:int9status, dl

restoreregs:
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	es
	pop	si
	popf

checkkybdport:
	push	ax
	in	al, 60h
	and	al, 80h
	cmp	al, 80h
	jne	cs:[restoremyax]
	pop	ax
	pushf
	call	cs:[old_interrupt9]
	jmp	cs:[bottomint9]

interm4:
	jmp	cs:[interm5]

restoremyax:
	pop	ax


normalInt:
	pushf
	call	cs:[old_interrupt9]
	cli

	;macro look up
	pushf
	push	si
	push	es
	push	dx
	push	di
	push	cx
	push	bx
	push	ax

	mov	al, cs:int9status
	cmp	al, 00h
	jne	cs:[macrorestoreregs]

	mov	cx, 40h
	mov	es, cx
	mov	bx, es:[1ch]
	sub	bx, 02h
	cmp	bx, 1eh
	jae	cs:[bxtooisnormal]
	mov	bx, 3ch
bxtooisnormal:
	mov	ax, es:[bx]				;last key typed
	mov	bx, cs:readmacrosstatus

	cmp	bx, 01h
	je	cs:[checkifenable]
	cmp	ax, 0231h
	je	cs:[disablemacros]
	cmp	ax, 0332h				;display all macros
	je	cs:[dosthfun]
	
	;look up key in ax in macrodb
	mov	cx, cs:MacroDBptr
	mov	si, offset cs:MacroDB

macrolookup:
	cmp	cx, 00
	je	cs:[macrorestoreregs]

	cmp	ax, cs:[si]
	je	cs:[keyfoundindb]
	add	si, 06h
	sub	cx, 06h
	jmp	cs:[macrolookup]

checkifenable:
	cmp	ax, 0b30h
	je	cs:[enablemacros]
	jmp	cs:[macrorestoreregs]

interm5:
	jmp	cs:[bottomint9]

dosthfun:
	mov	dl, 02
	mov	cs:int9status, dl
	mov	dx, 00
	mov	cs:readmacrosstatus, dx
	jmp	cs:[macrorestoreregs]

enablemacros:
	mov	ax, 00h
	mov	cs:readmacrosstatus, ax
	jmp	cs:[macrorestoreregs]

disablemacros:
	mov	ax, 01h
	mov	cs:readmacrosstatus, ax
	jmp	cs:[macrorestoreregs]

keyfoundindb:
	mov	di, cs:[si+2]			;di has start offset
	mov	cx, cs:[si+4]
	sub	cx, di				;length of macro
	mov	cs:mybufferptr, cx		;update buffer ptr

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

puttingstuff:
	cmp	si, cx
	je	cs:[macrorestoreregs]

	mov	ax, cs:[di]
	mov	cs:mybuffer[si], ax
	add	si, 02h
	add	di, 02h
	jmp	cs:[puttingstuff]	
	
macrorestoreregs:
	pop	ax
	pop	bx
	pop	cx
	pop	di
	pop	dx
	pop	es
	pop	si
	popf

bottomint9:
	mov	ss, cs:[oldSSint9]
	mov	sp, cs:[oldSPint9]

	sti
	iret

old_interrupt9 DWORD ?

int9handler ENDP

;-------------------------------------------
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

;resetbuffer:
;	cmp	cx, 00
;	je	cs:[restoreint16regs]

;	mov	cs:mybuffer[si], ax
;	inc	si
;	dec	cx
;	jmp	cs:[resetbuffer]

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
	mov	al, '*'
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


;;; ----------------------------------------------------------------------------
;;; OpenMacroFile
;;;
;;; Opens a macro file for reading
;;;
;;; Parameters:
;;;   None
;;; Returns:
;;;   BX = file handle
;;; ----------------------------------------------------------------------------

OpenMacroFile PROC
	pushf
	push	ax
	push	dx
	push	ds

	;; AH = 3Dh
	;; AL = access and sharing modes (see #01402)
	;; DS:DX -> ASCIZ filename
	;; CL = attribute mask of files to look for (server call only)

	mov	dx, cs
	mov	ds, dx
	mov	dx, OFFSET cs:MacroFileName
	mov	ah, 3Dh	; Open file
;	mov	al, 2		; Read/write
	int	DOS
	;; Return:
	;; CF clear if successful
	;; AX = file handle
	;; CF set on error
	;; AX = error code (01h,02h,03h,04h,05h,0Ch,56h) (see #01680 at AH=59h)

	jnc	done
	mov	al, 'o'
	call	cs:[biosoutputchar]
	mov	ax, TERMINATE
	int	DOS
done:
	mov	bx, ax
	pop	ds
	pop	dx
	pop	ax
	popf
	ret
OpenMacroFile ENDP

;;; ----------------------------------------------------------------------------
;;; WriteFile
;;;
;;; Writes a buffer of bytes to a file handle
;;;
;;; Parameters:
;;;   BX = file handle
;;;   CX = number of bytes to write
;;;   DS:DX = data to write
;;; Returns:
;;;   AX = number of bytes written
;;; ----------------------------------------------------------------------------

WriteFile PROC
	pushf
	push	ax
	;; AH = 40h
	;; BX = file handle
	;; CX = number of bytes to write
	;; DS:DX -> data to write
	mov	ah, 40h
	int	DOS
	;; Return:
	;; CF clear if successful
	;; AX = number of bytes actually written
	;; CF set on error
	;; AX = error code (05h,06h) (see #01680 at AH=59h/BX=0000h)
	jnc	done
	mov	al, 'w'
	call	cs:[biosoutputchar]
	mov	ax, TERMINATE
	int	DOS

done:
	pop	ax
	popf
	ret
WriteFile ENDP

;;; ----------------------------------------------------------------------------
;;; CloseFile
;;;
;;; Writes a buffer of bytes to a file handle
;;;
;;; Parameters:
;;;   BX = file handle
;;; Returns:
;;;   None
;;; ----------------------------------------------------------------------------

CloseFile PROC
	pushf
	push	ax

	;; AH = 3Eh
	;; BX = file handle

	mov	ah, 3Eh
	int	DOS
	;; Return:
	;; CF clear if successful
	;; AX destroyed
	;; CF set on error
	;; AX = error code (06h) (see #01680 at AH=59h/BX=0000h)
	jnc	done
	mov	al, 'c'
	call	cs:[biosoutputchar]
	mov	ax, TERMINATE
	int	DOS

done:
	pop	ax
	popf
	ret
CloseFile ENDP

;;; ----------------------------------------------------------------------------
;;; ReadFile
;;;
;;; Reads bytes from a file handle into a buffer of bytes
;;;
;;; Parameters:
;;;   BX = file handle
;;;   CX = number of bytes to read
;;;   DS:DX = buffer to fill
;;; Returns:
;;;   AX = number of bytes written
;;; ----------------------------------------------------------------------------

ReadFile PROC
	pushf
	push	ax
	;; AH = 3Fh
	;; BX = file handle
	;; CX = number of bytes to read
	;; DS:DX -> buffer for data
	mov	ah, 3Fh
	int	DOS
	;; Return:
	;; CF clear if successful
	;; AX = number of bytes actually read (0 if at EOF before call)
	;; CF set on error
	;; AX = error code (05h,06h) (see #01680 at AH=59h/BX=0000h)
	jnc	done
	mov	al, 'r'
	call	cs:[biosoutputchar]
	mov	ax, TERMINATE
	int	DOS
done:
	pop	ax
	popf
	ret
ReadFile ENDP

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

	pushf
	push	si
	push	cx
	push	ax

	mov	al, 0dh
	mov	ah, 0eh
	int	16
	mov	al, 0ah
	mov	ah, 0eh
	int	16

	mov	si, offset cs:InfoMsg
	mov	cx, 250h
;	call	cs:[bioswritestring]
;	mov	cx, lengthof InfoMsg
;	mov	ah, 0eh

l1:
	cmp	cx, 00
	je	cs:[newl]

	mov	al, [si]
	int	16
	inc	si
	dec	cx
	jmp	cs:[l1]

newl:
	mov	al, 0dh
	int	16
	mov	al, 0ah
	int	16
	
	pop	ax
	pop	cx
	pop	si
	popf

	jmp	cs:[install]

install:	
	mov	di, offset cs:old_interrupt9	;install int9 handler

	mov	bx, offset cs:int9handler
	call	cs:[installResCode]

	mov	di, offset cs:old_interrupt16	;install int16 handler
	mov	si, 58h
	mov	bx, es:[si]
	mov	bp, bx
	add	si, 02h
	mov	ax, es:[si]
	mov	bx, offset cs:int16handler
	call	cs:[installResCode]

	mov	si, offset cs:AskUser
	mov	cx, lengthof AskUser

getinfo:
	cmp	cx, 00
	je	cs:[wearedone]

	mov	al, cs:[si]
	call	cs:[biosoutputchar]
	dec	cx
	inc	si
	jmp	cs:[getinfo]

wearedone:
	mov	al, 0dh
	int	16
	mov	al, 0ah
	int	16

	mov	ah, 00h
	int	16h
	cmp	al, 'y'
	jne	cs:[nonewmacrosdefined]

	mov	al, 0
	call	cs:[OpenMacroFile]
	mov	dx, cs
	mov	ds, dx
	mov	dx, offset cs:MacroDBptr
	mov	cx, 1584d
	call	cs:[ReadFile]
	call	cs:[CloseFile]

nonewmacrosdefined:
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

	mov	al, 1
	call	cs:[OpenMacroFile]
	mov	filehandle, bx
	mov	dx, cs
	mov	ds, dx
	mov	dx, offset cs:MacroDBptr
	mov	cx, 1584d
	mov	bx, filehandle
	call	cs:[WriteFile]
	call	cs:[CloseFile]

	mov	ax, 4c00h
	int	21h
	
bottom:
	mov	ax, 3100h
	mov	dx, offset cs:end_ISR
	mov	cl, 4
	shr	dx, cl
	inc	dx
	int	21h
	
END start
