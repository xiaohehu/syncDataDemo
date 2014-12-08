#import "NSDate+ATISO8601.h"

@implementation NSDate (ATISO8601)

+ (NSDate *)at_dateFromISO8601String:(NSString *)dateString {
    static NSDateFormatter *dateFormatter1;
    static NSDateFormatter *dateFormatter2;
    static dispatch_once_t onceToken;
    if (dateString.length == 0) {
        return nil;
    }
    dispatch_once(&onceToken, ^{
        dateFormatter1 = [[NSDateFormatter alloc] init];
        [dateFormatter1 setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter1 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"];
        dateFormatter1.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        dateFormatter2 = [[NSDateFormatter alloc] init];
        [dateFormatter2 setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [dateFormatter2 setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZZZ"];
        dateFormatter2.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    NSDate *result = [dateFormatter1 dateFromString:dateString];
    if (!result) {
        result = [dateFormatter2 dateFromString:dateString];
    }
    NSAssert(result != nil, @"Cannot parse date string: %@", dateString);
    return result;
}

- (NSString *)at_iso8601String {
    return self.description;
}

@end
