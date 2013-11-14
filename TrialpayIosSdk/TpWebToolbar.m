//
// Created by Daniel Togni on 10/14/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//


#import "TpWebToolbar.h"
#import "TpUrlManager.h"
#import "TpUtils.h"


@implementation TpWebToolbar

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        NSURL *url = [NSURL URLWithString:[TpUrlManager getPrefixUrl:TPNavigationBarPrefixUrl]];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        [self loadRequest:request];
        self.delegate = self;
    }
    return self;
}

/*
 * Being called when the view is being drawn
 *
 * Note: You should not call this method directly. If you want to force a layout update, call the setNeedsLayout method instead
 */
- (void)layoutSubviews {
    self.backgroundColor = [UIColor cyanColor];
    self.scrollView.scrollEnabled = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    TPLog(@"NAVBAR %@", request);

    if ([request.URL.scheme hasPrefix:@"tp"]) {
        // create method call from string, to prevent overwrite unwanted methods, we add a prefix "nav".
        NSString *methodName = [request.URL.host stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[request.URL.host substringToIndex:1] uppercaseString]];
        SEL method = NSSelectorFromString([NSString stringWithFormat:@"nav%@:", methodName]);
        if ([self.tpDelegate respondsToSelector:method]) {
            TPLog(@"NAVBAR call %@", NSStringFromSelector(method));

            // Silences the warning for memory leak, This is not recommended in general as we have to make sure we are properly managing memory.
            // One option is: move all javascript calls to an dictionary and call stringByEvaluatingJavaScriptFromString from here.
            // We will have to make substitutions on strings when we need parameters (like for setTitle).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.tpDelegate performSelector:method withObject:request.URL];
#pragma clang diagnostic pop
        }

    }

    return YES;
}

- (void)showSpinner {
    [self stringByEvaluatingJavaScriptFromString:@"showSpinner();"];
}

- (void)hideSpinner {
    [self stringByEvaluatingJavaScriptFromString:@"hideSpinner();"];
}

- (void)setTitle:(NSString*)title {
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setTitle('%@');", title]];
}

- (void)setSubTitle:(NSString*)subTitle {
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setSubTitle('%@');", subTitle]];
}

- (void)disableBackButton {
    [self stringByEvaluatingJavaScriptFromString:@"disableBackButton();"];
}

- (void)enableBackButton {
    [self stringByEvaluatingJavaScriptFromString:@"enableBackButton();"];
}

- (void)disableDoneButton {
    [self stringByEvaluatingJavaScriptFromString:@"disableDoneButton();"];
}

- (void)enableDoneButton {
    [self stringByEvaluatingJavaScriptFromString:@"enableDoneButton();"];
}

- (void)switchToOfferwallMode {
    [self stringByEvaluatingJavaScriptFromString:@"switchToOfferwallMode();"];
}

- (void)switchToOfferMode {
    [self stringByEvaluatingJavaScriptFromString:@"switchToOfferMode();"];
}



@end
