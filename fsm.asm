TITLE FSM implementation

INCLUDE Irvine32.inc
INCLUDE defs.inc
INCLUDE fsm_protos_int.inc

PUBLIC curTok, vStack, vHeap, insBuf, argBuf
PUBLIC sPtr, iCount, aCount

.data
curTok BYTE ?							; Current token
vStack SDWORD STACK_MAX DUP (?)			; Virtual stack
vHeap SDWORD HEAP_MAX DUP (?)				; Virtual heap
insBuf BYTE INS_MAX DUP (?)				; Instruction buffer
argBuf SDWORD ARG_MAX DUP (?)				; Argument buffer
sPtr DWORD vStack						; Stack ptr
iCount DWORD 0							; Instruction ptr
aCount DWORD 0							; Argument ptr

.code
InterpretWS PROC,
	fileHandle:DWORD

; FSM for interpreting WS code
; Receives: EBP + 8 = fileHandle
; Returns: NA

IMP: GetNext STK, IMP_T, FLOW				; Imperative mode
IMP_T: GetNext ARITH, HP, IO				; Imp. tab submode

STK: GetNext PSH, STK_T, STK_L			; Stack mode
STK_T: GetNext CPY, Finished, SLD			; Stk. tab submode
STK_L: GetNext DPL, SWP, DSC				; Stk. LF submode

PSH:									; PUSH op
	PutWithArg I_PUSH
CPY:									; COPY op
	PutWithArg I_COPY
SLD:									; SLIDE op
	PutWithArg I_SLIDE
DPL:									; DUP op
	PutIA I_DUP
SWP:									; SWAP op
	PutIA I_SWAP
DSC:									; DISCARD op
	PutIA I_DISCARD

ARITH: GetNext ARITH_S, ARITH_T, Finished	; Arithmetic mode
ARITH_S: GetNext SADD, SSUB, SMUL			; Arith. space submode
ARITH_T: GetNext SDIV, SMOD, Finished		; Arith. tab submode

SADD:								; ADD op
	PutIA I_ADD
SSUB:								; SUB op
	PutIA I_SUB
SMUL:								; MUL op
	PutIA I_MUL
SDIV:								; DIV op
	PutIA I_DIV
SMOD:								; MOD op
	PutIA I_MOD

HP: GetNext STOR, LOD, Finished			; Heap mode

STOR:								; STORE op
	PutIA I_STORE
LOD:									; LOAD op
	PutIA I_LOAD

FLOW: GetNext FLOW_S, FLOW_T, FLOW_L		; Flow mode
FLOW_S: GetNext LBL, CLL, JUMP			; Flow space submode
FLOW_T: GetNext JMPZ, JMPS, SRET			; Flow tab submode
FLOW_L: GetNext Finished, Finished, OVER	; Flow LF submode

LBL:									; LABEL op
	PutWithArg I_LABEL
CLL:									; CALL op
	PutWithArg I_CALL
JUMP:								; JMP op
	PutWithArg I_JMP
JMPZ:								; JZ op
	PutWithArg I_JZ
JMPS:								; JS op
	PutWithArg I_JS
SRET:								; RET op
	PutIA I_RET
OVER:								; END op
	PutIA I_END

IO: GetNext IO_S, IO_T, Finished			; IO mode
IO_S: GetNext OCHAR, ONUM, Finished		; IO space submode
IO_T: GetNext ICHAR, INUM, Finished		; IO tab submode

OCHAR:								; OCHAR op
	PutIA I_OCHAR
ONUM:								; ONUM op
	PutIA I_ONUM
ICHAR:								; ICHAR op
	PutIA I_ICHAR
INUM:								; INUM op
	PutIA I_INUM

Finished:
	ret
InterpretWS ENDP

ExecWS PROC USES esi edi

; Executes instructions in buffer
; Receives: NA
; Returns: NA

	mov esi, 0						; Instruction = Argument offset
L1: 
	ExecIf I_PUSH, vPush				; This will be eventually replaced with a binary search
	ExecIf I_COPY, vCopy				; Kinda silly now but just temporary
	ExecIf I_SLIDE, vSlide				; Will macro it further as well
	ExecIf I_DUP, vDup
	ExecIf I_SWAP, vSwap
	ExecIf I_DISCARD, vDiscard
	ExecIf I_ADD, vAdd
	ExecIf I_SUB, vSub
	ExecIf I_MUL, vMul
	ExecIf I_DIV, vDiv
	ExecIf I_MOD, vMod
	ExecIf I_STORE, vStore
	ExecIf I_LOAD, vLoad
	ExecIf I_LABEL, vLabel
	ExecIf I_CALL, vCall
	ExecIf I_JMP, vJmp
	ExecIf I_JZ, vJz
	ExecIf I_JS, vJs
	ExecIf I_RET, vRet
	ExecIf I_END, vEnd
	ExecIf I_OCHAR, vOChar
	ExecIf I_ONUM, vONum
	ExecIf I_ICHAR, vIChar
	ExecIf I_INUM, vINum
Next:
	inc esi
	cmp esi, iCount
	jb L1

	ret
ExecWS ENDP

END