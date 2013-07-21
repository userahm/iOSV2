//
//  TpWebView.m
//
//  Created by Trialpay
//  Copyright (c) 2013 Yoav Yaari. All rights reserved.
//

#import "TpWebView.h"

// Create NSDLog - a debug call available on debug mode only
#ifdef DEBUG
#define NSDLog(FORMAT, ...) fprintf(stderr,"[TpWebView] %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSDLog(...)
#endif

@interface TpWebView()
@property (strong) NSString *initialUrl;
@property (strong) UIWebView *webViewContainer;
@property (strong) UIBarButtonItem *flexibleSpaceArea;
@property (strong) UIActivityIndicatorView *loadingIndicator;
@end

@implementation TpWebView

@synthesize mainView;
@synthesize doneButton;
@synthesize backButton;
@synthesize offerwallContainer;
@synthesize offerContainer;
@synthesize webViewContainer;
@synthesize toolbar;
@synthesize delegate;
@synthesize initialUrl;
@synthesize flexibleSpaceArea;
@synthesize loadingIndicator;

/*
 * Sets the given offerwallUrl as the initialUrl for the offerwallContainer.
 * The url is loaded in -layoutSubviews
 */
- (void)loadRequest:(NSString*)offerwallUrl {
    NSDLog(@"loadRequest");
    [self setInitialUrl:[NSString stringWithFormat:@"%@&tp_base_page=1",offerwallUrl]];
    if (nil != offerwallContainer) {
        NSURL *url = [NSURL URLWithString:initialUrl];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        [offerwallContainer loadRequest:request];
    }
}

/*
 * Loads the offerwall using the given frame size.
 * This is currently being overriden by -buildViewWithWidth:height:
 */
- (id)initWithFrame:(CGRect)frame {
    NSDLog(@"initWithFrame");
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.initialUrl = nil;
    }
    return self;
}

/*
 * Setting up the view structure with code.
 * We do not use XIBs in order to reduce plugin integration complexity
 */
- (UIView *)buildViewWithWidth:(CGFloat)width height:(CGFloat)height {
    NSDLog(@"buildViewWithWidth:%f height:%f", width, height);
    
    UIApplication *application = [UIApplication sharedApplication];
    float statusBarHeight = MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    float toolbarHeight = 44.0;
    
    // Build toolbar
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, width, toolbarHeight)];
    toolbar.alpha = 1.000;
    toolbar.autoresizesSubviews = YES;
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.clearsContextBeforeDrawing = NO;
    toolbar.clipsToBounds = NO;
    toolbar.contentMode = UIViewContentModeScaleToFill;
    toolbar.frame = CGRectMake(0.0, 0.0, width, 44.0);
    toolbar.hidden = NO;
    toolbar.multipleTouchEnabled = NO;
    toolbar.opaque = NO;
    toolbar.tag = 0;
    toolbar.userInteractionEnabled = YES;
    
    backButton = [[UIBarButtonItem alloc] init];
    backButton.imageInsets = UIEdgeInsetsZero;
    backButton.style = UIBarButtonItemStyleBordered;
    backButton.tag = 0;
    backButton.title = @"Back";
    backButton.width = 0.000;
    backButton.action = @selector(backButtonPushed:);
    
    flexibleSpaceArea = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    flexibleSpaceArea.enabled = YES;
    flexibleSpaceArea.imageInsets = UIEdgeInsetsZero;
    flexibleSpaceArea.style = UIBarButtonItemStylePlain;
    flexibleSpaceArea.tag = 0;
    flexibleSpaceArea.width = 0.000;
    
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:nil];
    doneButton.enabled = YES;
    doneButton.imageInsets = UIEdgeInsetsZero;
    doneButton.style = UIBarButtonItemStyleBordered;
    doneButton.tag = 0;
    doneButton.width = 0.000;
    doneButton.action = @selector(doneButtonPushed:);
    
    toolbar.items = [NSArray arrayWithObjects:flexibleSpaceArea, doneButton, nil];
    
    
    
    // Build offerwallContainer
    offerwallContainer = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, toolbarHeight, width, height-(toolbarHeight+statusBarHeight))];
    
    offerwallContainer.alpha = 1.000;
    offerwallContainer.autoresizesSubviews = YES;
    offerwallContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    offerwallContainer.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1.000];
    offerwallContainer.clearsContextBeforeDrawing = YES;
    offerwallContainer.clipsToBounds = NO;
    offerwallContainer.contentMode = UIViewContentModeScaleToFill;
    offerwallContainer.hidden = NO;
    offerwallContainer.multipleTouchEnabled = NO;
    offerwallContainer.opaque = YES;
    offerwallContainer.scalesPageToFit = NO;
    offerwallContainer.tag = 0;
    offerwallContainer.userInteractionEnabled = YES;
    offerwallContainer.delegate = self;
    
    [[offerwallContainer scrollView] setBounces:NO];
    [offerwallContainer setAllowsInlineMediaPlayback:YES];
    [offerwallContainer setMediaPlaybackRequiresUserAction:NO];
    [offerwallContainer setScalesPageToFit:YES];
    
    // Build main view (container)
    mainView = [[UIView alloc] initWithFrame:CGRectMake(0.0, statusBarHeight, width, height-statusBarHeight)];
    mainView.alpha = 1.000;
    mainView.autoresizesSubviews = YES;
    mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mainView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:1.000];
    mainView.clearsContextBeforeDrawing = YES;
    mainView.clipsToBounds = NO;
    mainView.contentMode = UIViewContentModeScaleToFill;
    mainView.hidden = NO;
    mainView.multipleTouchEnabled = NO;
    mainView.opaque = YES;
    mainView.tag = 0;
    mainView.userInteractionEnabled = YES;
    
    [mainView addSubview:toolbar];
    [mainView addSubview:offerwallContainer];
    
    return mainView;
}

/*
 * Returns the "name" of the UIWebView element for logging purposes
 */
- (NSString *)getWebViewName:(UIWebView *)webView {
    return [webView isEqual:offerwallContainer] ? @"offerwallContainer" : @"offerContainer";
}

/*
 * Being called when the view is being drawn
 *
 * Note: You should not call this method directly. If you want to force a layout update, call the setNeedsLayout method instead
 */
-(void)layoutSubviews {
    NSDLog(@"layoutSubviews");
    [super layoutSubviews];
    UIApplication *application = [UIApplication sharedApplication];
    float statusBarHeight = MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    
    if (mainView == nil) {
        CGRect screenRect =  [[UIScreen mainScreen] bounds];
        // we need to get the screen size with the right orientation which means to get the height and width
        // and then to switch their positions if (we got a landscape oriantation)XOR(we need landscape orientation)
        // we do that here with two replace statements
        
        // capture height and width
        CGFloat height = screenRect.size.height;
        CGFloat width = screenRect.size.width;
        NSDLog(@"height: %f, width: %f", height, width);
        // make sure that heigh<width (portrait mode properties)
        if (width>height) {
            NSDLog(@"Switch");
            CGFloat temp = width;
            width = height;
            height = temp;
        }
        NSDLog(@"height: %f, width: %f, %d", height, width, [[UIApplication sharedApplication] statusBarOrientation]);
        // change data to landscape if needed
        if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            NSDLog(@"Landscape");
            CGFloat temp = width;
            width = height;
            height = temp;
        }
        NSDLog(@"height: %f, width: %f", height, width);
        
        [self buildViewWithWidth:width height:height];
        [self addSubview:mainView];
        
        if (initialUrl) {
            NSURL* url = [NSURL URLWithString:initialUrl];
            NSURLRequest* request = [NSURLRequest requestWithURL:url];
            [offerwallContainer loadRequest:request];
            
            webViewContainer = offerwallContainer;
        }
        mainView.frame = CGRectMake(0, 0, width, height-statusBarHeight);
    }
}


- (void) loadOfferContainerWithRequest:(NSURLRequest *)request {
    NSDLog(@"loadOfferContainerWithRequest: %@", request.URL.absoluteString);
    
    offerContainer = [[UIWebView alloc] initWithFrame:offerwallContainer.frame];
    
    offerContainer.alpha = 1.000;
    offerContainer.autoresizesSubviews = YES;
    offerContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    offerContainer.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1.000];
    offerContainer.clearsContextBeforeDrawing = YES;
    offerContainer.clipsToBounds = NO;
    offerContainer.contentMode = UIViewContentModeScaleToFill;
    offerContainer.hidden = NO;
    offerContainer.multipleTouchEnabled = NO;
    offerContainer.opaque = YES;
    offerContainer.scalesPageToFit = NO;
    offerContainer.tag = 0;
    offerContainer.userInteractionEnabled = YES;
    offerContainer.delegate = self;
    
    [offerContainer setAllowsInlineMediaPlayback:YES];
    [offerContainer setMediaPlaybackRequiresUserAction:NO];
    [offerContainer setScalesPageToFit:YES];
    
    [offerContainer loadRequest:request];
    
    [UIView transitionWithView:mainView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ { [mainView addSubview:offerContainer]; }
                    completion:nil];
    
    webViewContainer = offerContainer;
    toolbar.items = [NSArray arrayWithObjects:backButton, flexibleSpaceArea, doneButton, nil];
}

- (void) unloadOfferContainer {
    NSDLog(@"unloadOfferContainer");
    webViewContainer = offerwallContainer;
    [offerContainer removeFromSuperview];
    offerContainer = nil;
    toolbar.items = [NSArray arrayWithObjects:flexibleSpaceArea, doneButton, nil];
}

- (void) showLoadingIndicator {
    if (nil == loadingIndicator) {
        CGRect indicatorBounds = CGRectMake(0, 12, offerwallContainer.frame.size.width, 24);
        loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:indicatorBounds];
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [loadingIndicator startAnimating];
        [mainView addSubview:loadingIndicator];
    }
}

- (void) hideLoadingIndicator {
    if (nil != loadingIndicator) {
        [loadingIndicator removeFromSuperview];
        loadingIndicator = nil;
    }
}

/************ webView:shouldStartLoadWithRequest:navigationType: (UIWebViewDelegate) ************/
/* Part of Trialpay's integration instructions
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSDLog(@"webView:%@ shouldStartLoadWithRequest:%@ navigationType:%d", [self getWebViewName:webView], [[request URL] absoluteString], navigationType);
    
    if ([webView isEqual:offerwallContainer]) {
        // when loading a new page, start by checking if it is a tp_base_page. These pages should be loaded in the offerwallContainer
        if ([request.URL.absoluteString rangeOfString:@"tp_base_page=1"].location != NSNotFound) {
            return YES;
        }
        // if it is not a tp_base_page, we need to see if the URL has a special protocol. if not, load the page in the offerContainer
        if ([request.URL.scheme hasPrefix:@"http"] || [request.URL.scheme hasPrefix:@"https"]) {
            [self loadOfferContainerWithRequest:request];
            return NO;
        }
    } else if ([webView isEqual:offerContainer]) {
        // we need to see if the URL has a special protocol. if not, load the page in the offerContainer
        if ([request.URL.scheme hasPrefix:@"http"] || [request.URL.scheme hasPrefix:@"https"]) {
            return YES;
        }
    } else {
        // If we got here that means that there's a page that the offerContainer attempts to open but it is already dismissed
        // in this scenario we will just skip loading
        return NO;
    }
    // if the special protocol starts with "tpbowhttp", remove tpbow prefix. it was needed only in order to skip the offerContainer
    NSURL *url = request.URL;
    if ([request.URL.scheme hasPrefix:@"tpbow"]) {
        url = [NSURL URLWithString:[request.URL.absoluteString substringFromIndex:5]];
    }
    [[UIApplication sharedApplication] openURL: url];
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSDLog(@"webViewDidStartLoad:%@", [self getWebViewName:webView]);
    [self showLoadingIndicator];
}

/************ webViewDidFinishLoad: (UIWebViewDelegate) ************/
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSDLog(@"webViewDidFinishLoad:%@", [self getWebViewName:webView]);
    [self hideLoadingIndicator];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    //Log this error even when not in DEBUG mode
    NSLog(@"[TpWebView] webView:%@ didFailLoadWithError:%@", [self getWebViewName:webView], [error description]);
    switch ([error code]) {
        case -1009:
        case -1001:
        {
            // The Internet connection appears to be offline
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"There seems to be a problem with your internet connection"
                                                            message:@"Would you like to try to reload the page?"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Reload", @"Close", nil];
            [alert setTag:1];
            [alert show];
            break;
        }

    }
    
}

/************ Done button pushed - for done button selector ************/
- (IBAction)doneButtonPushed:(id)sender {
    NSDLog(@"doneButtonPushed:");
    [self hideLoadingIndicator];
    if ([webViewContainer isEqual:offerContainer]) {
        [self unloadOfferContainer];
    } else {
        [delegate tpWebView:self donePushed:sender];
    }
}

/************ Back button pushed - for back button selector ************/
- (IBAction)backButtonPushed:(id)sender {
    NSDLog(@"backButtonPushed:");
    [self hideLoadingIndicator];
    if (webViewContainer.canGoBack) {
        [webViewContainer goBack];
    } else if ([webViewContainer isEqual:offerContainer]) {
        [self unloadOfferContainer];
    }
}

/**************/
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case 1:
        {
            switch (buttonIndex) {
                case 0: //Reload
                {
                    if (webViewContainer.canGoBack) {
                        [webViewContainer reload];
                    } else {
                        if ([webViewContainer isEqual:offerwallContainer] ) {
                            NSURL *url = [NSURL URLWithString:initialUrl];
                            NSURLRequest* request = [NSURLRequest requestWithURL:url];
                            [offerwallContainer loadRequest:request];
                        } else {
                            [self doneButtonPushed:nil]; //TODO: this needs to be fixed - reload does not work for the initial URL
                        }
                    }
                    break;
                }
                case 1: //Close
                {
                    [self doneButtonPushed:nil];
                    break;
                }
            }
            break;
        }
    }
}

@end
