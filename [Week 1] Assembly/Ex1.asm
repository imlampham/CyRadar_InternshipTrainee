section .data
    b1 dw 0                         ; Store first binary number (16-bit)
    b2 dw 0                         ; Store second binary number (16-bit)
    tb1 db "The first number (16-bit binary): ", 0
    tb2 db "The second number  (16-bit binary): ", 0
    tb3 db "The sum is: ", 0
    error_msg db "Invalid input!", 10, 0
    newline db 10, 0                ; Newline character for formatting output

section .bss
    buffer resb 18                  ; Increased buffer size to prevent overflow
    result resb 17                  ; Buffer to store binary result

section .text
    global _start

_start:
    ; Prompt for first binary number
    lea rsi, [rel tb1]
    call print_string
    lea rsi, [rel buffer]
    call read_binary                ; Read binary input from user
    call validate_input             ; Check if input is valid
    lea rsi, [rel buffer]
    call binary_to_decimal          ; Convert binary string to decimal
    mov word [rel b1], ax           ; Store result in b1

    ; Prompt for second binary number
    lea rsi, [rel tb2]
    call print_string
    lea rsi, [rel buffer]
    call read_binary
    call validate_input             ; Check if input is valid
    lea rsi, [rel buffer]
    call binary_to_decimal
    mov word [rel b2], ax           ; Store result in b2

    ; Perform addition of the two numbers
    lea rsi, [rel tb3]
    call print_string
    mov ax, [rel b1]
    add ax, [rel b2]                ; Add the two 16-bit numbers
    lea rsi, [rel result]
    call decimal_to_binary          ; Convert result to binary string
    call print_string               ; Display result
    call print_newline              ; Print newline for formatting

    ; Exit program
    mov rax, 0x2000001              ; System call for exit
    xor rdi, rdi                    ; Exit code 0
    syscall

; Function to print a string to standard output
print_string:
    mov rdx, 0                      ; Initialize length counter
    mov rcx, rsi                    ; Load string address
    call string_length              ; Get string length
    mov rdx, rax                    ; Store length in rdx
    mov rax, 0x2000004              ; System call for write
    mov rdi, 1                      ; File descriptor: stdout
    syscall
    ret

; Function to print a newline
print_newline:
    lea rsi, [rel newline]
    call print_string
    ret

; Function to read binary input
read_binary:
    mov rax, 0x2000003              ; System call for read
    mov rdi, 0                      ; File descriptor: stdin
    mov rdx, 18                     ; Max length to read (16 bits + newline + null terminator)
    syscall
    sub rax, 1                      ; Remove newline character
    mov byte [rsi + rax], 0         ; Null-terminate string
    ret

; Function to validate binary input
validate_input:
    xor rcx, rcx
    cmp rax, 17                     ; Check if input exceeds 16 bits
    jge invalid_input
validate_loop:
    mov dl, byte [rsi + rcx]
    cmp dl, 0
    je validate_done
    cmp dl, '0'
    je next_char
    cmp dl, '1'
    je next_char
    ; Invalid character found
    jmp invalid_input
next_char:
    inc rcx
    jmp validate_loop
validate_done:
    ret

invalid_input:
    lea rsi, [rel error_msg]
    call print_string
    mov rax, 0x2000001
    xor rdi, rdi
    syscall

; Function to convert binary string to decimal
binary_to_decimal:
    xor ax, ax                      ; Clear accumulator
    xor rcx, rcx                    ; Index counter
binary_loop:
    mov dl, byte [rsi + rcx]
    cmp dl, 0                       ; Check for null terminator
    je done_binary_conversion
    shl ax, 1                       ; Shift left to make space for next bit
    cmp dl, '1'
    je set_bit                      ; If character is '1', set bit
    jmp next_bit
set_bit:
    or ax, 1                        ; Set the least significant bit
next_bit:
    inc rcx                         ; Move to next character
    jmp binary_loop
done_binary_conversion:
    ret

; Function to convert decimal to binary string
decimal_to_binary:
    mov rcx, 16                     ; Process 16 bits
    lea rdi, [rsi + 15]             ; Start at end of buffer
    mov byte [rdi + 1], 0           ; Null-terminate result
convert_loop:
    test ax, 1                      ; Check least significant bit
    mov byte [rdi], '0'
    jz shift_bit
    mov byte [rdi], '1'
shift_bit:
    shr ax, 1                       ; Shift right to process next bit
    dec rdi                         ; Move to previous character in buffer
    loop convert_loop
    ret

; Function to get string length
string_length:
    xor rax, rax                    ; Clear counter
count_loop:
    cmp byte [rcx + rax], 0         ; Check for null terminator
    je done_counting
    inc rax                         ; Increment length counter
    jmp count_loop
done_counting:
    ret