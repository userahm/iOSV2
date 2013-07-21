//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 Trialpay Inc. All rights reserved.
//

#import "TpOfferwallViewController.h"

// Create NSDLog - a debug call available on debug mode only
#ifdef DEBUG
#define NSDLog(FORMAT, ...) fprintf(stderr,"[TpOfferwallViewController] %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSDLog(...)
#endif

@interface TpOfferwallViewController ()

@end

@implementation TpOfferwallViewController
@synthesize offerwallUrl;
@synthesize vic;
@synthesize sid;
@synthesize offerwallContainer;

/************ Init with VIC, SID ************/
- (id) initWithVic:(NSString *)vicValue sid:(NSString *)sidValue {
    NSDLog(@"initWithVic %@, %@", vicValue, sidValue);
    self = [self init];

    self.vic = vicValue;
    self.sid = sidValue;
    
    return self;
}

- (NSString *) getOfferwallUrl {
    NSString *url = [NSString stringWithFormat:@"%@%@?sid=%@&appver=%@&idfa=%@&sdkver=%@",
            [TpUtils getDispatchPath],
            vic,
            sid,
            [TpUtils getAppver],
            [TpUtils getIdfa],
            [[BaseTrialpayManager getInstance] getSdkVer]];
    
    return url;
}

/************ loadview (UIViewController) ************/
-(void)loadView {
    NSDLog(@"loadView");
    [[UIApplication sharedApplication] setStatusBarHidden:[UIApplication sharedApplication].statusBarHidden withAnimation:UIStatusBarAnimationFade];
    offerwallContainer = [[TpWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 460.0)];
    self.view = offerwallContainer;
    offerwallContainer.delegate = self;
}

/************ viewDidLoad (UIViewController) ************/
- (void)viewDidLoad {
    NSDLog(@"viewDidLoad");
    offerwallUrl = [self getOfferwallUrl];
    NSDLog(@"launchOfferwall %@", offerwallUrl);

    [super viewDidLoad];
    
    [offerwallContainer loadRequest:offerwallUrl];
}

/************ Done button pushed - for done button selector ************/
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender {
    NSDLog(@"tpWebView donePushed");
    [self dismissModalViewControllerAnimated:YES];
    [self.delegate tpOfferwallViewController:self close:sender];
}

/************ shouldAutorotateToInterfaceOrientation (UIViewController) ************/
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //support for all orientation change
    return YES;
}

/************ supportedInterfaceOrientations (UIViewController) ************/
- (NSUInteger)supportedInterfaceOrientations{
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
    return UIInterfaceOrientationMaskAll;
#else
    return UIInterfaceOrientationPortrait|UIInterfaceOrientationPortraitUpsideDown|UIInterfaceOrientationLandscapeLeft|UIInterfaceOrientationLandscapeRight;
#endif
}

@end
