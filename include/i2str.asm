include iLength.asm 

.code 

i2str: 
	enter 0, 0 
	push esi 
	push edi 
	push ecx 
	push edx 
	push ebx 
	
	mov byte ptr [ebp-1], 0 
	
	mov esi, dword ptr [ebp+8] 
	mov edi, dword ptr [ebp+12] 
	push esi 
	call iLength 
	xchg eax, ecx 
	mov eax, esi 
	i2str_lp1: 
		jecxz i2str_lp1s 
		dec ecx 
		push ecx 
		inc ecx 
		mov ebx, eax 
		call exp10 
		xchg eax, ebx 
		xor edx, edx 
		div ebx 
		dec ecx 
		add al, 48 
		mov byte ptr [edi], al 
		inc edi 
		sub al, 48 
		push ecx 
		mov ebx, eax 
		call exp10 
		mul ebx 
		sub esi, eax 
		mov eax, esi 
		jmp i2str_lp1 
	i2str_lp1s: 
	mov byte ptr [edi], 0 
	
	mov eax, dword ptr [ebp+12] 
	
	pop ebx 
	pop edx 
	pop ecx 
	pop edi 
	pop esi 
	leave 
	ret 8 
;; .....  