#import <Foundation/Foundation.h>

@interface NSDate (ATISO8601)

+ (NSDate *)at_dateFromISO8601String:(NSString *)dateString;

@property (nonatomic, readonly) NSString *at_iso8601String;

@end
