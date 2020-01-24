;TITLE hexdump.asm
;Ian Nduhiu
;September 25th

.data

;fail messages incase of error
invalidFuncMsg BYTE "Invalid Function number",0
fileNotFoundMsg BYTE "File not Found",0
pathNotFoundMsg BYTE "Path not Found",0
toomanyFilesMsg BYTE "Too many open files",0
accessDeniedMsg BYTE "Access denied",0
invalidAccessMsg BYTE "Invalid Access Code",0
invalidRackMsg BYTE "Invalid Rack Configuration",0
openfailMsg BYTE "No such file or directory",0
noFilename BYTE "Wrong arguments: No/Multiple file name(s) provided",0

;to place file handle temporarily
inHandle WORD ?

;holds filename variable
filename BYTE 127 DUP (?)
 
;lower address to print out; starts at 0
Address WORD 0000h

;variable to hold higher address
Address2 WORD 0000h

;array holding 16 bytes being read
arrByte BYTE 16 DUP(?)
prevArr BYTE 16 DUP (?)

;chars contains ascii values for all possible characters for our digits
chars BYTE 48d, 49d, 50d, 51d, 52d, 53d, 54d, 55d, 56d, 57d,
	   'a', 'b', 'c', 'd', 'e', 'f'

;global symbolic constants for 21h interrupt and 4c00h function
dos = 21h		;to call dos
terminate = 4C00h	;function to terminate


.code
;--------------------------------------------------
GetCommandTail PROC
;
; Gets a copy of the MS-DOS command tail at PSP:80h.
; Receives: DX contains the offset of the buffer
; that receives a copy of the command tail.
; Returns: CF=1 if the buffer is empty; otherwise,
; Uses si and di for copying of the strings
; Uses ax for function calls in ah
; Uses cx as a counter for the loops
; Uses es and bx to get psp
; CF=0.
;--------------------------------------------------
	SPACE = 20h
	pushf				;save flags

	push	si			;save all registers to be modified
	push	es
	push	dx
	push	di
	push	cx
	push	bx
	push	ax

	mov 	ah,62h 			; get PSP segment address
	int 	21h 			; returned in BX
	mov 	es,bx 			; copied to ES

	mov 	si,dx 			; point to buffer
	mov 	di,81h 			; PSP offset of command tail
	mov 	cx,0 			; byte count
	mov 	cl,es:[di-1] 		; get length byte
	cmp 	cx,0 			; is the tail empty?
	je 	L2 			; yes: exit
	cld 				; scan in forward direction
	mov 	al,SPACE 		; space character
	repz 	scasb 			; scan for non space
	jz 	L2 			; all spaces found
	dec 	di 			; non space found
	inc 	cx
L1: 
	mov 	al,es:[di] 		; copy tail to buffer
	mov 	[si],al 		; pointed to by DS:SI
	inc 	si
	inc 	di
	loop 	L1
	clc 				; CF=0 means tail found
	jmp 	L3
L2: 
	stc 				; CF=1 means no command tail
	mov	dx, OFFSET noFilename	; "No file name provided"
	call	ErrorMsg
	jmp	bottom
L3: 
	mov 	byte ptr [si],0 	; store null byte

	call	openFile		;open and read the file

bottom:
	pop 	ax			;restore register and flag values
	pop	bx
	pop	cx
	pop	di
	pop	dx
	pop	es
	pop	si
	popf
	ret
GetCommandTail ENDP

;---------------------------------------
PrintTheChars PROC
;
;Prints out the characters read as bytes with |'s enclosing them
;Prints out unprintable characters as '.'
;Receives in ax the bytes actually read and returns no value
;Uses si for indexing the array
;Uses dx for character output in dl
;Uses ax for 02h function call
;Uses cx as loop counter
;Only writes to standard output
;---------------------------------------
	pushf			;save flag values
	
	push	si		;save to-be-modified reg values
	push	dx
	push	cx
	push	ax

	mov	dl, '|'		;prints out the first bar |
	push	ax		;temporarily save ax
	mov	ah, 02h
	int	dos

	pop	ax		;restore ax

	mov	cx, 00h		;set cx to 0
	mov	si, 00h		;set si to 0

L1:
	cmp	cx, ax		;check if we are done
	je	bottom		;if so, jump to bottom of procedure

	mov	dl, arrByte[si]	;checking if value is unprintable
	cmp	dl, 20h		;if below 20h...
	jb	unprintable	;...jump to unprintable
	cmp	dl, 7eh		;if above 80h...
	ja	unprintable	;...jump to unprintable

	push	ax		;temporarily save ax
	mov	ah, 02h		;write char to stdout function
	int	dos		;call dos!
	pop	ax		;restore ax

	inc	si		;increment our indexing register
	inc	cx		;increment our count tracker
	jmp	L1

unprintable:
	push	ax		;temporarily save ax
	mov	dl, '.'		;print out period for unprintable chars
	mov	ah, 02h
	int	dos
	pop	ax		;restore ax
	inc	si		;increment our indexing register
	inc	cx		;increment our count tracker
	jmp	L1

bottom:
	mov	dl, '|'		;print closing bar |
	mov	ah, 02h
	int	dos
	
	pop	ax		;restore register values
	pop	cx
	pop	dx
	pop	si

	popf			;restore flag values

	ret
PrintTheChars ENDP


;---------------------------------------
HexOut PROC
;
;Prints out the byte values read from file separated by spaces
;Receives ax as the number of bytes actually read
;Returns no value
;Uses si for indexing array
;Uses dx for output of ascii character in dl
;Uses cx as a loop counter, and cl to store shifting value
;Uses bx for shifting operations
;Uses ax for 02h output function
;Writes to standard output
;---------------------------------------
	pushf			;save flag values
	
	push	si		;save to-be-modified register values
	push	dx
	push	cx
	push	bx
	push	ax

	mov	si, 00h
	mov	cx, 00h		;initialize the counter
	
L1:
	cmp	cx, ax		;compare cx to number of bytes being read
	je	bottom		;if equal, jump to bottom

	mov	bl, arrByte[si]	;get current byte
	and	bx, 0F0h	;get upper nybble
	push	cx		;temporarily save cx
	mov	cl, 04h		;shift value is 4 bits to the right
	shr	bx, cl
	pop	cx		;restore cx
	mov	dl, chars[bx]
	push	ax		;temporarily save ax
	mov	ah, 02h		;write char function
	int	dos		;dos!!

	mov	bl, arrByte[si]	;get byte again
	and	bx, 0Fh		;save only last nybble
	mov	dl, chars[bx]
	int	dos

	pop	ax		;restore ax

	push	ax		;temporarily save ax again
	dec	ax		;decrement ax
	cmp	cx, ax		;check if we are at last char
	je	RetL1		;if equal, no space is output
	mov	dl, 20h		;output space character
	mov	ah, 02h
	int	dos

	cmp	cx, 07h		;check if we have output 8 bytes
	jne	RetL1
	mov	dl, 20h		;output another space
	mov	ah, 02h
	int	dos

RetL1:
	pop	ax		;finally restore ax
	inc	cx		;increment cx
	inc	si		;increment si
	jmp	L1

bottom:
	pop	ax		;restore register values
	pop	bx
	pop	cx
	pop	dx
	pop	si
	
	popf			;restore flag values			
	ret
HexOut ENDP


;-------------------------------
PrintAddress PROC
;
;Prints out address from which bytes are being read
;Receives in si the address to be printed out
;Returns no value
;Uses dx for output of ascii characters in dl
;Uses cx as a loop counter, and cl to store shifting value
;Uses bx for shifting operations
;Uses ax for 02h output function used with ah
;-------------------------------
	pushf			;save flag values

	push 	dx		;save register values dx, cx, bx, ax
	push	cx
	push	bx
	push	ax

	mov	ah, 02h

	mov	bx, si		;getting the 4th bit
	and	bx, 0F000h	;number to & by
	mov	cl, 0Ch		;shifting by 12 bits to the right
	shr	bx, cl
	mov	dl, chars[bx]	;move char to be printed into dl
	int	dos		;call dos

	mov	bx, si
	and	bx, 0F00h
	mov	cl, 08h		;shifting by 8 bits to the right
	shr	bx, cl
	mov	dl, chars[bx]
	int	dos

	mov	bx, si
	and 	bx, 0F0h
	mov	cl, 04h		;shifting by 4 bits to the right
	shr	bx, cl
	mov	dl, chars[bx]
	int	dos

	mov	bx, si
	and	bx, 0Fh		;will give us last byte, no need to shift
	mov	dl, chars[bx]
	int	dos

	pop	ax		;restore register values
	pop	bx
	pop	cx
	pop	dx

	popf			;restore flag values

	ret
PrintAddress ENDP


;--------------------------------------
copyArr PROC
;
;Function used to copy bytes from one array
;into the other array. Used to save previous
;bytes read for comparison in order to determine
;if a * is to be output.
;
;Uses si for indexing
;Uses cx for storing length of the array
;Uses ax as intermediate register for copying of 
;direct memory operands
;
;No value is returned
;
;--------------------------------------
	pushf			;save flag values
	
	push	si		;save registers to be modified
	push	cx
	push	ax

	mov	cx, LENGTHOF arrByte
	mov	si, 00h

L1:
	cmp	cx, 00h		;condition for loop termination
	je	bottom		;jump to end if we are done

	mov	al, arrByte[si]	;move into temp register
	mov	prevArr[si], al	;copy to array

	dec	cx		;reduce counter
	inc	si		;increment si
	jmp	L1

bottom:
	pop	ax		;restore modified register vals		
	pop	cx
	pop	si	

	popf			;restore flags
	ret
copyArr ENDP


;------------------------------------
openFile PROC
;
;Procedure that opens the file
;Uses dx for offset of filename
;Uses ah for the open file function, 3dh
;Uses al for the mode
;If open fails, carry flag is set and error message is
;written to standard output
;Returns no value
;------------------------------------
;save flag values
	pushf
	
;save register values
	push	dx
	push	ax

;open the file routine
	mov	ah, 3dh			;function
	mov	al, 00h			;mode
	mov	dx, OFFSET filename	;offset of filename
	int	21h			;dos!!!
	jc	failed			;if CF is set, throw error
	mov	inHandle, ax		;else, move handle to variable

	call	readBytes		;read and write out bytes
	jmp	bottom			;jump to bottom

failed:
;	mov	dx, OFFSET openfailMsg	;informative error msg
;	call	ErrorMsg

;Determine type of error to print out informative error message
	cmp	ax, 01h			;"Invalid function number"
	je	invalidFunc

	cmp	ax, 02h			;"File not found"
	je	fileNotFound

	cmp	ax, 03h			;"Path not found"
	je	pathNotFound

	cmp	ax, 04h			;"Too many files open"
	je	toomanyFiles

	cmp	ax, 05h			;"Access denied"
	je	accessDenied

	cmp	ax, 0Ch			;"Invalid Access code"
	je	invalidAccess

	cmp	ax, 56h			;"Invalid Rack Configuration"
	je	invalidRack

	mov	dx, OFFSET openfailMsg
	call	ErrorMsg
	jmp	bottom

invalidFunc:
	mov	dx, OFFSET invalidFuncMsg
	call	ErrorMsg
	jmp	bottom

fileNotFound:
	mov	dx, OFFSET fileNotFoundMsg
	call	ErrorMsg
	jmp	bottom

pathNotFound:
	mov	dx, OFFSET pathNotFoundMsg
	call	ErrorMsg
	jmp	bottom

toomanyFiles:
	mov	dx, OFFSET toomanyFilesMsg
	call	ErrorMsg
	jmp	bottom

accessDenied:
	mov	dx, OFFSET accessDeniedMsg
	call	ErrorMsg
	jmp	bottom

invalidAccess:
	mov	dx, OFFSET invalidAccessMsg
	call	ErrorMsg
	jmp	bottom

invalidRack:
	mov	dx, OFFSET invalidRackMsg
	call	ErrorMsg
	jmp	bottom

bottom:
	pop	ax
	pop	dx

	popf
	ret

openFile ENDP

;----------------------------
readBytes PROC
;
;The procedure that reads bytes from the file
;and outputs the address, the bytes read and their
;representative ascii characters if it is ascii-printable
;
;Uses si for printing the addresses, comparison of previous
;bytes read and current bytes
;Uses dx for offset of the buffer, output of characters
;Uses di for comparison of previous bytes read and current bytes
;together with si
;Uses cx as loop counter, and to hold number of bytes being read
;Uses bx to hold file handle, intermediate register for comparison
;of bytes for previous and current bytes read and outputting extra
;spaces when less bytes are read
;Uses ax to get actual bytes read, outputting characters using 02h
;function with ah and increment of address
;
;Returns no values
;----------------------------
	pushf				;save flag values

	push	si			;save register values
	push	dx
	push	di
	push	cx
	push	bx
	push	bp
	push	ax

	mov	ah, 3fh			;read bytes function
	mov	bx, inHandle		;move file handle
	mov	cx, 10h			;read 16 bytes
	mov	dx, OFFSET arrByte	;offset of buffer
	int	dos			;call	DOS

	cmp	ax, 00h			;check if file is empty
	je	bottom			;do nothing if file is empty
	
	cmp	ax, 10h			;check if it read less than 16 bytes
	jne	lessBytes		;go to lessBytes

	mov	si, Address2		;pass higher address in SI
	call	PrintAddress
	mov	si, Address		;pass lower address in SI
	call	PrintAddress

	mov	dl, 20h			;print space characters
	push	ax			;temporarily save ax
	mov	ah, 02h			;write char to stdout function
	int	dos
	int	dos
	pop	ax			;restore ax

	call	HexOut			;print out bytes
	push	ax			;temporarily save ax
	mov	ah, 02h			;write to std output function
	mov	dl, 20h			;space char
	int	dos
	int	dos			;two spaces
	pop	ax

	call	PrintTheChars		;print characters
	mov	ah, 02h
	mov	dl, 0Dh			;carriage return
	int	dos
	mov	dl, 0Ah			;line feed
	int	dos			;move to new line

	mov	ax, Address
	add	ax, 10h			;increment by 16
	mov	Address, ax

	call	copyArr			;move current array into prevarr

	mov	bp, 0h			;set bp to use for star printing

L1:
	mov	ah, 3fh			;read bytes function
	mov	bx, inHandle		;move file handle
	mov	cx, 10h			;read 16 bytes
	mov	dx, OFFSET arrByte	;offset of buffer
	int	dos			;call	DOS
	cmp	ax, 10h			;check if we read 16 bytes
	jne	lessBytes		;jump to less bytes

;check if prev and current are the same
	mov	si, OFFSET arrByte	;offset of bytes just read
	mov	di, OFFSET prevArr	;offset of previous read bytes
	mov	cx, 10h

cmpArrays:		
	cmp	cx, 00h
	je	printStarChar
	
	mov	bl, [si]
	cmp	bl, [di]
	jne	printOut
	inc	si
	inc	di
	dec	cx
	jmp	cmpArrays	

printOut:
	mov 	bp, 00h			;restore bp

	mov	si, Address2		;pass high address
	call	PrintAddress
	mov	si, Address		;pass low address in SI
	call	PrintAddress
	mov	dl, 20h			;print space characters
	push	ax			;temporarily save ax
	mov	ah, 02h			;write char to stdout function
	int	dos
	int	dos
	pop	ax			;restore ax

	call	HexOut			;print out bytes
	push	ax			;temporarily save ax
	mov	ah, 02h			;write to std output function
	mov	dl, 20h			;space character
	int	dos
	int	dos			;two spaces
	pop	ax

	call	PrintTheChars		;print characters
	jmp	NewCrLf

printStarChar:
	cmp	bp, 01h
	je	incrementAddress	
	mov	dl, '*'			;star character if prev and curr match
	mov	ah, 02h
	int	dos
	
	mov	dl, 0Dh			;printing the newline after *
	int	dos
	mov	dl, 0Ah
	int	dos

	mov	bp, 01h
	jmp	incrementAddress
	
NewCrLf:
	mov	ah, 02h
	mov	dl, 0Dh			;carriage return
	int	dos
	mov	dl, 0Ah			;line feed
	int	dos			;move to new line

	call	CopyArr			;move curr array into prev array

incrementAddress:
	mov	ax, Address
	add	ax, 10h			;increment by 16
	mov	Address, ax		;restore address
	cmp	ax, 0000h		;check if overflow happened
	jne	L1
	mov	ax, Address2		;move into ax to increase by 1
	inc	ax
	mov	Address2, ax		;restore higherAddress
	jmp	L1
	
lessBytes:
	cmp	ax, 00h
	je	printLength

	mov	si, Address2		;pass high address
	call	PrintAddress
	mov	si, Address		;pass low address in si register
	call	PrintAddress

	push	ax			;temporarily save ax
	mov	ah, 02h
	mov	dl, 20h			;space character
	int	dos
	int	dos
	pop	ax

	call	HexOut			;print remaining bytes
	push	ax			;save ax before printing out spaces

	mov	cx, 10h
	sub	cx, ax			;get number of spaces to output
	cmp	cx, 08h
	jae	setCx
	mov	bx, cx
	add	cx, bx			;bytes * 2
	dec	bx
	add	cx, bx			;space after each byte
	add	cx, 03h			;add 3 spaces
	jmp	printSpaces

setCx:
	mov	bx, cx
	add	cx, bx			;bytes * 2
	dec	bx
	add	cx, bx			;space after each byte
	add	cx, 04h			;add 4 spaces

printSpaces:
	cmp	cx, 0h
	je	printCharsandLength
	mov	dl, 20h
	mov	ah, 02h
	int	dos
	dec	cx
	jmp	printSpaces

printCharsandLength:
	pop	ax
	call	PrintTheChars
	push	ax
	mov	dl, 0Dh			;carriage return
	mov	ah, 02h
	int	dos
	mov	dl, 0Ah			;line feed
	int	dos
	pop	ax

printLength:
	mov	bx, Address
	add	ax, Address		;add to get length of file
	mov	Address, ax		;restore address

	mov	si, Address2
	call	PrintAddress
	mov	si, Address		;pass in si Adrress as parameter
	call	PrintAddress		;print the length

bottom:
	mov	ax, 0000h
	mov	Address, ax		;restore memory variables
	mov	Address2, ax		;restore memory variables


	pop	ax			;restore register values
	pop	bp
	pop	bx
	pop	cx
	pop	di
	pop	dx
	pop	si

	popf				;restore flag values
	ret
readBytes ENDP

;--------------------------------------
ErrorMsg PROC
;
;Writes an error message to standard output
;Receives offset of error message in dx
;
;Uses dx for output of characters
;Uses bx for indexing of array of bytes
;Uses ax for 02h function in ah
;
;Returns no value
;-------------------------------------
	pushf				;save flag values

	push	dx			;save register values
	push	bx
	push	ax

	mov	bx, dx			;move into bx(indexable)
	mov	dl, [bx]
L1:
	cmp	dl, 00h
	je	bottom

	mov	ah, 02h
	int	dos
	
	inc	bx
	mov	dl, [bx]
	jmp	L1

bottom:
	pop	ax
	pop	bx
	pop	dx

	popf
	ret		

ErrorMsg ENDP


main PROC
;-----------------------------------------------
;This is the main procedure of hexdump.asm.
;
;The file name is got from the command tail. If the
;file name is not provided or the file can not be opened,
;an error is thrown. Otherwise, the process of reading bytes
;commences. If the file is empty, nothing is written to standard
;output. Otherwise an initial address of 00000000h is output
;followed by the actual bytes, and the ascii characters corresponding
;to the bytes. If the ascii character is not printable, a "." is output
;instead. The procedure stops once we read less than 16 bytes. At the
;very end, the total number of bytes in the file is output, followed by
;a new line.
;
;-----------------------------------------------
	mov	ax, @data
	mov	ds, ax

	push	dx			;save ax and dx
	push	ax

	mov	dx, OFFSET filename
	call	GetCommandTail		;gets filename and puts it in buffer

	mov	dl, 0Dh			;output a carriage return...
	mov	ah, 02h
	int	21h
	mov	dl, 0Ah			;...followed by a line feed
	int	21h
	
	pop	ax			;restore ax and dx
	pop	dx

	mov	ax, terminate		;terminate function
	int	dos			;call dos
main ENDP
END main
