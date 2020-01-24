;TITLE data.asm
;Ian Nduhiu
;Assignment 3
;9/7/2019

INCLUDE CS240.inc

.data
xB BYTE 20
xSb SBYTE -100
xW WORD 65510
xSw SWORD -32700
xDw DWORD 12345678h
xSdw SDWORD -2147483648
xFw FWORD 1000000323100
xQw QWORD 7834125612345678h
xTb TBYTE 800000000000001234h
xRfour REAL4 -1.2
xReight REAL8 2.2E-154
xRten REAL10 4.6E+3122
xLabel LABEL BYTE

.code
main PROC
	mov	ax, @data
	mov	ds, ax
	
	mov	dx, OFFSET xB		;offset of start of memory block
	mov	cx, xLabel - xB		;number of bytes to display
	call	DumpMem
	mov	ax, 4C00h
	int	21h			;wake up DOS
main ENDP
END main
