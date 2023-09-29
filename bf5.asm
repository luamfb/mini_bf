; vim: set ft=nasm:

; refactor common code in IO and braces.

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

    mov ecx, 1 ; brace counter

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
    mov eax, SYS_WRITE
    jmp io_common

input_cell:
    mov ebx, STDIN
    mov eax, SYS_READ
    ;jmp io_common

io_common:
    mov ecx, esi
    mov edx, 1
    int 0x80
    jmp main_loop_end_iter

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
