section .data
    tb1     db "Enter first number: ",0x0A,0x0D
    tb1_len equ $-tb1

    tb2     db "Enter second number: ",0x0A,0x0D
    tb2_len equ $-tb2

    addMsg  db "The sum is: ",0x0A,0x0D
    addMsg_len equ $-addMsg

    errorMsg db "Invalid input! Please enter a valid number.", 0x0A, 0x0D
    errorMsg_len equ $-errorMsg

section .bss
    inputBuffer   resb 32      ; Buffer to store the input
    numChar       resb 1       ; Buffer to store a single character
    b1            resq 1       ; First number
    b2            resq 1       ; Second number

section .text
    global _start

_start:
    ; Prompt for first number
    mov     rax, 0x2000004      ; sys_write
    mov     rdi, 1              ; stdout
    lea     rsi, [rel tb1]
    mov     rdx, tb1_len
    syscall

    ; Read first number from stdin
    mov     rax, 0x2000003      ; sys_read
    mov     rdi, 0              ; stdin
    lea     rsi, [rel inputBuffer]
    mov     rdx, 32
    syscall
    call    validate_input       ; Validate input
    call    convert_input_to_int ; Convert input to integer
    mov     qword [rel b1], rbx

    ; Prompt for second number
    mov     rax, 0x2000004
    mov     rdi, 1
    lea     rsi, [rel tb2]
    mov     rdx, tb2_len
    syscall

    ; Read second number from stdin
    mov     rax, 0x2000003
    mov     rdi, 0
    lea     rsi, [rel inputBuffer]
    mov     rdx, 32
    syscall
    call    validate_input       ; Validate input
    call    convert_input_to_int
    mov     qword [rel b2], rbx

    ; Display the sum message
    mov     rax, 0x2000004
    mov     rdi, 1
    lea     rsi, [rel addMsg]
    mov     rdx, addMsg_len
    syscall

    ; Compute A+B
    mov     rax, qword [rel b1]
    add     rax, qword [rel b2]
    call    print_number

    ; Exit the program
    mov     rax, 0x2000001      ; sys_exit
    xor     rdi, rdi
    syscall

; Function to validate input
validate_input:
    lea     rsi, [rel inputBuffer]
    xor     rcx, rcx
.validate_loop:
    mov     al, [rsi + rcx]
    cmp     al, 0x0A           ; Check for newline
    je      .valid
    cmp     al, '0'            ; Must be at least '0'
    jb      .invalid
    cmp     al, '9'            ; Must be at most '9'
    ja      .invalid
    inc     rcx
    jmp     .validate_loop
.invalid:
    mov     rax, 0x2000004      ; sys_write
    mov     rdi, 1              ; stdout
    lea     rsi, [rel errorMsg]
    mov     rdx, errorMsg_len
    syscall
    mov     rax, 0x2000001      ; sys_exit
    xor     rdi, rdi
    syscall
.valid:
    ret

; convert_input_to_int:
convert_input_to_int:
    xor     rbx, rbx          ; Clear RBX to accumulate the integer
    lea     rsi, [rel inputBuffer]
.convert_loop:
    mov     al, [rsi]         ; Get current character
    cmp     al, 0x0A          ; Check for newline
    je      .done
    cmp     al, '0'           ; Must be at least '0'
    jb      .done
    cmp     al, '9'           ; Must be at most '9'
    ja      .done
    imul    rbx, rbx, 10      ; Multiply current value by 10
    movzx   rax, al           ; Get the ASCII character in RAX
    sub     rax, '0'          ; Convert ASCII digit to numeric value
    add     rbx, rax          ; Add the digit
    inc     rsi               ; Next character
    jmp     .convert_loop
.done:
    ret

; print_number:
print_number:
    cmp     rax, 0
    jne     .convertDigits
    ; Special case: if the number is 0, print "0"
    mov     byte [rel numChar], '0'
    mov     rax, 0x2000004      ; sys_write
    mov     rdi, 1              ; stdout
    lea     rsi, [rel numChar]
    mov     rdx, 1
    syscall
    ret
.convertDigits:
    xor     rcx, rcx          ; Clear digit counter
.convertLoop:
    xor     rdx, rdx          ; Clear RDX before division
    mov     rbx, 10
    div     rbx               ; Divide RAX by 10, quotient in RAX, remainder in RDX
    add     rdx, '0'          ; Convert digit to ASCII
    push    rdx               ; Save digit on stack (in reverse order)
    inc     rcx               ; Increment digit count
    cmp     rax, 0
    jne     .convertLoop
.printLoop:
    pop     rax               ; Get digit from stack
    mov     byte [rel numChar], al
    mov     rax, 0x2000004      ; sys_write
    mov     rdi, 1              ; stdout
    lea     rsi, [rel numChar]
    mov     rdx, 1
    syscall
    loop    .printLoop
    ret