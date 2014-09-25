//
//  TpUtils.h
//
//  Created by Yoav Yaari on 5/30/13.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
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

extern BOOL __trialpayVerbose;

typedef enum {
    Male,
    Female,
    Unknown
} Gender;

typedef enum {
    TPModeUnknown,
    TPModeOfferwall,
    TPModeDealspot,
} TPViewControllerMode;

// Controls offerwall view presentation (fullscreen/popup)
typedef enum {
    TPViewModeUnknown = 0,
    TPViewModeFullscreen = 1,
    TPViewModePopup = 2,
} TPViewMode;

// Create TPLog - a debug call available on debug mode only
#ifdef DEBUG

#define TPLogLine(format, ...)  NSLog(@"[%@] %@", \
[NSString stringWithFormat:@"%@:%d", [[NSString stringWithFormat:@"%s", __FILE__] lastPathComponent] , __LINE__], \
[NSString stringWithFormat:format, ##__VA_ARGS__])

#define TPLogFunction(format, ...)  \
NSLog(@"[TPLOG] [%50.50@] %@", \
[NSString stringWithFormat:@"%@:%d", \
[NSString stringWithFormat:@"%s", __FUNCTION__] , __LINE__], \
[NSString stringWithFormat:format, ##__VA_ARGS__])

#define TPLog TPLogLine
#define TPLogEnter if (__trialpayVerbose) TPLog(@"%s enter", __FUNCTION__)

#else

#define TPLogLine(...)
#define TPLogFunction(...)
#define TPLog(...)
#define TPLogEnter

#endif

// Customer logging
#define TPCustomerLog(localized, format, ...) NSLog(@"TrialpayManager: %@", [NSString stringWithFormat:NSLocalizedString(format, localized), ##__VA_ARGS__]);
#define TPCustomerError(localized, format, ...) NSLog(@"ERROR: TrialpayManager: %@", [NSString stringWithFormat:NSLocalizedString(format, localized), ##__VA_ARGS__]);
#define TPCustomerWarning(localized, format, ...) NSLog(@"WARN: TrialpayManager: %@", [NSString stringWithFormat:NSLocalizedString(format, localized), ##__VA_ARGS__]);

// for use with dispatch_after...
#define TP_DISPATCH_TIME(delayInSeconds) dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC))

@interface TpUtils : NSObject

+ (void)verboseLogging:(BOOL)verbose;

+ (NSString *)appVersion;
+ (BOOL)idfa_enabled;
+ (NSString *)idfa;
+ (NSString *)macAddress;
+ (NSString *)sha1:(NSString*)input;
+ (int)getBasicOrientationSupport;

+ (NSString *)genderCodeForValue:(Gender)gender;
+ (Gender)genderValueForCode:(NSString *)genderStr;
+ (NSString *)viewModeString:(TPViewMode)mode;

+ (void)operation:(NSOperation*)operation sleepFor:(int)secondsValid;
+ (BOOL)singleFlowLockWithMessage:(NSString*)name;
+ (void)singleFlowUnlockWithMessage:(NSString*)name;

@end

@interface TpUserAgent : NSObject
+ (TpUserAgent *)sharedInstance;
- (void)populateUserAgent;
@property (strong, nonatomic) NSString *userAgent;
@end
