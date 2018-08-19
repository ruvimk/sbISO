.code 

exp10: 
	enter 0, 0 
	push ebx 
	push ecx 
	push edx 
	
	mov ecx, dword ptr [ebp+8] 
	mov eax, 1 
	mov ebx, 10 
	exp10_lp1: 
		jecxz exp10_lp1s 
		mul ebx 
		dec ecx 
		jmp exp10_lp1 
	exp10_lp1s: 
	
	pop edx 
	pop ecx 
	pop ebx 
	leave 
	ret 4 
;; .....  