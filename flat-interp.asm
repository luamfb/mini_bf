; vim: set ft=nasm:

; Linux handler for flat (instruction-only) 32-bit x86 binaries.
; This is meant to be installed using Linux's binfmt_misc support: see
; <https://www.kernel.org/doc/html/latest/admin-guide/binfmt-misc.html>.
;
; IMPORTANT: do NOT use the 'P' or 'O' flags when installing this handler!

BITS 32

global _start

STDIN   equ 0
STDOUT  equ 1
STDERR  equ 2

; syscall numbers at /usr/include/x86_64-linux-gnu/asm/unistd_32.h
SYS_EXIT    equ 1
SYS_READ    equ 3
SYS_WRITE   equ 4
SYS_OPEN    equ 5
SYS_CLOSE   equ 6

O_RDONLY    equ 0

PROG_MAX_SIZE equ 1 << 18 ; 256 Kib

section .data
    err_open: db 'Failed to open flat binary.'
    ERR_OPEN_SIZE equ $ - err_open

    err_read: db 'Failed to read contents of flat binary.'
    ERR_READ_SIZE equ $ - err_read

; note how we mark this section as executable, so we can run the instructions in buf.
section .bss exec
    buf: resb PROG_MAX_SIZE

section .text
_start:
    pop esi, ; argc
    cmp esi, 1
    jle .quit

    pop eax ; argv[0]: this interpreter's name. Discard it.

    mov eax, SYS_OPEN
    mov ebx, dword [esp] ; argv[1]: path to the flat binary to be executed.
    mov ecx, O_RDONLY
    int 0x80

    cmp eax, 0
    jl .err_open
    mov edi, eax ; file descriptor of binary to be executed

    mov eax, SYS_READ
    mov ebx, edi
    mov ecx, buf
    mov edx, PROG_MAX_SIZE
    int 0x80

    cmp eax, 0
    jl .err_write

    mov eax, SYS_CLOSE
    mov ebx, edi
    int 0x80

    ; set up initial stack state.
    ; argv is already the way we want it to be, since we removed this
    ; interpreter's name, and all other args are simply passed along.
    ; All that's needed is to push back argc - 1.
    ;
    dec esi
    push esi

    ; don't leak register state
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor edi, edi
    xor esi, esi
    xor ebp, ebp
    ; ...but maintain the stack pointer, of course.

    ; last but not least: run the instructions in the program, directly
    ; (without spawning a child process).
    jmp buf

.quit:
    xor ebx, ebx
    mov eax, SYS_EXIT
    int 0x80
.err_open:
    mov eax, SYS_WRITE
    mov ebx, STDERR
    mov ecx, err_open
    mov edx, ERR_OPEN_SIZE
    int 0x80
    jmp .quit
.err_write:
    mov eax, SYS_WRITE
    mov ebx, STDERR
    mov ecx, err_read
    mov edx, ERR_READ_SIZE
    int 0x80
    jmp .quit
