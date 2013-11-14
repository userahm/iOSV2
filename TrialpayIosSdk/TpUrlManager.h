//
// Created by Daniel Togni on 9/27/13.
// Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kTPKeyCustomDispatchPrefixUrl;
extern NSString *kTPKeyCustomBalancePrefixUrl;

typedef enum {
    TPOfferwallDispatchPrefixUrl,
    TPBalancePrefixUrl,
    TPDealspotTouchpointPrefixUrl,
    TPDealspotGeoPrefixUrl,
    TPUserPrefixUrl,
    TPSrcPrefixUrl,
    TPDeaslpotAvailabilityPrefixUrl,
    TPNavigationBarPrefixUrl,
} TPPrefixUrl;

@interface TpUrlManager : NSObject
+ (TpUrlManager *)sharedInstance;

+ (void)clearHTTPCache;

+ (NSString *)URLEncodeString:(NSString *)string;
+ (NSString *)URLDecodeString:(NSString *)string;
+ (NSURL *)getURLFromRelativePath:(NSURL *)url;

+ (NSString *)getPrefixUrl:(TPPrefixUrl)url;

+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid;
+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid usingBalanceInfo:(NSDictionary *)balanceInfo;

#if defined(TRIALPAY_ALLOW_CUSTOM_PATH)
+ (BOOL)hasCustomPrefixUrl:(TPPrefixUrl)prefixUrl;
+ (void)setCustomValue:(NSString *)customPrefixUrl forPrefixUrl:(TPPrefixUrl)prefixUrl;
#endif

- (NSString *)offerwallUrlForTouchpoint:(NSString *)touchpointName;
- (NSString *)customParamString:(BOOL)clearParams;

- (NSString *)dealspotUrlForTouchpoint:(NSString *)touchpointName withSize:(CGSize)size;
- (NSString *)dealspotAvailabilityUrlForTouchpoint:(NSString *)touchpointName userAgent:(NSString *)userAgent;
@end
