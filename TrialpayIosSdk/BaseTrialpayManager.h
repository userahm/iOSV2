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
@class TpDealspotView;

extern NSString *TPOfferwallOpenActionString; /*! The Trialpay offerwall was closed */
extern NSString *TPOfferwallCloseActionString; /*! The Trialpay offerwall was closed */
extern NSString *TPBalanceUpdateActionString;  /*! The device user balance was updated, check TrialpayManager::withdrawBalanceForTouchpoint:*/

@interface BaseTrialpayManager : NSObject <TpOfferwallViewControllerDelegate>

@property (nonatomic, assign) BOOL useWebNavigationBar;

+ (BaseTrialpayManager *)sharedInstance;
- (NSString*)sdkVersion;

- (void)appLoaded;

- (void)setSid:(NSString *)sid;
- (NSString *)sid;

- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName;

- (void)openTouchpoint:(NSString *)touchpointName;

- (TpDealspotView *)createDealspotViewForTouchpoint:(NSString *)touchpointName withFrame:(CGRect)touchpointFrame;

- (void)stopDealspotViewForTouchpoint:(NSString *)touchpointName;

- (void)initiateBalanceChecks;
- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName;

- (NSString *)urlForDealspotTouchpoint:(NSString *)touchpointName;

- (void)setAge:(int)age;
- (void)setGender:(Gender)gender;
- (void)updateLevel:(int)level;

- (void)setCustomParamValue:(NSString *)paramValue forName:(NSString *)paramName;

- (void)clearCustomParamWithName:(NSString *)paramName;
- (void)updateVcPurchaseInfoForTouchpoint:(NSString *)touchpointName dollarAmount:(float)dollarAmount vcAmount:(int)vcAmount;
- (void)updateVcBalanceForTouchpoint:(NSString *)touchpointName vcAmount:(int)vcAmount;

- (void)startAvailabilityCheckForTouchpoint:(NSString *)touchpointName;
- (BOOL)isAvailableTouchpoint:(NSString *)touchpointName;

@property (strong, nonatomic) id<TrialpayManagerDelegate> delegate;
@property (assign, nonatomic) __block BOOL isShowingOfferwall; // will be modified by a block

- (void)registerDealspotURL:(NSString *)urlString forTouchpoint:(NSString *)touchpointName;

@end
