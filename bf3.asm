; vim: set ft=nasm:

; same as the previous, but using an alignment of just 1 byte in text section
; Use -n when invoking ld, otherwise the alignment change won't have effect!

global _start

STDIN   equ 0
STDOUT  equ 1

; syscall numbers at /usr/include/x86_64-linux-gnu/asm/unistd_64.h
SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_EXIT    equ 60

MEM_SIZE_BYTES  equ 0x8000

section .bss
    ; the bss function is initialized to zero, so we can rest easy about mem
    ; starting out with zeroes. 
    ;
    mem resb  MEM_SIZE_BYTES

section .text align=1
_start:
    mov r9, [rsp + 16]  ; argv[1] = instruction pointer
    mov r8, mem         ; data pointer

main_loop:
    mov dl, byte [r9]
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
    inc r9
    jmp main_loop

next_cell:
    inc r8
    jmp main_loop_end_iter

prev_cell:
    dec r8
    jmp main_loop_end_iter

incr_cell:
    inc byte [r8]
    jmp main_loop_end_iter

decr_cell:
    dec byte [r8]
    jmp main_loop_end_iter

output_cell:
    mov rdi, STDOUT
    mov rsi, r8
    mov rdx, 1
    mov rax, SYS_WRITE
    syscall
    jmp main_loop_end_iter

input_cell:
    mov rdi, STDIN
    mov rsi, r8
    mov rdx, 1
    mov rax, SYS_READ
    syscall
    jmp main_loop_end_iter

go_forward_matching_brace:
    ; first and foremost, check the data pointer
    cmp byte [r8], 0
    jne main_loop_end_iter

    mov ecx, 1 ; brace counter
    inc r9
.loop:
    mov dl, byte [r9]
    cmp dl, '['
    je .open_brace
    cmp dl, ']'
    je .close_brace
.end_iter:
    inc r9
    jmp .loop
.open_brace:
    inc ecx
    jmp .end_iter
.close_brace:
    dec ecx
    cmp ecx, 0
    je main_loop ; instead of main_loop_end_iter, because we don't want to change r9 anymore
    jmp .end_iter

go_backward_matching_brace:
    cmp byte [r8], 0
    je main_loop_end_iter

    mov ecx, 1 ; brace counter (reversed)
    dec r9
.loop:
    mov dl, byte [r9]
    cmp dl, '['
    je .open_brace
    cmp dl, ']'
    je .close_brace
.end_iter:
    dec r9
    jmp .loop
.close_brace:
    inc ecx
    jmp .end_iter
.open_brace:
    dec ecx
    cmp ecx, 0
    je main_loop; instead of main_loop_end_iter, because we don't want to change r9 anymore
    jmp .end_iter

quit:
    xor rdi, rdi
    mov rax, SYS_EXIT
    syscall
