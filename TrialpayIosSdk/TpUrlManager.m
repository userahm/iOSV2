//
// Created by Daniel Togni on 9/27/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "TpUrlManager.h"
#import "BaseTrialpayManager.h"
#import "TpDataStore.h"

NSString *kTPKeyCustomDispatchPath = @"customDispathPath";
NSString *kTPKeyCustomBalancePath = @"customBalancePath";

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


#pragma mark - Base URLs
+ (NSString*)dispatchPath {
    #if defined(TRIALPAY_ALLOW_CUSTOM_PATH)
    NSString *customPath = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyCustomDispatchPath];
    if (customPath) {
        return customPath;
    }
    #endif
    return [NSString stringWithFormat:@"%@%@%@", @"https://www.", @"trialpay.com/", @"dispatch/"];
}

+ (NSString*)balancePath {
    #if defined(TRIALPAY_ALLOW_CUSTOM_PATH)
    NSString *customPath = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyCustomBalancePath];
    if (customPath) {
        return customPath;
    }
    #endif
    return [NSString stringWithFormat:@"%@%@%@", @"https://www.", @"trialpay.com/", @"api/balance/"];
}

#if defined(TRIALPAY_ALLOW_CUSTOM_PATH)
+ (void)setCustomDispatchPath:(NSString*)customDispatchPath {
    TPLog(@"Setting custom dispatch path: %@", customDispatchPath);
    [[TpDataStore sharedInstance] setDataWithValue:customDispatchPath forKey:kTPKeyCustomDispatchPath];
}
+ (void)setCustomBalancePath:(NSString*)customBalancePath {
    TPLog(@"Setting custom balance path: %@", customBalancePath);
    [[TpDataStore sharedInstance] setDataWithValue:customBalancePath forKey:kTPKeyCustomBalancePath];
}
#endif

#pragma mark - Build URLS
+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid{
    return [[NSString stringWithFormat:@"%@?vic=%@&sid=%@", [self balancePath], vic, sid] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid usingBalanceInfo:(NSDictionary *)balanceInfo {
    NSString *acknowledgeEndpoint = [NSString stringWithFormat:@"%@?vic=%@&sid=%@", [self balancePath], vic, sid];
    TPLog(@"balanceEndpoint = %@",acknowledgeEndpoint);
    for (id key in balanceInfo) {
        id value = [balanceInfo objectForKey: key];
        acknowledgeEndpoint = [NSString stringWithFormat:@"%@&%@=%@", acknowledgeEndpoint, key, value];
    }
    return [acknowledgeEndpoint stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)offerwallUrlForTouchpoint:(NSString *)touchpointName {
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

    NSMutableString *url = [NSMutableString stringWithFormat:@"%@%@?sid=%@&appver=%@&idfa=%@&sdkver=%@&tp_base_page=1",
                                                             [TpUrlManager dispatchPath],
                                                             vic,
                                                             [trialpayManager sid],
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

/*
 * Returns a string that contains additional parameters which can be added to the offerwall url.
 */
- (NSString *)extraUrlParametersForTouchpoint:(NSString *)touchpointName {
    TPLog(@"extraUrlParametersForTouchpoint:%@", touchpointName);

    NSMutableArray *params = [NSMutableArray array];

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
    return result;
}
@end
