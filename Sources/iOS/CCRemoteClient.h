#import <Foundation/Foundation.h>

@interface CCRemoteClient : NSObject

- (NSString *)sendCommand:(NSString *)command
                   toHost:(NSString *)host
                     port:(NSInteger)port
                  timeout:(NSTimeInterval)timeout
                    error:(NSError **)error;

@end
