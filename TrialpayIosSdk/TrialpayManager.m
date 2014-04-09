//
//  TrialpayManager.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import "TrialpayManager.h"
#import "TpDealspotView.h"

@implementation TrialpayManager

static TrialpayManager *__trialpayManagerInstance;

#pragma mark - getInstance
+ (TrialpayManager *)getInstance {
    TPLogEnter;
    if (!__trialpayManagerInstance) {
        __trialpayManagerInstance = [[TrialpayManager alloc] init];
    }
    return __trialpayManagerInstance;
}

#pragma mark - Get SDK Version
- (NSString*) sdkVersion {
    return [NSString stringWithFormat:@"sdk.%@", [super sdkVersion]];
}

- (void)setSid:(NSString *)sid {
    [super setSid:sid];
}

- (NSString *)sid {
    return [super sid];
}

- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName {
    [super registerVic:vic withTouchpoint:touchpointName];
}

// deprecated - developers should call openTouchpoint instead
- (void)openOfferwallForTouchpoint:(NSString *)touchpointName {
    [super openTouchpoint:touchpointName];
}

- (void)openTouchpoint:(NSString *)touchpointName {
    [super openTouchpoint:touchpointName];
}

- (TpDealspotView *)createDealspotViewForTouchpoint:(NSString *)touchpointName withFrame:(CGRect)touchpointFrame {
    return [super createDealspotViewForTouchpoint:touchpointName withFrame:touchpointFrame];
}

- (void)stopDealspotViewForTouchpoint:(NSString *)touchpointName {
    return [super stopDealspotViewForTouchpoint:touchpointName];
}

- (void)initiateBalanceChecks {
    [super initiateBalanceChecks];
}

- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName {
    return [super withdrawBalanceForTouchpoint:touchpointName];
}

- (void)startAvailabilityCheckForTouchpoint:(NSString *)touchpointName {
    [super startAvailabilityCheckForTouchpoint:touchpointName];
}

- (BOOL)isAvailableTouchpoint:(NSString *)touchpointName {
    return [super isAvailableTouchpoint:touchpointName];
}

- (void)setAge:(int)age {
    [super setAge:age];
}

- (void)setGender:(Gender)gender {
    [super setGender:gender];
}

- (void)updateLevel:(int)level {
    [super updateLevel:level];
}

- (void)setCustomParamValue:(NSString *)paramValue forName:(NSString *)paramName {
    [super setCustomParamValue:paramValue forName:paramName];
}

- (void)clearCustomParamWithName:(NSString *)paramName {
    [super clearCustomParamWithName:paramName];
}

- (void)updateVcPurchaseInfoForTouchpoint:(NSString *)touchpointName dollarAmount:(float)dollarAmount vcAmount:(int)vcAmount {
    [super updateVcPurchaseInfoForTouchpoint:touchpointName dollarAmount:dollarAmount vcAmount:vcAmount];
}

- (void)updateVcBalanceForTouchpoint:(NSString *)touchpointName vcAmount:(int)vcAmount {
    [super updateVcBalanceForTouchpoint:touchpointName vcAmount:vcAmount];
}

@end
