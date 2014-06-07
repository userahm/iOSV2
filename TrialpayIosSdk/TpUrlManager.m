//
// Created by Trialpay, Inc. on 9/27/13.
// Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//


#import "TpUrlManager.h"
#import "BaseTrialpayManager.h"
#import "TpDataStore.h"
#import "TpArcSupport.h"
#import "TrialpayManager.h"
#import "TpVideo.h"

// Terminator for buildQueryString, intentionally asymmetric
#define TP_END_QUERY @"__**TPENDQUERY*_*_"

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
        case TPOfferwallDispatchPrefixUrl:
            return [NSString stringWithFormat:@"%@%@%@", @"https://www.", @"trialpay.com/", @"dispatch/"];

        case TPBalancePrefixUrl:
            return [NSString stringWithFormat:@"%@%@%@", @"https://www.", @"trialpay.com/", @"api/balance/"];

        case TPDealspotTouchpointPrefixUrl:
            return [NSString stringWithFormat:@"%@%@%@", @"http://geo.", @"tp-cdn.com/", @"mobile/ds/"];

        case TPDealspotGeoPrefixUrl: break;
        case TPUserPrefixUrl: break;
        case TPSrcPrefixUrl: break;

        case TPDeaslpotAvailabilityPrefixUrl:
            return [NSString stringWithFormat:@"%@%@%@", @"http://geo.", @"tp-cdn.com/", @"api/interstitial/v1/"];

        case TPNavigationBarPrefixUrl:
            return [NSString stringWithFormat:@"%@%@%@", @"https://www.", @"trialpay.com/", @"social/offers/html5/navbar/"];
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
+ (NSString *)navigationPathForTouchpoint:(NSString *)touchpointName {
    NSDictionary *data = [self getVicAndSid:touchpointName];
    if (!data)
        return nil;
    
    return [NSString stringWithFormat:@"%@?%@", [self getPrefixUrl:TPNavigationBarPrefixUrl], [TpUrlManager buildQueryString:@"vic", [data objectForKey:@"vic"], TP_END_QUERY]];
}

+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid{
    return [NSString stringWithFormat:@"%@?%@", [self getPrefixUrl:TPBalancePrefixUrl], [TpUrlManager buildQueryString:
                                                                                         @"vic", vic,
                                                                                         @"sid", sid,
                                                                                         TP_END_QUERY]];
}

+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid usingBalanceInfo:(NSDictionary *)balanceInfo {
    NSMutableString *acknowledgeEndpoint = [NSMutableString stringWithFormat:@"%@?%@", [self getPrefixUrl:TPBalancePrefixUrl], [TpUrlManager buildQueryString:
                                                                                                                                @"vic", vic,
                                                                                                                                @"sid", sid,
                                                                                                                                TP_END_QUERY]];
    TPLog(@"balanceEndpoint = %@",acknowledgeEndpoint);
    if ([balanceInfo count] > 0) {
        [acknowledgeEndpoint appendFormat:@"&%@", [TpUrlManager buildQueryStringFromDictionary:balanceInfo]];
    }
    TPLog(@"balanceEndpoint = %@",acknowledgeEndpoint);
    return acknowledgeEndpoint;
}

- (NSString *)offerwallUrlForTouchpoint:(NSString *)touchpointName {
    // If this is dealspot then return the registered URL, otherwise build the offerwall url
    NSMutableString *url;
    NSString *integrationType = [[BaseTrialpayManager sharedInstance] getIntegrationTypeForTouchpoint:touchpointName];
    if ([integrationType isEqualToString:@"offerwall"]) {
        NSDictionary *data = [TpUrlManager getVicAndSid:touchpointName];
        if (!data)
            return nil;

        url = [NSMutableString stringWithFormat:@"%@%@?",
               [TpUrlManager getPrefixUrl:TPOfferwallDispatchPrefixUrl],
               [TpUrlManager URLEncodeQueryString:[data objectForKey:@"vic"]]];
        [self addCommonQueryParams:touchpointName toUrl:url];
    } else {
        // DS offer URL does not contain common query params
        url = [[[BaseTrialpayManager sharedInstance] urlForDealspotTouchpoint:touchpointName] mutableCopy];
        [url appendFormat:@"&%@", [TpUrlManager buildQueryString:@"tp_base_page", @"1", TP_END_QUERY]];
    }

    return url;
}

- (NSString *)dealspotUrlForTouchpoint:(NSString *)touchpointName withSize:(CGSize)size {
    NSDictionary *data = [TpUrlManager getVicAndSid:touchpointName];
    if (!data)
        return nil;

    NSString *_uh = [TpUrlManager getPrefixUrl:TPUserPrefixUrl];
    NSString *_sh = [TpUrlManager getPrefixUrl:TPSrcPrefixUrl];
    NSString *_gh = [TpUrlManager getPrefixUrl:TPDealspotGeoPrefixUrl];
    NSString *dealspotPrefixUrl = [TpUrlManager getPrefixUrl:TPDealspotTouchpointPrefixUrl];

    NSMutableString *urlAddress = [NSMutableString stringWithFormat:@"%@?%@", dealspotPrefixUrl, [TpUrlManager buildQueryString:
            @"vic", [data objectForKey:@"vic"],
            @"height", [NSString stringWithFormat:@"%fpx", size.height],
            @"width", [NSString stringWithFormat:@"%fpx", size.width],
            // optional values are excluded by buildQueryString
            @"__uh", _uh,
            @"__gh", _gh,
            @"__sh", _sh,
            TP_END_QUERY]];
    [self addCommonQueryParams:touchpointName toUrl:urlAddress];

    return urlAddress;
}

- (NSString *)dealspotAvailabilityUrlForTouchpoint:(NSString *)touchpointName userAgent:(NSString *)userAgent {
    NSDictionary *data = [TpUrlManager getVicAndSid:touchpointName];
    if (!data)
        return nil;

    NSString *availabilityUrl = [TpUrlManager getPrefixUrl:TPDeaslpotAvailabilityPrefixUrl];

    NSMutableString *urlAddress = [NSMutableString stringWithFormat:@"%@?%@", availabilityUrl,
                                                   [TpUrlManager buildQueryString:
                                                                 @"vic", [data objectForKey:@"vic"],
                                                                 @"ua", userAgent,
                                                                 @"orientation_support", [NSNumber numberWithInt:[TpUtils getBasicOrientationSupport]],
                                                                 TP_END_QUERY]];
    [self addCommonQueryParams:touchpointName toUrl:urlAddress];
    return urlAddress;
}

- (void)addCommonQueryParams:(NSString *)touchpointName toUrl:(NSMutableString *)url {
    NSString *lastChar = [url substringFromIndex:url.length-1];
    if (![lastChar isEqualToString:@"&"]) {
        if (![lastChar isEqualToString:@"?"]) {
            [url appendString:@"&"];
        }
    }
    [url appendFormat:@"%@", [TpUrlManager buildQueryString:
            @"sid", [[BaseTrialpayManager sharedInstance] sid],
            @"appver", [TpUtils appVersion],
            @"idfa_en", [TpUtils idfa_enabled]?@"1":@"0:",
            @"idfa", [TpUtils idfa],
            @"mac", [TpUtils macAddress],
            @"sdkver", [[BaseTrialpayManager sharedInstance] sdkVersion],
            @"loaded_vts", [[[TpVideo sharedInstance] getAllStoredVideoOffers] componentsJoinedByString:@"-"],
            @"tp_base_page", @"1",
            TP_END_QUERY]];

    NSString *customParams = [self customParamString:true];
    if ([customParams length] > 0) {
        [url appendFormat:@"&%@", customParams];
    }

    NSString *extraUrlParameters = [self extraUrlParametersForTouchpoint:touchpointName];
    if ([extraUrlParameters length] > 0) {
        [url appendFormat:@"&%@", extraUrlParameters];
    }

}

+ (NSDictionary *)getVicAndSid:(NSString *)touchpointName {
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
    
    NSMutableString *queryString = [NSMutableString new];
    
    NSMutableDictionary *vcPurchaseInfo = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVCPurchaseInfo];
    NSMutableDictionary *vcPurchaseInfoForTouchpoint = [vcPurchaseInfo objectForKey:touchpointName];
    NSString *gender = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyGender];
    NSString *age    = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyAge];
    NSString *level  = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyLevel];
    NSString *userCreationTime  = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyUserCreationTime];
    NSArray *visitTimestamps    = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitTimestamps];
    NSArray *visitLengths       = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitLengths];
    NSMutableDictionary *vcBalance = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVCBalance];
    NSString *genderCode = nil;
    NSString *visitTimestampsString = nil;
    NSString *visitLengthsString = nil;
    
    if (gender != nil) {
        Gender genderValue = (Gender) [gender integerValue];
        genderCode = [TpUtils genderCodeForValue:genderValue];
    }
    
    if (visitTimestamps != nil) {
        visitTimestampsString = [visitTimestamps componentsJoinedByString:@","];
    }
    
    if (visitLengths != nil) {
        visitLengthsString = [visitLengths componentsJoinedByString:@","];
    }
    
    [queryString appendString:[TpUrlManager buildQueryString:
                               @"total_dollars_spent", [vcPurchaseInfoForTouchpoint objectForKey:kTPKeyDollarAmount],
                               @"total_vc_earned", [vcPurchaseInfoForTouchpoint objectForKey:kTPKeyVCAmount],
                               @"tp_gender", genderCode,
                               @"tp_age", age,
                               @"vc_balance", [vcBalance objectForKey:touchpointName],
                               @"current_level", level,
                               @"user_creation_timestamp", userCreationTime,
                               @"visit_timestamps", visitTimestampsString,
                               @"visit_lengths", visitLengthsString,
                               TP_END_QUERY]];
    
    [queryString TP_AUTORELEASE];
    return queryString;
}

- (NSString *)customParamString:(BOOL)clearParams {
    BaseTrialpayManager *trialpayManager = [BaseTrialpayManager sharedInstance];
    NSDictionary *customParams = [trialpayManager consumeCustomParams:clearParams];
    
    return [TpUrlManager buildQueryStringFromDictionary:customParams];
}

#pragma mark - URL & Query encoding

// ALWAYS USE this function to build query string to prevent improper encoding.
// It encodes all keys and values.
// Note that variadic params must be nil terminated, or have a count.
// As for now we are allowing nil values to be passed (will be discarded from the query string), we need another terminator (TP_END_QUERY).
+ (NSString *)buildQueryString:(NSString *) firstString, ... {
    NSMutableArray *encodedPairs = [NSMutableArray new];
    
    va_list args;
    va_start(args, firstString);
    
    BOOL isKey = YES;
    NSString *key;
    NSString *value;
    id arg;

    // loop key/values until find TP_END_QUERY.
    for (arg = firstString; ![TP_END_QUERY isEqualToString:arg]; arg = va_arg(args, id)) {
        // we get non-strings (numbers), so we have to stringify them
        NSString *sArg = [arg isKindOfClass:[NSString class]]?arg:[arg stringValue];
        if (isKey) {
            if (nil != arg) {
                key = [TpUrlManager URLEncodeQueryString:sArg];
            } else {
                key = nil;
            }
        } else {
            // if key or value are nil, lets not include it at all
            if (nil != arg && nil != key) {
                value = [TpUrlManager URLEncodeQueryString:sArg];
                [encodedPairs addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
            } else {
                TPLog(@"Skips |%@=%@| of an encoding error or nil keys or values", key, arg);
            }
        }

        // expecting key1, value1, key2, value2
        isKey = !isKey;
    };
    va_end(args);
    
    [encodedPairs TP_AUTORELEASE];
    return [encodedPairs componentsJoinedByString:@"&"];
}

// ALWAYS USE this function to build query string to prevent improper encoding
+ (NSString *)buildQueryStringFromDictionary:(NSDictionary *)queryDict {
    if (![queryDict count]) return @"";
    NSMutableArray *encodedPairs = [[NSMutableArray alloc] init];

    for (NSString *paramName in [queryDict keyEnumerator]) {
        NSString *encodedParamName = [TpUrlManager URLEncodeQueryString:paramName];
        id arg = [queryDict valueForKey:paramName];
        // we get non-strings (numbers), so we have to stringify them
        NSString *sArg = [arg isKindOfClass:[NSString class]]?arg:[arg stringValue];
        NSString *encodedParamValue = [TpUrlManager URLEncodeQueryString:sArg];
        if (nil == encodedParamName || nil == encodedParamValue) {
            TPLog(@"Skips |%@=%@| because of an encoding error or nil keys or values", paramName, [queryDict valueForKey:paramName]);
        } else {
            [encodedPairs addObject:[NSString stringWithFormat:@"%@=%@", encodedParamName, encodedParamValue]];
        }
    }
    [encodedPairs TP_AUTORELEASE];
    return [encodedPairs componentsJoinedByString:@"&"];
}

+ (NSString *)URLEncodeQueryString:(NSString*)string {
    // URL-encode according to RFC 3986
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
    return result;
}

+ (NSString *)URLDecodeQueryString:(NSString*)string {
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,(__bridge CFStringRef)string, (__bridge CFStringRef)@"", kCFStringEncodingUTF8));
    return result;
}

@end
