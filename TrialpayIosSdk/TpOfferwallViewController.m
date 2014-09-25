//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import "TpOfferwallViewController.h"
#import "TpUtils.h"
#import "TpArcSupport.h"
#import "TpVideo.h"

@interface TpOfferwallViewController ()
@end

@implementation TpOfferwallViewController {
}

#pragma mark - Init with touchpoint name
- (id)initWithTouchpointName:(NSString *)touchpointName {
    TPLog(@"initWithTouchpointName %@", touchpointName);
    if ((self = [self init])) {
        _touchpointName = touchpointName;
    }

    return self;
}

#pragma mark - View Lifecycle

- (void)dealloc {
    // Help ARC release the memory faster
    self.tpWebView.delegate = nil; // release delegate on close
    [self.tpWebView stopWebViews];
    // lets help ARC to claim memory back faster
    self.view = nil;
    TP_ARC_RELEASE(tpWebView);
    [super TP_DEALLOC];
}

-(void)loadView {
    TPLogEnter;
    [[UIApplication sharedApplication] setStatusBarHidden:[UIApplication sharedApplication].statusBarHidden withAnimation:UIStatusBarAnimationFade];
    self.tpWebView = [[[TpWebView alloc] initWithFrame:CGRectZero] TP_AUTORELEASE]; // the frame is recalculated, lets make it clear that this frame doent matter
    self.view = self.tpWebView;
    self.tpWebView.delegate = self;
}

- (void)viewDidLoad {
    TPLogEnter;

    [super viewDidLoad];
    self.tpWebView.viewMode = self.viewMode;
    [self.tpWebView loadWebViewTouchpoint:self.touchpointName];
}

#pragma mark - Done button pushed - for done button selector
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender {
    TPLogEnter;
    if ([TpUtils singleFlowLockWithMessage:@"donePushed"]) {
        // dispatch sync forces a synchronization of the main thread, preventing multiple
        void (^completionBlock)(void) = ^{
            TPLog(@"Completion block %@", _touchpointName);
            [self.delegate closeTouchpoint:_touchpointName];
            [TpUtils singleFlowUnlockWithMessage:@"donePushed"];
        };
        [self dismissViewControllerAnimated:YES completion:[[completionBlock copy] TP_AUTORELEASE]];
    }
}

#pragma mark - Opening a video trailer from the offerwall
- (void)playVideoWithURL:(NSString *)videoResourceURL {
    [[TpVideo sharedInstance] playVideoWithURL:videoResourceURL fromViewController:self withBlock:nil];
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
