//
// Created by Daniel Togni on 10/14/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "TpToolbarDelegate.h"


@interface TpWebToolbar : UIWebView <UIWebViewDelegate>
@property (nonatomic, strong) id<TpToolbarDelegate> tpDelegate;

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
@end
