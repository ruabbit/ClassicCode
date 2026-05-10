#import "CCDiagnosticRemoteControlAdapter.h"
#import "CCConnectionProfile.h"
#import "CCRemoteClient.h"

@implementation CCDiagnosticRemoteControlAdapter {
    CCRemoteClient *_client;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        _client = [[CCRemoteClient alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_client release];
    [super dealloc];
}

- (NSError *)errorWithMessage:(NSString *)message
{
    NSDictionary *info = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:@"ClassicCodeDiagnosticAdapter" code:1 userInfo:info];
}

- (NSArray *)supportedOperations
{
    return [NSArray arrayWithObject:CCRemoteControlOperationStatus];
}

- (CCRemoteControlResult *)performOperation:(NSString *)operation
                                 parameters:(NSDictionary *)parameters
                                      error:(NSError **)error
{
    (void)parameters;
    if (![operation isEqualToString:CCRemoteControlOperationStatus]) {
        if (error != NULL) {
            *error = [self errorWithMessage:@"Operation requires Codex remote-control backend"];
        }
        return [CCRemoteControlResult resultWithOperation:operation
                                                    state:@"unavailable"
                                                  summary:@"Backend required"
                                                   detail:@"This operation is reserved for the Codex remote-control adapter."];
    }

    NSError *localError = nil;
    NSString *response = [_client sendCommand:@"INFO"
                                       toHost:[CCConnectionProfile host]
                                         port:[CCConnectionProfile port]
                                      timeout:3.0
                                        error:&localError];
    if ([response length] == 0) {
        if (error != NULL) {
            *error = localError;
        }
        return [CCRemoteControlResult resultWithOperation:operation
                                                    state:@"disconnected"
                                                  summary:@"Disconnected"
                                                   detail:[localError localizedDescription]];
    }

    return [CCRemoteControlResult resultWithOperation:operation
                                                state:@"connected"
                                              summary:@"Connected"
                                               detail:response];
}

@end
