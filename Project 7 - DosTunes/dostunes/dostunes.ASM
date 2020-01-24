
INCLUDE cs240.inc

TERMINATE=4C00h
DOS=21h

.386

;PlayNoteString PROTO
;NoteFrequencyToTimerCount PROTO
;NoteDelay PROTO
;InterNoteDelay PROTO

TIMER_DATA_PORT		= 42h
TIMER_CONTROL_PORT	= 43h
SPEAKER_PORT		= 61h
READY_TIMER		= 0B6h

freq = 1193180

.data

chars BYTE '0','1','2','3','4','5','6','7','8','9'

tempBpm BYTE 5 DUP(?)

BIOS = 16

filesize WORD ?

tempbxholder WORD ?

tempo WORD 0
Startwholenote DWORD 240000d			;mov to eax, divide by bpm

basewholenote WORD ?					;after divide
notetime WORD ?
restflag WORD 0

;order in octave tables is c,c#,d,d#,e,f,f#,g,g#,a,a#,b
octave0 WORD 16,17,18,19,21,22,23,24,26,27,29,31
octave1 WORD 33,35,37,39,41,44,46,49,52,55,58,62
octave2 WORD 65,69,73,78,82,87,92,98,104,110,116,123
octave3 WORD 131,139,147,155,165,175,185,196,208,220,233,245
octave4 WORD 262,277,294,311,330,349,370,392,415,440,466,494
octave5 WORD 523,554,587,622,659,698,740,784,831,880,932,988
octave6 WORD 1046,1109,1175,1244,1328,1397,1480,1568,1661,1760,1865,1975
octave7 WORD 2093,2217,2349,2489,2637,2794,2960,3136,3322,3520,3729,3951


colors0 WORD 1,4,5,9,10,13,47,63,79,95,32,48
		WORD 1,4,5,9,10,13,47,63,79,95,32,48
		WORD 1,4,5,9,10,13,47,63,79,95,32,48
		WORD 1,4,5,9,10,13,47,63,79,95,32,48
		WORD 1,4,5,9,10,13,47,63,79,95,32,48
		WORD 1,4,5,9,10,13,47,63,79,95,32,48
		WORD 1,4,5,9,10,13,47,63,79,95,32,48
		WORD 1,4,5,9,10,13,47,63,79,95,32,48

colorsclef WORD 32,48,64,80,32

colorsoffset WORD ?
colordist WORD ?

curr_x WORD 0
curr_y WORD 130


tempx WORD ?
tempy WORD ?


currylookup WORD 130,135,140,145,150,155,160,165,170,175,180,185

x_factor WORD ?
y_factor WORD ?


score	BYTE	10000 dup(0)

individualnotes BYTE 'CDEFGAB'
indexesnotes BYTE 0,4,8,10,14,18,22

lengthsymbols BYTE 'w','h','q','e','s'
lengths WORD 1,2,4,8,16

FileName BYTE 127 DUP(?)
openfailMsg BYTE "File can not be opened",0
nofilename BYTE "No file name provided",0

diffHM WORD 0
diffSmS WORD 0
targetHM WORD 0
targetSmS WORD 0

inHandle WORD ?


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
	mov	ah, 0eh
	mov	al, '2'
	int	16

bottom:
	pop	ax
	pop	dx

	popf
	ret

openFile ENDP


getandsetTempo PROC
	pushf
	pushad

	mov	si, offset score
	mov bx, 0h
	mov cl, 'b'

l1:
	cmp	[si], cl
	je	done

	mov	al, [si]
	mov	tempBpm[bx], al

	inc si
	inc bx
	jmp l1

done:	;jump 3+2chars ahead
	add bx, 05h
	mov tempbxholder, bx
	sub bx, 05h

	mov	cx, 1
l2:
	cmp bx, 0
	je	done2
	mov	si, 0
l3:
	mov	al, chars[si]
	cmp	tempBpm[bx-1], al
	je	charfound
	inc si
	jmp l3
charfound:
	mov	ax, si
	mul	cx

	add tempo, ax
	push bx
	mov bx, 10
	mov	ax, cx
	mul bx
	mov cx, ax
	pop bx
	dec bx
	jmp l2

done2: ;set basewholenote
	mov edx, 0
	mov ebx, edx
	mov eax, Startwholenote
	mov bx, tempo
	div ebx
	mov basewholenote, ax

	popad
	popf
	mov bx, tempbxholder
	ret
getandsetTempo ENDP


readBytes PROC
	pushf
	pushad

	mov	ah, 3fh
	mov	bx, inHandle
	mov	cx, 10000
	mov	dx, offset score
	int	dos
	jc	error
	mov	filesize, ax
	call	getandsetTempo		;returns in bx new start point
	
reading:					;-----
	cmp	bx, filesize
	jae	donewithreading

	mov	si, 0
	mov	di, offset octave0
	mov	dx, offset colors0
	mov	al, score[bx]

	cmp	al, 0dh
	je	resetreading
	cmp	al, 0ah
	je	resetreading

	cmp	al, '8'					;rest
	je	resttime
subloop1: 
	cmp	chars[si], al
	je	setoctave
	inc	si
	jmp	subloop1
setoctave:						;di has the octave we are in
	cmp	si, 0
	je	notelength

	add	di, 24
	add	dx, 24
	dec si
	jmp	setoctave

resttime:
	mov	restflag, 1

notelength:						;--------
	mov	colorsoffset, dx			;colors table to look up in

	inc	bx
	mov	si, 0
	mov	al, score[bx]
subloop2:
	cmp	lengthsymbols[si], al
	je	lengthfound
	inc	si
	jmp	subloop2
lengthfound:				;-------
	mov	ax, si
	add	si, ax
	
	mov	dx, 0
	mov	cx, lengths[si]
	mov	ax, basewholenote
	div	cx
	mov	notetime, ax			;length of note

	mov	ax, restflag
	cmp	ax, 01
	jne	norestfound
	mov	ax, 0
	mov	restflag, ax
	mov	ax, notetime
	push	ax
	call	NoteDelay
	pop	ax
	jmp	resetreading

norestfound:
	inc	bx
	mov	al, score[bx]

	cmp	al, '.'
	jne	therest
	call	dottime
	inc	bx
	mov	al, score[bx]

therest:
	;check if # or b
	cmp	al, '#'
	je	sharpnote
	cmp	al, 'b'
	je	flatnote

	mov	si, 0
lookupnote:
	cmp individualnotes[si], al
	je	notefound
	inc	si
	jmp	lookupnote

sharpnote:				;-------
	inc	bx
	mov	al, score[bx]
	mov	si, 0
lookupnotesharp:
	cmp individualnotes[si], al
	je	notefoundsharp
	inc	si
	jmp	lookupnotesharp
notefoundsharp:
	mov	ax, 0
	mov	al, indexesnotes[si]
	add	di, ax
	add	di, 02h

	add	ax, 02h
	mov	colordist, ax
	add	colorsoffset, ax
	jmp	playnote
	
flatnote:					;--------
	inc	bx
	mov	al, score[bx]
	mov	si, 0
lookupnoteflat:
	cmp individualnotes[si], al
	je	notefoundflat
	inc	si
	jmp	lookupnoteflat
notefoundflat:
	mov	ax, 0
	mov	al, indexesnotes[si]
	add	di, ax
	sub	di, 02h

	sub	ax, 02h
	mov	colordist, ax
	add	colorsoffset, ax
	jmp	playnote

notefound:
	mov	ax, 0
	mov	al, indexesnotes[si]
	mov	colordist, ax	;updates distance for x and y lookup
	add	di, ax			;gets the note we are playing
	add colorsoffset, ax	;gets color to use

	;at this point, I have delay-time in notetime, and note in [di]

playnote:				;--------
	call	PlayFrequency

resetreading:
	inc	bx
	jmp	reading

error:
	mov	ah, 0eh
	mov	al, '1'
	int	16

donewithreading:		;--------
	popad
	popf
	ret
readBytes ENDP

dottime PROC
	pushf
	pushad

	mov	dx, 0
	mov	ax, notetime
	mov	cx, 2
	div	cx
	add	notetime, ax

	popad
	popf
	ret
dottime ENDP


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

SpeakerMuted	BYTE	0

Mute PROC
	mov	cs:SpeakerMuted, 1
	ret
Mute ENDP

UnMute PROC
	mov	cs:SpeakerMuted, 0
	ret
UnMute ENDP

SpeakerOn PROC
	pushf
	push	ax

	test	cs:SpeakerMuted, 1
	jnz	muted

	in	al, SPEAKER_PORT		; Read the speaker register
	or	al, 03h				; Set the two low bits high
	out	SPEAKER_PORT, al		; Write the speaker register
	jmp	done
muted:
	push	dx
	mov	dl, 02h
	call	WriteChar
	pop	dx
done:
	pop	ax
	popf
	ret
SpeakerOn ENDP

SpeakerOff PROC

	pushf
	push	ax

	in	al, SPEAKER_PORT		; Read the speaker register
	and	al, 0FCh			; Clear the two low bits high
	out	SPEAKER_PORT, al		; Write the speaker register

	pop	ax
	popf
	ret
SpeakerOff ENDP

;----------------------------------
NoteDelay PROC
;
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
	cmp	ch, 24				;check if midnight
	jne	setTHM
	mov	ch, 00				;set to 00

setTHM:
	mov	targetHM, cx			;set target hours and minutes

	call	Setupgraphics
	
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

	call	Resetgraphics

	pop	ax				;restore registers and flags
	pop	bx
	pop	cx
	pop	dx
	popf
	pop	bp
	ret
NoteDelay ENDP

InterNoteDelay PROC
    ret
InterNoteDelay ENDP

NoteFrequencyToTimerCount PROC		;receives in  [di] note, returns in dx the div
	pushf
	push	eax
	push	ebx
	push	edi

	mov	ebx, 0
	mov	bx, [di]
	mov	edx, 0
	mov	eax, freq
	div	ebx
	mov	edx, eax

	
	pop	edi
	pop	ebx
	pop	eax
	popf

	ret
NoteFrequencyToTimerCount ENDP


PlayFrequency PROC					;param: [di] - note, timetodelay-notetime
	;; Frequency is found in DX

	pushf
	pushad

	call	NoteFrequencyToTimerCount

	mov	al, READY_TIMER			; Get the timer ready
	out	TIMER_CONTROL_PORT, al

	mov	al, dl
	out	TIMER_DATA_PORT, al		; Send the count low byte

	mov	al, dh
	out	TIMER_DATA_PORT, al		; Send the count high byte

	call	SpeakerOn
	mov	ax, notetime
	push	ax
	call	NoteDelay
	call	SpeakerOff
;	call	InterNoteDelay
	pop	ax

	popad
	popf
	ret
PlayFrequency ENDP


GetVideoMode PROC
	push	cx
	push	ax
	
	mov	ah, 0fh
	int	BIOS
	mov	cl, al
	
	pop	ax
	mov	al, cl
	pop	cx
	ret
GetVideoMode ENDP
	
	
SetVideoMode PROC
	push	ax
	
	mov	ah, 00
	int	BIOS
	
	pop	ax
	ret
SetVideoMode ENDP

DrawPixel PROC
	;; Screen resolution is 320x200

	push	ax
	push	dx
	push	di
	push	es
	
	mov	ax, 320
	mul	dx		; AX = 320 * Y
	add	ax, cx		; AX = 320 * Y + X
	
	mov	di, ax		; Set di to the offset

	push	dx
	mov	dx, 0A000h		; Set ES to the video segment
	mov	es, dx
	pop	dx
	
	mov	BYTE PTR es:[di], bl ; Set the pixel to the given color
	
	pop	es
	pop	di
	pop	dx
	pop	ax
	ret
DrawPixel ENDP

Setupgraphics PROC
	pushf
	pushad

;horizontal line
	mov	dx, colordist
	mov	si, offset currylookup
	add	si, dx
	mov	dx, [si]				;starting y
	mov	cx, curr_x				;starting x
	mov	si, colorsoffset
	mov	bx, [si]
;	call	Drawcurrline

	mov	ah, 00
	int	1ah
	push	dx
	mov	dx, 0
	pop	ax
	mov	ah, 0
	mov	cx, 5
	div	cx
	mov	si, dx
	add	si, dx
	mov	bx, colorsclef[si]
	call	theeye
;	call	drawclefs

	
	popad
	popf
	ret
Setupgraphics ENDP

Resetgraphics PROC			;same as setgraphics, but using black
	pushf
	pushad

;horizontal line
	mov	dx, colordist
	mov	si, offset currylookup
	add	si, dx
	mov	dx, [si]				;starting y
	mov	cx, curr_x				;starting x
	mov	bx, 255
;	call	Drawcurrline
	call	theeye
;	call	drawclefs

	popad
	popf
	ret
Resetgraphics ENDP


Drawcurrline PROC
	pushf
	pusha

	jmp	drawcurrcond
drawhori:
	call	DrawPixel
	inc	cx
drawcurrcond:
	cmp	cx, 320
	jl	drawhori

	popa
	popf
	ret
Drawcurrline ENDP


setupbackground PROC
	pushf
	pusha

	mov	bx, 255
	mov	cx, curr_x
	mov	dx, curr_y
drawingcurrlines:
	cmp	dx, 185
	jae	donewithright

	jmp	condcurr
l1curr:
	call	DrawPixel
	inc	cx
condcurr:
	cmp	cx, 320
	jl	l1curr
	mov	cx, 0
	add	dx, 5
	jmp	drawingcurrlines

donewithright:

	popa
	popf
	ret
setupbackground ENDP


theeye PROC
	pushf
	pusha

	mov	cx, 160
	mov	dx, 10
	mov	si, 90
	mov	tempx, cx
	mov	tempy, dx
restorefill:
	cmp	cx, 251
	je	donerestore

fillpupil:
	cmp	si, -1
	je	donefill

	push	cx
	push	dx
	mov	ah, 00h
	int	1ah
	mov	bx, dx
	add	bx, si
	mov	bh, 00
	pop	dx
	pop	cx

	call	DrawPixel
	dec	cx
	inc	dx
	dec	si
	jmp	fillpupil
donefill:
	mov	cx, tempx
	mov	dx, tempy
	inc	cx
	inc	dx
	mov	si, 90
	mov	tempx, cx
	mov	tempy, dx
	jmp	restorefill
donerestore:
	popa
	popf
	ret
theeye ENDP

drawdoubleclefs PROC		;recevies starting x in si, y in di
	pushf
	pusha

	call	drawsingleclef
	mov	cx, si
	mov	dx, di
	mov	ax, 20
	add	ax, cx
	call	DrawPixel
clef1:
	cmp	cx, ax
	jae	clef1downright
	call	DrawPixel
	inc	cx
	jmp	clef1
clef1downright:
	mov	si, cx
	mov	di, dx
	call	drawsingleclef

	popa
	popf
	ret
drawdoubleclefs ENDP

drawsingleclef PROC			;recevies in si x, di y
	pushf
	pusha

	mov	ax, 20
	add	ax, di
	mov	cx, si
	mov	dx, di
straight:
	cmp	dx, ax
	je	hook
	call	DrawPixel
	inc	dx
	jmp	straight
hook:
;	mov	ax, 5
;hookl:
;	cmp	ax, 0
;	je	donewithsingle
;	call	DrawPixel
;	dec	cx
;	dec	dx
;	dec	ax
;	jmp	hookl
	call	drawpixel
	inc	dx
	dec	cx
	call	drawpixel
	dec	cx
	call	drawpixel
	dec	cx
	dec	dx
	call	drawpixel
	dec	dx
	call	drawpixel
	inc	cx
	dec	dx
	call	drawpixel
	inc	cx
	call	drawpixel
	inc	cx
	inc	dx
	call	drawpixel
donewithsingle:
	popa
	popf
	ret
drawsingleclef ENDP

drawclefs PROC
	pushf
	pusha

	mov	si, 30
	mov	di, 90
	call	drawdoubleclefs

	mov	si, 290
	mov	di, 20
	call	drawsingleclef

	popa
	popf
	ret
drawclefs ENDP


main PROC
	mov     ax, @data
    mov     ds, ax

	call	GetVideoMode
	push	ax
	mov	al, 13h		; 320x200 x 256 colors
	call	SetVideoMode

;	call	setupbackground
	call	theeye
;	mov	bx, 255
;	call	drawclefs

	call	SpeakerOn
	mov	dx, offset filename
	call	GetCommandTail
	call	SpeakerOff

	pop	ax
	call	SetVideoMode

   	mov     ax, TERMINATE
    int     DOS
main ENDP

END main
