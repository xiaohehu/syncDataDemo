#import <AFNetworking/AFNetworking.h>

#import "ModelManager.h"
#import "SyncManager.h"

//#import "User.h"
//#import "Favorite.h"
//#import "Unit.h"

#import "ATScheduling.h"
#import "NSDate+ATISO8601.h"
#import "ATFuncmanStyle.h"


NSString *const SyncManagerSyncDidStartNotification = @"SyncManagerSyncDidStart";
NSString *const SyncManagerSyncDidFinishNotification = @"SyncManagerSyncDidFinish";

static NSString *const ServerApiToken = @"6LEDoRfuDDi7EPTFEcbs";


static id NSNullToNil(id obj) {
    if (obj == [NSNull null]) {
        return nil;
    } else {
        return obj;
    }
}


@implementation SyncManager {
    ATCoalescedState _updateCheckingState;
    AFHTTPSessionManager *_sessionManager;
    
    NSURL *_residencesUpdatesFileURL;
    id _residencesUpdates;
    
    NSURL *_residencesURL;
    NSURL *_usersDownloadURL;
    NSURL *_usersUploadURL;
    
    BOOL _verboseLogging;

    dispatch_queue_t _fileSerialQueue;
}

static SyncManager *sharedSyncManager;

+ (void)initializeSyncManager {
    sharedSyncManager = [SyncManager new];
    // to avoid unpleasant surprises we want sharedSyncManager to be set before performing initialization
    [sharedSyncManager _initializeSyncManager];
}

+ (instancetype)sharedSyncManager {
    NSAssert(sharedSyncManager != nil, @"sharedSyncManager called before initializeSyncManager");
    return sharedSyncManager;
}

- (void)_initializeSyncManager {
    _fileSerialQueue = dispatch_queue_create("SyncManager.fileQueue", NULL);

    _verboseLogging = NO;
#ifdef DEBUG
    _verboseLogging = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.neoscape.sync.verbose"];
#endif
    
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    _residencesUpdatesFileURL = [documentsDirectory URLByAppendingPathComponent:@"residences-updates.json"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.allowsCellularAccess = NO;
    configuration.timeoutIntervalForRequest = 130.0;
    configuration.timeoutIntervalForResource = 160.0;
    configuration.HTTPMaximumConnectionsPerHost = 1;
    
    BOOL staging = YES;
    if (staging) {
        _residencesURL = [NSURL URLWithString:@"http://theresidenceslongisland.com/io/o/availability/availability.json"];
        _usersDownloadURL = [NSURL URLWithString:@"http://andreyvit-demo.nfshost.com/rxr-northhills-sync/user-sync.php"];
        _usersUploadURL = _usersDownloadURL;
    } else {
        _residencesURL = [NSURL URLWithString:@"http://theresidenceslongisland.com/io/o/availability/availability.json"];
        abort();  // TODO
    }
    
    _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil sessionConfiguration:configuration];
    _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _sessionManager.requestSerializer.allowsCellularAccess = configuration.allowsCellularAccess;
    _sessionManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    [_sessionManager.requestSerializer setAuthorizationHeaderFieldWithUsername:ServerApiToken password:@"x"];
    
    dispatch_async(_fileSerialQueue, ^{
        NSData *data = [NSData dataWithContentsOfURL:_residencesUpdatesFileURL];
        if (data) {
            NSError *error;
            id raw = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (raw == nil) {
                NSLog(@"Error parsing JSON from %@: %@", _residencesUpdatesFileURL.path, error.localizedDescription);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _residencesUpdates = raw;
                    NSLog(@"The data get from server is %@", raw);
                    [[ModelManager sharedModelManager] updateUnitsWithData:raw];
                });
            }
        }
    });
}

- (void)checkForUpdates {
    AT_dispatch_coalesced_with_notifications(&_updateCheckingState, 0, ^(dispatch_block_t done) {
        [self synchronizeResidencesWithCompletionBlock:^(BOOL succeeded) {
            if (!succeeded) {
                done();
            } else {
                [self synchronizeUsersWithCompletionBlock:^(BOOL succeeded) {
                    done();
                }];
            }
        }];
    }, ^{
        if (_updateCheckingState > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SyncManagerSyncDidStartNotification object:self];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:SyncManagerSyncDidFinishNotification object:self];
        }
    });
}

- (void)synchronizeResidencesWithCompletionBlock:(void(^)(BOOL succeeded))completionBlock {
    NSLog(@"Sync: downloading residences.json");
    [_sessionManager GET:_residencesURL.absoluteString parameters:@{} success:^(NSURLSessionDataTask *task, id raw) {
        NSLog(@"Sync: residences.json download succeeded");
        if (_verboseLogging) {
            NSLog(@"Sync: residences.json = %@", raw);
        }

        if (_residencesUpdates == nil || ![_residencesUpdates isEqual:raw]) {
            _residencesUpdates = raw;
            
            dispatch_async(_fileSerialQueue, ^{
                NSData *data = [NSJSONSerialization dataWithJSONObject:raw options:0 error:NULL];
                [data writeToURL:_residencesUpdatesFileURL options:NSDataWritingAtomic error:NULL];
            });
            
            if ([[ModelManager sharedModelManager] updateUnitsWithData:raw]) {
                _unreportedResidencesUpdate = YES;
            }
        }
        completionBlock(YES);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Sync: residences.json download failed - %@", error.debugDescription);
        _lastUpdateCheckError = error;
        completionBlock(NO);
    }];
}

- (void)synchronizeUsersWithCompletionBlock:(void(^)(BOOL succeeded))completionBlock {
    [self downloadUsersWithCompletionBlock:^(NSArray *usersToUpload, BOOL succeeded) {
        if (!succeeded) {
            completionBlock(NO);
        } else {
            [self uploadUsers:usersToUpload completionBlock:^(BOOL succeeded) {
                completionBlock(succeeded);
            }];
        }
    }];
}

- (void)downloadUsersWithCompletionBlock:(void(^)(NSArray *usersToUpload, BOOL succeeded))completionBlock {
    NSLog(@"Sync: downloading users.json");
    [_sessionManager GET:_usersDownloadURL.absoluteString parameters:@{} success:^(NSURLSessionDataTask *task, id raw) {
        NSLog(@"Sync: users.json download succeeded");
        if (_verboseLogging) {
            NSLog(@"Sync: users.json = %@", raw);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Sync: users.json download failed - %@", error.debugDescription);
        _lastUpdateCheckError = error;
        completionBlock(nil, NO);
    }];

//        NSArray *incomingUserDictionaries = raw;
//        
//        NSDictionary *existingUsersByIdentifier = [User keyedAllInstances];
//        
//        NSError *lastError = nil;
//        
//        for (NSDictionary *userDictionary in incomingUserDictionaries) {
//            NSString *userIdentifier = userDictionary[@"identifier"];
//            VersionNumber newServerVersionNumber = [userDictionary[@"serverVersionNumber"] longLongValue];
//            User *user = existingUsersByIdentifier[userIdentifier] ?: [User instanceWithPrimaryKey:userIdentifier];
//            
//            if (newServerVersionNumber > user.serverVersionNumber) {
//                NSLog(@"Sync: Updating user %@ (%@) v%@ -> v%@", user.identifier, user.fullName, @(user.serverVersionNumber), @(newServerVersionNumber));
//
//                user.serverVersionNumber = newServerVersionNumber;
//
//                NSDate *creationTime = [NSDate at_dateFromISO8601String:userDictionary[@"creationTime"]];
//                if ((user.creationTime == nil) || ([user.creationTime compare:creationTime] == NSOrderedDescending)) {
//                    user.creationTime = creationTime;
//                }
//                
//                NSDate *modificationTime = [NSDate at_dateFromISO8601String:userDictionary[@"modificationTime"]];
//                if ((user.modificationTime == nil) || ([user.modificationTime compare:modificationTime] == NSOrderedAscending)) {
//                    user.modificationTime = modificationTime;
//                    user.email = userDictionary[@"email"];
//                    user.firstName = userDictionary[@"firstName"];
//                    user.lastName = userDictionary[@"lastName"];
//                    user.phone = userDictionary[@"phone"];
//                }
//                
//                NSDate *deletionTime = [NSDate at_dateFromISO8601String:NSNullToNil(userDictionary[@"deletionTime"])];
//                if (deletionTime) {
//                    if ((user.deletionTime == nil) || ([user.deletionTime compare:modificationTime] == NSOrderedDescending)) {
//                        user.deletionTime = deletionTime;
//                    }
//                }
//
//                FCModelSaveResult sr = [user save];
//                if (sr == FCModelSaveFailed) {
//                    NSLog(@"Sync: Failed to save user %@ (%@): %@", user.identifier, user.fullName, user.lastSQLiteError.debugDescription);
//                    lastError = lastError ?: user.lastSQLiteError;
//                }
//
//                NSDictionary *favorites = [[Favorite instancesWhere:@"userIdentifier = ?", user.identifier] at_dictionaryByIndexingByKeyPath:@"unitNumber"];
//                
//                NSArray *favoriteDictionaries = userDictionary[@"favorites"];
//                for (NSDictionary *favoriteDictionary in favoriteDictionaries) {
//                    NSString *unitNumber = favoriteDictionary[@"unitNumber"];
//                    Favorite *favorite = favorites[unitNumber];
//                    if (favorite == nil) {
//                        favorite = [Favorite new];
//                        favorite.user = user;
//                        favorite.unitNumber = unitNumber;
//                    }
//                    
//                    NSDate *creationTime = [NSDate at_dateFromISO8601String:favoriteDictionary[@"creationTime"]];
//                    if ((favorite.creationTime == nil) || ([favorite.creationTime compare:creationTime] == NSOrderedDescending)) {
//                        favorite.creationTime = creationTime;
//                    }
//                    
//                    NSDate *modificationTime = [NSDate at_dateFromISO8601String:favoriteDictionary[@"modificationTime"]];
//                    if ((favorite.modificationTime == nil) || ([favorite.modificationTime compare:modificationTime] == NSOrderedAscending)) {
//                        favorite.modificationTime = modificationTime;
//                        favorite.materialIdentifier = NSNullToNil(favoriteDictionary[@"materialIdentifier"]);
//                        favorite.variantIdentifier = NSNullToNil(favoriteDictionary[@"variantIdentifier"]);
//                    }
//
//                    NSDate *deletionTime = [NSDate at_dateFromISO8601String:NSNullToNil(favoriteDictionary[@"deletionTime"])];
//                    NSDate *undeletionTime = [NSDate at_dateFromISO8601String:NSNullToNil(favoriteDictionary[@"undeletionTime"])];
//                    if (deletionTime && undeletionTime) {
//                        favorite.deleted = ([deletionTime compare:undeletionTime] == NSOrderedDescending);
//                    } else {
//                        favorite.deleted = (deletionTime != nil);
//                    }
//                    favorite.deletionTime = deletionTime;
//                    favorite.undeletionTime = undeletionTime;
//                    
//                    FCModelSaveResult sr = [favorite save];
//                    if (sr == FCModelSaveFailed) {
//                        NSLog(@"Sync: Failed to save favorite %@ (%@) - %@: %@", user.identifier, user.fullName, favorite.unitNumber, favorite.lastSQLiteError.debugDescription);
//                        lastError = lastError ?: favorite.lastSQLiteError;
//                    }
//                }
//            } else {
//                if (_verboseLogging) {
//                    NSLog(@"Sync: User %@ (%@) is up to date at v%@", user.identifier, user.fullName, @(user.serverVersionNumber));
//                }
//            }

//    } failure:^(NSURLSessionDataTask *task, NSError *error) {
//        NSLog(@"Sync: users.json download failed - %@", error.debugDescription);
//        _lastUpdateCheckError = error;
//        completionBlock(nil, NO);
//    }];
}

- (void)uploadUsers:(NSArray *)users completionBlock:(void(^)(BOOL succeeded))completionBlock {
    [self uploadUsers:users startingAtIndex:0 previousSucceeded:YES completionBlock:completionBlock];
}

- (void)uploadUsers:(NSArray *)users startingAtIndex:(NSInteger)idx previousSucceeded:(BOOL)previousSucceeded completionBlock:(void(^)(BOOL succeeded))completionBlock {
    if (idx >= users.count) {
        completionBlock(previousSucceeded);
        return;
    }
    
    [self uploadUser:users[idx] completionBlock:^(BOOL succeeded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self uploadUsers:users startingAtIndex:idx+1 previousSucceeded:(previousSucceeded && succeeded) completionBlock:completionBlock];
        });
    }];
}

- (void)uploadUser:(User *)user completionBlock:(void(^)(BOOL succeeded))completionBlock {
//    NSArray *favorites = [Favorite instancesWhere:@"userIdentifier = ?", user.identifier];
//    
//    VersionNumber newVersionNumber = user.serverVersionNumber + 1;
//    
//    NSDictionary *userDictionary = @{
//        @"identifier": user.identifier,
//        @"serverVersionNumber": @(newVersionNumber),
//
//        @"email": user.email,
//        @"firstName": user.firstName,
//        @"lastName": user.lastName,
//        @"phone": user.phone,
//
//        @"modificationTime": user.modificationTime.at_iso8601String,
//        @"creationTime": user.creationTime.at_iso8601String,
//        
//        @"deletionTime": user.deletionTime.at_iso8601String ?: [NSNull null],
//        
//        @"favorites": [favorites at_map:^id(Favorite *favorite) {
//            return @{
//                @"unitNumber": favorite.unitNumber,
//                @"materialIdentifier": favorite.materialIdentifier ?: [NSNull null],
//                @"variantIdentifier": favorite.variantIdentifier ?: [NSNull null],
//
//                @"creationTime": favorite.creationTime.at_iso8601String,
//                @"modificationTime": favorite.modificationTime.at_iso8601String,
//                @"deletionTime": favorite.deletionTime.at_iso8601String ?: [NSNull null],
//                @"undeletionTime": favorite.undeletionTime.at_iso8601String ?: [NSNull null],
//            };
//        }],
//    };
//
//    NSLog(@"Sync: uploading user-%@.json (%@)", user.identifier, user.fullName);
//    [_sessionManager POST:_usersUploadURL.absoluteString parameters:userDictionary success:^(NSURLSessionDataTask *task, id raw) {
//        NSLog(@"Sync: user-%@.json (%@) v%@ upload succeeded - %@", user.identifier, user.fullName, @(newVersionNumber), raw);
//
//        user.serverVersionNumber = newVersionNumber;
//        user.dirty = NO;
//        [user save];
//        
//        completionBlock(YES);
//    } failure:^(NSURLSessionDataTask *task, NSError *error) {
//        NSLog(@"Sync: user-%@.json (%@) upload failed - %@", user.identifier, user.fullName, error.debugDescription);
//        _lastUpdateCheckError = error;
//        completionBlock(NO);
//    }];
    NSLog(@"Should upload data");
}

- (BOOL)isCheckingForUpdates {
    return _updateCheckingState > 0;
}

- (void)clearUnreportedUpdates {
    _unreportedResidencesUpdate = NO;
}

- (void)clearAllDataForDebugging {
//    [Favorite executeUpdateQuery:@"DELETE FROM $T"];
//    [User executeUpdateQuery:@"DELETE FROM $T"];
}

- (void)dataDidChange {
    [self checkForUpdates];
}

@end
