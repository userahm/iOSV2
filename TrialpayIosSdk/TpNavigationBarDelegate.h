//
// Created by Trialpay, Inc. on 10/15/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol TpNavigationBarDelegate <NSObject>
- (void)navClose:(NSString *)dummy;
- (void)navUp:(NSString *)dummy;
- (void)navBack:(NSString *)dummy;
- (void)navReload:(NSString *)dummy;
- (void)navRefresh:(NSString *)dummy;
- (void)navOfferwall:(NSString *)urlString;
- (void)navOffer:(NSString *)urlString;
- (void)navChangeNavBarHeight:(NSString *)heightString;
- (void)navLoaded:(NSString*)dummy; // called on webview delegate finish
@end
