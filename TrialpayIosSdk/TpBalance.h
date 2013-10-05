//  Copyright (C) 2013 TrialPay, Inc All Rights Reserved
//
//  TpBalance.h
//
//  Wrapper class for TrialPay Balance API calls
//
#import <Foundation/Foundation.h>

@interface TpBalance : NSObject {
    @private
        NSString *_sid;
        NSString *_vic;
        NSMutableDictionary *_lastQueryInfo;
        double _lastQueryTime;
        double _timeoutInSeconds;
}

- (TpBalance *)initWithVic:(NSString *)vic sid:(NSString *) sid;
- (void)setSid:(NSString *)sid;
- (void)setVic:(NSString *)vic;
- (NSDictionary *)queryBalanceInfo;
- (BOOL)acknowledgeBalanceInfo:(NSDictionary *)balanceInfo;

+(NSError*)consumeLastError;

@end
