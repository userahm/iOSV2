//
//  TpVideoViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2014 TrialPay, Inc. All Rights Reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "TpVideoViewController.h"
#import "BaseTrialpayManager.h"
#import "TpVideo.h"
#import "TpArcSupport.h"
#import "TpUtils.h"

@implementation TpVideoViewController {
    NSString *_downloadURL;
    NSTimer *_countdownTimer;
    int _duration;
    int _videoTimeRemaining;
    int _completionTime;;
    UIColor *_textColor;
    NSString *_nextStep;
    BOOL _didVideoAppear;
    // The following properties control the exit button
    UIButton *_exitButton;
    UILabel *_exitButtonLabel;
    BOOL _isShowExitButton;
    int _exitButtonDelay;
    // The following properties control the countdown text
    UILabel *_countdownLabel;
    BOOL _isShowCountdown;
    NSString *_countdownText;
    // The following properties control the download now button
    UIButton *_downloadNowButton;
    NSString *_downloadNowText;
    UIColor *_downloadNowTextColor;
    UIColor *_downloadNowBackgroundColor;
    UIColor *_downloadNowBorderColor;
}

int VIDEO_TIME_REMAINING_UNITIALIZED = -10;

#pragma mark - Countdown Label, Exit Button, and Download Now Button

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
    if (_downloadNowButton != nil) {
        // Shorten the text width by the width of the download now button. The download button appears in the lower right, the countdown
        // text appears in the lower left, and we don't want them to overlap.
        // Also subtract the width take by the button shadow, which is not accounted for in the button width.
        textWidth -= (_downloadNowButton.frame.size.width + kTpDownloadNowButtonShadowRadius * 2);
    }
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

- (CGRect)getDownloadNowButtonRectForFont:(UIFont *)font {
    CGSize viewFrameSize = [self getVideoViewFrameSize];
    struct TpVideoBorders videoBorders = [self getVideoBorders];

    // Get the basic size of the text.
    CGSize textSize;
    if ([_downloadNowText respondsToSelector:@selector(sizeWithAttributes:)]) { // Only available in iOS 7.0 and up.
        textSize = [_downloadNowText sizeWithAttributes:@{ NSFontAttributeName : font }];
    } else {
        textSize = [_downloadNowText sizeWithFont:font]; // Deprecated as of iOS 7.0.
    }

    // Get the size of the button interior by adding padding to the text.
    // Note that the shadow extends beyond the button dimensions.
    float horizontalPadding = 10.0f;
    float verticalPadding = 6.0f;
    float buttonWidth = textSize.width + horizontalPadding;
    float buttonHeight = textSize.height + verticalPadding;

    // Calculate the rectangle. The button will be located in the lower right of the video.
    CGRect buttonRect = CGRectMake(viewFrameSize.width - (videoBorders.horizontal + buttonWidth + kTpDownloadNowButtonShadowRadius),
                                   viewFrameSize.height - (videoBorders.vertical + buttonHeight + kTpDownloadNowButtonShadowRadius),
                                   buttonWidth,
                                   buttonHeight);
    return buttonRect;
}

// This is called from TpVideo once we have the endcap click id (which we need to pass to the tracking partner to track installation).
- (void)showDownloadNowButton {
    if (_downloadNowButton != nil) {
        // It should never happen that we call this twice, but check for it since this function is called from outside the class.
        return;
    }
    // Set configuration values that will be used in several places.
    float buttonOpacity = 0.8f;
    float fontSize = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? 20.0f : 10.0f); // Use a larger font on iPad.
    UIFont *titleFont = [UIFont fontWithName:@"Arial" size:fontSize];

    // Configure button basics.
    _downloadNowButton = [[UIButton buttonWithType:UIButtonTypeCustom] TP_RETAIN];
    _downloadNowButton.frame = [self getDownloadNowButtonRectForFont:titleFont];
    _downloadNowButton.layer.opacity = buttonOpacity;
    [_downloadNowButton setBackgroundColor:_downloadNowBackgroundColor];

    // Configure the button text.
    [_downloadNowButton setTitle:_downloadNowText forState:UIControlStateNormal];
    [_downloadNowButton setTitleColor:_downloadNowTextColor forState:UIControlStateNormal];
    _downloadNowButton.titleLabel.font = titleFont;
    _downloadNowButton.contentEdgeInsets = UIEdgeInsetsMake(2.0f, 0.0f, 0.0f, 0.0f); // Button text is more centered if we move it down a little.

    // Configure the button outline.
    _downloadNowButton.layer.borderWidth = 1.0f;
    _downloadNowButton.layer.borderColor = _downloadNowBorderColor.CGColor;

    // Configure the button shadow.
    _downloadNowButton.layer.masksToBounds = NO; // Necessary so that the shadow doesn't get cut off.
    _downloadNowButton.layer.shadowColor = _downloadNowBorderColor.CGColor;
    _downloadNowButton.layer.shadowRadius = kTpDownloadNowButtonShadowRadius;
    _downloadNowButton.layer.shadowOpacity = buttonOpacity;
    _downloadNowButton.layer.shadowOffset = CGSizeMake(0.0f, 0.0f); // We want the shadow to be centered on the button.
    // We explicity set the path for the shadow. This is the default path, but setting it explicitly helps rendering performance.
    // (We haven't encountered performance problems but want to play it safe.)
    CGPathRef path = CGPathCreateWithRect(CGRectMake(0, 0, _downloadNowButton.frame.size.width, _downloadNowButton.frame.size.height), NULL);
    _downloadNowButton.layer.shadowPath = path;
    CGPathRelease(path);

    // Assign the gesture recognizer.
    UITapGestureRecognizer *buttonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(earlyExitToAppStore:)];
    [_downloadNowButton addGestureRecognizer:buttonTapRecognizer];
    [buttonTapRecognizer TP_RELEASE];

    // Recalculate the size of the countdown text, if it exists.
    [self resizeCountdownText];

    [self.view addSubview:_downloadNowButton];
}

- (void)showCountdownText {
    _countdownLabel = [[UILabel alloc] initWithFrame:[self getCountdownLabelRect]];
    _countdownLabel.text = [self generateCountdownText];
    _countdownLabel.font = [UIFont fontWithName:@"Helvetica" size:18.0f];
    _countdownLabel.textColor = _textColor;
    _countdownLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_countdownLabel];
}

// Recalculate the placement rectangle for the countdown text.
// We'll want to do this after drawing the download now button,
// because the presence of the download now button can reduces
// the size of the countdown text (so that they don't overlap).
- (void)resizeCountdownText {
    if (_countdownLabel != nil) {
        _countdownLabel.frame = [self getCountdownLabelRect];
        [_countdownLabel setNeedsDisplay];
    }
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
    UITapGestureRecognizer *buttonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(earlyExitToEndcap:)];
    [_exitButton addGestureRecognizer:buttonTapRecognizer];
    [buttonTapRecognizer TP_RELEASE];

    [self.view addSubview:_exitButton];
    [self.view addSubview:_exitButtonLabel];
}

#pragma mark - Counter

// Runs every second
- (void)countdown {
    if (_videoTimeRemaining == VIDEO_TIME_REMAINING_UNITIALIZED) {
        // Confirm that the moviePlayer is fully initialized. We need this information for placing
        // display elements, as well as getting the duration information for old video offers.
        if ((self.moviePlayer == nil) || (self.moviePlayer.duration <= 0) ||
            (self.moviePlayer.naturalSize.width <= 0) || (self.moviePlayer.naturalSize.height <= 0)) {
            // Do nothing for now (we'll check again the next time we run this timer).
            TPLog(@"moviePlayer is still being initialized - returning from countdown early");
            return;
        } else {
            if (_duration <= 0) {
                // Video was set up before we required this information. Try to read it from the file.
                _duration = (int)self.moviePlayer.duration;
            }
            _videoTimeRemaining = _duration;
        }
    } else {
        _videoTimeRemaining--;
    }
    if (_videoTimeRemaining <= 0) {
        [_countdownTimer invalidate];
    }

    // Completion firing. Confirm that we're at least 5 seconds into the video, so that the click API request has time to complete.
    if ((_duration - _videoTimeRemaining) >= 5) {
        if (_completionTime >= 0) {
            // complete at X seconds from the start of the video
            if ((_duration - _videoTimeRemaining) >= _completionTime) {
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
            if ((_duration - _videoTimeRemaining) >= _exitButtonDelay) {
               [self showExitButton];
            }
        }
    }
}

#pragma mark - Init & Dealloc

// Initialize the view controller.
// Params:
//  - NSString *downloadURL - The resource URL from which we download the video. used for identification.
//  - NSNumber *duration - The duration, in seconds, of the app trailer video.
//  - NSString *textColor - UIColor name for countdown text and exit button. e.g. 'blackColor', 'lightGrayColor', etc
//  - NSNumber *completionTime - number of seconds until we fire the completion. Negative values are calculated from the end of the video. (e.g. -3 means 3 seconds from the end)
//  - NSNumber *exitButtonDelay - number of seconds until we show the exit button. A value of -1 means the button is never shown.
//  - NSNumber *isShowCountdown - Whether to display countdown text.
//  - NSString *countdownText - Text format for displaying countdown. The placeholder "%time%" will be replaced by the integer countdown.
//  - NSString *downloadNowText - The text to display in the download now button. For example, "Download Now!".
//  - NSString *downloadNowTextColor - The color of the text in the download now button.
//  - NSString *downloadNowBackgroundColor - The color of the background for the download now button.
//  - NSString *downloadNowBorderColor - The color of the border for the download now button.
- (id)initWithContentURL:(NSURL *)URL andParams:(NSDictionary *)params {
    if ((self = [super initWithContentURL:URL])) {
        // The video should have already been downloaded to the device, but we use this URL for referencing the video.
        _downloadURL = [[params objectForKey:@"downloadURL"] TP_RETAIN];

        // Get the duration of the video.
        _duration = [[params objectForKey:@"duration"] intValue];

        // Determine the time at which we should fire the video completion.
        NSNumber *completionTime = [params objectForKey:@"completionTime"];
        if (completionTime != nil) {
            _completionTime = [completionTime intValue];
        } else {
            _completionTime = -2;
        }

        // Grab the color params. Check that we've been passed valid color names, otherwise use defaults.
        // A mapping from color param names to the color value. We'll overwrite these defaults if the passed value is valid.
        // (Note that dictionaryWithObjectsAndKeys: lists objects before their keys.)
        NSMutableDictionary *colorParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                @"grayColor",  @"textColor",
                                                                @"whiteColor", @"downloadNowTextColor",
                                                                @"blackColor", @"downloadNowBackgroundColor",
                                                                @"whiteColor", @"downloadNowBorderColor",
                                                                nil];
        for (NSString *paramName in [colorParams allKeys]) {
            NSString *paramValue = [params objectForKey:paramName];
            if ((paramValue != nil) && [UIColor respondsToSelector:NSSelectorFromString(paramValue)]) {
                // Overwrite the default value in the colorParams dictionary.
                [colorParams setValue:paramValue forKey:paramName];
            } else {
                TPLog(@"Invalid %@ value (%@) was provided for video %@. Defaulting to %@.", paramName, paramValue, _downloadURL, [colorParams objectForKey:paramName]);
            }
        }
        // Set the final colors
        _textColor = [[UIColor performSelector:NSSelectorFromString([colorParams objectForKey:@"textColor"])] TP_RETAIN];
        _downloadNowTextColor = [[UIColor performSelector:NSSelectorFromString([colorParams objectForKey:@"downloadNowTextColor"])] TP_RETAIN];
        _downloadNowBackgroundColor = [[UIColor performSelector:NSSelectorFromString([colorParams objectForKey:@"downloadNowBackgroundColor"])] TP_RETAIN];
        _downloadNowBorderColor = [[UIColor performSelector:NSSelectorFromString([colorParams objectForKey:@"downloadNowBorderColor"])] TP_RETAIN];

        // Look at the exitButtonDelay to decide if and when to show the exit early button.
        NSNumber *exitButtonDelay = [params objectForKey:@"exitButtonDelay"];
        if ((exitButtonDelay != nil) && ([exitButtonDelay intValue] >= 0)) {
            _isShowExitButton = YES;
            _exitButtonDelay = [exitButtonDelay intValue];
        } else {
            _isShowExitButton = NO;
        }

        // Grab parameters for the countdown text. First check if we should show the text at all.
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

        // Grab the text for the download now button, even if this offer won't show the button.
        NSString *downloadNowText = [params objectForKey:@"downloadNowText"];
        if ((downloadNowText != nil) && ([downloadNowText length] > 0)) {
            _downloadNowText = downloadNowText;
        } else {
            // This is expected IFF the offer is not set to show the download now button, but we should be fine in either case.
            _downloadNowText = @"Download Now!";
        }
        [_downloadNowText TP_RETAIN];

        // Track whether we ever show the video. We use this to perform proper bookkeeping when the video ends or fails.
        _didVideoAppear = NO;

        // Remove the default observation of the video finish event - we don't want the video view controller to automatically dismiss itself.
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
        // Use our own notification listener for video completion.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleVideoFinish:) name:@"MPMoviePlayerPlaybackDidFinishNotification" object:self.moviePlayer];
    }
    return self;
}

- (void)dealloc {
    [_downloadURL TP_RELEASE];
    [_nextStep TP_RELEASE];
    [_countdownTimer invalidate];
    [_countdownTimer TP_RELEASE];

    [_countdownLabel TP_RELEASE];
    [_countdownText TP_RELEASE];

    [_downloadNowButton TP_RELEASE];
    [_downloadNowText TP_RELEASE];

    [_textColor TP_RELEASE];
    [_downloadNowTextColor TP_RELEASE];
    [_downloadNowBackgroundColor TP_RELEASE];
    [_downloadNowBorderColor TP_RELEASE];

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
    // Bookkeeping to allow proper handling of video finish or error.
    _didVideoAppear = YES;

    // Log the offer impression.
    [[TpVideo sharedInstance] fireImpressionForURL:_downloadURL];
    // Create the session, user, and click.
    [[TpVideo sharedInstance] fireClickForURL:_downloadURL];
    // Create the click for the endcap offer.
    [[TpVideo sharedInstance] createEndcapClickForURL:_downloadURL];

    // Fire the countdown function once now, then create a timer to call it every second afterwards.
    _videoTimeRemaining = VIDEO_TIME_REMAINING_UNITIALIZED;
    [self countdown];
    // Create the timer.
    _countdownTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdown) userInfo:nil repeats:YES] TP_RETAIN];
    [[NSRunLoop mainRunLoop] addTimer:_countdownTimer forMode:NSRunLoopCommonModes];

    // By default, open the endcap interstitial webview when the video ends.
    // (If the user presses the download now button, we'll set this to "appStore" before stopping the video.)
    _nextStep = @"endcap";

    [super viewDidAppear:animated];
}

#pragma mark - Video Completion methods

- (void)earlyExitToEndcap:(UIGestureRecognizer *)gestureRecognizer {
    _nextStep = @"endcap"; // This is redundant because "endcap" is the default, but set it just in case.
    // Stop the video. This will fire the MPMoviePlayerPlaybackDidFinishNotification notification, which will send the handleVideoFinish: message.
    [self.moviePlayer stop];
}

- (void)earlyExitToAppStore:(UIGestureRecognizer *)gestureRecognizer {
    _nextStep = @"appStore";
    // Stop the video. This will fire the MPMoviePlayerPlaybackDidFinishNotification notification, which will send the handleVideoFinish: message.
    [self.moviePlayer stop];
    // Fire necessary pings (e.g. pass click id to tracking partner, record the button tap event on our server, etc)
    [[TpVideo sharedInstance] firePingsForDownloadNowButtonClickForVideo:_downloadURL];
}

- (void)handleVideoFinish:(NSNotification *)notification {
    if (_didVideoAppear) {
        [_countdownTimer invalidate];
        if (_videoTimeRemaining <= 0) {
            // We should have fired the completion by now. Make sure it's been fired.
            [[TpVideo sharedInstance] fireCompletionIfNotFiredForURL:_downloadURL];
        }
        // Move to the next step in our flow.
        if ([_nextStep isEqualToString:@"appStore"]) {
            // Open the app store directly.
            [[TpVideo sharedInstance] openAppStoreFrom:@"video"];
        } else {
            // Open the endcap webview.
            [[TpVideo sharedInstance] openEndcap:_downloadURL];
        }
    } else {
        // The video finished without ever opening, which is probably because of an invalid video file.
        TPLog(@"Video ended before it was ever displayed - video file is probably invalid and will be marked as such.");
        // Mark the video file as invalid.
        [[TpVideo sharedInstance] markVideoFileInvalid:_downloadURL];
        // Close the video trailer flow. Don't dismiss the view controller; because we never presented the video
        // controller, the dismiss call would dismiss the topmost controller instead.
        [[TpVideo sharedInstance] closeTrailerFlowAndDismissViewController:NO];
    }
}

@end
