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
    UIView *_overlay;
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
        _overlay = nil;
        _isExitButtonShown = NO;
        // Default to showing an exit button while the endcap is loading. This is a public property and can be overwritten.
        _shouldShowExitButton = YES;
    }
    return self;
}

- (void)dealloc {
    [super TP_DEALLOC];
}

- (void)viewWillAppear:(BOOL)animated {
    if (_shouldShowExitButton) {
        // iOS8 reports the frames inverted (from prev versions), but we are always on landscape, so we are forcing using the longer edge...
        CGRect view_frame = self.view.frame;
        if (self.view.frame.size.width > self.view.frame.size.height) {
            view_frame = CGRectMake(self.view.frame.origin.y, self.view.frame.origin.x, self.view.frame.size.width, self.view.frame.size.height);
        }
        
        // Create and display overlay with the native exit button. We'll hide this overlay once
        // the endcap finishes loading. After that we use an HTML close button.
        _overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, view_frame.size.width, view_frame.size.height)];
        _overlay.backgroundColor = [UIColor whiteColor];
        UIActivityIndicatorView * activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_overlay addSubview:activityIndicator];
        [activityIndicator startAnimating];
        
        CGRect activityIndicatorFrame = CGRectMake(view_frame.size.width / 2 - activityIndicator.frame.size.width / 2, view_frame.size.height / 2 - activityIndicator.frame.size.height / 2, activityIndicator.frame.size.width, activityIndicator.frame.size.height);
        activityIndicator.frame = activityIndicatorFrame;
        
        float buttonSize = 44.0; // Standard iOS element size.
        // Place the button in upper right corner.
        // We separate the button from the edges of the screen with a margin of 3 pixels.
        // Use the frame height in the horizontal calculation because the frame size is always returned as if we're in portrait (and we're always in landscape).
        CGRect exitButtonLabelRect = CGRectMake(view_frame.size.height - (3.0 + buttonSize), 3.0, buttonSize, buttonSize);

        UILabel * exitButtonLabel = [[UILabel alloc] initWithFrame:exitButtonLabelRect];
        
        exitButtonLabel = [[UILabel alloc] initWithFrame:exitButtonLabelRect];
        // Configure button
        exitButtonLabel.text = @"\u2716"; // "X" unicode character 
        exitButtonLabel.font = [UIFont fontWithName:@"Helvetica" size:34.0f];
        exitButtonLabel.textColor = [UIColor blackColor];
        exitButtonLabel.backgroundColor = [UIColor clearColor];
        // Add tap recognizer
        exitButtonLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *buttonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(nativeExitButtonClick:)];
        [exitButtonLabel addGestureRecognizer:buttonTapRecognizer];
        [buttonTapRecognizer TP_RELEASE];
        // Display
        [_overlay addSubview:exitButtonLabel];
        [self.view addSubview:_overlay];
        _isExitButtonShown = YES;

        [activityIndicator TP_RELEASE];
    }

    [super viewWillAppear:animated];
}

- (void)nativeExitButtonClick:(UIGestureRecognizer *)gestureRecognizer {
    [[TpVideo sharedInstance] closeTrailerFlowAndDismissViewController:YES];
}

- (void)hideNativeExitButton {
    // Make sure we don't display the close button if viewDidAppear is called after this.
    _shouldShowExitButton = NO;
    // If the exit button has already been displayed, remove it.
    if (_isExitButtonShown) {
        [_overlay removeFromSuperview];
    }
}

@end
