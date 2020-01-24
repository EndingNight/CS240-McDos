DOS		= 21h
BIOS		= 10h
TERMINATE	= 4C00h
	
NUL	= 0
LF	= 10
CR	= 13

.code
	
;;; ----------------------------------------------------------------------------
;;; CreateMacroFile
;;;
;;; Creates a file for writing macros
;;;
;;; Parameters:
;;;   None
;;; Returns:
;;;   BX = file handle
;;; ----------------------------------------------------------------------------
MacroFileName	BYTE "c:\macros.dat", NUL
CreateMacroFileError BYTE "Error creating file", CR, LF, NUL
CreateMacroFile PROC
	pushf
	push	ax
	push	cx
	push	dx
	push	ds

	mov	dx, cs
	mov	ds, dx
	mov	dx, OFFSET MacroFileName
	mov	cx, 2		; Writeable file
	mov	ah, 03Ch	; Create or truncate file
	int	DOS
	;; Return:
	;; CF clear if successful
	;; AX = file handle
	;; CF set on error
	;; AX = error code (03h,04h,05h) (see #01680 at AH=59h/BX=0000h)
	jnc	done
	mov	dx, OFFSET CreateMacroFileError
	call	WriteString
	mov	ax, TERMINATE
	int	DOS
done:
	mov	bx, ax
	pop	ds
	pop	dx
	pop	cx
	pop	ax
	popf
	ret
CreateMacroFile ENDP

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

OpenMacroFileError BYTE "Error creating file", CR, LF, NUL
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
	mov	dx, OFFSET MacroFileName
	mov	ah, 3Dh	; Open file
	mov	al, 0		; Read only
	int	DOS
	;; Return:
	;; CF clear if successful
	;; AX = file handle
	;; CF set on error
	;; AX = error code (01h,02h,03h,04h,05h,0Ch,56h) (see #01680 at AH=59h)

	jnc	done
	mov	dx, OFFSET OpenMacroFileError
	call	WriteString
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
WriteFileError BYTE "Error writing to file", CR, LF, NUL
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
	mov	dx, OFFSET WriteFileError
	call	WriteString
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
CloseFileError BYTE "Error closing file", CR, LF, NUL
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
	mov	dx, OFFSET CloseFileError
	call	WriteString
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
ReadFileError BYTE "Error reading from file", CR, LF, NUL
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
	mov	dx, OFFSET ReadFileError
	call	WriteString
	mov	ax, TERMINATE
	int	DOS
done:
	pop	ax
	popf
	ret
ReadFile ENDP

;;; ----------------------------------------------------------------------------
;;; SaveMacros
;;;
;;; Saves a block of memory to the macros file
;;;
;;; Parameters:
;;;   DX = Offset of macro buffer
;;;   CX = Size of macro buffer
;;; Returns:
;;;   None
;;; ----------------------------------------------------------------------------
MacrosNeedSaving BYTE 0
MacroBufferOffset WORD 0
MacroBufferSize WORD 0
SaveMacros PROC
	mov	cs:MacroBufferOffset, dx
	mov	cs:MacroBufferSize, cx
	mov	cs:MacrosNeedSaving, 1
	ret
SaveMacros ENDP

;;; ----------------------------------------------------------------------------
;;; InstallFileServices
;;;
;;; Enables saving of macro files from a TSR. This function must be called
;;; from a DOS client.
;;;
;;; Parameters:
;;;   None
;;; Returns:
;;;   None
;;; ----------------------------------------------------------------------------
GET_INDOS = 34h
InstallFileServices PROC
	push	ax
	push	bx
	push	dx
	push	ds
	push	es

	mov	cs:MacrosNeedSaving, 0
	mov	ah, GET_INDOS
	int	DOS
	mov	cs:INDOSSegment, es
	mov	cs:INDOSOffset, bx
	mov	ah, 35h
	mov	al, 1Ch
	int	21h
	mov	cs:OldDOSTimerHandlerSegment, es
	mov	cs:OldDOSTimerHandlerOffset, bx
	mov	al, 28h
	int	21h
	mov	cs:OldDOSIdleHandlerSegment, es
	mov	cs:OldDOSIdleHandlerOffset, bx
	mov	ah, 25h
	mov	al, 1Ch
	mov	dx, cs
	mov	ds, dx
	mov	dx, DOSTimerInterruptHandler
	int	21h
	mov	al, 28h
	mov	dx, DOSIdleInterruptHandler
	int	21h

	pop	es
	pop	ds
	pop	dx
	pop	bx
	pop	ax
	ret
InstallFileServices ENDP

;;; ----------------------------------------------------------------------------
;;; UninstallFileServices
;;;
;;; Unloads the file services. This code must be called from a DOS client.
;;;
;;; Parameters:
;;;   None
;;; Returns:
;;;   None
;;; ----------------------------------------------------------------------------
UninstallFileServices PROC
	push	ax
	push	dx
	push	ds

	mov	ah, 25h
	mov	al, 1Ch
	mov	dx, cs:OldDOSTimerHandlerSegment
	mov	ds, dx
	mov	dx, cs:OldDOSTimerHandlerOffset
	int	21h
	mov	al, 28h
	mov	dx, cs:OldDOSIdleHandlerSegment
	mov	ds, dx
	mov	dx, cs:OldDOSIdleHandlerOffset
	int	21h

	pop	ds
	pop	dx
	pop	ax
	ret
UninstallFileServices ENDP

;;; ----------------------------------------------------------------------------
;;; WaitForMacrosToSave
;;;
;;; This function blocks until the macro file has been written. You probably
;;; don't need this.
;;;
;;; Parameters:
;;;   None
;;; Returns:
;;;   None
;;; ----------------------------------------------------------------------------
WaitForMacrosToSave PROC
top:
	test	cs:MacrosNeedSaving, 1
	jnz	top
	ret
WaitForMacrosToSave ENDP

OldDOSIdleHandler LABEL DWORD
OldDOSIdleHandlerOffset WORD 0
OldDOSIdleHandlerSegment WORD 0

DOSIdleInterruptHandler PROC
	cli

	test	cs:MacrosNeedSaving, 1
	jz	nope

	call	AttemptToSaveMacros

nope:
	pushf
	call	cs:OldDOSIdleHandler
	sti
	iret
DOSIdleInterruptHandler ENDP

OldDOSTimerHandler LABEL DWORD
OldDOSTimerHandlerOffset WORD 0
OldDOSTimerHandlerSegment WORD 0

DOSTimerInterruptHandler PROC
	cli
	pushf

	test	cs:MacrosNeedSaving, 1
	jz	nope

	call	AttemptToSaveMacros
nope:
	pushf
	call	cs:OldDOSTimerHandler

	popf
	sti
	iret
DOSTimerInterruptHandler ENDP

INDOSFlag LABEL DWORD
INDOSSegment WORD 0
INDOSOffset WORD 0

AttemptToSaveMacros PROC
	pushf
	push	si
	push	es

	mov	es, cs:INDOSSegment
	mov	si, cs:INDOSOffset

	mov	si, es:[si - 1]
	cmp	si, 0
	jne	notready

	call	_SaveMacros
	;; Put the call to do the actual save here
	mov	cs:MacrosNeedSaving, 0

notready:
	pop	es
	pop	si
	popf
	ret
AttemptToSaveMacros ENDP

_SaveMacros PROC
	push	cx
	push	dx
	push	ds

	call	CreateMacroFile
	mov	dx, cs
	mov	ds, dx
	mov	dx, cs:MacroBufferOffset
	mov	cx, cs:MacroBufferSize
	call	WriteFile
	call	CloseFile

	pop	ds
	pop	dx
	pop	cx
	ret
_SaveMacros ENDP
