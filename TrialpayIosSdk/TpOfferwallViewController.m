//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import "TpOfferwallViewController.h"
#import "TpUtils.h"
#import "TpArcSupport.h"
#import "BaseTrialpayManager.h"

@interface TpOfferwallViewController ()
@end

@implementation TpOfferwallViewController {
}

#pragma mark - Init with touchpoint name
- (id)initWithTouchpointName:(NSString *)touchpointName {
    TPLog(@"initWithTouchpointName %@", touchpointName);
    self = [self init];
    _touchpointName = touchpointName;

    return self;
}

#pragma mark - View Lifecycle

- (void)dealloc {
    // Help ARC release the memory faster
    [self.tpWebView stopWebViews];
    // lets help ARC to claim memory back faster
    self.view = nil;
    TP_ARC_RELEASE(tpWebView);
    [super TP_DEALLOC];
}

-(void)loadView {
    TPLogEnter;
    [[UIApplication sharedApplication] setStatusBarHidden:[UIApplication sharedApplication].statusBarHidden withAnimation:UIStatusBarAnimationFade];
    self.tpWebView = [[[TpWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 460.0)] TP_AUTORELEASE];
    self.view = self.tpWebView;
    self.tpWebView.delegate = self;
}

- (void)viewDidLoad {
    TPLogEnter;

    [super viewDidLoad];
    [self.tpWebView loadWebViewTouchpoint:self.touchpointName];
}

#pragma mark - Done button pushed - for done button selector
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender {
    TPLogEnter;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate tpOfferwallViewController:self close:sender forTouchpointName:_touchpointName];
    self.tpWebView.delegate = nil; // release delegate on close
}

#pragma mark - Autorotate for both ios5 and ios6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    //support for all orientation change
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
    return UIInterfaceOrientationMaskAll;
#else
    return UIInterfaceOrientationPortrait|UIInterfaceOrientationPortraitUpsideDown|UIInterfaceOrientationLandscapeLeft|UIInterfaceOrientationLandscapeRight;
#endif
}

@end
