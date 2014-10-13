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
//    TPLogEnter;
    if (nil != _trialpayManagerDictionary) {
        // It turns out that writeToFile is a long operation, so if we are not using ARC (ex: Unity)
        // path may become invalid by memory overwrite and writeToFile crashes on segmentation fault
        // so we have to retain/release path
        NSString *path = [[self path] TP_RETAIN];

        // Lets prevent writing it too often, the idea here is to postpone writing until we dont have changes for a while.
        // Than save once. We create many dispatches with that approach though, as dispatches are lightweight, this should be fine.
        static NSDate *__datastoreChangedOn = nil;
        __datastoreChangedOn = [[NSDate date] TP_RETAIN];
        float waitTime = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            @synchronized(self) { // our toplevel function was protected by sync to prevent double writing file, so lets keep it protected.
                if (__datastoreChangedOn != nil && [__datastoreChangedOn timeIntervalSinceNow] < -waitTime) { // its been enough time without change
                    [_trialpayManagerDictionary writeToFile:path atomically:YES];
                    // now, lets prevent subsequent saves, by reseting counter, worst case a new date and dispatch will happen subsequently
                    [__datastoreChangedOn TP_RELEASE];
                    __datastoreChangedOn = nil;
                }
            };
        });
        [path TP_RELEASE];
        return YES;
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
//    TPLog(@"setDataWithValue:%@ forKey:%@", value, key);
    NSMutableDictionary* dict = [self dataDictionary];
    @synchronized (self) {
        [dict setValue:value forKey:key];
        BOOL res = [self saveDataDictionary];
        return res;
    }
}

- (id)dataValueForKey:(NSString *)key {
//    TPLog(@"dataValueForKey:%@", key);
    NSDictionary *trialpayManagerDictionary = [self dataDictionary];
    return [trialpayManagerDictionary valueForKey:key];
}
@end
