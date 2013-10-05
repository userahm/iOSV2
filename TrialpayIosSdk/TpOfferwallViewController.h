//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 Trialpay Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TpOfferwallViewController;

@protocol TpOfferwallViewControllerDelegate
- (void)tpOfferwallViewController:(TpOfferwallViewController *)tpOfferwallViewController close:(id)sender;
@end

#import "TpWebView.h"

@interface TpOfferwallViewController : UIViewController <TpWebViewDelegate>

- (id)initWithTouchpointName:(NSString *)touchpointName;

@property (strong, nonatomic, readonly) NSString *touchpointName;

@property (strong, nonatomic) id<TpOfferwallViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet TpWebView *tpWebView;

@end
