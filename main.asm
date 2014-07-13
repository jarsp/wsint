TITLE wsint, a whitespace interpreter
; Version: 0.1
; Created by: jarsp
; Last updated: 4 Jun 2014
;
; This is a whitespace interpreter written in MASM.
; Created for educational purposes (i.e. fun) and so that I can get more used to asm.
; Based on a FSM type structure.

INCLUDE Irvine32.inc
INCLUDE defs.inc
INCLUDE fsm_protos_ext.inc

.data?
fh DWORD ?							; Filehandle
.data
infile BYTE "script.ws"					; Temp file

.code
main PROC
	mov edx, OFFSET infile
	call OpenInputFile
	mov fh, eax
	INVOKE InterpretWS, fh
	INVOKE ExecWS
	exit
main ENDP

END main