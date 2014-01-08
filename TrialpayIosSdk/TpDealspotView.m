//
//  TpDealspotView.m
//  TpDealspotView
//
//  Copyright (c) 2013 TrialPay. All rights reserved.
//

#import "TpDealspotView.h"
#import "TpUrlManager.h"
#import "TpUtils.h"
#import "BaseTrialpayManager.h"
#import "TpArcSupport.h"

@interface TpDealspotView ()
@end

@implementation TpDealspotView {
    NSString *_touchpointName;
}

- (void)setup {
    self.hidden = YES;
    self.delegate = self;
    
    [self.scrollView setBounces:NO];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self setOpaque:NO];
}

- (void)setTouchpointName:(NSString*)touchpointName {
    _touchpointName = [touchpointName TP_RETAIN];
    [self refresh];
}

/*
 Initializes the TrialPay Dealspot object as a customized UIWebView
 
 Initializes and returns a newly allocated DealSpotView object with the specified frame rectangle.
 The new view object must be inserted into the view hierarchy of a window before it can be used.
 
 @param aRect The frame rectangle for the view, measured in points. The origin of the frame is relative to the superview in which you plan to add it. This method uses the frame rectangle to set the center and bounds properties accordingly.
 */
- (id)initWithFrame:(CGRect)aRect {
    if ((self = [super initWithFrame:aRect])) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setup];
    }
    return self;
}

/*
    Initializes the TrialPay Dealspot object with a reference to the parent view controller that contains the
    TrialPay Dealspot object. The segue identifier should be passed in as well so that on clicking the Trialpay Dealspot
    touchpoint, the user is taken through the correct Storyboard flow.
    
    @param parentView View Controller that the TrialPay Dealspot element should be added into
 */
- (id)initWithFrame:(CGRect)aRect forTouchpoint:(NSString *)touchpointName {
    if ((self = [self initWithFrame:aRect])) {
        [self setTouchpointName:touchpointName];
    }
    return self;
}

- (void)dealloc {
    [self stopWebViews];
    [_touchpointName TP_RELEASE];
    [super TP_DEALLOC];
}

/*
    Helper function to hide the touchpoint. In general, this should only be called from within the TpDealspotView class.
    Note that this merely hides the touchpoint and does not remove the touchpoint. On the internal refresh, the TpDealspotView
    touchpoint will appear again and be resized back to touchpoint size if offers are available.
 */
- (void)hideDealspotIcon {
    TPLogEnter;
    self.hidden = YES;
}

/*
    Helper function to size the TrialPay touchpoint up to touchpoint size. This should only be called from outside the
    TpDealspotView class.
 */
- (void)showDealspotIcon {
    TPLogEnter;
    self.hidden = NO;
}

/*
   Function override of default WebView behavior to catch events thrown by the TrialPay JS package. This appropriately reacts to 
   different events such as no offers available, offer available, and user clicked on touchpoint.
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    TPLog(@"DS URL %@", request.URL);
	if ([request.URL.scheme hasPrefix:@"http"]) {
        return YES;
    }
    
    NSURL *url = request.URL;
    if ([url.absoluteString hasPrefix:@"trialpay://dsresizefull:"]) {
        [self hideDealspotIcon];
        NSString* urlString = [request.URL.absoluteString substringFromIndex:24];
        [[BaseTrialpayManager sharedInstance] registerDealspotURL:urlString forTouchpoint:_touchpointName];
        [[BaseTrialpayManager sharedInstance] openOfferwallForTouchpoint:_touchpointName];
        return NO;
    } else if ([url.absoluteString hasPrefix:@"trialpay://dsresizetouchpoint"]) {
        [self showDealspotIcon];
        return NO;
    } else {
        if ([request.URL.scheme hasPrefix:@"tpbow"]) {
            url = [NSURL URLWithString:[request.URL.absoluteString substringFromIndex:5]];
        }
        [[UIApplication sharedApplication] openURL:url];
    }
    return NO;
}

/**
   This reloads the TrialPay Touchpoint with the default URL with the settings set up in setupSid:...vic:... height:... width:...
   xCoordinate:... yCoordinate:...
 
   This should be called when you want to retrieve new offers, but shouldn't be called excessively to avoid unnecessary bandwidth 
   consumption.
 */
- (void)refresh {
    NSString *urlAddress = [[TpUrlManager sharedInstance] dealspotUrlForTouchpoint:_touchpointName withSize:self.frame.size];
    TPLog(@"Dealspot icon URL is %@", urlAddress);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlAddress]];
    [self loadRequest:request];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    TPLogEnter;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    TPLog(@"%@", error);
}

// stop WebViews clearing its delegates first
- (void)stopWebViews {
    TPLogEnter;
    self.delegate = nil;
    [self stopLoading];
}

@end
