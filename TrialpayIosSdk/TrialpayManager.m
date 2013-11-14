//
//  TrialpayManager.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import "TrialpayManager.h"

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
+ (NSString*) sdkVersion {
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

- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName onOfferwallClose:(TPDelegateBlock)onOfferwallClose onBalanceUpdate:(TPDelegateBlock)onBalanceUpdate {
    [super registerVic:vic withTouchpoint:touchpointName onOfferwallClose:onOfferwallClose onBalanceUpdate:onBalanceUpdate];
}

- (void)openOfferwallForTouchpoint:(NSString *)touchpointName {
    [super openOfferwallForTouchpoint:touchpointName];
}

- (void)initiateBalanceChecks {
    [super initiateBalanceChecks];
}

- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName {
    return [super withdrawBalanceForTouchpoint:touchpointName];
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
