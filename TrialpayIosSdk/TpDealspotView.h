//
//  TpDealspotView.h
//  TpDealspotView
//
//  Created by Roger Hsiao on 2/27/13.
//  Copyright (c) 2013 TrialPay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TpWebView.h"
#import "TpOfferwallViewController.h"

@interface TpDealspotView : UIWebView <UIWebViewDelegate> {
}

//@property (nonatomic, strong) UIWebView *dealspotTouchpointWebView;

- (id)initWithFrame:(CGRect)frame;
- (id)initWithCoder:(NSCoder *)aDecoder;
- (void)setTouchpointName:(NSString*)touchpointName;
- (id)initWithFrame:(CGRect)frame forTouchpoint:(NSString *)touchpointName;

- (void)hideDealspotIcon;
- (void)showDealspotIcon;
//- (void)start;
//- (void)stop;
- (void)refresh;

@end
