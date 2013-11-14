//
//  TpBalance.h
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//
//  Wrapper class for TrialPay Balance API calls
//

#import <Foundation/Foundation.h>

@interface TpBalance : NSObject {
    @private
        NSMutableDictionary *_lastQueryInfo;
        double _lastQueryTime;
        double _timeoutInSeconds;
}

@property (nonatomic, strong, readonly) NSString *sid;
@property (nonatomic, strong, readonly) NSString *vic;

- (TpBalance *)initWithVic:(NSString *)vic sid:(NSString *)sid;
- (NSDictionary *)queryBalanceInfo;
- (BOOL)acknowledgeBalanceInfo:(NSDictionary *)balanceInfo;

+(NSError*)consumeLastError;

@end
