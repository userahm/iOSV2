//
//  TpUtils.h
//  baseSdk
//
//  Created by Yoav Yaari on 5/30/13.
//  Copyright (c) 2013 Yoav Yaari. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
#import <AdSupport/ASIdentifierManager.h>
#endif

typedef enum {
    Male,
    Female,
    Unknown
} Gender;

// Create TPLog - a debug call available on debug mode only
#ifdef DEBUG

#define TPLogLine(format, ...)  NSLog(@"[TPLOG] [%35.35s] %@", \
[[NSString stringWithFormat:@"%@:%d", [[NSString stringWithFormat:@"%s", __FILE__] lastPathComponent] , __LINE__] UTF8String], \
[NSString stringWithFormat:format, ##__VA_ARGS__])

#define TPLogFunction(format, ...)  \
NSLog(@"[TPLOG] [%50.50s] %@", \
[[NSString stringWithFormat:@"%@:%d", \
[NSString stringWithFormat:@"%s", __FUNCTION__] , __LINE__] UTF8String], \
[NSString stringWithFormat:format, ##__VA_ARGS__])

#define TPLog TPLogLine
#define TPLogEnter TPLog(@"%s enter", __FUNCTION__)

#else

#define TPLogLine(...)
#define TPLogFunction(...)
#define TPLog(...)
#define TPLogEnter

#endif

// Customer logging
#define TPCustomerLog(localized, format, ...) NSLog(@"TrialpayManager: %s", [[NSString stringWithFormat:NSLocalizedString(format, localized), ##__VA_ARGS__] UTF8String]);
#define TPCustomerError(localized, format, ...) NSLog(@"ERROR: TrialpayManager: %s", [[NSString stringWithFormat:NSLocalizedString(format, localized), ##__VA_ARGS__] UTF8String]);
#define TPCustomerWarning(localized, format, ...) NSLog(@"WARN: TrialpayManager: %s", [[NSString stringWithFormat:NSLocalizedString(format, localized), ##__VA_ARGS__] UTF8String]);

@interface TpUtils : NSObject

+ (NSString*) appVersion;
+ (NSString*) idfa;
+ (NSString*) macAddress;
+ (NSString*) sha1:(NSString*)input;

+ (NSString *) genderCodeForValue:(Gender)gender;
@end
