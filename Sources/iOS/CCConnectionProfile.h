#import <Foundation/Foundation.h>

@interface CCConnectionProfile : NSObject

+ (void)registerDefaults;
+ (NSString *)displayName;
+ (NSString *)host;
+ (NSInteger)port;
+ (NSString *)workspace;
+ (void)saveDisplayName:(NSString *)displayName
                   host:(NSString *)host
                   port:(NSInteger)port
              workspace:(NSString *)workspace;
+ (void)saveDisplayName:(NSString *)displayName
                   host:(NSString *)host
                   port:(NSInteger)port;
+ (void)saveWorkspace:(NSString *)workspace;
+ (NSString *)summary;

@end
