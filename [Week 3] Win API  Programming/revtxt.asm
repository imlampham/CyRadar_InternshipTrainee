.386
.model flat, stdcall
option casemap:none

; Include necessary Windows API headers
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

.data
; Define window class name and application title
ClassName   db "ReverseTextClass",0
AppName     db "Reverse Text",0
EditClass   db "EDIT",0

.data?
; Store instance handle and control handles
hInstance   HINSTANCE ?
hwndInput   HWND ?
hwndOutput  HWND ?
wc          WNDCLASSEX <>    ; Moved from local to global scope
msg         MSG <>           ; Moved from local to global scope
buffer      db 256 dup (?)   ; Buffer for input text
revbuf      db 256 dup (?)   ; Buffer for reversed text

.const
; Define control IDs
IDC_INPUT   equ 1001
IDC_OUTPUT  equ 1002

.code
; Window Procedure - Handles window messages
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg == WM_CREATE
        ; Create input edit control
        invoke CreateWindowEx, 0, addr EditClass, NULL,
            WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL,
            10, 10, 280, 25,
            hWnd, IDC_INPUT, hInstance, NULL
        mov hwndInput, eax

        ; Create output edit control (read-only)
        invoke CreateWindowEx, 0, addr EditClass, NULL,
            WS_CHILD or WS_VISIBLE or WS_BORDER or ES_READONLY or ES_AUTOHSCROLL,
            10, 45, 280, 25,
            hWnd, IDC_OUTPUT, hInstance, NULL
        mov hwndOutput, eax

    .elseif uMsg == WM_COMMAND
        ; Handle input text change event
        mov eax, wParam
        shr eax, 16
        .if ax == EN_CHANGE
            mov eax, wParam
            .if ax == IDC_INPUT
                ; Get input text from edit control
                invoke GetWindowText, hwndInput, addr buffer, 256
                
                ; Calculate length of input text and prepare for reversal
                xor ecx, ecx
                lea esi, buffer
                lea edi, revbuf
length_loop:
                mov al, [esi]
                .if al == 0
                    jmp reverse_start
                .endif
                inc ecx
                inc esi
                jmp length_loop

reverse_start:
                dec esi
                mov edx, ecx  ; Store length of the string
                
reverse_loop:
                .if ecx == 0
                    jmp reverse_done
                .endif
                mov al, [esi]
                mov [edi], al
                dec esi
                inc edi
                dec ecx
                jmp reverse_loop

reverse_done:
                mov byte ptr [edi], 0  ; Null-terminate the reversed string
                
                ; Set reversed text in the output edit control
                invoke SetWindowText, hwndOutput, addr revbuf
            .endif
        .endif

    .elseif uMsg == WM_DESTROY
        ; Handle window close event
        invoke PostQuitMessage, 0
    .else
        ; Default message handling
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .endif
    xor eax, eax
    ret
WndProc endp

; Application entry point
start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax

    ; Register window class
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset WndProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInstance
    mov wc.hInstance, eax
    mov wc.hbrBackground, COLOR_WINDOW+1  ; Set background color
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, offset ClassName
    invoke LoadIcon, NULL, IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax

    ; Register window class with Windows
    invoke RegisterClassEx, addr wc

    ; Create main application window
    invoke CreateWindowEx, 0,
        addr ClassName, addr AppName,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 320, 120,
        NULL, NULL, hInstance, NULL

    ; Display the window
    invoke ShowWindow, eax, SW_SHOW
    invoke UpdateWindow, eax

    ; Message loop - Handles user input and system messages
msg_loop:
    invoke GetMessage, addr msg, NULL, 0, 0
    .if eax != 0
        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg
        jmp msg_loop
    .endif

    ; Exit application when message loop ends
    invoke ExitProcess, msg.wParam
end start
