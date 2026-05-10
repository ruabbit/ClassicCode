#import <Foundation/Foundation.h>

extern NSString * const CCWireProtocolVersion;
extern NSString * const CCWireDefaultHost;
extern const int CCWireDefaultPort;

NSString *CCWireTrimLine(NSString *line);
NSString *CCWireResponseForLine(NSString *line);
BOOL CCWireLineRequestsClose(NSString *line);
