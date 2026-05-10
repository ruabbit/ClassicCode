#import "CCRemoteControl.h"

NSString * const CCRemoteControlOperationStatus = @"status";
NSString * const CCRemoteControlOperationListWorkspaces = @"list-workspaces";
NSString * const CCRemoteControlOperationListSessions = @"list-sessions";
NSString * const CCRemoteControlOperationGetTranscript = @"get-transcript";
NSString * const CCRemoteControlOperationListFiles = @"list-files";
NSString * const CCRemoteControlOperationReadFile = @"read-file";
NSString * const CCRemoteControlOperationStartTask = @"start-task";
NSString * const CCRemoteControlOperationCancelTask = @"cancel-task";
NSString * const CCRemoteControlOperationTailLogs = @"tail-logs";

@implementation CCRemoteControlResult

@synthesize operation = _operation;
@synthesize state = _state;
@synthesize summary = _summary;
@synthesize detail = _detail;
@synthesize items = _items;

+ (id)resultWithOperation:(NSString *)operation
                    state:(NSString *)state
                  summary:(NSString *)summary
                   detail:(NSString *)detail
{
    CCRemoteControlResult *result = [[[CCRemoteControlResult alloc] init] autorelease];
    result.operation = operation;
    result.state = state;
    result.summary = summary;
    result.detail = detail;
    result.items = [NSArray array];
    return result;
}

- (void)dealloc
{
    [_operation release];
    [_state release];
    [_summary release];
    [_detail release];
    [_items release];
    [super dealloc];
}

@end

NSArray *CCRemoteControlPlannedOperations(void)
{
    return [NSArray arrayWithObjects:
            CCRemoteControlOperationStatus,
            CCRemoteControlOperationListWorkspaces,
            CCRemoteControlOperationListSessions,
            CCRemoteControlOperationGetTranscript,
            CCRemoteControlOperationListFiles,
            CCRemoteControlOperationReadFile,
            CCRemoteControlOperationStartTask,
            CCRemoteControlOperationCancelTask,
            CCRemoteControlOperationTailLogs,
            nil];
}

BOOL CCRemoteControlOperationNeedsCodexBackend(NSString *operation)
{
    if ([operation isEqualToString:CCRemoteControlOperationStatus]) {
        return NO;
    }
    return [CCRemoteControlPlannedOperations() containsObject:operation];
}
