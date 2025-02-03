section .data
    invalid_msg db "Invalid inputs!", 10, 0 
    msg1 db "Enter first binary number (up to 16 bits): ", 0
    msg2 db "Enter second binary number (up to 16 bits): ", 0
    msg3 db "The sum in binary is: ", 0
    newline db 10, 0

section .bss
    buffer resb 17
    num1 resb 17
    num2 resb 17
    result resb 17          ; Updated buffer size to 17 (16 bits + null terminator)

section .text
    global _start

_start:
    ; Input first binary number
    mov rdx, 42                 ; Length of msg1
    lea rsi, [rel msg1]         ; RIP-relative addressing for msg1
    call print_string

    lea rsi, [rel num1]         ; Address for the first binary number
    call read_binary

    ; Input second binary number
    mov rdx, 42                 ; Length of msg2
    lea rsi, [rel msg2]         ; RIP-relative addressing for msg2
    call print_string

    lea rsi, [rel num2]         ; Address for the second binary number
    call read_binary

    ; Convert binary to decimal and add
    lea rsi, [rel num1]
    call binary_to_decimal
    mov rbx, rax                ; Store the first decimal number in rbx

    lea rsi, [rel num2]
    call binary_to_decimal
    add rbx, rax                ; Add second decimal number to rbx
    and rbx, 0xFFFF             ; Limit the result to 16 bits

    ; Convert result back to binary
    mov rax, rbx                ; Move the result to rax
    lea rsi, [rel result]
    call decimal_to_binary

    ; Debug: Check the result buffer
    lea rsi, [rel result]
    mov rdx, 17                 ; Print the entire result buffer (debugging step)
    call print_string

    ; Print the result
    mov rdx, 24                 ; Length of msg3
    lea rsi, [rel msg3]         ; RIP-relative addressing for msg3
    call print_string

    lea rsi, [rel result]       ; Address of result string
    call print_string

    ; Print a newline
    lea rsi, [rel newline]
    call print_string

    ; Exit program
    mov rax, 0x2000001          ; syscall: exit
    xor rdi, rdi                ; status: 0
    syscall

; Function to print a string using syscall
print_string:
    mov rax, 0x2000004          ; syscall: write
    mov rdi, 1                  ; file descriptor: stdout
    syscall
    ret

; Function to read a binary number from user input
read_binary:
    mov rax, 0x2000003          ; syscall: read
    mov rdi, 0                  ; file descriptor: stdin
    mov rdx, 17                 ; max bytes to read
    syscall

    ; Null-terminate input
    sub rax, 1                  ; Adjust for the newline character
    cmp rax, 0
    jl show_invalid_msg         ; If no valid input, show invalid message
    mov byte [rsi + rax], 0     ; Null-terminate the input

    ; Validate input
    xor rcx, rcx                ; Index for the input buffer
    
validate_loop:
    mov dl, byte [rsi + rcx]    ; Load the current character
    cmp dl, 0                   ; End of string (null terminator)?
    je validate_done            ; If null, input is valid
    cmp dl, '0'                 ; Is it '0'?
    je next_char
    cmp dl, '1'                 ; Is it '1'?
    je next_char

    ; Invalid character found
    jmp show_invalid_msg

next_char:
    inc rcx                     ; Move to the next character
    cmp rcx, 16                 ; Ensure input does not exceed 16 bits
    jg show_invalid_msg         ; If exceeded, it's invalid
    jmp validate_loop

validate_done:
    ret

show_invalid_msg:
    ; Print an error message for invalid input
    lea rsi, [rel invalid_msg]  ; Load the invalid input message
    call print_string
    mov rax, 0x2000001          ; syscall: exit
    xor rdi, rdi                ; status: 0
    syscall

; Function to convert binary string to decimal
binary_to_decimal:
    xor rax, rax                ; Clear rax for decimal result
    xor rcx, rcx                ; Index

binary_loop:
    mov dl, byte [rsi + rcx]
    cmp dl, 0
    je done_binary_conversion
    shl rax, 1                  ; Shift left by 1
    cmp dl, '1'
    je set_bit
    jmp next_bit

set_bit:
    or rax, 1                   ; Set the least significant bit

next_bit:
    inc rcx
    jmp binary_loop

done_binary_conversion:
    ret

; Function to convert decimal in rax to binary string
decimal_to_binary:
    xor rcx, rcx                ; Bit position counter
    mov rbx, 16                 ; Number of bits to process
    mov rdi, rsi                ; Address of result buffer

    ; Initialize buffer with '0' and null-terminate
    mov rdx, 17
fill_buffer:
    mov byte [rdi + rcx], '0'
    inc rcx
    dec rdx
    jnz fill_buffer
    mov byte [rdi + 16], 0      ; Null-terminate the buffer

    ; Convert decimal to binary
    lea rdi, [rsi + 15]         ; Start at the end of the buffer
convert_loop:
    test rax, 1                 ; Check the least significant bit
    jz write_zero
    mov byte [rdi], '1'
    jmp shift_and_decrement

write_zero:
    mov byte [rdi], '0'

shift_and_decrement:
    shr rax, 1                  ; Shift right by 1
    dec rdi                     ; Move to the previous position
    loop convert_loop
    ret
