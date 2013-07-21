//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 Trialpay Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TpWebView.h"

@class TpOfferwallViewController;

@protocol TpOfferwallViewControllerDelegate
- (void)tpOfferwallViewController:(TpOfferwallViewController *)tpOfferwallViewController close:(id)sender;
@end

#import "BaseTrialpayManager.h"


@interface TpOfferwallViewController : UIViewController <TpWebViewDelegate>

- (id)initWithVic:(NSString *)vicValue sid:(NSString *)sidValue;

@property (strong, nonatomic) NSString *offerwallUrl;
@property (strong, nonatomic) NSString *vic;
@property (strong, nonatomic) NSString *sid;

@property (strong, nonatomic) id<TpOfferwallViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet TpWebView *offerwallContainer;

@end
