//
// Created by Trialpay, Inc. on 10/14/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
// Added UIKit to prevent compilation erros on adobe - INTERNAL
#import <UIKit/UIKit.h>
#import "TpNavigationBarDelegate.h"


@interface TpWebNavigationBar : UIWebView <UIWebViewDelegate>

@property (nonatomic, strong) id<TpNavigationBarDelegate> tpDelegate;
@property (nonatomic, assign) BOOL isReady;

- (id)initWithFrame:(CGRect)frame touchpointName:(NSString *)touchpointName;

- (void)executeCommand:(NSString *)jsCommand;

- (void)showSpinner;

- (void)hideSpinner;

- (void)setTitle:(NSString *)title;

- (void)setSubTitle:(NSString *)subTitle;

- (void)disableBackButton;

- (void)enableBackButton;

- (void)disableDoneButton;

- (void)enableDoneButton;

- (void)switchToOfferwallMode;

- (void)switchToOfferMode;

- (void)onSDKEvent:(NSDictionary *)aData;

@end
