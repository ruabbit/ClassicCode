#import <Foundation/Foundation.h>

extern NSString * const CCRemoteControlOperationStatus;
extern NSString * const CCRemoteControlOperationListWorkspaces;
extern NSString * const CCRemoteControlOperationListSessions;
extern NSString * const CCRemoteControlOperationGetTranscript;
extern NSString * const CCRemoteControlOperationListFiles;
extern NSString * const CCRemoteControlOperationReadFile;
extern NSString * const CCRemoteControlOperationStartTask;
extern NSString * const CCRemoteControlOperationCancelTask;
extern NSString * const CCRemoteControlOperationTailLogs;

@interface CCRemoteControlResult : NSObject

@property (nonatomic, copy) NSString *operation;
@property (nonatomic, copy) NSString *state;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, retain) NSArray *items;

+ (id)resultWithOperation:(NSString *)operation
                    state:(NSString *)state
                  summary:(NSString *)summary
                   detail:(NSString *)detail;

@end

@protocol CCRemoteControlAdapter <NSObject>

- (CCRemoteControlResult *)performOperation:(NSString *)operation
                                 parameters:(NSDictionary *)parameters
                                      error:(NSError **)error;
- (NSArray *)supportedOperations;

@end

NSArray *CCRemoteControlPlannedOperations(void);
BOOL CCRemoteControlOperationNeedsCodexBackend(NSString *operation);
