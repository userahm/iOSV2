//
// Created by Trialpay, Inc. on 9/27/13.
// Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//


#import "BaseTrialpayManager.h"
#import "TpDataStore.h"
#import "TpArcSupport.h"

@implementation TpDataStore {
    NSMutableDictionary *_trialpayManagerDictionary;
}

// trigger error if already initialized
static BOOL __initialized = NO;

// singleton
static TpDataStore *__trialpayDataStoreSingleton;
+ (TpDataStore *)sharedInstance {
    if (__trialpayDataStoreSingleton) return __trialpayDataStoreSingleton;
    __trialpayDataStoreSingleton = [[TpDataStore alloc] init];
    __initialized = YES;
    return __trialpayDataStoreSingleton;
}

- (void)dealloc {
    [_trialpayManagerDictionary TP_RELEASE];
    _trialpayManagerDictionary = nil;
    [super TP_DEALLOC];
}

#pragma mark - Handling dictionary in TrialpayManager.plist

- (NSString *)path {
// Get path
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"TrialpayManager.plist"];
    return path;
}

- (NSMutableDictionary *)dataDictionary {
    if (nil == _trialpayManagerDictionary) {
        NSString *path = [[self path] TP_RETAIN];

        // If the file exists - get the content from there. If not, create an empty dictionary
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            _trialpayManagerDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        } else {
            _trialpayManagerDictionary = [[NSMutableDictionary alloc] init];
        }
        [path TP_RELEASE];
    }
    return _trialpayManagerDictionary;
}

- (BOOL)saveDataDictionary {
    TPLogEnter;
    if (nil != _trialpayManagerDictionary) {
        // It turns out that writeToFile is a long operation, so if we are not using ARC (ex: Unity)
        // path may become invalid by memory overwrite and writeToFile crashes on segmentation fault
        // so we have to retain/release path
        NSString *path = [[self path] TP_RETAIN];
        BOOL ret = [_trialpayManagerDictionary writeToFile:path atomically:YES];
        [path TP_RELEASE];
        return ret;
    }
    return NO;
}

- (void) clearDataDictionary {
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *path= [[self path] TP_RETAIN];
    if ([fileMgr fileExistsAtPath:path]) {
        if ([fileMgr removeItemAtPath:path error:&error] != YES) {
            TPLog(@"Unable to delete file: %@", [error localizedDescription]);
        } else {
            if (__initialized) {
                _trialpayManagerDictionary = [[NSMutableDictionary alloc] init];
                TPLog(@"PLEASE RESET THE APP: %@", [error localizedDescription]);
                [NSException raise:@"TrialpayManagerInconsistency" format:@"If dictionary is cleared and an instance of the manager was already created the behavior may be unpredictable"];
            }
        }
    } else {
        TPLog(@"File does not exist");
    }
    [path TP_RELEASE];
}

- (BOOL)setDataWithValue:(NSObject *)value forKey:(NSString *)key {
    TPLog(@"setDataWithValue:%@ forKey:%@)", value, key);
    NSMutableDictionary* dict = [self dataDictionary];
    @synchronized (self) {
        [dict setValue:value forKey:key];
        BOOL res = [self saveDataDictionary];
        return res;
    }
}

- (id)dataValueForKey:(NSString *)key {
    TPLog(@"dataValueForKey:%@", key);
    NSDictionary *trialpayManagerDictionary = [self dataDictionary];
    return [trialpayManagerDictionary valueForKey:key];
}
@end
