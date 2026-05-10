#import <Foundation/Foundation.h>
#import "CCWire.h"

#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

static int CCReadLine(int fd, char *buffer, size_t capacity)
{
    size_t offset = 0;
    while (offset + 1 < capacity) {
        char ch = 0;
        ssize_t count = recv(fd, &ch, 1, 0);
        if (count == 0) {
            break;
        }
        if (count < 0) {
            if (errno == EINTR) {
                continue;
            }
            return -1;
        }
        buffer[offset++] = ch;
        if (ch == '\n') {
            break;
        }
    }
    buffer[offset] = '\0';
    return (int)offset;
}

static void CCWriteString(int fd, NSString *string)
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    const char *bytes = (const char *)[data bytes];
    NSUInteger remaining = [data length];
    while (remaining > 0) {
        ssize_t sent = send(fd, bytes, remaining, 0);
        if (sent < 0) {
            if (errno == EINTR) {
                continue;
            }
            break;
        }
        bytes += sent;
        remaining -= (NSUInteger)sent;
    }
}

static void CCHandleClient(int client)
{
    char line[1024];
    CCWriteString(client, @"OK ClassicCodeHost ready\n");
    for (;;) {
        int count = CCReadLine(client, line, sizeof(line));
        if (count <= 0) {
            break;
        }

        NSString *request = [[[NSString alloc] initWithBytes:line length:(NSUInteger)count encoding:NSUTF8StringEncoding] autorelease];
        NSString *response = CCWireResponseForLine(request);
        CCWriteString(client, response);

        if (CCWireLineRequestsClose(request)) {
            break;
        }
    }
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    signal(SIGPIPE, SIG_IGN);

    int port = CCWireDefaultPort;
    const char *portFromEnv = getenv("CLASSICCODE_PORT");
    if (portFromEnv != NULL && strlen(portFromEnv) > 0) {
        port = atoi(portFromEnv);
    }
    if (argc > 1) {
        port = atoi(argv[1]);
    }
    if (port <= 0 || port > 65535) {
        fprintf(stderr, "Invalid port: %d\n", port);
        [pool drain];
        return 64;
    }

    int server = socket(AF_INET, SOCK_STREAM, 0);
    if (server < 0) {
        perror("socket");
        [pool drain];
        return 1;
    }

    int yes = 1;
    setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons((uint16_t)port);

    if (bind(server, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("bind");
        close(server);
        [pool drain];
        return 1;
    }

    if (listen(server, 8) < 0) {
        perror("listen");
        close(server);
        [pool drain];
        return 1;
    }

    NSLog(@"ClassicCodeHost listening on 127.0.0.1:%d", port);
    for (;;) {
        int client = accept(server, NULL, NULL);
        if (client < 0) {
            if (errno == EINTR) {
                continue;
            }
            perror("accept");
            break;
        }

        NSAutoreleasePool *clientPool = [[NSAutoreleasePool alloc] init];
        CCHandleClient(client);
        close(client);
        [clientPool drain];
    }

    close(server);
    [pool drain];
    return 0;
}
