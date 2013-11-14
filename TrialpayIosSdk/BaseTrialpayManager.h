//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "TpUtils.h"
#import "TpOfferwallViewController.h"
#import "TpBalance.h"
#import "TpSdkConstants.h"
#import "TrialpayManagerDelegate.h"


@class TrialpayManager;


@interface BaseTrialpayManager : NSObject <TpOfferwallViewControllerDelegate>

+ (BaseTrialpayManager *)sharedInstance;
+ (NSString*)sdkVersion;

- (void)appLoaded;

- (void)setSid:(NSString *)sid;
- (NSString *)sid;

- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName;
- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName onOfferwallClose:(TPDelegateBlock)onOfferwallClose onBalanceUpdate:(TPDelegateBlock)onBalanceUpdate;
- (void)openOfferwallForTouchpoint:(NSString *)touchpointName;
- (void)initiateBalanceChecks;
- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName;

- (void)setAge:(int)age;
- (void)setGender:(Gender)gender;
- (void)updateLevel:(int)level;

- (void)setCustomParamValue:(NSString *)paramValue forName:(NSString *)paramName;

- (void)clearCustomParamWithName:(NSString *)paramName;
- (void)updateVcPurchaseInfoForTouchpoint:(NSString *)touchpointName dollarAmount:(float)dollarAmount vcAmount:(int)vcAmount;
- (void)updateVcBalanceForTouchpoint:(NSString *)touchpointName vcAmount:(int)vcAmount;

@property (strong, nonatomic) id<TrialpayManagerDelegate> delegate;

@end
