//
//  TpVideo.h
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//


#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface TpVideo : NSObject <UIWebViewDelegate, SKStoreProductViewControllerDelegate>
+ (TpVideo *)sharedInstance;

- (void)pruneVideoStorage;

- (void)initializeVideo:(NSString *)downloadURL withParams:(NSDictionary *)params;
- (BOOL)isResourceReady:(NSString *)downloadURL;

- (void)fireImpressionForURL:(NSString *)downloadURL;
- (void)fireClickForURL:(NSString *)downloadURL;
- (void)fireCompletionIfNotFiredForURL:(NSString *)downloadURL;

- (void)hideStatusBar;

- (void)playVideoWithURL:(NSString *)downloadURL;
- (void)openEndcap:(NSString *)downloadURL;
- (void)openAppStore;

@end
