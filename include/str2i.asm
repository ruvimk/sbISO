include exp10.asm 

.code 

str2i: 
	enter 0, 0 
	push edi 
	
	xor edi, edi 
	mov ebx, dword ptr [ebp+8] 
	str2i_lp1: 
		xor eax, eax 
		mov al, byte ptr [ebx] 
		cmp al, 48 
		jl str2i_lp1s 
		cmp al, 58 
		jnl str2i_lp1s 
		push eax 
		mov eax, edi 
		mov ecx, 10 
		mul ecx 
		mov edi, eax 
		pop eax 
		sub al, 48 
		add edi, eax 
		inc ebx 
		jmp str2i_lp1 
	str2i_lp1s: 
	mov eax, edi 
	
	pop edi 
	leave 
	ret 4 
;; .....  