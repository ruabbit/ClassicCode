#import "CCRemoteClient.h"

#include <arpa/inet.h>
#include <errno.h>
#include <netdb.h>
#include <netinet/in.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>

@implementation CCRemoteClient

- (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message
{
    NSDictionary *info = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"ClassicCodeRemoteClient" code:code userInfo:info];
}

- (BOOL)writeData:(NSData *)data toSocket:(int)fd error:(NSError **)error
{
    const char *bytes = (const char *)[data bytes];
    NSUInteger remaining = [data length];
    while (remaining > 0) {
        ssize_t sent = send(fd, bytes, remaining, 0);
        if (sent < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (error != NULL) {
                *error = [self errorWithCode:errno message:[NSString stringWithFormat:@"send failed: %s", strerror(errno)]];
            }
            return NO;
        }
        bytes += sent;
        remaining -= (NSUInteger)sent;
    }
    return YES;
}

- (NSString *)readLineFromSocket:(int)fd error:(NSError **)error
{
    NSMutableData *data = [NSMutableData data];
    for (;;) {
        char ch = 0;
        ssize_t count = recv(fd, &ch, 1, 0);
        if (count == 0) {
            break;
        }
        if (count < 0) {
            if (errno == EINTR) {
                continue;
            }
            if (error != NULL) {
                *error = [self errorWithCode:errno message:[NSString stringWithFormat:@"recv failed: %s", strerror(errno)]];
            }
            return nil;
        }
        [data appendBytes:&ch length:1];
        if (ch == '\n') {
            break;
        }
    }

    if ([data length] == 0) {
        if (error != NULL) {
            *error = [self errorWithCode:0 message:@"connection closed"];
        }
        return nil;
    }

    NSString *line = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if (line == nil && error != NULL) {
        *error = [self errorWithCode:0 message:@"response was not UTF-8"];
    }
    return line;
}

- (NSString *)sendCommand:(NSString *)command
                   toHost:(NSString *)host
                     port:(NSInteger)port
                  timeout:(NSTimeInterval)timeout
                    error:(NSError **)error
{
    if ([host length] == 0) {
        if (error != NULL) {
            *error = [self errorWithCode:0 message:@"host is empty"];
        }
        return nil;
    }

    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        if (error != NULL) {
            *error = [self errorWithCode:errno message:[NSString stringWithFormat:@"socket failed: %s", strerror(errno)]];
        }
        return nil;
    }

    struct timeval tv;
    tv.tv_sec = (int)timeout;
    tv.tv_usec = 0;
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_port = htons((uint16_t)port);

    const char *hostBytes = [host UTF8String];
    if (inet_aton(hostBytes, &address.sin_addr) == 0) {
        struct hostent *entry = gethostbyname(hostBytes);
        if (entry == NULL || entry->h_addr_list == NULL || entry->h_addr_list[0] == NULL) {
            close(fd);
            if (error != NULL) {
                *error = [self errorWithCode:h_errno message:@"host lookup failed"];
            }
            return nil;
        }
        memcpy(&address.sin_addr, entry->h_addr_list[0], sizeof(address.sin_addr));
    }

    if (connect(fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        close(fd);
        if (error != NULL) {
            *error = [self errorWithCode:errno message:[NSString stringWithFormat:@"connect failed: %s", strerror(errno)]];
        }
        return nil;
    }

    NSError *localError = nil;
    NSString *banner = [self readLineFromSocket:fd error:&localError];
    if (banner == nil) {
        close(fd);
        if (error != NULL) {
            *error = localError;
        }
        return nil;
    }

    NSString *line = [command stringByAppendingString:@"\n"];
    NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
    if (![self writeData:data toSocket:fd error:&localError]) {
        close(fd);
        if (error != NULL) {
            *error = localError;
        }
        return nil;
    }

    NSString *response = [self readLineFromSocket:fd error:&localError];
    close(fd);
    if (response == nil && error != NULL) {
        *error = localError;
    }
    return response;
}

@end
