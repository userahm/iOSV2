//
// Created by Trialpay, Inc. on 10/14/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//


#import "TpWebNavigationBar.h"
#import "TpUrlManager.h"
#import "TpUtils.h"
#import "TpConstants.h"

@implementation TpWebNavigationBar

NSMutableArray* jsCommands;

- (id)initWithFrame:(CGRect)frame touchpointName:(NSString *)touchpointName {
    if ((self = [super initWithFrame:frame])) {
        NSURL *url = [NSURL URLWithString:[TpUrlManager navigationPathForTouchpoint:touchpointName]];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        [self loadRequest:request];
        self.delegate = self;
        jsCommands = [[NSMutableArray alloc] init];
    }
    return self;
}

/*
 * Being called when the view is being drawn
 *
 * Note: You should not call this method directly. If you want to force a layout update, call the setNeedsLayout method instead
 */
- (void)layoutSubviews {
    self.backgroundColor = [UIColor clearColor];
    self.scrollView.scrollEnabled = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    TPLog(@"NAVBAR %@", request);

    if ([request.URL.scheme hasPrefix:@"tp"]) {
        NSString *tpCommand = request.URL.host;

        if ([tpCommand isEqualToString:@"ready"]) {
            // update the navbar readiness status, now it's ready to handle some commands
            TPLog(@"NAVBAR is ready");
            self.isReady = YES;

            while ([jsCommands count] > 0) {
                [self stringByEvaluatingJavaScriptFromString:[jsCommands objectAtIndex:0]];
                [jsCommands removeObjectAtIndex:0];
            }

        } else {
            // execute the command, i.e. "refresh", "back" etc.

            // create method call from string, to prevent overwrite unwanted methods, we add a prefix "nav".
            // TODO: replace the methodName lookup logic with a dictionary. The methodName should include the nav prefix.
            NSString *methodName = [tpCommand stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[tpCommand substringToIndex:1] uppercaseString]];

            SEL method = NSSelectorFromString([NSString stringWithFormat:@"nav%@:", methodName]);

            NSString *urlArgumentString = request.URL.absoluteString;
            NSUInteger position = [urlArgumentString rangeOfString:@"/" options:0 range:NSMakeRange(5,urlArgumentString.length-5)].location;
            if (position == NSNotFound) {
                urlArgumentString = @"";
            } else {
                urlArgumentString = [urlArgumentString substringFromIndex:position+1];
            }

            if ([self.tpDelegate respondsToSelector:method]) {
                TPLog(@"NAVBAR call %@", NSStringFromSelector(method));

                // Silences the warning for memory leak, This is not recommended in general as we have to make sure we are properly managing memory.
                // One option is: move all javascript calls to an dictionary and call stringByEvaluatingJavaScriptFromString from here.
                // We will have to make substitutions on strings when we need parameters (like for setTitle).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.tpDelegate performSelector:method withObject:urlArgumentString];
#pragma clang diagnostic pop
            }
        }
        return NO;
    }

    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.tpDelegate navLoaded:@""];
}

- (void)executeCommand:(NSString *)jsCommand {
    TPLog(@"executeCommand:%@", jsCommand);
    if (self.isReady && [jsCommands count] == 0) {
        [self stringByEvaluatingJavaScriptFromString:jsCommand];
    } else {
        [jsCommands addObject:jsCommand];
    }
}

- (void)showSpinner {
    [self executeCommand:@"showSpinner()"];
}

- (void)hideSpinner {
    [self executeCommand:@"hideSpinner()"];
}

- (void)setTitle:(NSString*)title {
    [self executeCommand:[NSString stringWithFormat:@"setTitle('%@')", title]];
}

- (void)setSubTitle:(NSString*)subTitle {
    [self executeCommand:[NSString stringWithFormat:@"setSubTitle('%@')", subTitle]];
}

- (void)disableBackButton {
    [self executeCommand:@"disableBackButton()"];
}

- (void)enableBackButton {
    [self executeCommand:@"enableBackButton()"];
}

- (void)disableDoneButton {
    [self executeCommand:@"disableDoneButton()"];
}

- (void)enableDoneButton {
    [self executeCommand:@"enableDoneButton()"];
}

- (void)switchToOfferwallMode {
    [self executeCommand:@"switchToOfferwallMode()"];
}

- (void)switchToOfferMode {
    [self executeCommand:@"switchToOfferMode()"];
}

- (void)onSDKEvent:(NSDictionary *)jsParams {
#if defined(__TRIALPAY_USE_EXCEPTIONS)
    @try {
#endif
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsParams
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self executeCommand:[NSString stringWithFormat:@"onSDKEvent(%@)", jsonString]];
#if defined(__TRIALPAY_USE_EXCEPTIONS)
    } @catch (NSException *exception) {
        TPLog(@"%@\n%@", exception, [exception callStackSymbols]);
    }
#endif
}

@end
