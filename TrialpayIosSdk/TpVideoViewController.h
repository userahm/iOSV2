//
//  TpVideoViewController.h
//
//  Created by Trialpay Inc.
//  Copyright (c) 2014 TrialPay, Inc. All Rights Reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MPMoviePlayerController.h>

@interface TpVideoViewController : MPMoviePlayerViewController
- (id)initWithContentURL:(NSURL *)URL andParams:(NSDictionary *)params;
- (void)showDownloadNowButton;
@end
