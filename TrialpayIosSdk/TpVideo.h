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

- (void)initializeVideoWithParams:(NSDictionary *)params;
- (BOOL)isResourceReady:(NSString *)downloadURL;
- (NSArray *)getAllStoredVideoOffers;

- (void)fireImpressionForURL:(NSString *)downloadURL;
- (void)fireClickForURL:(NSString *)downloadURL;
- (void)fireCompletionIfNotFiredForURL:(NSString *)downloadURL;
- (void)firePingsForDownloadNowButtonClickForVideo:(NSString *)downloadURL;

- (void)hideStatusBar;

- (void)playVideoWithURL:(NSString *)downloadURL fromViewController:(UIViewController *)baseViewController withBlock:(void (^)(void))completionBlock;
- (void)openEndcap:(NSString *)downloadURL;
- (void)openAppStoreFrom:(NSString *)viewControllerDescriptor;
- (void)closeTrailerFlow;

@end
