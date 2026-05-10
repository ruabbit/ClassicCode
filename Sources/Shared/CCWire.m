#import "CCWire.h"
#include <unistd.h>

NSString * const CCWireProtocolVersion = @"0";
NSString * const CCWireDefaultHost = @"127.0.0.1";
const int CCWireDefaultPort = 17390;

static NSString *CCWireHostName(void)
{
    char buffer[256];
    if (gethostname(buffer, sizeof(buffer)) == 0) {
        buffer[sizeof(buffer) - 1] = '\0';
        return [NSString stringWithUTF8String:buffer];
    }
    return @"unknown";
}

NSString *CCWireTrimLine(NSString *line)
{
    if (line == nil) {
        return @"";
    }
    return [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

NSString *CCWireResponseForLine(NSString *line)
{
    NSString *trimmed = CCWireTrimLine(line);
    NSString *upper = [trimmed uppercaseString];

    if ([upper length] == 0) {
        return @"ERR empty-command\n";
    }

    if ([upper isEqualToString:@"HELLO"]) {
        return [NSString stringWithFormat:@"OK ClassicCode/%@ host=%@\n", CCWireProtocolVersion, CCWireHostName()];
    }

    if ([upper isEqualToString:@"PING"]) {
        return @"PONG\n";
    }

    if ([upper isEqualToString:@"INFO"]) {
        NSString *os = [[NSProcessInfo processInfo] operatingSystemVersionString];
        return [NSString stringWithFormat:@"INFO protocol=%@ host=%@ os=%@\n", CCWireProtocolVersion, CCWireHostName(), os];
    }

    if ([upper isEqualToString:@"HELP"]) {
        return @"OK commands=HELLO,PING,INFO,HELP,QUIT\n";
    }

    if ([upper isEqualToString:@"QUIT"]) {
        return @"BYE\n";
    }

    return [NSString stringWithFormat:@"ERR unknown-command command=%@\n", trimmed];
}

BOOL CCWireLineRequestsClose(NSString *line)
{
    return [[CCWireTrimLine(line) uppercaseString] isEqualToString:@"QUIT"];
}
