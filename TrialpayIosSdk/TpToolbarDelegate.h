//
// Created by Daniel Togni on 10/15/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

@protocol TpToolbarDelegate <NSObject>
- (void)navClose:(NSURL *)url;
- (void)navUp:(NSURL *)url;
- (void)navBack:(NSURL *)url;
- (void)navReload:(NSURL *)url;
- (void)navRefresh:(NSURL *)url;
- (void)navOfferwall:(NSURL *)url;
- (void)navOffer:(NSURL *)url;
- (void)navChangeHeaderHeight:(NSURL *)url;
@end
