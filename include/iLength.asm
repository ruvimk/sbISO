.code 

iLength: 
	enter 0, 0 
	push ebx 
	push ecx 
	push edx 
	
	mov eax, dword ptr [ebp+8] 
	xor ecx, ecx 
	iLength_lp1: 
		mov ebx, 10 
		xor edx, edx 
		div ebx 
		inc ecx 
		cmp eax, 0 
		jnz iLength_lp1 
	iLength_lp1s: 
	
	mov eax, ecx 
	
	pop edx 
	pop ecx 
	pop ebx 
	leave 
	ret 4 
;; .....  