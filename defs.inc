TITLE Constant definitions, Macro definition, Proto definitions and more!

SPACE = 20h
TAB = 9h
LF = 0Ah
STACK_MAX = 4096
HEAP_MAX = 4096
INS_MAX = 4096
ARG_MAX = 4096
OPNUM = 24

I_PUSH = 0
I_COPY = 1
I_SLIDE = 2
I_DUP = 3
I_SWAP = 4
I_DISCARD = 5
I_ADD = 6
I_SUB = 7
I_MUL = 8
I_DIV = 9
I_MOD = 10
I_STORE = 11
I_LOAD = 12
I_LABEL = 13
I_CALL = 14
I_JMP = 15
I_JZ = 16
I_JS = 17
I_RET = 18
I_END = 19
I_OCHAR = 20
I_ONUM = 21
I_ICHAR = 22
I_INUM = 23

M_GetChar TEXTEQU <INVOKE GetNextChar, fileHandle>
M_GetArg TEXTEQU <INVOKE GetArg, fileHandle>

ifSp MACRO val:REQ
	cmp val, SPACE
ENDM

ifTb MACRO val:REQ
	cmp val, TAB
ENDM

ifLf MACRO val:REQ
	cmp val, LF
ENDM

GetNext MACRO lbl1:REQ, lbl2:REQ, lbl3:REQ
	LOCAL Top
Top:
	M_GetChar
	jz Finished						; EOF
	ifSp curTok						; Contents of buffer
	je lbl1							; Space read
	ifTb curTok
	je lbl2							; Tab read
	ifLf curTok
	je lbl3							; Lf read
	jmp Top							; Non-token char
ENDM

PutIns MACRO val:REQ
	push esi
	mov esi, iCount
	mov BYTE PTR insBuf[esi], val
	inc iCount
	pop esi
	jmp IMP
ENDM

PutArg MACRO val:REQ
	push esi
	mov esi, aCount
	mov DWORD PTR argBuf[esi * TYPE SDWORD], val
	inc aCount
	pop esi
ENDM

PutWithArg MACRO val:REQ
	M_GetArg
	jz Finished						; Error in reading argument
	PutArg eax
	PutIns val
ENDM

PutIA MACRO val:REQ
	PutArg 0
	PutIns val
ENDM

ExecIf MACRO insNum:REQ, funcName:REQ
	LOCAL After
	cmp insBuf[esi], insNum				; esi is the instruction offset
	jne After
	INVOKE funcName
	jmp Next
After:
ENDM

FetchArg MACRO reg
	mov reg, argBuf[esi * 4]
ENDM