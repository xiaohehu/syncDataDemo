#import <Foundation/Foundation.h>


@class User;
@class Unit;
@class SearchRequest;


extern NSString *const ModelManagerDidChangeUnitDataNotification;


@interface ModelManager : NSObject

+ (void)initializeModelManager;

+ (instancetype)sharedModelManager;

@property (nonatomic, readonly) NSArray *sites;

- (Unit *)unitWithNumber:(NSString *)unitNumber;

@property (nonatomic) User *currentlySelectedUser;

- (NSArray *)unitsMatchingSearchRequest:(SearchRequest *)searchRequest;

- (BOOL)updateUnitsWithData:(NSArray *)updatedUnitData;

@end
