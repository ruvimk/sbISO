include \masm32\include\windows.inc 
include \masm32\include\gdi32.inc 
include \masm32\include\masm32.inc 
include \masm32\include\user32.inc 
include \masm32\include\msvcrt.inc 
include \masm32\include\wsock32.inc 
include \masm32\include\ws2_32.inc 
include \masm32\include\shell32.inc 
include \masm32\include\comdlg32.inc 
include \masm32\include\winspool.inc 
include \masm32\include\kernel32.inc 
includelib \masm32\lib\gdi32.lib 
includelib \masm32\lib\masm32.lib 
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\msvcrt.lib 
includelib \masm32\lib\wsock32.lib 
includelib \masm32\lib\ws2_32.lib 
includelib \masm32\lib\shell32.lib 
includelib \masm32\lib\comdlg32.lib 
includelib \masm32\lib\winspool.lib 
includelib \masm32\lib\kernel32.lib 
integer macro a 
	LOCAL b 
	;; Defines an integer in memory with the value a and returns its memory address. 
	.data 
	ifnb <a> 
		b dd a 
	else 
		b dd 0 
	endif 
	.code 
	exitm <offset b> 
endm 
string macro p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, \
p31, p32 
	LOCAL a 
	ifnb <p1> 
	;; Saves a string (up to 32 entries (ex. string "Hello World!", 13, 10, 13, 10, ".....  " makes 6 entries)) and returns its memory address. 
	.data 
	a db p1 
	for entry, <p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, \
p31, p32> 
		ifnb <entry> 
			db entry 
		endif 
	endm 
	db 0 
	else 
		.data? 
		a         DB  512 dup (?) 
	endif 
	.code 
	exitm <offset a> 
endm 
space macro s 
	LOCAL a 
	.data? 
	a       DB  s dup (?) 
	.code 
	exitm <offset a> 
endm 
set_space macro a, b, c 
	LOCAL p1, p2 
	push eax 
	push ebx 
	push ecx 
	mov ebx, a 
	mov al, b 
	mov ecx, c 
	p1: 
		jecxz p2 
		dec ecx 
		mov [ebx], al 
		jmp p1 
	p2: 
	pop ecx 
	pop ebx 
	pop eax 
endm 
transfer macro a, b 
	mov ebx, b 
	mov eax, [ebx] 
	mov ebx, a 
	mov [ebx], eax 
endm 
declare macro a, b 
	LOCAL d 
	.data 
	d  dd b 
	.code 
	b   equ d 
endm 
retreive macro a 
	mov ebx, a 
	mov eax, [ebx] 
	exitm eax 
endm 
ints macro n 
	mov eax, n 
	shl eax, 2 
	mov ebx, offset integers01 
	add ebx, eax 
	xor eax, eax 
	exitm ebx 
endm 
strs macro n 
	mov eax, n 
	shl eax, 2 
	mov ebx, offset strings01 
	add ebx, eax 
	xor eax, eax 
	exitm ebx 
endm 
decl_vars macro 
	integers01                         DB  2048 dup (?) 
	strings01                          DB  2048 dup (?) 
endm 