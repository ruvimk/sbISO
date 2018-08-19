;; ISO - ISO Image Manager 
;; File: "iso.asm" 
;; Version: 0.8 
;; Copyright © 2011 By Ruvim Kondratyev 
.386 
.model flat, stdcall 
option casemap:none 
include include\include.inc 
include include\rslib.inc 
include include\i2str.asm 
include include\str2i.asm 
includelib lib\str.lib 
includelib lib\rslib.lib 
extern replace  : near 
extern enclose  : near 
.data 
usage_msg               db "Usage:  iso <option> <image> <filename>", 13, 10 
db 9, "<option>      ", "The action to take. ", 13, 10 
db 9, "              ", "    ", "-r    ", "Replace a file on the image. ", 13, 10 
db 9, "              ", "    ", "-e    ", "Extract a file from the image. ", 13, 10 
db 9, "              ", "    ", "-n    ", "Make a new file on the image. ", 13, 10 
db 9, "<image>       ", "The filename of the ISO image. ", 13, 10 
db 9, "<filename>    ", "The name of the file to handle. ", 13, 10 
db 0, 0 
.data? 
imgFilename             DB  512 dup (?) 
dirFilename             DB  512 dup (?) 
OptionIdent             DB  512 dup (?) 
CommandLine             DWORD ? 
hISO                    DWORD ? 
pISO                    DWORD ? 
sISO                    DWORD ? 
hFile                   DWORD ? 
pFile                   DWORD ? 
sFile                   DWORD ? 
isoBlockSize            DWORD ? 
isoRoughSize            DWORD ? 
isoTotalSize            DWORD ? 
pRecord                 DWORD ? 
sRecord                 DWORD ? 
err_num                 DWORD ? 
err_str                 DWORD ? 
debug_num1              DWORD ? 
debug_num2              DWORD ? 
fSize                   DWORD ? 
time                    SYSTEMTIME <> 
.code 
start: 

call GetCommandLine 
mov dword ptr [CommandLine], eax 

push dword ptr offset time 
call GetSystemTime 

call main 

xor eax, eax 
ret 

main proc 
	enter 0, 0 
	
	call get_command 
	cmp eax, -1 
	jnz @F 
		push dword ptr offset usage_msg 
		call StdOut 
		
		leave 
		ret 
	@@: 
	
	push dword ptr offset OptionIdent 
	call get_option 
	
	push dword ptr offset OptionIdent 
	call uc 
	
	push dword ptr offset imgFilename 
	call uc 
	
	push dword ptr offset dirFilename 
	call uc 
	
	mov ebx, offset OptionIdent 
	
	mov eax, string("R") 
	call strcmp 
	cmp eax, 0 
	jz main_iso_replace 
	
	mov eax, string("E") 
	call strcmp 
	cmp eax, 0 
	jz main_iso_extract 
	
	mov eax, string("N") 
	call strcmp 
	cmp eax, 0 
	jz main_iso_newfile 
	
	push dword ptr string("Unrecognized option: ", 34) 
	call StdOut 
	push dword ptr offset OptionIdent 
	call StdOut 
	push dword ptr string(34, 13, 10) 
	call StdOut 
	
	jmp finish 
	
	main_iso_newfile: 
		
		push dword ptr 2 
		push dword ptr space(SIZEOF OFSTRUCT) 
		push dword ptr offset imgFilename 
		call OpenFile 
		mov dword ptr [hISO], eax 
		
		cmp eax, 0 
		jz err_no_img 
		cmp eax, -1 
		jz err_no_img 
		
		push dword ptr 0 
		push eax 
		call GetFileSize 
		mov dword ptr [sISO], eax 
		
		push eax 
		push dword ptr 0 
		call GlobalAlloc 
		mov dword ptr [pISO], eax 
		
		cmp eax, 0 
		jz err_no_mem 
		
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr [sISO] 
		push dword ptr [pISO] 
		push dword ptr [hISO] 
		call ReadFile 
		
		;; begin 
			
			mov eax, dword ptr [pISO] 
			mov ebx, eax 
			xor eax, eax 
			mov ax, word ptr [ebx+32768+128] 
			mov dword ptr [isoBlockSize], eax 
			mov ecx, eax 
			
			mov eax, dword ptr [sISO] 
			xor edx, edx 
			div ecx 
			inc eax 
			push eax 
			mul ecx 
			mov dword ptr [isoRoughSize], eax 
			
			pop eax 
			
			mov ebx, string() 
			mov byte ptr [ebx+01], 0 
			mov dword ptr [ebx+02], eax 
			call b_swap 
			mov dword ptr [ebx+06], eax 
			mov dword ptr [ebx+10], 0 
			mov dword ptr [ebx+14], 0 
			mov ax, word ptr [time.wYear] 
			sub ax, 1900 
			mov byte ptr [ebx+18], al 
			mov al, byte ptr [time.wMonth] 
			mov byte ptr [ebx+19], al 
			mov al, byte ptr [time.wDay] 
			mov byte ptr [ebx+20], al 
			mov al, byte ptr [time.wHour] 
			mov byte ptr [ebx+21], al 
			mov al, byte ptr [time.wMinute] 
			mov byte ptr [ebx+22], al 
			mov al, byte ptr [time.wSecond] 
			mov byte ptr [ebx+23], al 
			mov byte ptr [ebx+24], 0 
			mov byte ptr [ebx+25], 0 
			mov byte ptr [ebx+26], 0 
			mov byte ptr [ebx+27], 0 
			mov eax, 1 
			mov word ptr [ebx+28], ax 
			xchg al, ah 
			mov word ptr [ebx+30], ax 
			mov eax, offset dirFilename 
			call check_dir_name 
			call StringLength 
			mov byte ptr [ebx+32], al 
			add eax, 33 
			test eax, 1 
			jz @F 
				inc eax 
			@@: 
			mov byte ptr [ebx+00], al 
			
			mov dword ptr [sRecord], eax 
			mov eax, ebx 
			mov dword ptr [pRecord], eax 
			
			add eax, 33 
			mov ebx, offset dirFilename 
			call StringCopy 
			
			mov eax, dword ptr [pISO] 
			mov ebx, eax 
			
			mov eax, dword ptr [ebx+32768+156+02] 
			mov ecx, eax 
			mov eax, dword ptr [isoBlockSize] 
			mul ecx 
			add ebx, eax 
			
			push ebx 
			call isoScanToBlank 
			mov ebx, eax 
			
			mov eax, dword ptr [pRecord] 
			mov edx, eax 
			
			xor ecx, ecx 
			lp01: 
				mov eax, ecx 
				cmp eax, dword ptr [sRecord] 
				jnl lp01s 
				
				mov al, byte ptr [edx] 
				mov byte ptr [ebx], al 
				
				inc ebx 
				inc ecx 
				inc edx 
				jmp lp01 
			lp01s: 
			mov byte ptr [ebx+1], 0 
			
			push dword ptr offset dirFilename 
			push dword ptr [pISO] 
			call isoGetFileRecord 
			mov dword ptr [pRecord], eax 
			
			cmp eax, 0 
			jz err_no_dir 
			cmp eax, -1 
			jz err_no_dir 
			
			mov ebx, eax 
			
			mov eax, dword ptr [isoBlockSize] 
			mov ecx, eax 
			mov eax, dword ptr [isoRoughSize] 
			xor edx, edx 
			div ecx 
			mov dword ptr [ebx+02], eax 
			call b_swap 
			mov dword ptr [ebx+06], eax 
			
			xor eax, eax 
			mov dword ptr [ebx+10], eax 
			call b_swap 
			mov dword ptr [ebx+14], eax 
			
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr [hISO] 
			call SetFilePointer 
			
			push dword ptr [hISO] 
			call SetEndOfFile 
			
			push dword ptr 0 
			push dword ptr integer() 
			push dword ptr [sISO] 
			push dword ptr [pISO] 
			push dword ptr [hISO] 
			call WriteFile 
			
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr [isoRoughSize] 
			push dword ptr [hISO] 
			call SetFilePointer 
			
			push dword ptr [hISO] 
			call SetEndOfFile 
			
		;; end 
		
		push dword ptr [pISO] 
		call GlobalFree 
		mov dword ptr [pISO], 0 
		
		push dword ptr [hISO] 
		call CloseHandle 
		mov dword ptr [hISO], 0 
		
	jmp finish 
	
	main_iso_replace: 
		
		push dword ptr 2 
		push dword ptr space(SIZEOF OFSTRUCT) 
		push dword ptr offset imgFilename 
		call OpenFile 
		mov dword ptr [hISO], eax 
		
		cmp eax, 0 
		jz err_no_img 
		cmp eax, -1 
		jz err_no_img 
		
		push dword ptr 0 
		push eax 
		call GetFileSize 
		mov dword ptr [sISO], eax 
		
		push eax 
		push dword ptr 0 
		call GlobalAlloc 
		mov dword ptr [pISO], eax 
		
		cmp eax, 0 
		jz err_no_mem 
		
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr [sISO] 
		push dword ptr [pISO] 
		push dword ptr [hISO] 
		call ReadFile 
		
		;; begin 
			
			push dword ptr 0 
			push dword ptr space(SIZEOF OFSTRUCT) 
			push dword ptr offset dirFilename 
			call OpenFile 
			mov dword ptr [hFile], eax 
			
			cmp eax, 0 
			jz err_no_fl 
			cmp eax, -1 
			jz err_no_fl 
			
			push dword ptr 0 
			push eax 
			call GetFileSize 
			mov dword ptr [sFile], eax 
			
			push eax 
			push dword ptr 0 
			call GlobalAlloc 
			mov dword ptr [pFile], eax 
			
			cmp eax, 0 
			jz err_no_mem 
			
			push dword ptr 0 
			push dword ptr integer() 
			push dword ptr [sFile] 
			push dword ptr [pFile] 
			push dword ptr [hFile] 
			call ReadFile 
			
			push dword ptr [hFile] 
			call CloseHandle 
			mov dword ptr [hFile], 0 
			
			mov eax, dword ptr [pISO] 
			mov ebx, eax 
			xor eax, eax 
			mov ax, word ptr [ebx+32768+128] 
			mov dword ptr [isoBlockSize], eax 
			mov ecx, eax 
			
			mov eax, dword ptr [ebx+32768+80] 
			mov ecx, eax 
			mov eax, dword ptr [isoBlockSize] 
			mul ecx 
			mov dword ptr [isoRoughSize], eax 
			
			mov eax, dword ptr [sFile] 
			mov ecx, eax 
			mov eax, dword ptr [isoBlockSize] 
			xchg eax, ecx 
			xor edx, edx 
			div ecx 
			cmp eax, 0 
			jz @F 
				inc eax 
			@@: 
			mul ecx 
			mov dword ptr [fSize], eax 
			add eax, dword ptr [isoRoughSize] 
			mov dword ptr [isoTotalSize], eax 
			
			mov eax, dword ptr [isoBlockSize] 
			mov ecx, eax 
			mov eax, dword ptr [isoTotalSize] 
			xor edx, edx 
			div ecx 
			mov dword ptr [ebx+32768+80], eax 
			call b_swap 
			mov dword ptr [ebx+32768+84], eax 
			
			push dword ptr offset dirFilename 
			push dword ptr [pISO] 
			call isoGetFileRecord 
			mov dword ptr [pRecord], eax 
			
			cmp eax, 0 
			jz err_no_dir 
			cmp eax, -1 
			jz err_no_dir 
			
			mov ebx, eax 
			
			mov eax, dword ptr [isoBlockSize] 
			mov ecx, eax 
			mov eax, dword ptr [isoRoughSize] 
			xor edx, edx 
			div ecx 
			mov dword ptr [ebx+02], eax 
			call b_swap 
			mov dword ptr [ebx+06], eax 
			
			mov eax, dword ptr [sFile] 
			mov dword ptr [ebx+10], eax 
			call b_swap 
			mov dword ptr [ebx+14], eax 
			
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr [hISO] 
			call SetFilePointer 
			
			push dword ptr [hISO] 
			call SetEndOfFile 
			
			push dword ptr 0 
			push dword ptr integer() 
			push dword ptr [sISO] 
			push dword ptr [pISO] 
			push dword ptr [hISO] 
			call WriteFile 
			
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr [isoRoughSize] 
			push dword ptr [hISO] 
			call SetFilePointer 
			
			push dword ptr 0 
			push dword ptr integer() 
			push dword ptr [sFile] 
			push dword ptr [pFile] 
			push dword ptr [hISO] 
			call WriteFile 
			
			push dword ptr 0 
			push dword ptr 0 
			push dword ptr [isoTotalSize] 
			push dword ptr [hISO] 
			call SetFilePointer 
			
			push dword ptr [hISO] 
			call SetEndOfFile 
			
			push dword ptr [pFile] 
			call GlobalFree 
			mov dword ptr [pFile], 0 
			
		;; end 
		
		push dword ptr [pISO] 
		call GlobalFree 
		mov dword ptr [pISO], 0 
		
		push dword ptr [hISO] 
		call CloseHandle 
		mov dword ptr [hISO], 0 
		
	jmp finish 
	
	main_iso_extract: 
		
		push dword ptr 0 
		push dword ptr space(SIZEOF OFSTRUCT) 
		push dword ptr offset imgFilename 
		call OpenFile 
		mov dword ptr [hISO], eax 
		
		cmp eax, 0 
		jz err_no_img 
		cmp eax, -1 
		jz err_no_img 
		
		push dword ptr 0 
		push eax 
		call GetFileSize 
		mov dword ptr [sISO], eax 
		
		push eax 
		push dword ptr 0 
		call GlobalAlloc 
		mov dword ptr [pISO], eax 
		
		cmp eax, 0 
		jz err_no_mem 
		
		push dword ptr 0 
		push dword ptr integer() 
		push dword ptr [sISO] 
		push dword ptr [pISO] 
		push dword ptr [hISO] 
		call ReadFile 
		
		;; begin 
			
			mov eax, dword ptr [pISO] 
			mov ebx, eax 
			xor eax, eax 
			mov ax, word ptr [ebx+32768+128] 
			mov dword ptr [isoBlockSize], eax 
			
			push dword ptr offset dirFilename 
			push dword ptr [pISO] 
			call isoGetFileRecord 
			mov dword ptr [pRecord], eax 
			mov dword ptr [err_num], eax 
			cmp eax, 0 
			jz err_no_dir 
			cmp eax, -1 
			jz err_no_dir 
			
			push dword ptr 2 or 1000h 
			push dword ptr space(SIZEOF OFSTRUCT) 
			push dword ptr offset dirFilename 
			call OpenFile 
			mov dword ptr [hFile], eax 
			
			mov eax, dword ptr [pRecord] 
			mov ebx, eax 
			
			mov eax, dword ptr [ebx+02] 
			mov ecx, eax 
			mov eax, dword ptr [isoBlockSize] 
			mul ecx 
			add eax, dword ptr [pISO] 
			mov edx, eax 
			
			mov eax, dword ptr [ebx+10] 
			mov ecx, eax 
			
			mov ebx, edx 
			
			mov dword ptr [debug_num1], eax 
			
			push dword ptr 0 
			push dword ptr offset debug_num2 
			push ecx 
			push ebx 
			push dword ptr [hFile] 
			call WriteFile 
			
			mov eax, dword ptr [debug_num1] 
			cmp eax, dword ptr [debug_num2] 
			jnz err_write_file 
			
			push dword ptr [hFile] 
			call CloseHandle 
			mov dword ptr [hFile], 0 
			
		;; end 
		
		push dword ptr [pISO] 
		call GlobalFree 
		mov dword ptr [pISO], 0 
		
		push dword ptr [hISO] 
		call CloseHandle 
		mov dword ptr [hISO], 0 
		
	jmp finish 
	
	err_no_img: 
		push dword ptr string("Error:  Image file ") 
		call StdOut 
		push dword ptr offset imgFilename 
		call StdOut 
		push dword ptr string(" not found. ", 13, 10, 13, 10, "Error Number: 1", 13, 10) 
		call StdOut 
		jmp finish 
	err_no_fl: 
		push dword ptr string("Error:  File ") 
		call StdOut 
		push dword ptr offset dirFilename 
		call StdOut 
		push dword ptr string(" not found. ", 13, 10, 13, 10, "Error Number: 2", 13, 10) 
		call StdOut 
		jmp finish 
	err_no_dir: 
		push dword ptr string("Error:  Directory record for ") 
		call StdOut 
		push dword ptr offset dirFilename 
		call StdOut 
		push dword ptr string(" not found in ISO image ") 
		call StdOut 
		push dword ptr offset imgFilename 
		call StdOut 
		push dword ptr string(13, 10, 13, 10, "Error Number: 3", 13, 10) 
		call StdOut 
		push dword ptr string(13, 10, "Extra Error Code: ") 
		call StdOut 
			push dword ptr offset err_str 
			push dword ptr [err_num] 
			call i2str 
			push dword ptr offset err_str 
			call StdOut 
		push dword ptr string(13, 10) 
		call StdOut 
		push dword ptr string(13, 10, "Debug Code 1: ") 
		call StdOut 
			push dword ptr offset err_str 
			push dword ptr [debug_num1] 
			call i2str 
			push dword ptr offset err_str 
			call StdOut 
		push dword ptr string(13, 10, "Debug Code 2: ") 
		call StdOut 
			push dword ptr offset err_str 
			push dword ptr [debug_num2] 
			call i2str 
			push dword ptr offset err_str 
			call StdOut 
		push dword ptr string(13, 10) 
		call StdOut 
		jmp finish 
	err_no_mem: 
		push dword ptr string("Error:  Could not allocate memory. ", 13, 10, 13, 10, "Error Number: 4", 13, 10) 
		call StdOut 
		jmp finish 
	err_write_file: 
		call GetLastError 
		mov dword ptr [err_num], eax 
		push dword ptr string("Error:  Writing to file ") 
		call StdOut 
		push dword ptr offset dirFilename 
		call StdOut 
		push dword ptr string(" failed. ", 13, 10, 13, 10, "Error Number: 5", 13, 10) 
		call StdOut 
		push dword ptr string("Windows System Error Code: ") 
		call StdOut 
			push dword ptr offset err_str 
			push dword ptr [err_num] 
			call i2str 
			push eax 
			call StdOut 
		push dword ptr string(13, 10) 
		call StdOut 
		jmp finish 
	;; .....  
	
	finish: 
	
	push dword ptr [hISO] 
	call CloseHandle 
	push dword ptr [hFile] 
	call CloseHandle 
	
	push dword ptr [pISO] 
	call GlobalFree 
	push dword ptr [pFile] 
	call GlobalFree 
	
	leave 
	ret 
main endp 

get_command proc 
	enter 0, 0 
	
	mov eax, dword ptr [CommandLine] 
	mov ebx, eax 
	
	call s02 
	call s01 
	call s02 
	
	mov eax, offset OptionIdent 
	call StringCopy 
	
	call s01 
	call s02 
	
	mov eax, offset imgFilename 
	call StringCopy 
	
	call s01 
	call s02 
	
	mov eax, offset dirFilename 
	call StringCopy 
	
	push dword ptr offset imgFilename 
	call t01 
	
	push dword ptr offset dirFilename 
	call t01 
	
	push dword ptr offset OptionIdent 
	call t01 
	
	mov eax, offset OptionIdent 
	call StringLength 
	cmp eax, 0 
	jz no_param 
	
	mov eax, offset imgFilename 
	call StringLength 
	cmp eax, 0 
	jz no_param 
	
	mov eax, offset dirFilename 
	call StringLength 
	cmp eax, 0 
	jz no_param 
	
	xor eax, eax 
	jmp finish 
	
	no_param: 
		mov eax, -1 
		jz finish 
	finish: 
	
	leave 
	ret 
get_command endp 

t01 proc 
	enter 0, 0 
	
	mov eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz lp1s 
		cmp al, 9 
		jz lp1s 
		cmp al, 13 
		jz lp1s 
		cmp al, 10 
		jz lp1s 
		cmp al, 0 
		jz lp1s 
		
		inc ebx 
		jmp lp1 
	lp1s: 
	mov byte ptr [ebx], 0 
	
	leave 
	ret 4 
t01 endp 

s01 proc 
	enter 0, 0 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz lp1s 
		cmp al, 10 
		jz lp1s 
		cmp al, 0 
		jz lp1s 
		
		inc ebx 
		jmp lp1 
	lp1s: 
	
	leave 
	ret 
s01 endp 

s02 proc 
	enter 0, 0 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 32 
		jz lp1o 
		cmp al, 9 
		jz lp1o 
		
		jmp lp1s 
		
	lp1o: 
		inc ebx 
		jmp lp1 
	lp1s: 
	
	leave 
	ret 
s02 endp 

get_option proc 
	enter 0, 0 
	
	mov eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, "-" 
		jz lp1o 
		cmp al, "/" 
		jz lp1o 
		jmp lp1s 
	lp1o: 
		inc ebx 
		jmp lp1 
	lp1s: 
	
	mov eax, dword ptr [ebp+8] 
	call StringCopy 
	
	leave 
	ret 4 
get_option endp 

b_swap proc 
	enter 4, 0 
	pusha 
	
	mov cx, ax 
	shr eax, 16 
	xchg al, ah 
	xchg cl, ch 
	shl ecx, 16 
	mov cx, ax 
	mov eax, ecx 
	
	mov dword ptr [ebp-4], eax 
	
	popa 
	mov eax, dword ptr [ebp-4] 
	leave 
	ret 
b_swap endp 

uc proc 
	enter 0, 0 
	
	mov eax, dword ptr [ebp+8] 
	
	mov ebx, eax 
	lp2: 
		mov al, byte ptr [ebx] 
		cmp al, 97 
		jl lp2o 
		cmp al, 97 + 26 
		jnl lp2o 
		sub al, 32 
		mov byte ptr [ebx], al 
	lp2o: 
		cmp al, 0 
		jz lp2s 
		inc ebx 
		jmp lp2 
	lp2s: 
	
	leave 
	ret 4 
uc endp 

strcmp proc 
	enter 4, 0 
	pusha 
	
	mov edx, ebx 
	mov ebx, eax 
	
	xor eax, eax 
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 0 
		jz lp1s 
		sub al, byte ptr [edx] 
		jnz lp1s 
		
		inc ebx 
		inc edx 
		jmp lp1 
	lp1s: 
	
	mov dword ptr [ebp-4], eax 
	
	popa 
	mov eax, dword ptr [ebp-4] 
	leave 
	ret 
strcmp endp 

isoGetFileRecord proc 
	enter 8, 0 
	
	mov eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	mov al, byte ptr [ebx+32768+00] 
	cmp al, 1 
	jnz err_img 
	
	cmp byte ptr [ebx+32768+01], "C" 
	jnz err_img 
	cmp byte ptr [ebx+32768+02], "D" 
	jnz err_img 
	cmp byte ptr [ebx+32768+03], "0" 
	jnz err_img 
	cmp byte ptr [ebx+32768+04], "0" 
	jnz err_img 
	cmp byte ptr [ebx+32768+05], "1" 
	jnz err_img 
	
	xor eax, eax 
	mov ax, word ptr [ebx+32768+128] 
	mov dword ptr [ebp-4], eax 
	
	mov ecx, 32768 
	add ecx, 156 
	
	mov eax, dword ptr [ebx+ecx+10] 
	add eax, ebx 
	mov dword ptr [ebp-8], eax 
	
	mov eax, dword ptr [ebx+ecx+02] 
	mov ecx, eax 
	mov eax, dword ptr [ebp-4] 
	mul ecx 
	mov ecx, eax 
	
	add dword ptr [ebp-8], eax 
	
	add eax, dword ptr [pISO] 
	mov ebx, eax 
	
	xor edx, edx 
	
	lp1: 
		mov eax, dword ptr [ebp-08] 
		cmp ebx, eax 
		jnl lp1s 
		
		mov edx, ebx 
		add ebx, 33 
		mov eax, dword ptr [ebp+12] 
		call strcmp 
		cmp eax, 0 
		jz lp1s 
		
		mov ebx, edx 
		xor eax, eax 
		xor edx, edx 
		mov al, byte ptr [ebx] 
		add ebx, eax 
		cmp eax, 0 
		jnz lp1 
	lp1s: 
	
	jmp finish 
	
	err_img: 
	mov edx, -1 
	
	finish: 
	mov eax, edx 
	
	leave 
	ret 8 
isoGetFileRecord endp 

isoScanForRecord proc 
	enter 0, 0 
	
	mov eax, dword ptr [ebp+8] 
	mov ebx, eax 
	
	xor edx, edx 
	lp1: 
		mov eax, dword ptr [ebp-08] 
		cmp ebx, eax 
		jnl lp1s 
		
		mov edx, ebx 
		add ebx, 33 
		mov eax, dword ptr [ebp+12] 
		call strcmp 
		cmp eax, 0 
		jz lp1s 
		
		mov ebx, edx 
		xor eax, eax 
		xor edx, edx 
		mov al, byte ptr [ebx] 
		add ebx, eax 
		cmp eax, 0 
		jnz lp1 
	lp1s: 
	
	cmp edx, 0 
	jnz @F 
		mov edx, ebx 
	@@: 
	mov eax, edx 
	
	leave 
	ret 8 
isoScanForRecord endp 

isoScanToBlank proc 
	enter 0, 0 
	
	push dword ptr string("!!!!!!!!!!!!!!!!!!!!") 
	push dword ptr [ebp+8] 
	call isoScanForRecord 
	
	leave 
	ret 4 
isoScanToBlank endp 

check_dir_name proc 
	enter 8, 0 
	pusha 
	
	mov dword ptr [ebp-4], eax 
	
	push dword ptr string(59) 
	push dword ptr string(63) 
	push eax 
	call replace 
	
	lp1: 
		mov al, byte ptr [ebx] 
		cmp al, 44 
		jz lp1b 
		cmp al, 0 
		jz lp1a 
		
		inc ebx 
		jmp lp1 
	lp1b: 
		mov eax, ebx 
		inc eax 
		mov dword ptr [ebp-8], eax 
		push eax 
		call str2i 
		cmp eax, 0 
		jnz @F 
			inc eax 
		@@: 
		push dword ptr [ebp-8] 
		push eax 
		call i2str 
		
		jmp lp1s 
	lp1a: 
		mov eax, dword ptr [ebp-4] 
		mov ebx, string(44, 49) 
		call StringCat 
		
		jmp lp1s 
	lp1s: 
	
	popa 
	leave 
	ret 
check_dir_name endp 

end start 