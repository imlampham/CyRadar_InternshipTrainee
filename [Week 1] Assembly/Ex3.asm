section .data
    prompt      db "Enter a string: ", 0x0A, 0x0D
    prompt_len  equ $ - prompt

    rev_msg     db "Reversed string: ", 0x0A, 0x0D
    rev_msg_len equ $ - rev_msg

    buffer      db 20, 0, 20 dup(0) ; Buffer to store a string of up to 20 characters

section .bss
    charBuffer  resb 1           ; Buffer to store a single character

section .text
    global _start

_start:
    ; Print prompt: "Enter a string: "
    mov     rax, 0x2000004       ; sys_write
    mov     rdi, 1               ; stdout
    lea     rsi, [rel prompt]
    mov     rdx, prompt_len
    syscall

    ; Read a string from stdin into buffer.
    movzx   rcx, byte [rel buffer]   ; maximum length (20)
    lea     rsi, [rel buffer+2]
    mov     rdi, 0                   ; stdin
    mov     rax, 0x2000003           ; sys_read
    mov     rdx, rcx                 ; read up to 20 bytes
    syscall                        ; RAX = number of bytes read
    mov     byte [rel buffer+1], al  ; store count into buffer[1]

    ; Remove trailing newline (0x0A) if present.
    movzx   rcx, byte [rel buffer+1]   ; rcx = count of characters read
    cmp     rcx, 0
    je      exit                       ; nothing was read

    lea     rbx, [rel buffer+2]         ; pointer to first character
    mov     rdx, rcx
    dec     rdx                       ; index of last character
    cmp     byte [rbx + rdx], 0x0A      ; check last char for newline
    jne     .continue_read
    dec     byte [rel buffer+1]       ; reduce count if newline found

.continue_read:
    ; Print header for reversed string
    mov     rax, 0x2000004           ; sys_write
    mov     rdi, 1                   ; stdout
    lea     rsi, [rel rev_msg]
    mov     rdx, rev_msg_len
    syscall

    ; Reverse-print the input string:
    movzx   rcx, byte [rel buffer+1]   ; rcx = number of characters
    cmp     rcx, 0
    je      exit                     ; nothing to print
    lea     rbx, [rel buffer+2]       ; pointer to start of input string
    add     rbx, rcx                 ; rbx now points one past the last character
    dec     rbx                      ; adjust to point to the last character

.reverse_loop:
    mov     dl, byte [rbx]           ; load current character into DL
    mov     byte [rel charBuffer], dl
    mov     rax, 0x2000004           ; sys_write
    mov     rdi, 1                   ; stdout
    lea     rsi, [rel charBuffer]
    mov     rdx, 1                   ; write one byte
    syscall
    dec     rbx                      ; move pointer backwards
    dec     rcx                      ; decrement character count
    jnz     .reverse_loop

exit:
    mov     rax, 0x2000001           ; sys_exit
    xor     rdi, rdi               ; exit code 0
    syscall
