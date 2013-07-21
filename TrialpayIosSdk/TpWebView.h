//
//  TpWebView.h
//
//  Created by Trialpay
//  Copyright (c) 2013 Yoav Yaari. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TpWebView;

@protocol TpWebViewDelegate
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender;
@end

@interface TpWebView : UIView <UIWebViewDelegate, UIAlertViewDelegate> {
    // Local class var to hold offer wall URL
    NSString* baseOfferwallUrl;
}

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIWebView *offerwallContainer;
@property (strong, nonatomic) IBOutlet UIWebView *offerContainer;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) id<TpWebViewDelegate> delegate;

- (void)loadRequest:(NSString*)url;

@end
