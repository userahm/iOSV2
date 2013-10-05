//
// Created by Daniel Togni on 9/27/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <Foundation/Foundation.h>

extern NSString *kTPKeyCustomDispatchPath;
extern NSString *kTPKeyCustomBalancePath;

@interface TpUrlManager : NSObject
+ (TpUrlManager *)sharedInstance;

+ (void)clearHTTPCache;
+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid;
+ (NSString *)balancePathWithVic:(NSString *)vic andSid:(NSString *)sid usingBalanceInfo:(NSDictionary *)balanceInfo;

#if defined(TRIALPAY_ALLOW_CUSTOM_PATH)
+ (void)setCustomDispatchPath:(NSString*)customDispatchPath;
+ (void)setCustomBalancePath:(NSString*)customBalancePath;
#endif

- (NSString *) offerwallUrlForTouchpoint:(NSString *)touchpointName;
- (NSString *) customParamString:(BOOL)clearParams;
@end
