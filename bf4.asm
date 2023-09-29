; vim: set ft=nasm:

; rewrite of the previous one, but in 32 bits.

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
    je next_cell
    cmp dl, '<'
    je prev_cell
    cmp dl, '+'
    je incr_cell
    cmp dl, '-'
    je decr_cell
    cmp dl, '.'
    je output_cell
    cmp dl, ','
    je input_cell
    cmp dl, '['
    je go_forward_matching_brace
    cmp dl, ']'
    je go_backward_matching_brace
    ; none of them: ignore.

main_loop_end_iter:
    inc edi
    jmp main_loop

next_cell:
    inc esi
    jmp main_loop_end_iter

prev_cell:
    dec esi
    jmp main_loop_end_iter

incr_cell:
    inc byte [esi]
    jmp main_loop_end_iter

decr_cell:
    dec byte [esi]
    jmp main_loop_end_iter

output_cell:
    mov ebx, STDOUT
    mov ecx, esi
    mov edx, 1
    mov eax, SYS_WRITE
    int 0x80
    jmp main_loop_end_iter

input_cell:
    mov ebx, STDIN
    mov ecx, esi
    mov edx, 1
    mov eax, SYS_READ
    int 0x80
    jmp main_loop_end_iter

go_forward_matching_brace:
    ; first and foremost, check the data pointer
    cmp byte [esi], 0
    jne main_loop_end_iter

    mov ecx, 1 ; brace counter
    inc edi
.loop:
    mov dl, byte [edi]
    cmp dl, '['
    je .open_brace
    cmp dl, ']'
    je .close_brace
.end_iter:
    inc edi
    jmp .loop
.open_brace:
    inc ecx
    jmp .end_iter
.close_brace:
    dec ecx
    cmp ecx, 0
    je main_loop ; instead of main_loop_end_iter, because we don't want to change edi anymore
    jmp .end_iter

go_backward_matching_brace:
    cmp byte [esi], 0
    je main_loop_end_iter

    mov ecx, 1 ; brace counter (reversed)
    dec edi
.loop:
    mov dl, byte [edi]
    cmp dl, '['
    je .open_brace
    cmp dl, ']'
    je .close_brace
.end_iter:
    dec edi
    jmp .loop
.close_brace:
    inc ecx
    jmp .end_iter
.open_brace:
    dec ecx
    cmp ecx, 0
    je main_loop; instead of main_loop_end_iter, because we don't want to change edi anymore
    jmp .end_iter

quit:
    mov ebx, 0
    mov eax, SYS_EXIT
    int 0x80
