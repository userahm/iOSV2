//
//  TpWebView.h
//
//  Created by Yoav Yaari.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "TpToolbarDelegate.h"

@class TpWebView;
@class TpWebToolbar;

@protocol TpWebViewDelegate<NSObject>
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender;
@end

@interface TpWebView : UIView <UIWebViewDelegate, TpToolbarDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIWebView *offerwallContainer;
@property (strong, nonatomic) IBOutlet UIWebView *offerContainer;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) id<TpWebViewDelegate> delegate;
@property (nonatomic, strong) TpWebToolbar *webToolbar;

- (BOOL)loadOfferwallForTouchpoint:(NSString *)touchpointName;
- (BOOL)loadDealspotForTouchpoint:(NSString *)touchpointName withUrl:(NSString *)dealspotUrl;
- (void)loadRequest:(NSString *)urlString;
- (void)stopWebViews;

@end
