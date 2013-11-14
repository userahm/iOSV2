//
// Created by Daniel Togni on 9/27/13.
// Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//


#import "TpUrlManager.h"
#import "BaseTrialpayManager.h"
#import "TpDataStore.h"
#import "TpArcSupport.h"

NSString *kTPKeyCustomDispatchPrefixUrl = @"customDispathPath";
NSString *kTPKeyCustomBalancePrefixUrl = @"customBalancePath";
NSString *kTPKeyCustomDealspotTouchpointPrefixUrl = @"customDealspotTouchpointPrefixUrl";
NSString *kTPKeyCustomDealspotGeoPrefixUrl = @"customDealspotGeoPrefixUrl";
NSString *kTPKeyCustomUserPrefixUrl = @"customUserPrefixUrl";
NSString *kTPKeyCustomSrcPrefixUrl = @"customSrcPrefixUrl";
NSString *kTPKeyCustomDealspotAvailabilityPrefixUrl = @"customDeaslpotAvailabilityPrefixUrl";
NSString *kTPKeyCustomNavigationBarPrefixUrl = @"customNavigationBarPrefixUrl";

// Declaring category to expose methods that were not exposed to users (and shouldnt be)
@interface BaseTrialpayManager (TpUrlManager)
- (NSDictionary *)consumeCustomParams:(BOOL)clear;
- (NSString *)vicForTouchpoint:(NSString *)touchpointName;
@end

@interface TpUrlManager ()
@end

@implementation TpUrlManager {

}

TpUrlManager *__TrialPayURLManagerSingleton = nil;
+ (TpUrlManager *)sharedInstance {
    if (__TrialPayURLManagerSingleton) return __TrialPayURLManagerSingleton;
    __TrialPayURLManagerSingleton = [[TpUrlManager alloc] init];
    return __TrialPayURLManagerSingleton;
}

#pragma mark - Clear HTTP cache (private)
+ (void) clearHTTPCache {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    TPLog(@"Cache Cleared!");
}

+ (NSString *)URLEncodeString:(NSString*)string {
    // URL-encode according to RFC 3986
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
    return result;
}

+ (NSString*)URLDecodeString:(NSString*)string {
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,(__bridge CFStringRef)string, (__bridge CFStringRef)@"", kCFStringEncodingUTF8));
    return result;
}

#pragma mark - Prefix URLs

+ (NSString *)getPrefixUrl:(TPPrefixUrl)prefixUrl {

#if defined(TRIALPAY_ALLOW_CUSTOM_PATH)
    NSString *key = [self keyForPrefixUrl:prefixUrl];
    NSString *customPath = [[TpDataStore sharedInstance] dataValueForKey:key];
    if (customPath) {
        return customPath;
    }
#endif

    switch (prefixUrl) {
        case TPOfferwallDispatchPrefixUrl:          return [NSString stringWithFormat:@"%@%@%@", @"https://www.", @"trialpay.com/", @"dispatch/"];
        case TPBalancePrefixUrl:                    return [NSString stringWithFormat:@"%@%@%@", @"https://www.", @"trialpay.com/", @"api/balance/"];
        case TPDealspotTouchpointPrefixUrl:         return [NSString stringWithFormat:@"%@%@%@", @"http://geo.", @"tp-cdn.com/", @"mobile/ds/"];
        case TPDealspotGeoPrefixUrl:                break;
        case TPUserPrefixUrl:                       break;
        case TPSrcPrefixUrl:                        break;
        case TPDeaslpotAvailabilityPrefixUrl:       return [NSString stringWithFormat:@"%@%@%@", @"http://geo.", @"tp-cdn.com/", @"api/interstitial/v1/"];
//        case TPNavigationBarPrefixUrl:              return @"http://dtogni.trialpay.com:4766/nav.html";
    }
    return nil;
}

#pragma mark - Utilities
+ (NSURL *)getURLFromRelativePath:(NSURL *)url {
    return [NSURL URLWithString:[[url relativePath] substringFromIndex:1] relativeToURL:nil];
}

+ (NSString *)keyForPrefixUrl:(TPPrefixUrl)prefixUrl {
    NSString *key = nil;
    switch (prefixUrl) {
        case TPOfferwallDispatchPrefixUrl:      key = kTPKeyCustomDispatchPrefixUrl; break;
        case TPBalancePrefixUrl:                key = kTPKeyCustomBalancePrefixUrl; break;
        case TPDealspotTouchpointPrefixUrl:     key = kTPKeyCustomDealspotTouchpointPrefixUrl; break;
        case TPDealspotGeoPrefixUrl:            key = kTPKeyCustomDealspotGeoPrefixUrl; break;
        case TPUserPrefixUrl:                   key = kTPKeyCustomUserPrefixUrl; break;
        case TPSrcPrefixUrl:                    key = kTPKeyCustomSrcPrefixUrl; break;
        case TPDeaslpotAvailabilityPrefixUrl:   key = kTPKeyCustomDealspotAvailabilityPrefixUrl; break;
        case TPNavigationBarPrefixUrl:          key = kTPKeyCustomNavigationBarPrefixUrl; break;
    }
    return key;
}

#pragma mark - Custom paths

#if defined(TRIALPAY_ALLOW_CUSTOM_PATH)
+ (BOOL)hasCustomPrefixUrl:(TPPrefixUrl)prefixUrl {
    NSString *key = [self keyForPrefixUrl:prefixUrl];
    BOOL hasCustomPath = [[TpDataStore sharedInstance] dataValueForKey:key] != nil;
    return hasCustomPath;
}
+ (void)setCustomValue:(NSString *)customPrefixUrl forPrefixUrl:(TPPrefixUrl)prefixUrl {
    NSString *key = [self keyForPrefixUrl:prefixUrl];
    TPLog(@"Setting %@: %@", key, customPrefixUrl);
    [[TpDataStore sharedInstance] setDataWithValue:customPrefixUrl forKey:key];
}
#endif

#pragma mark - Build URLS
+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid{
    return [[NSString stringWithFormat:@"%@?vic=%@&sid=%@", [self getPrefixUrl:TPBalancePrefixUrl], vic, sid] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid usingBalanceInfo:(NSDictionary *)balanceInfo {
    NSString *acknowledgeEndpoint = [NSString stringWithFormat:@"%@?vic=%@&sid=%@", [self getPrefixUrl:TPBalancePrefixUrl], vic, sid];
    TPLog(@"balanceEndpoint = %@",acknowledgeEndpoint);
    for (id key in balanceInfo) {
        id value = [balanceInfo objectForKey: key];
        acknowledgeEndpoint = [NSString stringWithFormat:@"%@&%@=%@", acknowledgeEndpoint, key, value];
    }
    return [acknowledgeEndpoint stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)offerwallUrlForTouchpoint:(NSString *)touchpointName {
    NSDictionary *data = [self getVicAndSid:touchpointName];
    if (!data)
        return nil;

    NSMutableString *url = [NSMutableString stringWithFormat:@"%@%@?sid=%@&appver=%@&idfa=%@&sdkver=%@&tp_base_page=1",
                    [TpUrlManager getPrefixUrl:TPOfferwallDispatchPrefixUrl],
                    [data objectForKey:@"vic"],
                    [data objectForKey:@"sid"],
                    [TpUtils appVersion],
                    [TpUtils idfa],
                    [BaseTrialpayManager sdkVersion]];

    [url appendString:[self customParamString:true]];

    NSString *extraUrlParameters = [self extraUrlParametersForTouchpoint:touchpointName];
    if (extraUrlParameters != nil) {
        [url appendFormat:@"&%@", extraUrlParameters];
    }

    return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)getVicAndSid:(NSString *)touchpointName {
    BaseTrialpayManager *trialpayManager = [BaseTrialpayManager sharedInstance];
    if (nil == trialpayManager) {
        TPCustomerError(@"TrialpayManager Instance is not accessible. Blocking URL creation", @"TrialpayManager Instance is not accessible. Blocking URL creation");
        return nil;
    }

    // Resolve vic to touchpointName and vice-versa
    NSString *vic = [trialpayManager vicForTouchpoint:touchpointName];
    if (nil == vic) {
        TPCustomerError(@"Unknown touchpoint {touchpointName}", @"Unknown touchpoint %@", touchpointName);
        return nil;
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:vic, @"vic", [trialpayManager sid], @"sid", nil];
}

/*
 * Returns a string that contains additional parameters which can be added to the offerwall url.
 */
- (NSString *)extraUrlParametersForTouchpoint:(NSString *)touchpointName {
    TPLog(@"extraUrlParametersForTouchpoint:%@", touchpointName);

    NSMutableArray *params = [[NSMutableArray array] TP_RETAIN];

    NSMutableDictionary *vcPurchaseInfo = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVCPurchaseInfo];
    NSMutableDictionary *vcPurchaseInfoForTouchpoint = [vcPurchaseInfo objectForKey:touchpointName];

    if (vcPurchaseInfoForTouchpoint != nil) {
        [params addObject:[NSString stringWithFormat:@"total_dollars_spent=%@&total_vc_earned=%@",
                           [vcPurchaseInfoForTouchpoint objectForKey:kTPKeyDollarAmount],
                           [vcPurchaseInfoForTouchpoint objectForKey:kTPKeyVCAmount]]];
    }

    NSString *gender = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyGender];
    NSString *age    = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyAge];
    NSString *level  = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyLevel];
    NSString *userCreationTime  = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyUserCreationTime];
    NSArray *visitTimestamps    = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitTimestamps];
    NSArray *visitLengths       = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitLengths];

    if (gender != nil) {
        Gender genderValue = (Gender) [gender integerValue];
        NSString *genderCode = [TpUtils genderCodeForValue:genderValue];
        [params addObject:[NSString stringWithFormat:@"tp_gender=%@", genderCode]];
    }

    if (age != nil) {
        [params addObject:[NSString stringWithFormat:@"tp_age=%@", age]];
    }

    NSMutableDictionary *vcBalance = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVCBalance];

    if ([vcBalance objectForKey:touchpointName] != nil) {
        [params addObject:[NSString stringWithFormat:@"vc_balance=%@", [vcBalance objectForKey:touchpointName]]];
    }

    if (level != nil) {
        [params addObject:[NSString stringWithFormat:@"current_level=%@", level]];
    }

    if (userCreationTime != nil) {
        [params addObject:[NSString stringWithFormat:@"user_creation_timestamp=%@", userCreationTime]];
    }

    if (visitTimestamps != nil) {
        NSString *visitTimestampsString = [visitTimestamps componentsJoinedByString:@","];
        [params addObject:[NSString stringWithFormat:@"visit_timestamps=%@", visitTimestampsString]];
    }

    if (visitLengths != nil) {
        NSString *visitLengthsString = [visitLengths componentsJoinedByString:@","];
        [params addObject:[NSString stringWithFormat:@"visit_lengths=%@", visitLengthsString]];
    }

    [params TP_AUTORELEASE];
    return [params componentsJoinedByString:@"&"];
}

- (NSString *) customParamString:(BOOL)clearParams {
    BaseTrialpayManager *trialpayManager = [BaseTrialpayManager sharedInstance];
    NSDictionary *customParams = [trialpayManager consumeCustomParams:clearParams];

    if (![customParams count]) return @"";
    NSMutableString *result = [[NSMutableString alloc] init];
    for (NSString *paramName in [customParams keyEnumerator]) {
        NSString *encodedParamName = [paramName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedParamValue = [[customParams valueForKey:paramName] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (nil == encodedParamName || nil == encodedParamValue) {
            TPLog(@"Skips |%@=%@| because of an encoding exception", paramName, [customParams valueForKey:paramName]);
        } else {
            [result appendFormat:@"&%@=%@", encodedParamName, encodedParamValue];
        }
    }
    return [result TP_AUTORELEASE];
}

- (NSString *)dealspotUrlForTouchpoint:(NSString *)touchpointName withSize:(CGSize)size {
    NSDictionary *data = [self getVicAndSid:touchpointName];
    if (!data)
        return nil;

    NSString *_uh = [TpUrlManager getPrefixUrl:TPUserPrefixUrl];
    NSString *_sh = [TpUrlManager getPrefixUrl:TPSrcPrefixUrl];
    NSString *_gh = [TpUrlManager getPrefixUrl:TPDealspotGeoPrefixUrl];
    NSString *dealspotPrefixUrl = [TpUrlManager getPrefixUrl:TPDealspotTouchpointPrefixUrl];

    NSMutableString *urlAddress = [NSMutableString stringWithFormat:@"%@?vic=%@&sid=%@&height=%fpx&width=%fpx", dealspotPrefixUrl, [data objectForKey:@"vic"], [data objectForKey:@"sid"], size.height, size.width];

    if (_uh) [urlAddress appendFormat:@"&__uh=%@", _uh];
    if (_gh) [urlAddress appendFormat:@"&__gh=%@", _gh];
    if (_sh) [urlAddress appendFormat:@"&__sh=%@", _sh];

    NSLog(@"Dev MDS v2:");
    NSLog(@"%@", urlAddress);
    return urlAddress;
}


- (NSString *)dealspotAvailabilityUrlForTouchpoint:(NSString *)touchpointName userAgent:(NSString *)userAgent {
    NSDictionary *data = [self getVicAndSid:touchpointName];
    if (!data)
        return nil;

    NSString *availabilityUrl = [TpUrlManager getPrefixUrl:TPDeaslpotAvailabilityPrefixUrl];

    NSString *urlAddress = [NSString stringWithFormat:@"%@/?vic=%@&sid=%@&ua=%@", availabilityUrl, [data objectForKey:@"vic"], [data objectForKey:@"sid"], userAgent];
    return urlAddress;
}
@end
