//
//  TpVideoEndcapViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2014 TrialPay, Inc. All Rights Reserved.
//

#import "TpVideoEndcapViewController.h"
#import "TpArcSupport.h"
#import "TpVideo.h"

@implementation TpVideoEndcapViewController {
    BOOL _isExitButtonShown;
    UILabel *_exitButtonLabel;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    // NOTE: inside viewDidAppear we assume we're in landscape mode. If we start supporting
    // portrait that will need to be changed.
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (id)init {
    if ((self = [super init])) {
        _exitButtonLabel = nil;
        _isExitButtonShown = NO;
        // Default to showing an exit button while the endcap is loading. This is a public property and can be overwritten.
        _shouldShowExitButton = YES;
    }
    return self;
}

- (void)dealloc {
    [_exitButtonLabel TP_RELEASE];
    [super TP_DEALLOC];
}

- (void)viewDidAppear:(BOOL)animated {
    if (_shouldShowExitButton) {
        ////////////////////////////////////////////////////////////////////////
        // Create and display the native exit button. We'll hide this button once
        // the endcap finishes loading. After that we use an HTML close button.
        float buttonSize = 44.0; // Standard iOS element size.
        // Place the button in upper right corner.
        // We separate the button from the edges of the screen with a margin of 3 pixels.
        // Use the frame height in the horizontal calculation because the frame size is always returned as if we're in portrait (and we're always in landscape).
        CGRect exitButtonLabelRect = CGRectMake(self.view.frame.size.height - (3.0 + buttonSize), 3.0, buttonSize, buttonSize);
        _exitButtonLabel = [[UILabel alloc] initWithFrame:exitButtonLabelRect];
        // Configure button
        _exitButtonLabel.text = @"X";
        _exitButtonLabel.font = [UIFont fontWithName:@"Helvetica" size:70.0f];
        _exitButtonLabel.textColor = [UIColor blackColor];
        _exitButtonLabel.backgroundColor = [UIColor clearColor];
        // Add tap recognizer
        _exitButtonLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *buttonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nativeExitButtonClick:)];
        [_exitButtonLabel addGestureRecognizer:buttonTapRecognizer];
        [buttonTapRecognizer TP_RELEASE];
        // Display
        [self.view addSubview:_exitButtonLabel];
        _isExitButtonShown = YES;
    }

    [super viewDidAppear:animated];
}

- (void)nativeExitButtonClick:(UIGestureRecognizer *)gestureRecognizer {
    [[TpVideo sharedInstance] closeTrailerFlowAndDismissViewController:YES];
}

- (void)hideNativeExitButton {
    // Make sure we don't display the close button if viewDidAppear is called after this.
    _shouldShowExitButton = NO;
    // If the exit button has already been displayed, remove it.
    if (_isExitButtonShown) {
        [_exitButtonLabel removeFromSuperview];
    }
}

@end
