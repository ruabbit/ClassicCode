#import "CCLineRemoteControlAdapter.h"
#import "CCConnectionProfile.h"
#import "CCRemoteClient.h"

@implementation CCLineRemoteControlAdapter {
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
    return [NSError errorWithDomain:@"ClassicCodeLineAdapter" code:1 userInfo:info];
}

- (NSArray *)supportedOperations
{
    return CCRemoteControlPlannedOperations();
}

- (NSString *)stringParameter:(NSString *)name fromParameters:(NSDictionary *)parameters
{
    id value = [parameters objectForKey:name];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    return nil;
}

- (NSString *)commandForOperation:(NSString *)operation parameters:(NSDictionary *)parameters error:(NSError **)error
{
    if ([operation isEqualToString:CCRemoteControlOperationStatus]) {
        return @"INFO";
    }
    if ([operation isEqualToString:CCRemoteControlOperationListWorkspaces]) {
        return @"LIST_WORKSPACES 100";
    }
    if ([operation isEqualToString:CCRemoteControlOperationListSessions]) {
        NSString *workspace = [self stringParameter:@"workspace" fromParameters:parameters];
        if ([workspace length] == 0) {
            workspace = [CCConnectionProfile workspace];
        }
        return [NSString stringWithFormat:@"LIST_SESSIONS 20 %@", workspace];
    }
    if ([operation isEqualToString:CCRemoteControlOperationListFiles]) {
        NSString *path = [self stringParameter:@"path" fromParameters:parameters];
        if ([path length] == 0) {
            path = [CCConnectionProfile workspace];
        }
        return [@"LIST_FILES " stringByAppendingString:path];
    }
    if ([operation isEqualToString:CCRemoteControlOperationReadFile]) {
        NSString *path = [self stringParameter:@"path" fromParameters:parameters];
        if ([path length] == 0) {
            if (error != NULL) {
                *error = [self errorWithMessage:@"read-file requires path"];
            }
            return nil;
        }
        return [@"READ_FILE " stringByAppendingString:path];
    }
    if ([operation isEqualToString:CCRemoteControlOperationGetTranscript]) {
        NSString *threadID = [self stringParameter:@"threadId" fromParameters:parameters];
        if ([threadID length] == 0) {
            if (error != NULL) {
                *error = [self errorWithMessage:@"get-transcript requires threadId"];
            }
            return nil;
        }
        return [@"GET_TRANSCRIPT " stringByAppendingString:threadID];
    }
    if ([operation isEqualToString:CCRemoteControlOperationTailLogs]) {
        NSString *threadID = [self stringParameter:@"threadId" fromParameters:parameters];
        if ([threadID length] == 0) {
            if (error != NULL) {
                *error = [self errorWithMessage:@"tail-logs requires threadId"];
            }
            return nil;
        }
        return [@"TAIL_LOGS " stringByAppendingString:threadID];
    }
    if ([operation isEqualToString:CCRemoteControlOperationStartTask]) {
        NSString *prompt = [self stringParameter:@"prompt" fromParameters:parameters];
        NSString *workspace = [self stringParameter:@"workspace" fromParameters:parameters];
        if ([workspace length] == 0) {
            workspace = [CCConnectionProfile workspace];
        }
        if ([prompt length] == 0) {
            if (error != NULL) {
                *error = [self errorWithMessage:@"start-task requires prompt"];
            }
            return nil;
        }
        return [NSString stringWithFormat:@"START_TASK %@\t%@", workspace, prompt];
    }
    if ([operation isEqualToString:CCRemoteControlOperationCancelTask]) {
        NSString *threadID = [self stringParameter:@"threadId" fromParameters:parameters];
        NSString *turnID = [self stringParameter:@"turnId" fromParameters:parameters];
        if ([threadID length] == 0 || [turnID length] == 0) {
            if (error != NULL) {
                *error = [self errorWithMessage:@"cancel-task requires threadId and turnId"];
            }
            return nil;
        }
        return [NSString stringWithFormat:@"CANCEL_TASK %@ %@", threadID, turnID];
    }

    if (error != NULL) {
        *error = [self errorWithMessage:@"unknown operation"];
    }
    return nil;
}

- (NSString *)trimmedLine:(NSString *)line
{
    return [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (id)JSONObjectFromOKLine:(NSString *)line error:(NSError **)error
{
    NSString *trimmed = [self trimmedLine:line];
    if (![trimmed hasPrefix:@"OK "]) {
        if (error != NULL) {
            *error = [self errorWithMessage:trimmed];
        }
        return nil;
    }

    NSString *payload = [trimmed substringFromIndex:3];
    if (![payload hasPrefix:@"{"] && ![payload hasPrefix:@"["]) {
        return payload;
    }

    NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    return object;
}

- (NSString *)prettyStringForObject:(id)object
{
    if (object == nil) {
        return @"";
    }
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    if (![NSJSONSerialization isValidJSONObject:object]) {
        return [object description];
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    return string;
}

- (NSArray *)itemsForOperation:(NSString *)operation object:(id)object
{
    if ([operation isEqualToString:CCRemoteControlOperationListSessions] &&
        [object isKindOfClass:[NSDictionary class]]) {
        id data = [object objectForKey:@"data"];
        if ([data isKindOfClass:[NSArray class]]) {
            return data;
        }
    }
    if ([operation isEqualToString:CCRemoteControlOperationListWorkspaces] &&
        [object isKindOfClass:[NSDictionary class]]) {
        id workspaces = [object objectForKey:@"workspaces"];
        if ([workspaces isKindOfClass:[NSArray class]]) {
            return workspaces;
        }
    }
    if ([operation isEqualToString:CCRemoteControlOperationListFiles] &&
        [object isKindOfClass:[NSDictionary class]]) {
        id entries = [object objectForKey:@"entries"];
        if ([entries isKindOfClass:[NSArray class]]) {
            return entries;
        }
    }
    if ([operation isEqualToString:CCRemoteControlOperationGetTranscript] &&
        [object isKindOfClass:[NSDictionary class]]) {
        id transcriptItems = [object objectForKey:@"transcriptItems"];
        if ([transcriptItems isKindOfClass:[NSArray class]]) {
            return transcriptItems;
        }
    }
    return [NSArray array];
}

- (NSString *)summaryForOperation:(NSString *)operation object:(id)object
{
    NSArray *items = [self itemsForOperation:operation object:object];
    if ([operation isEqualToString:CCRemoteControlOperationListSessions]) {
        return [NSString stringWithFormat:@"%lu sessions", (unsigned long)[items count]];
    }
    if ([operation isEqualToString:CCRemoteControlOperationListWorkspaces]) {
        return [NSString stringWithFormat:@"%lu workspaces", (unsigned long)[items count]];
    }
    if ([operation isEqualToString:CCRemoteControlOperationListFiles]) {
        return [NSString stringWithFormat:@"%lu entries", (unsigned long)[items count]];
    }
    if ([operation isEqualToString:CCRemoteControlOperationStatus]) {
        return @"Connected";
    }
    if ([operation isEqualToString:CCRemoteControlOperationGetTranscript]) {
        return @"Transcript";
    }
    if ([operation isEqualToString:CCRemoteControlOperationReadFile]) {
        return @"File";
    }
    if ([operation isEqualToString:CCRemoteControlOperationStartTask]) {
        return @"Task";
    }
    return @"OK";
}

- (CCRemoteControlResult *)performOperation:(NSString *)operation
                                 parameters:(NSDictionary *)parameters
                                      error:(NSError **)error
{
    NSError *localError = nil;
    NSString *command = [self commandForOperation:operation parameters:parameters error:&localError];
    if (command == nil) {
        if (error != NULL) {
            *error = localError;
        }
        return [CCRemoteControlResult resultWithOperation:operation
                                                    state:@"unavailable"
                                                  summary:@"Unavailable"
                                                   detail:[localError localizedDescription]];
    }

    NSString *response = [_client sendCommand:command
                                       toHost:[CCConnectionProfile host]
                                         port:[CCConnectionProfile port]
                                      timeout:5.0
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

    id object = [self JSONObjectFromOKLine:response error:&localError];
    if (object == nil) {
        if (error != NULL) {
            *error = localError;
        }
        return [CCRemoteControlResult resultWithOperation:operation
                                                    state:@"error"
                                                  summary:@"Error"
                                                   detail:[localError localizedDescription]];
    }

    NSString *detail = [self prettyStringForObject:object];
    if ([operation isEqualToString:CCRemoteControlOperationGetTranscript]) {
        detail = @"Invalid transcript response.";
        if ([object isKindOfClass:[NSDictionary class]]) {
            id transcript = [object objectForKey:@"transcriptText"];
            if ([transcript isKindOfClass:[NSString class]] && [transcript length] > 0) {
                detail = transcript;
            } else {
                detail = @"No renderable transcript messages. Restart the ClassicCode bridge if this conversation should contain messages.";
            }
        }
    }

    CCRemoteControlResult *result = [CCRemoteControlResult resultWithOperation:operation
                                                                         state:@"connected"
                                                                       summary:[self summaryForOperation:operation object:object]
                                                                        detail:detail];
    if ([operation isEqualToString:CCRemoteControlOperationReadFile] &&
               [object isKindOfClass:[NSDictionary class]]) {
        id text = [object objectForKey:@"text"];
        id encoding = [object objectForKey:@"encoding"];
        if ([text isKindOfClass:[NSString class]] && [text length] > 0) {
            result.detail = text;
        } else if ([encoding isKindOfClass:[NSString class]] && [encoding isEqualToString:@"binary"]) {
            result.detail = @"Binary file cannot be displayed.";
        }
    }
    result.items = [self itemsForOperation:operation object:object];
    return result;
}

@end
