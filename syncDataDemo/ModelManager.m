#import <FCModel/FCModel.h>

#import "ModelManager.h"
//#import "Unit.h"
//#import "Site.h"
//#import "Floor.h"
//#import "FloorRegion.h"
//#import "SearchRequest.h"

#import "ATFuncmanStyle.h"
#import "ATEasyResourceAccess.h"


NSString *const ModelManagerDidChangeUnitDataNotification = @"ModelManagerDidChangeUnitData";


@implementation ModelManager {
    NSArray *_sites;
    NSDictionary *_sitesByAddress;
    NSDictionary *_sitesByBuildingNumber;

    NSArray *_units;
    NSDictionary *_unitsByNumber;
}

static ModelManager *sharedModelManager;

+ (instancetype)sharedModelManager {
    NSAssert(sharedModelManager != nil, @"sharedModelManager called before initializeModelManager");
    return sharedModelManager;
}

+ (void)initializeModelManager {
    sharedModelManager = [ModelManager new];

    NSURL *legacyDatabaseURL = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] URLByAppendingPathComponent:@"rxrnorthhills.sqlite"];
    [[NSFileManager defaultManager] removeItemAtURL:legacyDatabaseURL error:NULL];

    [sharedModelManager _initializeDatabase];
//    [sharedModelManager _loadBuildingsAndUnits];
}

- (void)_initializeDatabase {
    NSURL *databaseURL = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] URLByAppendingPathComponent:@"data.sqlite"];
    NSLog(@"Database path: %@", databaseURL.path);

    [FCModel openDatabaseAtPath:databaseURL.path withDatabaseInitializer:^(FMDatabase *db) {
        // db.traceExecution = YES;
        db.crashOnErrors = YES;
    } schemaBuilder:^(FMDatabase *db, int *schemaVersion) {
        if (*schemaVersion < 1) {
            [db executeStatements:[NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"0001_create_users.sql" withExtension:@""] encoding:NSUTF8StringEncoding error:NULL]];
            *schemaVersion = 1;
        }
        if (*schemaVersion < 2) {
            [db executeStatements:[NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"0002_create_favorites.sql" withExtension:@""] encoding:NSUTF8StringEncoding error:NULL]];
            *schemaVersion = 2;
        }
        if (*schemaVersion < 3) {
            [db executeStatements:[NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"0003_enable_sync.sql" withExtension:@""] encoding:NSUTF8StringEncoding error:NULL]];
            *schemaVersion = 3;
        }
    }];
}
//
//- (void)_loadBuildingsAndUnits {
//    __block NSInteger siteIndex = 0;
//	_sites = [ATJSONObjectFromBundledFile(@"sites.json")[@"sites"] at_map:^id(NSDictionary *buildingData) {
//        Site *site = [Site new];
//        site.index = siteIndex++;
//        site.address = buildingData[@"title"];
//        site.buildingNumbers = buildingData[@"buildingNumbers"];
//        __block NSInteger floorIndex = 0;
//        site.floors = [buildingData[@"floors"] at_map:^id(NSDictionary *floorData) {
//            Floor *floor = [Floor new];
//            floor.index = floorIndex++;
//            floor.name = floorData[@"floorname"];
//            floor.plateImageName = floorData[@"floorplateImage"];
//            floor.regions = [self _regionsForFloor:floor inSite:site];
//            return floor;
//        }];
//        return site;
//    }];
//    _sitesByAddress = [_sites at_dictionaryByIndexingByKeyPath:@"address"];
//    _sitesByBuildingNumber = [_sites at_unionAndIndexUsingBlock:^NSArray *(Site *site) {
//        return site.buildingNumbers;
//    }];
//
//    NSArray *rows = ATJSONObjectFromBundledFile(@"units.json");
//    NSArray *units = [rows at_map:^id(NSDictionary *row) {
//        Unit *unit = [Unit new];
//        [unit updateUsingValuesFromDictionary:row];
//
//        Site *site = _sitesByBuildingNumber[unit.buildingNumber];
//        NSAssert(site != nil, @"Cannot find site for unit %@", row);
//        unit.site = site;
//
//        return unit;
//    }];
//    _units = units;
//    _unitsByNumber = [units at_dictionaryByIndexingByKeyPath:@"number"];
//
//    for (Site *site in _sites) {
//        site.units = [units at_filter:^BOOL(Unit *unit) {
//            return unit.site == site;
//        }];
//    }
//
//    for (Site *site in _sites) {
//        for (Floor *floor in site.floors) {
//            for (FloorRegion *region in floor.regions) {
//                region.unit = _unitsByNumber[region.unitNumber];
//                NSAssert(region.unit != nil, @"Cannot find unit for floor region with unit number '%@'", region.unitNumber);
//                region.unit.floor = floor;
//            }
//        }
//    }
//
//    for (Unit *unit in _units) {
//        NSAssert(unit.floor != nil, @"Floor not populated for unit number '%@'", unit.number);
//        [unit populateVariants];
//    }
//
//    NSDictionary *sitePlanData = ATObjectFromBundledPropertyListFile(@"floorplanData.plist")[0];
//    for (Site *site in _sites) {
//        site.sitePlanImageName = sitePlanData[@"siteplan"];
//        [sitePlanData[@"floorplans"] enumerateObjectsUsingBlock:^(NSDictionary *unitData, NSUInteger idx, BOOL *stop) {
//            NSDictionary *rawFloorPlanData = unitData[@"floorplaninfo"][0];
//
//            // TODO FIXME: use more sensible matching
//            if (idx < site.units.count) {
//                Unit *unit = site.units[idx];
//                unit.rawFloorPlanData = rawFloorPlanData;
//            }
//        }];
//    }
//}

- (Unit *)unitWithNumber:(NSString *)unitNumber {
    return _unitsByNumber[unitNumber];
}

- (NSArray *)unitsMatchingSearchRequest:(SearchRequest *)searchRequest {
    return [_units at_filter:^BOOL(Unit *unit) {
//        return [searchRequest isSatisfiedByUnit:unit];
        return nil;
    }];
}

- (BOOL)updateUnitsWithData:(NSArray *)updatedUnitData {
    BOOL changesMade = NO;
    for (NSDictionary *row in updatedUnitData) {
        NSString *unitNumber = row[@"UNIT"];
        Unit *unit = _unitsByNumber[unitNumber];
        if (unit != nil) {
//            if ([unit updateStaticDataUsingValuesFromDictionary:row]) {
//                [unit updateDerivedData];
//                changesMade = YES;
//            }
        }
    }
    if (changesMade) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ModelManagerDidChangeUnitDataNotification object:nil];
    }
    return changesMade;
}


#pragma mark - Floor Regions

//- (NSArray *)_regionsForFloor:(Floor *)floor inSite:(Site *)site {
//    NSMutableArray *regions = [NSMutableArray new];
//
//    NSString *(^N)(NSInteger ordinal) = ^NSString *(NSInteger ordinal) {
//        return [NSString stringWithFormat:@"%d%d%02d", (int)(site.index + 1), (int)(floor.index - 1), (int)ordinal];
//    };
//
//    if (site.index == 0 && floor.index > 0) {
//
//        CGPoint offset = CGPointMake(-1, 78);
//
//        UIBezierPath* unit_1x01Path = [UIBezierPath bezierPath];
//        [unit_1x01Path moveToPoint: CGPointMake(offset.x + 357, 300 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 417.6, 300 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 417.02, 279 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 446, 279 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 446, 209 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 419.21, 209 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 418.37, 207 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 384.13, 207 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 384.63, 211 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 357, 211 + offset.y)];
//        [unit_1x01Path addLineToPoint: CGPointMake(offset.x + 357, 300 + offset.y)];
//        [unit_1x01Path closePath];
//
//        UIBezierPath* unit_1x03Path = [UIBezierPath bezierPath];
//        [unit_1x03Path moveToPoint: CGPointMake(offset.x + 258, 300 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 355, 300 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 355, 218 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 322.61, 217.35 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 322.12, 212 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 285.99, 212 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 285.26, 214.35 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 258, 215 + offset.y)];
//        [unit_1x03Path addLineToPoint: CGPointMake(offset.x + 258, 300 + offset.y)];
//        [unit_1x03Path closePath];
//
//        UIBezierPath* unit_1x05Path = [UIBezierPath bezierPath];
//        [unit_1x05Path moveToPoint: CGPointMake(offset.x + 167, 281 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 194.8, 281 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 194.71, 300 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 256, 300 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 256, 212 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 229.76, 212 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 229.14, 207 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 194.07, 207 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 194.01, 209 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 167, 209 + offset.y)];
//        [unit_1x05Path addLineToPoint: CGPointMake(offset.x + 167, 281 + offset.y)];
//        [unit_1x05Path closePath];
//
//        UIBezierPath* unit_1x07Path = [UIBezierPath bezierPath];
//        [unit_1x07Path moveToPoint: CGPointMake(offset.x + 62, 278.1 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 60, 278.21 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 60, 307 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 137.85, 307 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 137.66, 296 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 151, 296 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 151, 205 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 112.95, 205 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 113.32, 207.88 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 84.83, 208.27 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 84.61, 220 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 62, 220 + offset.y)];
//        [unit_1x07Path addLineToPoint: CGPointMake(offset.x + 62, 278.1 + offset.y)];
//        [unit_1x07Path closePath];
//
//        UIBezierPath* unit_1x08Path = [UIBezierPath bezierPath];
//        [unit_1x08Path moveToPoint: CGPointMake(offset.x + 61, 337 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 62.11, 336.77 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 61.82, 395 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 85.59, 395 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 84.79, 407.39 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 114.52, 408 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 113.89, 411.03 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 165, 411 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 164.67, 336.52 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 151.54, 336.73 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 151, 321 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 138.3, 321 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 138.35, 309 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 61, 309 + offset.y)];
//        [unit_1x08Path addLineToPoint: CGPointMake(offset.x + 61, 337 + offset.y)];
//        [unit_1x08Path closePath];
//
//        UIBezierPath* unit_1x06Path = [UIBezierPath bezierPath];
//        [unit_1x06Path moveToPoint: CGPointMake(offset.x + 167, 410 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 199.55, 410 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 200.15, 417 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 236.89, 417 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 237.65, 414 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 265, 414 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 265, 329 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 167, 329 + offset.y)];
//        [unit_1x06Path addLineToPoint: CGPointMake(offset.x + 167, 410 + offset.y)];
//        [unit_1x06Path closePath];
//
//        UIBezierPath* unit_1x04Path = [UIBezierPath bezierPath];
//        [unit_1x04Path moveToPoint: CGPointMake(offset.x + 267, 401 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 293.34, 401 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 294.5, 405 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 330.57, 405 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 331.01, 398 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 364, 398 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 364, 316 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 267, 316 + offset.y)];
//        [unit_1x04Path addLineToPoint: CGPointMake(offset.x + 267, 401 + offset.y)];
//        [unit_1x04Path closePath];
//
//        UIBezierPath* unit_1x02Path = [UIBezierPath bezierPath];
//        [unit_1x02Path moveToPoint: CGPointMake(offset.x + 366, 430 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 452.1, 430 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 452, 409 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 465.32, 408.31 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 465, 379.79 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 488.65, 380.29 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 488.15, 357.52 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 466.83, 357.6 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 467, 328 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 393.15, 328 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 393.64, 341 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 366, 341 + offset.y)];
//        [unit_1x02Path addLineToPoint: CGPointMake(offset.x + 366, 430 + offset.y)];
//        [unit_1x02Path closePath];
//
//        UIBezierPath* unit_1x09Path = [UIBezierPath bezierPath];
//        [unit_1x09Path moveToPoint: CGPointMake(offset.x + 583, 279 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 613.29, 279.42 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 612.96, 300 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 673, 300 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 673, 212 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 645.92, 212 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 645.89, 207 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 610.59, 207 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 610.48, 210 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 583, 210 + offset.y)];
//        [unit_1x09Path addLineToPoint: CGPointMake(offset.x + 583, 279 + offset.y)];
//        [unit_1x09Path closePath];
//
//        UIBezierPath* unit_1x11Path = [UIBezierPath bezierPath];
//        [unit_1x11Path moveToPoint: CGPointMake(offset.x + 675, 300 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 772, 300 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 772, 215 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 744.29, 215 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 743.44, 212 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 707.62, 212 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 706.76, 219 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 675, 219 + offset.y)];
//        [unit_1x11Path addLineToPoint: CGPointMake(offset.x + 675, 300 + offset.y)];
//        [unit_1x11Path closePath];
//
//        UIBezierPath* unit_1x13Path = [UIBezierPath bezierPath];
//        [unit_1x13Path moveToPoint: CGPointMake(offset.x + 774, 300 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 834.91, 300 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 835, 281 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 862, 280.42 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 862, 209 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 834.68, 209 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 834.51, 207 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 800.23, 207 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 799.68, 212 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 774, 212 + offset.y)];
//        [unit_1x13Path addLineToPoint: CGPointMake(offset.x + 774, 300 + offset.y)];
//        [unit_1x13Path closePath];
//
//        UIBezierPath* unit_1x15Path = [UIBezierPath bezierPath];
//        [unit_1x15Path moveToPoint: CGPointMake(offset.x + 878, 296 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 891.76, 296 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 892.17, 307 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 968, 307 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 968, 221 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 945.11, 221 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 945.26, 208 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 913.77, 208 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 913.88, 205 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 878, 205 + offset.y)];
//        [unit_1x15Path addLineToPoint: CGPointMake(offset.x + 878, 296 + offset.y)];
//        [unit_1x15Path closePath];
//
//        UIBezierPath* unit_1x12Path = [UIBezierPath bezierPath];
//        [unit_1x12Path moveToPoint: CGPointMake(offset.x + 765, 401 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 792.33, 401 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 792.54, 404.09 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 828.76, 404.09 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 829.08, 398 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 862, 398 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 862, 316 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 765, 316 + offset.y)];
//        [unit_1x12Path addLineToPoint: CGPointMake(offset.x + 765, 401 + offset.y)];
//        [unit_1x12Path closePath];
//
//        UIBezierPath* unit_1x10Path = [UIBezierPath bezierPath];
//        [unit_1x10Path moveToPoint: CGPointMake(offset.x + 667, 397 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 698.3, 397 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 698.37, 404 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 735.79, 404 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 735.36, 401 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 763, 401 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 763, 316 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 667, 316 + offset.y)];
//        [unit_1x10Path addLineToPoint: CGPointMake(offset.x + 667, 397 + offset.y)];
//        [unit_1x10Path closePath];
//
//        UIBezierPath* unit_1x14Path = [UIBezierPath bezierPath];
//        [unit_1x14Path moveToPoint: CGPointMake(offset.x + 864, 411 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 913.64, 410.48 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 914.13, 409.08 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 944.58, 407.91 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 944.36, 395.52 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 967, 395 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 967, 335.37 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 969, 334.96 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 969, 309 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 892, 309 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 892, 320 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 878, 320 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 877.68, 335.79 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 864, 336 + offset.y)];
//        [unit_1x14Path addLineToPoint: CGPointMake(offset.x + 864, 411 + offset.y)];
//        [unit_1x14Path closePath];
//
//
//        // top left
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(1) bezierPath:unit_1x01Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(3) bezierPath:unit_1x03Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(5) bezierPath:unit_1x05Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(7) bezierPath:unit_1x07Path]];
//
//        // bottom left
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(8) bezierPath:unit_1x08Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(6) bezierPath:unit_1x06Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(4) bezierPath:unit_1x04Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(2) bezierPath:unit_1x02Path]];
//
//        // top right
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(9) bezierPath:unit_1x09Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(11) bezierPath:unit_1x11Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(13) bezierPath:unit_1x13Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(15) bezierPath:unit_1x15Path]];
//
//        // bottom right
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(10) bezierPath:unit_1x10Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(12) bezierPath:unit_1x12Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(14) bezierPath:unit_1x14Path]];
//
//    } else if (site.index == 1 && floor.index > 0) {
//		UIBezierPath* unit_x001Path = [UIBezierPath bezierPath];
//		[unit_x001Path moveToPoint: CGPointMake(518.5, 257.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(518.5, 269.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(491.5, 269.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(491.5, 333.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(514.5, 333.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(514.5, 339.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(545.5, 339.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(545.5, 336.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(567.5, 336.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(567.5, 334.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(593.5, 334.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(593.5, 256.5)];
//		[unit_x001Path addLineToPoint: CGPointMake(518.5, 257.5)];
//		[unit_x001Path closePath];
//
//
//
//		//// unit_x003 Drawing
//		UIBezierPath* unit_x003Path = [UIBezierPath bezierPath];
//		[unit_x003Path moveToPoint: CGPointMake(595.5, 256.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(595.5, 327.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(623.5, 327.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(623.5, 333.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(654.5, 333.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(654.5, 330.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(679.5, 330.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(679.5, 269.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(693.5, 269.8)];
//		[unit_x003Path addLineToPoint: CGPointMake(693.5, 256.5)];
//		[unit_x003Path addLineToPoint: CGPointMake(595.5, 256.5)];
//		[unit_x003Path closePath];
//
//
//
//		//// unit_x005 Drawing
//		UIBezierPath* unit_x005Path = [UIBezierPath bezierPath];
//		[unit_x005Path moveToPoint: CGPointMake(679.5, 269.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(679.5, 343.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(703.5, 343.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(703.5, 346.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(734.5, 346.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(734.5, 341.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(763.5, 341.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(763.5, 269.5)];
//		[unit_x005Path addLineToPoint: CGPointMake(679.5, 269.5)];
//		[unit_x005Path closePath];
//
//
//
//		//// unit_x007 Drawing
//		UIBezierPath* unit_x007Path = [UIBezierPath bezierPath];
//		[unit_x007Path moveToPoint: CGPointMake(787.28, 250.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(787.5, 260.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(775.5, 260.66)];
//		[unit_x007Path addLineToPoint: CGPointMake(775.5, 339.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(806.5, 339.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(806.5, 336.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(832.5, 336.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(832.5, 325.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(853.5, 325.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(853.5, 250.5)];
//		[unit_x007Path addLineToPoint: CGPointMake(787.28, 250.5)];
//		[unit_x007Path closePath];
//
//
//
//		//// unit_x002 Drawing
//		UIBezierPath* unit_x002Path = [UIBezierPath bezierPath];
//		[unit_x002Path moveToPoint: CGPointMake(518.5, 243.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(518.5, 223.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(491.5, 223.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(491.5, 167.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(514.5, 167.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(514.5, 162.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(545.5, 162.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(545.5, 164.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(567.5, 164.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(567.5, 166.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(593.5, 166.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(593.5, 244.5)];
//		[unit_x002Path addLineToPoint: CGPointMake(518.5, 243.5)];
//		[unit_x002Path closePath];
//
//
//
//		//// unit_x004 Drawing
//		UIBezierPath* unit_x004Path = [UIBezierPath bezierPath];
//		[unit_x004Path moveToPoint: CGPointMake(595.5, 244.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(595.5, 173.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(623.5, 173.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(623.5, 167.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(654.5, 167.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(654.5, 170.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(678.5, 170.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(678.5, 244.5)];
//		[unit_x004Path addLineToPoint: CGPointMake(595.5, 244.5)];
//		[unit_x004Path closePath];
//
//
//
//		//// unit_x006 Drawing
//		UIBezierPath* unit_x006Path = [UIBezierPath bezierPath];
//		[unit_x006Path moveToPoint: CGPointMake(679.5, 240.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(679.5, 166.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(703.5, 166.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(703.5, 163.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(734.5, 163.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(734.5, 168.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(763.5, 168.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(763.5, 240.5)];
//		[unit_x006Path addLineToPoint: CGPointMake(679.5, 240.5)];
//		[unit_x006Path closePath];
//
//
//
//		//// unit_x008 Drawing
//		UIBezierPath* unit_x008Path = [UIBezierPath bezierPath];
//		[unit_x008Path moveToPoint: CGPointMake(787.28, 249.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(787.5, 240.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(764.5, 240.34)];
//		[unit_x008Path addLineToPoint: CGPointMake(764.5, 162.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(806.5, 162.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(806.5, 165.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(832.5, 165.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(832.5, 176.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(853.5, 176.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(853.5, 249.5)];
//		[unit_x008Path addLineToPoint: CGPointMake(787.28, 249.5)];
//		[unit_x008Path closePath];
//
//
//
//		//// unit_x016 Drawing
//		UIBezierPath* unit_x016Path = [UIBezierPath bezierPath];
//		[unit_x016Path moveToPoint: CGPointMake(226.61, 618.72)];
//		[unit_x016Path addLineToPoint: CGPointMake(226.67, 600.61)];
//		[unit_x016Path addLineToPoint: CGPointMake(215.5, 600.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(215.5, 574.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(213.5, 574.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(213.5, 532.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(277.5, 532.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(277.5, 543.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(290.5, 543.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(290.89, 554.73)];
//		[unit_x016Path addLineToPoint: CGPointMake(299.5, 554.23)];
//		[unit_x016Path addLineToPoint: CGPointMake(299.5, 619.5)];
//		[unit_x016Path addLineToPoint: CGPointMake(226.61, 618.72)];
//		[unit_x016Path closePath];
//
//
//
//		//// unit_x015 Drawing
//		UIBezierPath* unit_x015Path = [UIBezierPath bezierPath];
//		[unit_x015Path moveToPoint: CGPointMake(374.39, 618.72)];
//		[unit_x015Path addLineToPoint: CGPointMake(374.33, 600.61)];
//		[unit_x015Path addLineToPoint: CGPointMake(385.5, 600.5)];
//		[unit_x015Path addLineToPoint: CGPointMake(385.5, 574.5)];
//		[unit_x015Path addLineToPoint: CGPointMake(387.5, 574.5)];
//		[unit_x015Path addLineToPoint: CGPointMake(387.5, 543.5)];
//		[unit_x015Path addLineToPoint: CGPointMake(310.5, 543.5)];
//		[unit_x015Path addLineToPoint: CGPointMake(310.11, 554.73)];
//		[unit_x015Path addLineToPoint: CGPointMake(301.5, 554.23)];
//		[unit_x015Path addLineToPoint: CGPointMake(301.5, 619.5)];
//		[unit_x015Path addLineToPoint: CGPointMake(374.39, 618.72)];
//		[unit_x015Path closePath];
//
//
//
//		//// unit_x014 Drawing
//		UIBezierPath* unit_x014Path = [UIBezierPath bezierPath];
//		[unit_x014Path moveToPoint: CGPointMake(218.5, 455.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(218.5, 477.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(214.5, 477.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(214.5, 507.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(216.5, 507.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(216.5, 530.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(276.5, 530.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(276.5, 506.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(293.5, 506.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(293.5, 455.5)];
//		[unit_x014Path addLineToPoint: CGPointMake(218.5, 455.5)];
//		[unit_x014Path closePath];
//
//
//
//		//// unit_x013 Drawing
//		UIBezierPath* unit_x013Path = [UIBezierPath bezierPath];
//		[unit_x013Path moveToPoint: CGPointMake(382.5, 455.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(382.5, 477.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(386.5, 477.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(386.5, 507.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(384.5, 507.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(384.5, 530.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(324.5, 530.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(324.5, 506.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(307.5, 506.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(307.5, 455.5)];
//		[unit_x013Path addLineToPoint: CGPointMake(382.5, 455.5)];
//		[unit_x013Path closePath];
//
//
//
//		//// unit_x012 Drawing
//		UIBezierPath* unit_x012Path = [UIBezierPath bezierPath];
//		[unit_x012Path moveToPoint: CGPointMake(203.5, 370.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(203.5, 392.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(201.5, 392.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(201.5, 425.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(207.5, 425.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(207.5, 453.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(277.5, 453.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(277.5, 370.5)];
//		[unit_x012Path addLineToPoint: CGPointMake(203.5, 370.5)];
//		[unit_x012Path closePath];
//
//
//
//		//// unit_x011 Drawing
//		UIBezierPath* unit_x011Path = [UIBezierPath bezierPath];
//		[unit_x011Path moveToPoint: CGPointMake(381.5, 370.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(381.5, 392.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(383.5, 392.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(383.5, 425.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(377.5, 425.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(377.5, 453.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(307.5, 453.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(307.5, 370.5)];
//		[unit_x011Path addLineToPoint: CGPointMake(381.5, 370.5)];
//		[unit_x011Path closePath];
//
//
//
//		//// unit_x010 Drawing
//		UIBezierPath* unit_x010Path = [UIBezierPath bezierPath];
//		[unit_x010Path moveToPoint: CGPointMake(217.5, 267.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(217.5, 290.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(212.5, 290.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(212.5, 320.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(215.5, 320.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(215.5, 342.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(217.5, 342.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(217.5, 368.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(294.5, 368.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(294.5, 294.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(271.5, 294.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(271.5, 267.5)];
//		[unit_x010Path addLineToPoint: CGPointMake(217.5, 267.5)];
//		[unit_x010Path closePath];
//
//
//
//		//// unit_x009 Drawing
//		UIBezierPath* unit_x009Path = [UIBezierPath bezierPath];
//		[unit_x009Path moveToPoint: CGPointMake(347.88, 257.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(347.82, 284.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(375.5, 284.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(375.5, 295.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(394.5, 295.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(394.5, 368.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(307.5, 368.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(307.5, 282.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(328.5, 282.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(328.5, 257.5)];
//		[unit_x009Path addLineToPoint: CGPointMake(347.88, 257.5)];
//		[unit_x009Path closePath];
//
//        // top right
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(2) bezierPath:unit_x002Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(4) bezierPath:unit_x004Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(6) bezierPath:unit_x006Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(8) bezierPath:unit_x008Path]];
//
//        // bottom right
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(1) bezierPath:unit_x001Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(3) bezierPath:unit_x003Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(5) bezierPath:unit_x005Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(7) bezierPath:unit_x007Path]];
//
//        // left
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(9) bezierPath:unit_x009Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(10) bezierPath:unit_x010Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(11) bezierPath:unit_x011Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(12) bezierPath:unit_x012Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(13) bezierPath:unit_x013Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(14) bezierPath:unit_x014Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(15) bezierPath:unit_x015Path]];
//        [regions addObject:[FloorRegion floorRegionWithUnitNumber:N(16) bezierPath:unit_x016Path]];
//    }
//    return regions;
//}

@end
