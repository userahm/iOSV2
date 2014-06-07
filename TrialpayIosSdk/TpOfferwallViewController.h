//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>

@class TpOfferwallViewController;

@protocol TpOfferwallViewControllerDelegate
- (void)closeTouchpoint:(NSString *)touchpointName;
@end

#import "TpWebView.h"

@interface TpOfferwallViewController : UIViewController <TpWebViewDelegate>

@property (strong, nonatomic, readonly) NSString *touchpointName;
@property (strong, nonatomic) id<TpOfferwallViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet TpWebView *tpWebView;

@property (nonatomic) TPViewMode viewMode;

- (id)initWithTouchpointName:(NSString *)touchpointName;

@end
