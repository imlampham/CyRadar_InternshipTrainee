#include <windows.h>
#include <stdio.h>

#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 600
#define BALL_SIZE 20

typedef struct {
    int x; 
    int y; 
    int dx;
    int dy;
} Ball;

Ball ball = { WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 5, 3 };

HBRUSH ballBrush;

RECT clientRect;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        ballBrush = CreateSolidBrush(RGB(255, 0, 0));
        SetTimer(hwnd, 1, 16, NULL);
        break;

    case WM_TIMER:
        ball.x += ball.dx;
        ball.y += ball.dy;

        GetClientRect(hwnd, &clientRect);

        // Check for collision with right boundary
        if (ball.x + BALL_SIZE > clientRect.right) {
            ball.x = clientRect.right - BALL_SIZE;
            ball.dx = -ball.dx; 
        }

        // Check for collision with left boundary
        if (ball.x < clientRect.left) {
            ball.x = clientRect.left;
            ball.dx = -ball.dx;
        }

        // Check for collision with bottom boundary
        if (ball.y + BALL_SIZE > clientRect.bottom) {
            ball.y = clientRect.bottom - BALL_SIZE;
            ball.dy = -ball.dy;
        }

        // Check for collision with top boundary
        if (ball.y < clientRect.top) {
            ball.y = clientRect.top;
            ball.dy = -ball.dy;
        }

        InvalidateRect(hwnd, NULL, TRUE);
        break;

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        FillRect(hdc, &ps.rcPaint, (HBRUSH)(COLOR_WINDOW + 1));
        SelectObject(hdc, ballBrush);
        Ellipse(hdc, ball.x, ball.y, ball.x + BALL_SIZE, ball.y + BALL_SIZE);
        EndPaint(hwnd, &ps);
        break;
    }

    case WM_DESTROY:
        KillTimer(hwnd, 1);
        DeleteObject(ballBrush);
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}

int main() {
    HINSTANCE hInstance = GetModuleHandle(NULL);

    const wchar_t CLASS_NAME[] = L"BouncingBallWindow";
    WNDCLASSW wc = { 0 };
    wc.lpfnWndProc = WndProc; 
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hCursor = LoadCursorW(NULL, IDC_ARROW); 
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1); 

    if (!RegisterClassW(&wc)) {
        MessageBoxW(NULL, L"Window Registration Failed!", L"Error!", MB_ICONEXCLAMATION | MB_OK);
        return 1;
    }

    HWND hwnd = CreateWindowW(
        CLASS_NAME,             
        L"Bouncing Ball",       
        WS_OVERLAPPEDWINDOW,    
        CW_USEDEFAULT, CW_USEDEFAULT, WINDOW_WIDTH, WINDOW_HEIGHT, 
        NULL, NULL, hInstance, NULL 
    );

    if (hwnd == NULL) {
        MessageBoxW(NULL, L"Window Creation Failed!", L"Error!", MB_ICONEXCLAMATION | MB_OK);
        return 1;
    }

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    MSG msg = { 0 };
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return (int)msg.wParam;
}
