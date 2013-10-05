//  Copyright (C) 2013 TrialPay, Inc All Rights Reserved
//
//  TrialpayManager.m
//

#import "TrialpayManager.h"

@implementation TrialpayManager

static TrialpayManager *__trialpayManagerInstance;

#pragma mark - getInstance
+ (TrialpayManager *)getInstance {
    TPLogEnter;
    if (!__trialpayManagerInstance) {
        __trialpayManagerInstance = [[TrialpayManager alloc] init];
    }
    return __trialpayManagerInstance;
}

#pragma mark - Get SDK Version
+ (NSString*) sdkVersion {
    return [NSString stringWithFormat:@"base.%@", [super sdkVersion]];
}


@end
