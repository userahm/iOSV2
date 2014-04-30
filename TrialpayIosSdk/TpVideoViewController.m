//
//  TpVideoViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2014 TrialPay, Inc. All Rights Reserved.
//

#import "TpVideoViewController.h"
#import "BaseTrialpayManager.h"
#import "TpVideo.h"
#import "TpArcSupport.h"
#import "TpUtils.h"

@implementation TpVideoViewController {
    NSString *_downloadURL;
    NSTimer *_countdownTimer;
    int _videoTimeRemaining;
    int _completionTime;;
    BOOL _didHideStatusBar;
    UIColor *_textColor;
    // The following properties control the exit button
    UIButton *_exitButton;
    UILabel *_exitButtonLabel;
    BOOL _isShowExitButton;
    int _exitButtonDelay;
    // The following properties control the countdown text
    UILabel *_countdownLabel;
    BOOL _isShowCountdown;
    NSString *_countdownText;
}

int VIDEO_TIME_REMAINING_UNITIALIZED = -10;

#pragma mark - Countdown Label & Exit Button

- (NSString *)generateCountdownText {
    // Check to see if we have the %time% placeholder
    if ([_countdownText rangeOfString:@"%time%"].location == NSNotFound) {
        return _countdownText;
    } else {
        return [_countdownText stringByReplacingOccurrencesOfString:@"%time%" withString:[NSString stringWithFormat:@"%d", _videoTimeRemaining]];
    }
}

- (CGSize)getVideoViewFrameSize {
    CGSize viewFrameSize = self.view.frame.size;
    viewFrameSize = CGSizeMake(viewFrameSize.height, viewFrameSize.width); // We're displaying in landscape mode so swap the parameters.
    return viewFrameSize;
}

// Describe the width of horizontal and vertical borders
struct TpVideoBorders {
    float horizontal;
    float vertical;
};

- (struct TpVideoBorders)getVideoBorders {
    struct TpVideoBorders borders;

    CGSize naturalSize = self.moviePlayer.naturalSize;
    if ((naturalSize.width <= 0) || (naturalSize.height <= 0)) {
        // The moviePlayer hasn't finished initializing yet. We should have caught this inside countdown, but
        // we'll do a fallback check here. Returing 0 borders will just mean UI elements will be placed relative
        // to the screen, not the video.
        TPLog(@"Invalid naturalSize of moviePlayer. Defaulting to 0 borders.");
        borders.horizontal = 0.0f;
        borders.vertical = 0.0f;
        return borders;
    }

    CGSize displayedVideoSize;
    CGSize viewFrameSize = [self getVideoViewFrameSize];
    float widthRatio = viewFrameSize.width / naturalSize.width;
    float heightRatio = viewFrameSize.height / naturalSize.height;
    if (widthRatio > heightRatio) {
        displayedVideoSize = CGSizeMake(naturalSize.width * heightRatio, viewFrameSize.height);
    } else {
        displayedVideoSize = CGSizeMake(viewFrameSize.width, naturalSize.height * widthRatio);
    }
    borders.horizontal = (viewFrameSize.width - displayedVideoSize.width) / 2.0;
    borders.vertical = (viewFrameSize.height - displayedVideoSize.height) / 2.0;
    return borders;
}

- (CGRect)getCountdownLabelRect {
    CGSize viewFrameSize = [self getVideoViewFrameSize];
    struct TpVideoBorders videoBorders = [self getVideoBorders];
    float textHeight = 18.0; // this does not correspond to font point
    float textWidth = viewFrameSize.width - (videoBorders.horizontal * 2.0); // set textWidth equal to the width of the displayed video, to accommodate long text.
    // Place the countdown text in the lower left corner.
    CGRect countdownLabelRect = CGRectMake(videoBorders.horizontal + 2.0, viewFrameSize.height - (videoBorders.vertical + textHeight), textWidth, textHeight);
    return countdownLabelRect;
}

- (CGRect)getExitButtonLabelRect {
    CGSize viewFrameSize = [self getVideoViewFrameSize];
    struct TpVideoBorders videoBorders = [self getVideoBorders];
    float textHeight = 24.0;
    float textWidth = 16.0;
    // Place the close button in the upper right corner.
    CGRect exitButtonLabelRect = CGRectMake(viewFrameSize.width - (videoBorders.horizontal + 3.0 + textWidth), videoBorders.vertical + 1.0, textWidth, textHeight);
    return exitButtonLabelRect;
}

// Takes the output of getExitButtonLabelRect and generates a 100x100 rect centered on the provided rect.
- (CGRect)getExitButtonRect:(CGRect)labelRect {
    CGPoint labelRectCenter = CGPointMake(labelRect.origin.x + labelRect.size.width/2, labelRect.origin.y + labelRect.size.height/2);
    float buttonHeight = 100.0;
    float buttonWidth = 100.0;
    CGRect exitButtonRect = CGRectMake(labelRectCenter.x - buttonWidth/2, labelRectCenter.y - buttonHeight/2, buttonWidth, buttonHeight);
    return exitButtonRect;
}

- (void)showCountdownText {
    _countdownLabel = [[UILabel alloc] initWithFrame:[self getCountdownLabelRect]];
    _countdownLabel.text = [self generateCountdownText];
    _countdownLabel.font = [UIFont fontWithName:@"Helvetica" size:18.0f];
    _countdownLabel.textColor = _textColor;
    _countdownLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_countdownLabel];
}

- (void)showExitButton {
    // We generate the button and button text separately. We want the button text (a UILabel element) to display at
    // a certain size, but we want the clickable area to be larger, for which we use an invisible UIButton.

    CGRect labelRect = [self getExitButtonLabelRect];
    _exitButtonLabel = [[UILabel alloc] initWithFrame:labelRect];
    _exitButtonLabel.text = @"X";
    _exitButtonLabel.font = [UIFont fontWithName:@"Helvetica" size:24.0f];
    _exitButtonLabel.textColor = _textColor;
    _exitButtonLabel.backgroundColor = [UIColor clearColor];

    // Use a custom button type. A custom button has no default styling, making it invisible but still able to receive inputs.
    _exitButton = [[UIButton buttonWithType:UIButtonTypeCustom] TP_RETAIN];
    _exitButton.frame = [self getExitButtonRect:labelRect];
    UITapGestureRecognizer *buttonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exitVideoEarly:)];
    [_exitButton addGestureRecognizer:buttonTapRecognizer];
    [buttonTapRecognizer TP_RELEASE];

    [self.view addSubview:_exitButton];
    [self.view addSubview:_exitButtonLabel];
}

#pragma mark - Counter

// Runs every second
- (void)countdown {
    if (_videoTimeRemaining == VIDEO_TIME_REMAINING_UNITIALIZED) {
        // Confirm that the moviePlayer is fully initialized.
        if ((self.moviePlayer == nil) || (self.moviePlayer.duration <= 0) ||
            (self.moviePlayer.naturalSize.width <= 0) || (self.moviePlayer.naturalSize.height <= 0)) {
            // Do nothing for now (we'll check again the next time we run this timer).
            TPLog(@"moviePlayer is still being initialized - returning from countdown early");
            return;
        } else {
            _videoTimeRemaining = (int)self.moviePlayer.duration;
        }
    } else {
        _videoTimeRemaining--;
    }
    if (_videoTimeRemaining <= 0) {
        [_countdownTimer invalidate];
    }

    // Completion firing. Confirm that we're at least 5 seconds into the video, so that the click API request has time to complete.
    if ((self.moviePlayer.duration - _videoTimeRemaining) >= 5) {
        if (_completionTime >= 0) {
            // complete at X seconds from the start of the video
            if ((self.moviePlayer.duration - _videoTimeRemaining) >= _completionTime) {
                [[TpVideo sharedInstance] fireCompletionIfNotFiredForURL:_downloadURL];
            }
        } else {
            // complete at X seconds from the end of the video
            if (_videoTimeRemaining <= (_completionTime * -1)) {
                [[TpVideo sharedInstance] fireCompletionIfNotFiredForURL:_downloadURL];
            }
        }
    }
    // Showing the countdown text.
    if (_isShowCountdown) {
        if (_countdownLabel == nil) {
            [self showCountdownText];
        } else {
            _countdownLabel.text = [self generateCountdownText];
            [_countdownLabel setNeedsDisplay];
        }
    }
    // Showing the exit button.
    if (_isShowExitButton) {
        if (_exitButton == nil) {
            if ((self.moviePlayer.duration - _videoTimeRemaining) >= _exitButtonDelay) {
               [self showExitButton];
            }
        }
    }
}

#pragma mark - Init & Dealloc

// Initialize the view controller.
// Params:
//  - NSString *downloadURL - The resource URL from which we download the video. used for identification.
//  - NSString *textColor - UIColor name for countdown text and exit button. e.g. 'blackColor', 'lightGrayColor', etc
//  - NSNumber *completionTime - number of seconds until we fire the completion. Negative values are calculated from the end of the video. (e.g. -3 means 3 seconds from the end)
//  - NSNumber *exitButtonDelay - number of seconds until we show the exit button. A value of -1 means the button is never shown.
//  - BOOL isShowCountdown - Whether to display countdown text.
//  - NSString *countdownText - Text format for displaying countdown. The placeholder "%time%" will be replaced by the integer countdown.
- (id)initWithContentURL:(NSURL *)URL andParams:(NSDictionary *)params {
    if ((self = [super initWithContentURL:URL])) {
        _downloadURL = [[params objectForKey:@"downloadURL"] TP_RETAIN];

        NSNumber *countdownTime = [params objectForKey:@"completionTime"];
        if (countdownTime != nil) {
            _completionTime = [countdownTime intValue];
        } else {
            _completionTime = -2;
        }

        NSString *colorStr = [params objectForKey:@"textColor"];
        if ((colorStr != nil) && [UIColor respondsToSelector:NSSelectorFromString(colorStr)]) {
            _textColor = [UIColor performSelector:NSSelectorFromString(colorStr)];
        } else {
            TPLog(@"Invalid text color %@ was provided for video %@. Defaulting to gray.", colorStr, _downloadURL);
            _textColor = [UIColor grayColor];
        }
        [_textColor TP_RETAIN];

        NSNumber *exitButtonDelay = [params objectForKey:@"exitButtonDelay"];
        if ((exitButtonDelay != nil) && ([exitButtonDelay intValue] >= 0)) {
            _isShowExitButton = YES;
            _exitButtonDelay = [exitButtonDelay intValue];
        } else {
            _isShowExitButton = NO;
        }

        _isShowCountdown = (([params objectForKey:@"isShowCountdown"] != nil) && ([[params objectForKey:@"isShowCountdown"] intValue] == 1));
        if (_isShowCountdown) {
            // Assign the countdown text format.
            NSString *countdownText = [params objectForKey:@"countdownText"];
            if ((countdownText != nil) && ([countdownText length] > 0)) {
                _countdownText = countdownText;
            } else {
                NSString *defaultFormat = @"%time%s";
                TPLog(@"Countdown text format was not supplied for video %@. Defaulting to: %@", _downloadURL, defaultFormat);
                _countdownText = defaultFormat;
            }
            [_countdownText TP_RETAIN];
        }
    }
    return self;
}

- (void)dealloc {
    [_downloadURL TP_RELEASE];
    [_countdownLabel TP_RELEASE];
    [_countdownTimer invalidate];
    [_countdownTimer TP_RELEASE];
    [_countdownText TP_RELEASE];
    [_textColor TP_RELEASE];
    [_exitButtonLabel TP_RELEASE];
    [_exitButton TP_RELEASE];
    [super TP_DEALLOC];
}

#pragma mark - Overridden methods

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [[TpVideo sharedInstance] hideStatusBar];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    // Log the offer impression.
    [[TpVideo sharedInstance] fireImpressionForURL:_downloadURL];
    // Create the session, user, and click.
    [[TpVideo sharedInstance] fireClickForURL:_downloadURL];

    // Fire the countdown function once now, then create a timer to call it every second afterwards.
    _videoTimeRemaining = VIDEO_TIME_REMAINING_UNITIALIZED;
    [self countdown];
    // Create the timer.
    _countdownTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdown) userInfo:nil repeats:YES] TP_RETAIN];
    [[NSRunLoop mainRunLoop] addTimer:_countdownTimer forMode:NSRunLoopCommonModes];

    // Remove the default observation of the video finish event - we don't want the view view controller to automatically dismiss itself.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    // Use our own notification listener for video completion.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleVideoFinish:) name:@"MPMoviePlayerPlaybackDidFinishNotification" object:self.moviePlayer];
    [super viewDidAppear:animated];
}

#pragma mark - Video Completion methods

- (void)exitVideoEarly:(UIGestureRecognizer *)gestureRecognizer {
    // Stop the video. This will fire the MPMoviePlayerPlaybackDidFinishNotification notification, which will send the handleVideoFinish: message.
    [self.moviePlayer stop];
}

- (void)handleVideoFinish:(NSNotification *)notification {
    [_countdownTimer invalidate];
    if (_videoTimeRemaining <= 0) {
        // We should have fired the completion by now. Make sure it's been fired.
        [[TpVideo sharedInstance] fireCompletionIfNotFiredForURL:_downloadURL];
    }
    // Open the endcap webview.
    [[TpVideo sharedInstance] openEndcap:_downloadURL];
}

@end
