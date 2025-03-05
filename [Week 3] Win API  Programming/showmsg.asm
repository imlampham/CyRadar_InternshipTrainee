.386
.model flat, stdcall
option casemap :none

; Include necessary Windows API headers
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc

; Link necessary Windows API libraries
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib

.data
; Define window class name and application title
ClassName db "SimpleWindowClass", 0
AppName db "Show message", 0
ButtonClassName db "BUTTON", 0
ButtonText db "Show", 0
EditClassName db "EDIT", 0
MessageBoxTitle db "Message", 0

.data?
; Store instance handle and control handles
hInstance HINSTANCE ?
hwndEdit HWND ?
hwndButton HWND ?
buffer db 256 dup (?)  ; Buffer to store user input text

.const
; Define control IDs
IDC_EDIT equ 1001
IDC_BUTTON equ 1002

.code
; Prototype declaration for WinMain function
WinMain proto :HINSTANCE, :HINSTANCE, :LPSTR, :DWORD

start:
    invoke GetModuleHandle, NULL
    mov hInstance, eax
    ; Call WinMain to start the window
    invoke WinMain, hInstance, NULL, NULL, SW_SHOWDEFAULT
    ; Exit process
    invoke ExitProcess, eax

; Main function to create and display the window
WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX  ; Window class structure
    LOCAL msg:MSG        ; Message structure
    LOCAL hwnd:HWND      ; Window handle

    ; Initialize window class structure
    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW  ; Redraw window on horizontal/vertical resize
    mov wc.lpfnWndProc, OFFSET WndProc  ; Window procedure to handle messages
    mov wc.cbClsExtra, NULL  ; Extra class memory (not used)
    mov wc.cbWndExtra, NULL  ; Extra window memory (not used)
    push hInst
    pop wc.hInstance  ; Store instance handle
    mov wc.hbrBackground, COLOR_BTNFACE+1  ; Set background color
    mov wc.lpszMenuName, NULL  ; No menu assigned
    mov wc.lpszClassName, OFFSET ClassName  ; Assign class name
    invoke LoadIcon, NULL, IDI_APPLICATION  ; Load default application icon
    mov wc.hIcon, eax
    mov wc.hIconSm, eax  ; Set small icon
    invoke LoadCursor, NULL, IDC_ARROW  ; Load default arrow cursor
    mov wc.hCursor, eax
    ; Register window class
    invoke RegisterClassEx, addr wc

    ; Create main application window
    invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 300, 200, NULL, NULL, hInst, NULL
    mov hwnd, eax  ; Store window handle
    ; Show window with specified show mode
    invoke ShowWindow, hwnd, CmdShow
    invoke UpdateWindow, hwnd  ; Refresh window display

    ; Message loop to process window events
    .WHILE TRUE
        invoke GetMessage, ADDR msg, NULL, 0, 0  ; Retrieve messages from queue
        .BREAK .IF (!eax)  ; Exit loop if WM_QUIT is received
        invoke TranslateMessage, ADDR msg  ; Translate virtual key messages
        invoke DispatchMessage, ADDR msg  ; Send message to window procedure
    .ENDW

    mov eax, msg.wParam  ; Return exit code
    ret
WinMain endp

; Window procedure to handle messages
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_CREATE
        ; Create an edit control for user text input
        invoke CreateWindowEx, WS_EX_CLIENTEDGE, ADDR EditClassName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL, 10, 10, 200, 25, hWnd, IDC_EDIT, hInstance, NULL
        mov hwndEdit, eax

        ; Create a button to display message box when clicked
        invoke CreateWindowEx, NULL, ADDR ButtonClassName, ADDR ButtonText, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, 10, 50, 80, 25, hWnd, IDC_BUTTON, hInstance, NULL
        mov hwndButton, eax

    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        .IF ax == IDC_BUTTON
            ; Retrieve text from edit control and show it in a message box
            invoke GetWindowText, hwndEdit, ADDR buffer, 256
            invoke MessageBox, hWnd, ADDR buffer, ADDR MessageBoxTitle, MB_OK
        .ENDIF

    .ELSEIF uMsg == WM_DESTROY
        ; Post quit message to terminate the application
        invoke PostQuitMessage, NULL

    .ELSE
        ; Pass all unhandled messages to default window procedure
        invoke DefWindowProc, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF

    xor eax, eax
    ret
WndProc endp

end start
