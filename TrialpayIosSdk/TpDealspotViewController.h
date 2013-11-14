//
//  TpDealspotViewController.h
//  TpDealspotViewController
//
//  Created by Roger Hsiao on 2/27/13.
//  Copyright (c) 2013 TrialPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TpWebView.h"
#import "TpOfferwallViewController.h"

@interface TpDealspotViewController : UIViewController <UIWebViewDelegate> {
}

@property (nonatomic, strong) UIWebView *dealspotTouchpointWebView;

- (TpDealspotViewController *)initWithParentViewController:(UIView *)parentView;
- (void)setupTouchpoint:(NSString*)touchpointName withFrame:(CGRect)frame;
- (void)resizeTpDsContainerInvisible;
- (void)resizeTpDsContainerTouchpoint;
- (void)start;
- (void)stop;
- (void)refresh;

@end
