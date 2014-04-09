//
//  TpAppStoreViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2014 TrialPay, Inc. All Rights Reserved.
//

#import "TpAppStoreViewController.h"

@implementation TpAppStoreViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    // In iOS 6 the app store displays oddly in landscape mode. But the app store doesn't load at all if it first appears in
    // an orientation different from the previous views. To prevent that problem we restrict the orientation to be the same
    // as previous views (i.e. landscape).
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

@end
