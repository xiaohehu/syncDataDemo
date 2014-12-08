#import "ATEasyResourceAccess.h"

id ATJSONObjectFromBundledFile(NSString *fileName) {
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    NSCAssert(fileURL != nil, @"Cannot find bundled file %@", fileName);

    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    NSError *error;
    id raw = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSCAssert(raw != nil, @"Error reading JSON from %@: %@", fileName, error.localizedDescription);

    return raw;
}

id ATObjectFromBundledPropertyListFile(NSString *fileName) {
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    NSCAssert(fileURL != nil, @"Cannot find bundled file %@", fileName);

    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    NSError *error;
    id raw = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&error];
    NSCAssert(raw != nil, @"Error reading plist %@: %@", fileName, error.localizedDescription);

    return raw;
}

NSString *ATStringFromBundledFile(NSString *fileName) {
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    NSCAssert(fileURL != nil, @"Cannot find bundled file %@", fileName);

    return [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
}
