#import "CCConnectionProfile.h"
#import "CCWire.h"

static NSString * const CCProfileDisplayNameKey = @"connection.displayName";
static NSString * const CCProfileHostKey = @"connection.host";
static NSString * const CCProfilePortKey = @"connection.port";
static NSString * const CCProfileWorkspaceKey = @"connection.workspace";

@implementation CCConnectionProfile

+ (void)registerDefaults
{
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"Mac mini", CCProfileDisplayNameKey,
                              CCWireDefaultHost, CCProfileHostKey,
                              [NSNumber numberWithInt:CCWireDefaultPort], CCProfilePortKey,
                              @"ClassicCode", CCProfileWorkspaceKey,
                              nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (NSString *)stringForKey:(NSString *)key fallback:(NSString *)fallback
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if ([value length] == 0) {
        return fallback;
    }
    return value;
}

+ (NSString *)displayName
{
    return [self stringForKey:CCProfileDisplayNameKey fallback:@"Mac mini"];
}

+ (NSString *)host
{
    return [self stringForKey:CCProfileHostKey fallback:CCWireDefaultHost];
}

+ (NSInteger)port
{
    NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey:CCProfilePortKey];
    if (port <= 0 || port > 65535) {
        return CCWireDefaultPort;
    }
    return port;
}

+ (NSString *)workspace
{
    return [self stringForKey:CCProfileWorkspaceKey fallback:@"ClassicCode"];
}

+ (void)saveDisplayName:(NSString *)displayName
                   host:(NSString *)host
                   port:(NSInteger)port
              workspace:(NSString *)workspace
{
    [self saveDisplayName:displayName host:host port:port];
    [self saveWorkspace:workspace];
}

+ (void)saveDisplayName:(NSString *)displayName
                   host:(NSString *)host
                   port:(NSInteger)port
{
    if (port <= 0 || port > 65535) {
        port = CCWireDefaultPort;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:([displayName length] > 0 ? displayName : @"Mac mini") forKey:CCProfileDisplayNameKey];
    [defaults setObject:([host length] > 0 ? host : CCWireDefaultHost) forKey:CCProfileHostKey];
    [defaults setInteger:port forKey:CCProfilePortKey];
    [defaults synchronize];
}

+ (void)saveWorkspace:(NSString *)workspace
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:([workspace length] > 0 ? workspace : @"ClassicCode") forKey:CCProfileWorkspaceKey];
    [defaults synchronize];
}

+ (NSString *)summary
{
    return [NSString stringWithFormat:@"%@ %@:%d", [self displayName], [self host], (int)[self port]];
}

@end
