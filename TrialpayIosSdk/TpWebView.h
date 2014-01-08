//
//  TpWebView.h
//
//  Created by Yoav Yaari.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "TpNavigationBarDelegate.h"

@class TpWebView;
@class TpWebNavigationBar;

@protocol TpWebViewDelegate<NSObject>
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender;
@end

@interface TpWebView : UIView <UIWebViewDelegate, TpNavigationBarDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIWebView *offerwallContainer;
@property (strong, nonatomic) IBOutlet UIWebView *offerContainer;
@property (strong, nonatomic) IBOutlet UIToolbar *navigationBar;

@property (strong, nonatomic) id<TpWebViewDelegate> delegate;
@property (nonatomic, strong) TpWebNavigationBar *webNavigationBar;

- (BOOL)loadWebViewTouchpoint:(NSString *)touchpointName;
- (void)loadRequest:(NSString *)urlString;
- (void)stopWebViews;

- (IBAction)doneButtonPushed:(id)sender;
- (IBAction)backButtonPushed:(id)sender;

@end
