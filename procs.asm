TITLE Procedure library

INCLUDE Irvine32.inc
INCLUDE defs.inc

EXTERN curTok:BYTE, vStack:SDWORD, vHeap:SDWORD, insBuf:BYTE, argBuf:SDWORD
EXTERN lblBuf:SDWORD, sPtr:PTR SDWORD, iCount:DWORD, aCount:DWORD, lblPtr:DWORD

.code
GetNextChar PROC USES eax edx ecx,
	fileHandle:DWORD

; Reads the next char into the buffer
; Receives: EBP + 8 = fileHandle
; Returns: Sets ZF if reach eof

	mov eax, fileHandle
	mov edx, OFFSET curTok
	mov ecx, 1
	call ReadFromFile
	test eax, eax

	ret
GetNextChar ENDP

GetArg PROC USES ebx,
	fileHandle:DWORD

; Gets a number/label argument
; Labels all treated as unsigned
; Does not produce Tmin properly
; Receives: EBP + 8 = fileHandle
; Returns: EAX = Signed int
;		 ZF is set if reached EOF
; Note: To indicate zero, use [LF] (pref), [SP/TB][LF], or [SP/TB][SP][LF]

	mov eax, 0
	mov bl, 0							; Sign
Start:
	M_GetChar
	jz Done							; Invalid input
	ifTb curTok
	jne NotNeg
	mov bl, 1							; Negative number
	jmp Next
NotNeg:
	ifLf curTok
	je DoNeg							; Single LF, arg is 0
	ifSp curTok
	je Next							; Num is positive
	jmp Start							; Not a token
Next:
	shl eax, 1						; prepare next bit
NotToken:
	M_GetChar
	jz Done							; Invalid input
	ifTb curTok
	jne NotTab
	or eax, 1							; Set bit if tab
	jmp Next
NotTab:
	ifLf curTok
	je DoNeg							; Lf signifies the end
	ifSp curTok
	jne NotToken						; Not a token, cannot shl
	jmp Next							; Space, don't need to set bit but must shl
DoNeg:
	shr eax, 1						; shifted once too many (before LF was read)
	cmp bl, 0
	je ClrError						; Num is pos, no need to do anyth
	neg eax							; Num is negative, negate
ClrError:
	or bl, 1							; clear ZF on a successful return from the function
Done:

	ret
GetArg ENDP

GetLabelDest PROC USES edi ebx

; Gets the line pointed to by label in eax.
; Receives: EAX = label
; Returns: EAX = destination

	mov ebx, 0
	mov edi, lblPtr
Top:
	cmp eax, lblBuf[ebx]
	je Found
	add ebx, 2 * TYPE SDWORD
	cmp ebx, edi
	jl Top
	mov eax, -2					; Not found, will be -1 after esi inc

	ret
Found:
	mov eax, lblBuf[ebx + TYPE SDWORD]
	
	ret
GetLabelDest ENDP

vPush PROC USES eax ebx

; PUSH function
; Receives: ESI = offset from argBuf
; Returns: NA

	mov eax, sPtr
	FetchArg ebx
	mov [eax], ebx
	add sPtr, TYPE SDWORD
	
	ret
vPush ENDP

vCopy PROC USES eax ebx

; Copy nth element from stack ptr (0 indexed) to top of stack
; Receives: ESI = offset from argBuf
; Returns: NA

	FetchArg eax
	mov ebx, sPtr
	shl eax, 2						; Mul by TYPE SDWORD
	sub ebx, eax
	sub ebx, TYPE SDWORD				; Zero indexed
	mov eax, vStack[eax]
	mov ebx, sPtr
	mov [ebx], eax
	add sPtr, TYPE SDWORD
	
	ret
vCopy ENDP

vSlide PROC USES eax ebx ecx

; Slides n items off top of stack, excluding top item
; Receives: ESI = offset from argBuf
; Returns: NA
	
	FetchArg eax
	shl eax, 2
	mov ebx, sPtr
	sub sPtr, eax							; Adjust stack ptr
	sub ebx, TYPE SDWORD					; Location of top elem

	mov ecx, ebx
	sub ecx, eax							; Move top elem here

	mov eax, [ebx]
	mov [ecx], eax							; Moved

	ret
vSlide ENDP

vDup PROC USES eax ebx

; Duplicates the top element of the stack
; Receives: NA
; Returns: NA

	mov eax, sPtr
	mov ebx, [eax - TYPE SDWORD]
	mov [eax], ebx
	add sPtr, TYPE SDWORD

	ret
vDup ENDP

vSwap PROC USES eax ebx

; Swaps top two elements of stack
; Receives: NA
; Returns: NA

	mov eax, sPtr
	mov ebx, [eax - TYPE SDWORD]
	xchg ebx, [eax - 2 * TYPE SDWORD]
	mov [eax - TYPE SDWORD], ebx

	ret
vSwap ENDP

vDiscard PROC

; Discards top element of stack
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD

	ret
vDiscard ENDP

vAdd PROC USES eax ebx

; Adds top two elements of stack, replaces them with the sum
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov eax, sPtr
	mov ebx, [eax]
	add [eax - TYPE SDWORD], ebx
	
	ret
vAdd ENDP

vSub PROC USES eax ebx

; Subs the top element from the one preceding it, replaces them
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov eax, sPtr
	mov ebx, [eax]
	sub [eax - TYPE SDWORD], ebx

	ret
vSub ENDP

vMul PROC USES eax ebx

; Multiplies the top two elements, replaces them
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov ebx, sPtr
	mov eax, [ebx - TYPE SDWORD]
	imul eax, [ebx]
	mov [ebx - TYPE SDWORD], eax

	ret
vMul ENDP

vDiv PROC USES eax ebx ecx edx

; Integer division
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov ecx, sPtr
	mov ebx, [ecx]
	mov eax, [ecx - TYPE SDWORD]
	cdq
	idiv ebx
	mov [ecx - TYPE SDWORD], eax

	ret
vDiv ENDP

vMod PROC USES eax ebx ecx edx

; Modulus
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov ecx, sPtr
	mov ebx, [ecx]
	mov eax, [ecx - TYPE SDWORD]
	cdq
	idiv ebx
	mov [ecx - TYPE SDWORD], edx

	ret
vMod ENDP

vStore PROC USES eax ebx

; Stores a value into memory.
; Push the offset (zero-indexed) then the value, then call this command
; Arguments are cleaned up
; Receives: NA
; Returns: NA

	mov eax, sPtr
	mov ebx, [eax - 2 * TYPE SDWORD]
	mov eax, [eax - TYPE SDWORD]
	mov vHeap[ebx * TYPE SDWORD], eax
	sub sPtr, 2 * TYPE SDWORD

	ret
vStore ENDP

vLoad PROC USES eax ebx

; Loads a value from memory into top position on stack
; Push the offset (zero-indexed) and then call this command
; Args are removed before putting onto stack
; Receives: NA
; Returns: NA

	mov eax, sPtr
	mov eax, [eax - TYPE SDWORD]
	mov eax, vHeap[eax * TYPE SDWORD]
	mov ebx, sPtr
	mov [ebx - TYPE SDWORD], eax

	ret
vLoad ENDP

vLabel PROC

; Doesn't do anything. Labels are processed in the first pass.

	ret
vLabel ENDP

vCall PROC USES eax

; Calls a subroutine by a 32-bit label.
; Sets up the requisite stack frame (well, just the eip).
; No error checking yet
; Receives: ESI = instruction pointer
; Returns: NA

	mov eax, sPtr
	mov [eax], esi					; esi not decrem., so when incremented, points to next ins.
	add sPtr, TYPE SDWORD
	FetchArg eax
	call GetLabelDest
	mov esi, eax

	ret
vCall ENDP

vJmp PROC USES eax

; Jumps to a specified label (i.e. currently instruction number)
; Receives: ESI = instruction pointer
; Returns: NA

	FetchArg eax
	call GetLabelDest
	mov esi, eax

	ret
vJmp ENDP

vJz PROC USES eax ebx

; Jumps to a specified label if top of stack is 0
; Receives: ESI = instruction pointer
; Returns: NA

	mov eax, sPtr
	mov ebx, 0
	cmp [eax - TYPE SDWORD], ebx
	jne NoJump
	FetchArg eax
	call GetLabelDest
	mov esi, eax
NoJump:

	ret
vJz ENDP

vJs PROC USES eax ebx

; Jumps to a specified label if top of stack is neg
; Receives: ESI = instruction pointer
; Returns: NA

	mov eax, sPtr
	mov ebx, 0
	cmp [eax - TYPE SDWORD], ebx
	jnl NoJump
	FetchArg eax
	call GetLabelDest
	mov esi, eax
NoJump:

	ret
vJs ENDP

vRet PROC

; Returns from a function call. Make sure local vars are cleaned first!
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov esi, sPtr
	mov esi, [esi]

	ret
vRet ENDP

vEnd PROC

; Ends the program
; Receives: NA
; Returns: NA

	mov iCount, 0

	ret
vEnd ENDP

vOChar PROC USES eax

; Outputs an ASCII formatted char from the top of the stack
; Removes the char at the top of the stack
; Auto-compensates for windows CRLF
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov eax, sPtr
	mov eax, [eax]
	cmp eax, 0Ah							; Handle CRLF
	jne Write
	call Crlf
	jmp After
Write:
	call WriteChar
After:
	
	ret
vOChar ENDP

vONum PROC USES eax

; Outputs a 32-bit signed decimal num from the top of the stack
; Removes the number from top of stack
; Receives: NA
; Returns: NA

	sub sPtr, TYPE SDWORD
	mov eax, sPtr
	mov eax, [eax]
	call WriteInt

	ret
vONum ENDP

vIChar PROC USES eax ebx ecx

; Reads in a single ASCII character onto the top of the stack
; Char is echoed onto screen
; If a control key is pressed, result is 0
; Receives: NA
; Returns: NA

	mov ebx, sPtr
	call ReadChar
	cmp al, 0dh					; Handle CRLF echoing; 0dh is read when enter pressed
	jne NotCR
	call Crlf
	mov eax, 0ah
	jmp Put
NotCR:
	call WriteChar
Put:
	movzx ecx, al
	mov [ebx], ecx
	add sPtr, TYPE SDWORD

	ret
vIChar ENDP

vINum PROC USES eax ebx

; Reads in a signed 32-bit decimal int from the screen onto the stack
; 0 if integer overflows
; Currently puts an ugly + for positive nos.
; Will eventually write a subroutine for this
; Receives: NA
; Returns: NA

	mov ebx, sPtr
	call ReadInt
	mov [ebx], eax
	add sPtr, TYPE SDWORD

	ret
vINum ENDP

END