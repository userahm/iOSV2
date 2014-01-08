//
// Created by Trialpay, Inc. on 9/27/13.
// Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kTPKeyCustomDispatchPrefixUrl;
extern NSString *kTPKeyCustomBalancePrefixUrl;

typedef enum {
    TPOfferwallDispatchPrefixUrl = 1,
    TPBalancePrefixUrl = 2,
    TPDealspotTouchpointPrefixUrl = 3,
    TPDealspotGeoPrefixUrl = 4,
    TPUserPrefixUrl = 5,
    TPSrcPrefixUrl = 6,
    TPDeaslpotAvailabilityPrefixUrl = 7,
    TPNavigationBarPrefixUrl = 8,
} TPPrefixUrl;

@interface TpUrlManager : NSObject
+ (TpUrlManager *)sharedInstance;

+ (void)clearHTTPCache;

+ (NSString *)URLEncodeQueryString:(NSString *)string;
+ (NSString *)URLDecodeQueryString:(NSString *)string;
+ (NSURL *)getURLFromRelativePath:(NSURL *)url;

+ (NSString *)getPrefixUrl:(TPPrefixUrl)url;

+ (NSString *)navigationPathForTouchpoint:(NSString *)touchpointName;

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
