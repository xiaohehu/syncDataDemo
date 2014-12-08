
#import <Foundation/Foundation.h>


@interface NSArray (ATFuncmanStyle)

// returns { key1: value1, key2: value2, ... }
- (NSDictionary *)at_dictionaryByIndexingByKeyPath:(NSString *)keyPath;
- (NSDictionary *)at_dictionaryByIndexingUsingBlock:(id(^)(id value))block;

// returns { key1: [value11, value12, ...], key2: [value21, value22, ...], ... }
- (NSDictionary *)at_dictionaryByGroupingByKeyPath:(NSString *)keyPath;

// same as groupBy, but each block/keyPath returns an array
- (NSDictionary *)at_unionAndGroupByKeyPath:(NSString *)keyPath;
- (NSDictionary *)at_unionAndGroupUsingBlock:(NSArray *(^)(id value))block;

- (NSDictionary *)at_unionAndIndexUsingBlock:(NSArray *(^)(id value))block;

- (NSArray *)at_map:(id(^)(id value))block;
- (NSArray *)at_mapToKeyPath:(NSString *)keyPath;

- (NSSet *)at_mapToKeyPathAsSet:(NSString *)keyPath;

- (NSArray *)at_filter:(BOOL(^)(id value))block;

- (id)at_find:(BOOL(^)(id value))block;

- (id)at_findMinBy:(NSInteger(^)(id value))block;

- (BOOL)at_all:(BOOL(^)(id object))block;
- (BOOL)at_any:(BOOL(^)(id object))block;

- (NSArray *)at_arrayByMergingDictionaryValuesWithArray:(NSArray *)peer groupedByKeyPath:(NSString *)keyPath;

@end


@interface NSDictionary (ATFuncmanStyle)

- (NSDictionary *)at_dictionaryByReversingKeysAndValues;

- (NSDictionary *)at_dictionaryByMappingKeysToSelector:(SEL)selector;
- (NSDictionary *)at_dictionaryByMappingValuesToSelector:(SEL)selector;
- (NSDictionary *)at_dictionaryByMappingValuesToSelector:(SEL)selector withObject:(id)object;
- (NSDictionary *)at_dictionaryByMappingValuesToKeyPath:(NSString *)valueKeyPath;
- (NSDictionary *)at_dictionaryByMappingValuesToBlock:(id(^)(id key, id value))block;

- (NSDictionary *)at_dictionaryByMappingValuesAccordingToSchema:(NSDictionary *)schema;

- (NSDictionary *)at_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)peer;

- (NSDictionary *)at_dictionaryByMergingDictionaryValuesWithDictionary:(NSDictionary *)peer;

- (NSArray *)at_arrayByMappingEntriesUsingBlock:(id(^)(id key, id value))block;

@end
