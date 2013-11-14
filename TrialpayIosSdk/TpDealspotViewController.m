//
//  TpDealspotViewController.m
//  TpDealspotViewController
//
//  Copyright (c) 2013 TrialPay. All rights reserved.
//

#import "TpDealspotViewController.h"
#import "TpUrlManager.h"
#import "TrialpayManager.h"
#import "TpArcSupport.h"

@interface BaseTrialpayManager (Dealspot)
- (void)openDealspotForTouchpoint:(NSString *)touchpointName withUrl:(NSString *)dealspotUrl;
@end

@interface TpDealspotViewController ()
@property (nonatomic, strong) id dealspotUrl;
@end

@implementation TpDealspotViewController {
    NSString *_touchpointName;
    CGRect _touchpointFrame;
    CGRect _invisibleFrame;
    UIView *_parentView;
}


/*
    Initializes the TrialPay Dealspot object with a reference to the parent view controller that contains the
    TrialPay Dealspot object. The segue identifier should be passed in as well so that on clicking the Trialpay Dealspot
    touchpoint, the user is taken through the correct Storyboard flow.
    
    @param parentView View Controller that the TrialPay Dealspot element should be added into
 */
- (TpDealspotViewController *)initWithParentViewController:(UIView *)parentView {
    self = [super init];
    _parentView = [parentView TP_RETAIN];
    _invisibleFrame = CGRectMake(0, 0, 1, 1);
    return self;
}


- (void)dealloc {
    [self stopWebViews];
    [_touchpointName TP_RELEASE];
    [_parentView TP_RELEASE];
    [super TP_DEALLOC];
}

/*
    Sets up the TrialPay Dealspot touchpoint to ping the correct TrialPay endpoint for offers available to the current user and to
    display the TrialPay touchpoint in the specified location in the layout.
 */
- (void)setupTouchpoint:(NSString*)touchpointName withFrame:(CGRect)frame {
    // Setup the Touchpoint Frame right now as well
    _touchpointName = [touchpointName TP_RETAIN];
    _touchpointFrame = frame;
}

/*
    Helper function to hide the touchpoint. In general, this should only be called from within the TpDealspotViewController class.
    Note that this merely hides the touchpoint and does not remove the touchpoint. On the internal refresh, the TpDealspotViewController
    touchpoint will appear again and be resized back to touchpoint size if offers are available.
 */
- (void)resizeTpDsContainerInvisible {
    self.dealspotTouchpointWebView.frame = _invisibleFrame;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[BaseTrialpayManager sharedInstance].delegate trialpayManager:(TrialpayManager *) [BaseTrialpayManager sharedInstance] withAction:TPDealspotTouchointHideAction];
    });
}

/*
    Helper function to size the TrialPay touchpoint up to touchpoint size. This should only be called from outside the
    TpDealspotViewController class.
 */
- (void)resizeTpDsContainerTouchpoint {
    self.dealspotTouchpointWebView.frame = _touchpointFrame;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[BaseTrialpayManager sharedInstance].delegate trialpayManager:(TrialpayManager *) [BaseTrialpayManager sharedInstance] withAction:TPDealspotTouchointShowAction];
    });
}

/*
   Creates and inserts the Trialpay Dealspot 1x1 touchpoint frame to the parent layout/container. Communicates to the touchpoint to then
   ping the TrialPay server for any offers available. Calling start begins the process of pinging for offers and displaying them to
   the user.
 
 */
- (void)start {
    self.dealspotTouchpointWebView = [[UIWebView alloc] initWithFrame:_invisibleFrame];
    self.dealspotTouchpointWebView.delegate = self;
    
    [self.dealspotTouchpointWebView.scrollView setBounces:NO];
    [self.dealspotTouchpointWebView.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.dealspotTouchpointWebView.scrollView setShowsVerticalScrollIndicator:NO];
    
    [self.dealspotTouchpointWebView setBackgroundColor:[UIColor clearColor]];
    [self.dealspotTouchpointWebView setOpaque:NO];
    [self refresh];
    [_parentView addSubview:self.dealspotTouchpointWebView];
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
        [self resizeTpDsContainerInvisible];
        NSString* urlString = [request.URL.absoluteString substringFromIndex:24];
        [[BaseTrialpayManager sharedInstance] openDealspotForTouchpoint:_touchpointName withUrl:urlString];
        return NO;
    } else if ([url.absoluteString hasPrefix:@"trialpay://dsresizetouchpoint"]) {
        [self resizeTpDsContainerTouchpoint];
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
    NSString *urlAddress = [[TpUrlManager sharedInstance] dealspotUrlForTouchpoint:_touchpointName withSize:_touchpointFrame.size];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlAddress]];
    [self.dealspotTouchpointWebView loadRequest:request];
}

/**
   Removes the TpDealspotViewController touchpoint/container from the parent view. Pings to the TrialPay server will no longer occur and the
   DealSpot touchpoint will not be shown again until start is called.
 */
-(void)stop {
    [self.dealspotTouchpointWebView removeFromSuperview];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    TPLogEnter;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    TPLog(@"%@", error);
}

- (void)viewDidDisappear:(BOOL)animated {
    [self stopWebViews];
    // lets help ARC to claim memory back faster
    self.view = nil;
    [super viewDidDisappear:animated];
}

/////////// INTERSTITIAL
//
//- (void)checkAvailability {
//    NSString* userAgent = [[self.dealspotTouchpointWebView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSString *urlAddress = [[TpUrlManager sharedInstance] dealspotAvailabilityUrlForTouchpoint:_touchpointName userAgent:userAgent];
//        NSLog(@"api url = %@", urlAddress);
//        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlAddress]];
//
//        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"Returned DS Touchpoint Interstitial Data");
//        NSLog(@"%@", newStr);
//
//        [self updateDealspotDisplay:data];
//    });
//
//}
//
//- (void)updateDealspotDisplay:(NSData *)responseData {
//    if (responseData != nil) {
//        //parse out the json data
//        NSError* error;
//        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
//
//        self.dealspotUrl = [json objectForKey:@"url"]; //2
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (self.dealspotUrl == nil || [[self.dealspotUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqual:@""]) {
//                [self.delegate hideDealspot];
//            } else {
//                [self.delegate showDealspot];
//            }
//        });
//    } else {
//        self.dealspotUrl = @"";
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.delegate hideDealspot];
//        });
//    }
//    NSLog(@"dealspot Url: %@", self.dealspotUrl); //3
//}

// stop WebViews clearing its delegates first
- (void)stopWebViews {
    TPLogEnter;
    self.dealspotTouchpointWebView.delegate = nil;
    [self.dealspotTouchpointWebView stopLoading];
}


@end
