
#import "ATFuncmanStyle.h"


#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


@implementation NSArray (ATFuncmanStyle)

- (NSDictionary *)at_dictionaryByIndexingByKeyPath:(NSString *)keyPath {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        id key = [element valueForKeyPath:keyPath];
        if (key == nil)
            continue;
        [grouped setObject:element forKey:key];
    }
    return grouped;
}

- (NSDictionary *)at_dictionaryByGroupingByKeyPath:(NSString *)keyPath {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        id key = [element valueForKeyPath:keyPath];
        if (key == nil)
            continue;

        NSMutableArray *array = grouped[key];
        if (!array) {
            array = [NSMutableArray new];
            grouped[key] = array;
        }
        [array addObject:element];
    }
    return grouped;
}

- (NSDictionary *)at_dictionaryByIndexingUsingBlock:(id(^)(id value))block {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        id key = block(element);
        if (key == nil)
            continue;
        [grouped setObject:element forKey:key];
    }
    return grouped;
}

- (NSDictionary *)at_unionAndGroupByKeyPath:(NSString *)keyPath {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        NSArray *keys = [element valueForKeyPath:keyPath];
        for (id key in keys) {
            NSMutableArray *array = [grouped objectForKey:key];
            if (!array) {
                array = [NSMutableArray array];
                [grouped setObject:array forKey:key];
            }
            [array addObject:element];
        }
    }
    return grouped;
}

- (NSDictionary *)at_unionAndIndexUsingBlock:(NSArray *(^)(id value))block {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        NSArray *keys = block(element);
        for (id key in keys) {
            grouped[key] = element;
        }
    }
    return grouped;
}

- (NSDictionary *)at_unionAndGroupUsingBlock:(NSArray *(^)(id value))block {
    NSMutableDictionary *grouped = [NSMutableDictionary dictionary];
    for (id element in self) {
        NSArray *keys = block(element);
        for (id key in keys) {
            NSMutableArray *array = [grouped objectForKey:key];
            if (!array) {
                array = [NSMutableArray array];
                [grouped setObject:array forKey:key];
            }
            [array addObject:element];
        }
    }
    return grouped;
}

- (NSSet *)at_mapToKeyPathAsSet:(NSString *)keyPath {
    NSMutableSet *result = [NSMutableSet set];
    for (id element in self) {
        id key = [element valueForKeyPath:keyPath];
        if (key == nil)
            continue;
        [result addObject:key];
    }
    return result;
}

- (NSArray *)at_mapToKeyPath:(NSString *)keyPath {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        id value = [element valueForKeyPath:keyPath];
        if (value == nil)
            continue;
        [result addObject:value];
    }
    return result;
}

- (NSArray *)at_map:(id(^)(id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        id value = block(element);
        if (value == nil)
            continue;
        [result addObject:value];
    }
    return result;
}

- (NSArray *)at_filter:(BOOL(^)(id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        if (block(element))
            [result addObject:element];
    }
    return result;
}

- (id)at_find:(BOOL(^)(id value))block {
//    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        if (block(element)) {
            return element;
        }
    }
    return nil;
}

- (id)at_findMinBy:(NSInteger(^)(id value))block {
    id bestElement = nil;
    NSInteger bestValue = NSIntegerMax;

//    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    for (id element in self) {
        NSInteger value = block(element);
        if (value < bestValue) {
            bestElement = element;
            bestValue = value;
        }
    }
    return bestElement;
}

- (NSArray *)at_arrayByMergingDictionaryValuesWithArray:(NSArray *)peer groupedByKeyPath:(NSString *)keyPath {
    NSDictionary *first = [self at_dictionaryByIndexingByKeyPath:keyPath];
    NSDictionary *second = [peer at_dictionaryByIndexingByKeyPath:keyPath];
    NSDictionary *merged = [first at_dictionaryByMergingDictionaryValuesWithDictionary:second];
    return [merged allValues];
}

- (BOOL)at_all:(BOOL(^)(id object))block {
    for (id element in self) {
        if (!block(element))
            return NO;
    }
    return YES;
}

- (BOOL)at_any:(BOOL(^)(id object))block {
    for (id element in self) {
        if (block(element))
            return YES;
    }
    return NO;
}

@end


@implementation NSDictionary (ATFuncmanStyle)

- (NSDictionary *)at_dictionaryByReversingKeysAndValues {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        result[obj] = key;
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingKeysToSelector:(SEL)selector {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:obj forKey:[key performSelector:selector withObject:nil]];
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingValuesToSelector:(SEL)selector {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:[obj performSelector:selector withObject:nil] forKey:key];
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingValuesToSelector:(SEL)selector withObject:(id)object {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:[obj performSelector:selector withObject:object] forKey:key];
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingValuesToKeyPath:(NSString *)valueKeyPath {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result setObject:[obj valueForKeyPath:valueKeyPath] forKey:key];
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingValuesToBlock:(id(^)(id key, id value))block {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id newValue = block(key, obj);
        if (newValue)
            result[key] = newValue;
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByMappingValuesAccordingToSchema:(NSDictionary *)schema {
    schema = [schema at_dictionaryByReversingKeysAndValues];

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id outputKey = schema[key];
        if (outputKey)
            result[outputKey] = value;
    }];
    return result;
}

- (NSDictionary *)at_dictionaryByAddingEntriesFromDictionary:(NSDictionary *)peer {
    NSMutableDictionary *result = [self mutableCopy];
    [result addEntriesFromDictionary:peer];
    return result;
}

- (NSDictionary *)at_dictionaryByMergingDictionaryValuesWithDictionary:(NSDictionary *)peer {
    NSMutableDictionary *result = [self mutableCopy];
    [peer enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id oldValue = result[key];
        if ([oldValue isKindOfClass:[NSDictionary class]] && [value isKindOfClass:[NSDictionary class]]) {
            value = [oldValue at_dictionaryByMergingDictionaryValuesWithDictionary:value];
        }
        result[key] = value;
    }];
    return result;
}

- (NSArray *)at_arrayByMappingEntriesUsingBlock:(id(^)(id key, id value))block {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id item = block(key, value);
        if (item == nil)
            return;
        [result addObject:item];
    }];
    return result;
}

@end
