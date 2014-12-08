#import <Foundation/Foundation.h>


extern NSString *const SyncManagerSyncDidStartNotification;
extern NSString *const SyncManagerSyncDidFinishNotification;


@interface SyncManager : NSObject

+ (void)initializeSyncManager;

+ (instancetype)sharedSyncManager;

- (void)checkForUpdates;

@property (nonatomic, readonly, getter=isCheckingForUpdates) BOOL checkingForUpdates;
@property (nonatomic, readonly) NSError *lastUpdateCheckError;

@property (nonatomic, readonly) BOOL unreportedResidencesUpdate;
- (void)clearUnreportedUpdates;

- (void)clearAllDataForDebugging;

- (void)dataDidChange;

@end
