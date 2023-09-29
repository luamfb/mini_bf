; vim: set ft=nasm:

; re-structure jumps in main loop

BITS 32

global _start

STDIN   equ 0
STDOUT  equ 1

; syscall numbers at /usr/include/x86_64-linux-gnu/asm/unistd_32.h
SYS_READ    equ 3
SYS_WRITE   equ 4
SYS_EXIT    equ 1

MEM_SIZE_BYTES  equ 0x8000

section .bss
    ; the bss function is initialized to zero, so we can rest easy about mem
    ; starting out with zeroes. 
    ;
    mem resb  MEM_SIZE_BYTES

section .text align=1
_start:
    mov edi, dword [esp + 8]    ; argv[1] = instruction pointer
    mov esi, mem                ; data pointer

main_loop:
    mov dl, byte [edi]
    cmp dl, 0
    je quit

    cmp dl, '>'
    jne .L1
    inc esi
.L1:
    cmp dl, '<'
    jne .L2
    dec esi
.L2:
    cmp dl, '+'
    jne .L3
    inc byte [esi]
.L3:
    cmp dl, '-'
    jne .L4
    dec byte [esi]
.L4:
    cmp dl, '.'
    jne .L5
    mov ebx, STDOUT
    mov eax, SYS_WRITE
    jmp .io_common
.L5:
    cmp dl, ','
    jne .L6
    mov ebx, STDIN
    mov eax, SYS_READ
    ;jmp .io_common
.io_common:
    mov ecx, esi
    mov edx, 1
    int 0x80
    jmp main_loop_end_iter
.L6:
    mov ecx, 1 ; brace counter

    cmp dl, '['
    je go_forward_matching_brace
    cmp dl, ']'
    je go_backward_matching_brace
    ; none of them: ignore.

main_loop_end_iter:
    inc edi
    jmp main_loop

go_forward_matching_brace:
    ; first and foremost, check the data pointer
    cmp byte [esi], 0
    jne main_loop_end_iter
    mov dh, ']'
.loop:
    inc edi
    call matching_brace_one_iter
    jmp .loop

go_backward_matching_brace:
    cmp byte [esi], 0
    je main_loop_end_iter
    mov dh, '['
.loop:
    dec edi
    call matching_brace_one_iter
    jmp .loop

matching_brace_one_iter:
    cmp byte [edi], dh
    je .seeked_char
    cmp byte [edi], dl
    je .same_char
    ret
.same_char:
    inc ecx
    ret
.seeked_char:
    dec ecx
    cmp ecx, 0
    je skip_main_loop_update
    ret

; Pop the instruction pointer, since matching_brace_one_iter was called
; with call instruction but didn't return with ret. On the long run, this
; might cause a stack overflow if we don't pop the values that were push'd...
;
skip_main_loop_update:
    pop eax
    jmp main_loop ; instead of main_loop_end_iter, because we don't want to change edi anymore

quit:
    mov ebx, 0
    mov eax, SYS_EXIT
    int 0x80
