//
//  TpWebView.h
//
//  Created by Yoav Yaari.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import "TpNavigationBarDelegate.h"
#import "TpUtils.h"

@class TpWebView;
@class TpWebNavigationBar;

@protocol TpWebViewDelegate<NSObject>
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender;

// Present the video from the delegate view controller
- (void)playVideoWithURL:(NSString *)videoResourceURL;
@end

@interface TpWebView : UIView <UIWebViewDelegate, TpNavigationBarDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIWebView *offerwallContainer;
@property (strong, nonatomic) IBOutlet UIWebView *offerContainer;
@property (strong, nonatomic) IBOutlet UIToolbar *navigationBar;

@property (strong, nonatomic) id<TpWebViewDelegate> delegate;
@property (strong, nonatomic) TpWebNavigationBar *webNavigationBar;
@property (assign, nonatomic) TPViewMode viewMode;

- (BOOL)loadWebViewTouchpoint:(NSString *)touchpointName;
- (void)loadRequest:(NSString *)urlString;
- (void)stopWebViews;

- (IBAction)doneButtonPushed:(id)sender;
- (IBAction)backButtonPushed:(id)sender;

@end
