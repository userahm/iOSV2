//
//  TpWebView.m
//
//  Created by Trialpay
//  Copyright (c) 2013 Yoav Yaari. All rights reserved.
//

#import "TpWebView.h"
#import "TpUtils.h"
#import "TpUrlManager.h"

@interface TpWebView()
@property (strong) NSString *initialUrl;
@property (strong) UIWebView *webViewContainer;
@property (strong) UIBarButtonItem *flexibleSpaceArea;
@property (strong) UIActivityIndicatorView *loadingIndicator;
@end

@implementation TpWebView

/*
 * Loads the offerwall using the given frame size.
 * This is currently being overriden by -buildViewWithWidth:height:
 */
- (id)initWithFrame:(CGRect)frame {
    TPLogEnter;
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.initialUrl = nil;
    }
    return self;
}

/*
 * Sets the given offerwallUrl as the initialUrl for the offerwallContainer.
 * The url is loaded in -layoutSubviews
 */
- (void)loadRequest:(NSString*)offerwallUrl {
    TPLogEnter;
    [self setInitialUrl:[NSString stringWithFormat:@"%@&tp_base_page=1",offerwallUrl]];
    if (nil != _offerwallContainer) {
        NSURL *url = [NSURL URLWithString:_initialUrl];
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        [_offerwallContainer loadRequest:request];
    }
}

#pragma mark - pragmatically build views
/*
 * Setting up the view structure with code.
 * We do not use XIBs in order to reduce plugin integration complexity
 */
- (UIView *)buildViewWithWidth:(CGFloat)width height:(CGFloat)height {
    TPLog(@"buildViewWithWidth:%f height:%f", width, height);
    
    UIApplication *application = [UIApplication sharedApplication];
    float statusBarHeight = MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    float toolbarHeight = 44.0;
    
    // Build toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, width, toolbarHeight)];
    _toolbar.alpha = 1.000;
    _toolbar.autoresizesSubviews = YES;
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _toolbar.barStyle = UIBarStyleDefault;
    _toolbar.clearsContextBeforeDrawing = NO;
    _toolbar.clipsToBounds = NO;
    _toolbar.contentMode = UIViewContentModeScaleToFill;
    _toolbar.frame = CGRectMake(0.0, 0.0, width, 44.0);
    _toolbar.hidden = NO;
    _toolbar.multipleTouchEnabled = NO;
    _toolbar.opaque = NO;
    _toolbar.tag = 0;
    _toolbar.userInteractionEnabled = YES;
    
    _backButton = [[UIBarButtonItem alloc] init];
    _backButton.imageInsets = UIEdgeInsetsZero;
    _backButton.style = UIBarButtonItemStyleBordered;
    _backButton.tag = 0;
    _backButton.title = @"Back";
    _backButton.width = 0.000;
    _backButton.action = @selector(backButtonPushed:);
    
    _flexibleSpaceArea = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    _flexibleSpaceArea.enabled = YES;
    _flexibleSpaceArea.imageInsets = UIEdgeInsetsZero;
    _flexibleSpaceArea.style = UIBarButtonItemStylePlain;
    _flexibleSpaceArea.tag = 0;
    _flexibleSpaceArea.width = 0.000;
    
    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:nil];
    _doneButton.enabled = YES;
    _doneButton.imageInsets = UIEdgeInsetsZero;
    _doneButton.style = UIBarButtonItemStyleBordered;
    _doneButton.tag = 0;
    _doneButton.width = 0.000;
    _doneButton.action = @selector(doneButtonPushed:);
    
    _toolbar.items = [NSArray arrayWithObjects:_flexibleSpaceArea, _doneButton, nil];
    
    
    
    // Build offerwallContainer
    _offerwallContainer = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, toolbarHeight, width, height-(toolbarHeight+statusBarHeight))];
    
    _offerwallContainer.alpha = 1.000;
    _offerwallContainer.autoresizesSubviews = YES;
    _offerwallContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _offerwallContainer.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1.000];
    _offerwallContainer.clearsContextBeforeDrawing = YES;
    _offerwallContainer.clipsToBounds = NO;
    _offerwallContainer.contentMode = UIViewContentModeScaleToFill;
    _offerwallContainer.hidden = NO;
    _offerwallContainer.multipleTouchEnabled = NO;
    _offerwallContainer.opaque = YES;
    _offerwallContainer.scalesPageToFit = NO;
    _offerwallContainer.tag = 0;
    _offerwallContainer.userInteractionEnabled = YES;
    _offerwallContainer.delegate = self;
    
    [[_offerwallContainer scrollView] setBounces:NO];
    [_offerwallContainer setAllowsInlineMediaPlayback:YES];
    [_offerwallContainer setMediaPlaybackRequiresUserAction:NO];
    [_offerwallContainer setScalesPageToFit:YES];
    
    // Build main view (container)
    _mainView = [[UIView alloc] initWithFrame:CGRectMake(0.0, statusBarHeight, width, height-statusBarHeight)];
    _mainView.alpha = 1.000;
    _mainView.autoresizesSubviews = YES;
    _mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mainView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:1.000];
    _mainView.clearsContextBeforeDrawing = YES;
    _mainView.clipsToBounds = NO;
    _mainView.contentMode = UIViewContentModeScaleToFill;
    _mainView.hidden = NO;
    _mainView.multipleTouchEnabled = NO;
    _mainView.opaque = YES;
    _mainView.tag = 0;
    _mainView.userInteractionEnabled = YES;
    
    [_mainView addSubview:_toolbar];
    [_mainView addSubview:_offerwallContainer];
    
    return _mainView;
}

/*
 * Returns the "name" of the UIWebView element for logging purposes
 */
- (NSString *)getWebViewName:(UIWebView *)webView {
    return [webView isEqual:_offerwallContainer] ? @"offerwallContainer" : @"offerContainer";
}

/*
 * Being called when the view is being drawn
 *
 * Note: You should not call this method directly. If you want to force a layout update, call the setNeedsLayout method instead
 */
- (void)layoutSubviews {
    TPLog(@"layoutSubviews");
    [super layoutSubviews];
    UIApplication *application = [UIApplication sharedApplication];
    float statusBarHeight = MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    
    if (_mainView == nil) {
        CGRect screenRect =  [[UIScreen mainScreen] bounds];
        // we need to get the screen size with the right orientation which means to get the height and width
        // and then to switch their positions if (we got a landscape orientation)XOR(we need landscape orientation)
        // we do that here with two replace statements
        
        // capture height and width
        CGFloat height = screenRect.size.height;
        CGFloat width = screenRect.size.width;
        TPLog(@"height: %f, width: %f", height, width);
        // make sure that height<width (portrait mode properties)
        if (width>height) {
            TPLog(@"Switch");
            CGFloat temp = width;
            width = height;
            height = temp;
        }
        TPLog(@"height: %f, width: %f, %d", height, width, [[UIApplication sharedApplication] statusBarOrientation]);
        // change data to landscape if needed
        if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
            TPLog(@"Landscape");
            CGFloat temp = width;
            width = height;
            height = temp;
        }
        TPLog(@"height: %f, width: %f", height, width);
        
        [self buildViewWithWidth:width height:height];
        [self addSubview:_mainView];
        
        if (_initialUrl) {
            NSURL* url = [NSURL URLWithString:_initialUrl];
            NSURLRequest* request = [NSURLRequest requestWithURL:url];
            [_offerwallContainer loadRequest:request];
            
            _webViewContainer = _offerwallContainer;
        }

        // ViewController::edgesForExtendedLayout is not working, so we will need to move the start y on ios7, possible reasons:
        // - we are drawing the view ourselves, and we were supposed to use the property ourselves, its not clear from iOS SDK documentation
        // - the property is not working as expected, an iOS SDK issue
        float startY = 0;
        
        // iOS 7 changes handling of status bar, this prevents "views under status bar"
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            startY = statusBarHeight;
            // TODO: presuming offerwall status bar should always be white...
            self.backgroundColor = [UIColor whiteColor];
        }

        _mainView.frame = CGRectMake(0, startY, width, height-statusBarHeight);
    }
}

#pragma mark - Loading offers
- (void) loadOfferContainerWithRequest:(NSURLRequest *)request {
    TPLog(@"loadOfferContainerWithRequest: %@", request.URL.absoluteString);
    
    _offerContainer = [[UIWebView alloc] initWithFrame:_offerwallContainer.frame];
    
    _offerContainer.alpha = 1.000;
    _offerContainer.autoresizesSubviews = YES;
    _offerContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _offerContainer.backgroundColor = [UIColor colorWithRed:1.000 green:1.000 blue:1.000 alpha:1.000];
    _offerContainer.clearsContextBeforeDrawing = YES;
    _offerContainer.clipsToBounds = NO;
    _offerContainer.contentMode = UIViewContentModeScaleToFill;
    _offerContainer.hidden = NO;
    _offerContainer.multipleTouchEnabled = NO;
    _offerContainer.opaque = YES;
    _offerContainer.scalesPageToFit = NO;
    _offerContainer.tag = 0;
    _offerContainer.userInteractionEnabled = YES;
    _offerContainer.delegate = self;
    
    [_offerContainer setAllowsInlineMediaPlayback:YES];
    [_offerContainer setMediaPlaybackRequiresUserAction:NO];
    [_offerContainer setScalesPageToFit:YES];
    
    [_offerContainer loadRequest:request];
    
    [UIView transitionWithView:_mainView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ { [_mainView addSubview:_offerContainer]; }
                    completion:nil];
    
    _webViewContainer = _offerContainer;
    _toolbar.items = [NSArray arrayWithObjects:_backButton, _flexibleSpaceArea, _doneButton, nil];
}

- (void) unloadOfferContainer {
    TPLog(@"unloadOfferContainer");
    _webViewContainer = _offerwallContainer;
    [_offerContainer removeFromSuperview];
    _offerContainer = nil;
    _toolbar.items = [NSArray arrayWithObjects:_flexibleSpaceArea, _doneButton, nil];
}

#pragma mark - Indicator on Navigation Bar
- (void) showLoadingIndicator {
    if (nil == _loadingIndicator) {
        CGRect indicatorBounds = CGRectMake(_offerwallContainer.frame.size.width/4, 12, _offerwallContainer.frame.size.width/2, 24);
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:indicatorBounds];
        _loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        _loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_loadingIndicator startAnimating];
        [_mainView addSubview:_loadingIndicator];
    }
}

- (void) hideLoadingIndicator {
    if (nil != _loadingIndicator) {
        [_loadingIndicator removeFromSuperview];
        _loadingIndicator = nil;
    }
}

#pragma mark - webView (UIWebViewDelegate)
/* Part of Trialpay's integration instructions
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    TPLog(@"webView:%@ shouldStartLoadWithRequest:%@ navigationType:%d", [self getWebViewName:webView], [[request URL] absoluteString], navigationType);
    
    if ([webView isEqual:_offerwallContainer]) {
        if ([request.URL.scheme hasPrefix:@"http"] || [request.URL.scheme hasPrefix:@"https"]) {
            NSArray *tpHosts = [NSArray arrayWithObjects:@"trialpay.com", @"trialpay.net", @"tp-cdn.com", nil];
            NSString *host = request.URL.host;
            if ([host hasPrefix:@"www."]) {
                host = [host substringFromIndex:4];
            }
            if ([tpHosts containsObject:host]) {
                // when loading a new page, start by checking if it is a tp_base_page. These pages should be loaded in the offerwallContainer
                if ([request.URL.absoluteString rangeOfString:@"tp_base_page=1"].location != NSNotFound) {
                    return YES;
                } else {
                    [self loadOfferContainerWithRequest:request];
                    return NO;
                }
            } else {
                return YES;
            }
        }
    } else if ([webView isEqual:_offerContainer]) {
        // we need to see if the URL has a special protocol. if not, load the page in the offerContainer
        if ([request.URL.scheme hasPrefix:@"http"] || [request.URL.scheme hasPrefix:@"https"]) {
            return YES;
        }
    } else {
        // If we got here that means that there's a page that the offerContainer attempts to open but it is already dismissed
        // in this scenario we will just skip loading
        return NO;
    }
    // if the special protocol starts with "tpbowhttp(s)", remove tpbow prefix. it was needed only in order to skip the offerContainer
    NSURL *url = request.URL;
    if ([request.URL.scheme hasPrefix:@"tpbow"]) {
        url = [NSURL URLWithString:[request.URL.absoluteString substringFromIndex:5]];
    }
    [[UIApplication sharedApplication] openURL: url];
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    TPLog(@"%@", [self getWebViewName:webView]);
    [self showLoadingIndicator];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    TPLog(@"%@", [self getWebViewName:webView]);
    [self hideLoadingIndicator];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    //Log this error even when not in DEBUG mode
    TPCustomerError(@"webView:didFailLoadWithError:", @"webView:%@ didFailLoadWithError:%@", [self getWebViewName:webView], [error description]);
    [self hideLoadingIndicator];
    switch ([error code]) {
        case -1009:
        case -1001:
        {
            // The Internet connection appears to be offline
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"There seems to be a problem with your internet connection",@"There seems to be a problem with your internet connection")
                                                            message:NSLocalizedString(@"Would you like to try to reload the page?",@"Would you like to try to reload the page?")
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"Reload",@"Reload"), NSLocalizedString(@"Close",@"Close"), nil];
            [alert setTag:1];
            [alert show];
            break;
        }

    }
    
}

#pragma mark - Buttons
/** Done button pushed - for done button selector */
- (IBAction)doneButtonPushed:(id)sender {
    TPLogEnter;
    [self hideLoadingIndicator];
    if ([_webViewContainer isEqual:_offerContainer]) {
        [self unloadOfferContainer];
    } else {
        [_delegate tpWebView:self donePushed:sender];
    }
}

/** Back button pushed - for back button selector */
- (IBAction)backButtonPushed:(id)sender {
    TPLogEnter;
    [self hideLoadingIndicator];
    if (_webViewContainer.canGoBack) {
        [_webViewContainer goBack];
    } else if ([_webViewContainer isEqual:_offerContainer]) {
        [self unloadOfferContainer];
    }
}

#pragma mark - Alert view delegate (connection issues)
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case 1:
        {
            switch (buttonIndex) {
                case 0: //Reload
                {
                    if (_webViewContainer.canGoBack) {
                        [_webViewContainer reload];
                    } else {
                        if ([_webViewContainer isEqual:_offerwallContainer] ) {
                            NSURL *url = [NSURL URLWithString:_initialUrl];
                            NSURLRequest* request = [NSURLRequest requestWithURL:url];
                            [_offerwallContainer loadRequest:request];
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

- (BOOL)loadOfferwallForTouchpoint:(NSString *)touchpointName {
    NSString *url = [[TpUrlManager sharedInstance] offerwallUrlForTouchpoint:touchpointName];
    TPLog(@"Url: %@", url);
    if (url == nil) {
        TPCustomerLog(@"Unable to get offerwall URL fo {url}", @"Unable to get offerwall URL fo %@", touchpointName);
        return false;
    }
    [self unloadOfferContainer];
    [self loadRequest:url];
    return true;
}

@end
