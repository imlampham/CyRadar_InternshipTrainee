#define _WIN32_WINNT 0x501 
#include <winsock2.h>    
#include <ws2tcpip.h>      
#include <stdio.h>
#include <vector>
#include <thread>         

#define DEFAULT_PORT "27015"
#define DEFAULT_BUFLEN 512

std::vector<SOCKET> clients;

void ClientHandler(SOCKET clientSocket) {
    char recvbuf[DEFAULT_BUFLEN];
    int recvbuflen = DEFAULT_BUFLEN;
    int iResult;

    while (true) {
        iResult = recv(clientSocket, recvbuf, recvbuflen, 0);
        if (iResult > 0) {
            recvbuf[iResult] = '\0';
            printf("Received from client: %s\n", recvbuf);

            for (SOCKET otherClient : clients) {
                if (otherClient != clientSocket) {
                    send(otherClient, recvbuf, iResult, 0);
                }
            }
        }
        else if (iResult == 0) {
            printf("Connection closing...\n");
            break;
        }
        else {
            printf("recv failed: %d\n", WSAGetLastError());
            break;
        }
    }

    for (auto it = clients.begin(); it != clients.end(); ++it) {
        if (*it == clientSocket) {
            clients.erase(it);
            break;
        }
    }
    closesocket(clientSocket);
}

int main() {
    WSADATA wsaData;
    int iResult;

    SOCKET ListenSocket = INVALID_SOCKET;
    SOCKET ClientSocket = INVALID_SOCKET;

    struct addrinfo* result = NULL;
    struct addrinfo hints;

    iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (iResult != 0) {
        printf("WSAStartup failed: %d\n", iResult);
        return 1;
    }

    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = AI_PASSIVE;

    iResult = getaddrinfo(NULL, DEFAULT_PORT, &hints, &result);
    if (iResult != 0) {
        printf("getaddrinfo failed: %d\n", iResult);
        WSACleanup();
        return 1;
    }

    ListenSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
    if (ListenSocket == INVALID_SOCKET) {
        printf("socket failed: %d\n", WSAGetLastError());
        freeaddrinfo(result);
        WSACleanup();
        return 1;
    }

    iResult = bind(ListenSocket, result->ai_addr, (int)result->ai_addrlen);
    if (iResult == SOCKET_ERROR) {
        printf("bind failed: %d\n", WSAGetLastError());
        freeaddrinfo(result);
        closesocket(ListenSocket);
        WSACleanup();
        return 1;
    }

    freeaddrinfo(result);

    iResult = listen(ListenSocket, SOMAXCONN);
    if (iResult == SOCKET_ERROR) {
        printf("listen failed: %d\n", WSAGetLastError());
        closesocket(ListenSocket);
        WSACleanup();
        return 1;
    }

    printf("Server started. Waiting for connections...\n");

    while (true) {
        ClientSocket = accept(ListenSocket, NULL, NULL);
        if (ClientSocket == INVALID_SOCKET) {
            printf("accept failed: %d\n", WSAGetLastError());
            closesocket(ListenSocket);
            WSACleanup();
            return 1;
        }

        clients.push_back(ClientSocket);
        printf("New client connected. Total clients: %d\n", clients.size());

        std::thread clientThread(ClientHandler, ClientSocket);
        clientThread.detach();
    }

    closesocket(ListenSocket);
    WSACleanup();

    return 0;
}