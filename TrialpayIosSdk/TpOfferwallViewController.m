//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 Trialpay Inc. All rights reserved.
//

#import "TpOfferwallViewController.h"
#import "TpUtils.h"

@interface TpOfferwallViewController ()
@end

@implementation TpOfferwallViewController

#pragma mark - Init with touchpoint name
- (id)initWithTouchpointName:(NSString *)touchpointName {
    TPLog(@"initWithTouchpointName %@", touchpointName);
    self = [self init];
    
    _touchpointName = touchpointName;
    
    return self;
}

#pragma mark - View Lifecycle
-(void)loadView {
    TPLogEnter;
    [[UIApplication sharedApplication] setStatusBarHidden:[UIApplication sharedApplication].statusBarHidden withAnimation:UIStatusBarAnimationFade];
    _tpWebView = [[TpWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 460.0)];
    self.view = self.tpWebView;
    self.tpWebView.delegate = self;
}

- (void)viewDidLoad {
    TPLogEnter;

    [super viewDidLoad];
    
    [self.tpWebView loadOfferwallForTouchpoint:self.touchpointName];
}

#pragma mark - Done button pushed - for done button selector
- (void)tpWebView:(TpWebView *)tpWebView donePushed:(id)sender {
    TPLogEnter;
  
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:animated:completion:)]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        // if iOS version < 6 is used
        [self dismissModalViewControllerAnimated:YES];
    }
  
    [self.delegate tpOfferwallViewController:self close:sender];
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
