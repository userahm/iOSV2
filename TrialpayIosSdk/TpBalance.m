//
//  TpBalance.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import "TpBalance.h"
#import "TpConstants.h"
#import "TpUrlManager.h"
#import "TpUtils.h"
#import "TpSdkConstants.h"
#import "TpArcSupport.h"

@implementation TpBalance

/**
 initWithVic: <NSString> sid: <NSString>
 Initializes the TrialPay balance class with vic (vendor integration code - provided by your AM) and 
 sid (User identifier on your system)
 
 return: Initialized TpBalance object with preset vic and sid.
 **/
- (TpBalance *)initWithVic:(NSString *)vic sid:(NSString *)sid {
    self = [super init];
    
    if (self) {
        _sid = [sid TP_RETAIN];
        _vic = [vic TP_RETAIN];
    }
    
    return self;
}

- (void)dealloc {
    [_sid TP_RELEASE];
    [_vic TP_RELEASE];
    [_lastQueryInfo TP_RELEASE];
    [super TP_DEALLOC];
}

static NSError *__lastError;
+(NSError*)consumeLastError {
    NSError *ret = __lastError;
    __lastError = nil;
    TPLog(@"consuming %@", ret);
    return ret;
}

/**
 queryBalanceInfo
 Pings the TrialPay Balance API to retrieve current balance for the vic and sid that
 the class is initialized with
 
 return: 
    success: NSDictionary with at the very least entry 'balance' of type NSNumber
    failure: nil
 **/
 
- (NSDictionary *)queryBalanceInfo {
    NSDictionary *balanceInfo = nil;
    double currentTime = [[NSDate date] timeIntervalSince1970];

#if defined(__TRIALPAY_USE_EXCEPTIONS)
    @try {
#endif
        // Check to see if we are in the valid timeframe
        if (_lastQueryTime != 0 && _timeoutInSeconds != 0 && currentTime - _lastQueryTime < _timeoutInSeconds) {
            balanceInfo = [NSDictionary dictionaryWithDictionary:_lastQueryInfo];
            return balanceInfo;
        }

        NSString* balanceEndpoint = [TpUrlManager balancePathWithVic:_vic andSid:_sid];
        TPLog(@"balanceEndpoint = %@",balanceEndpoint);

        NSError *downloadError = nil;
        NSData* endpointResponseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:balanceEndpoint] options:NSDataReadingMappedIfSafe error:&downloadError];
        if (downloadError) {
            TPCustomerError(@"TrialPay API Balance Query Error", @"TrialPay API Balance Query Error: %@", downloadError);
            __lastError = downloadError;
            return nil;
        }
        NSError* decodeError = nil;

        NSNumber *queriedBalance = nil;
        NSNumber *queriedSecondsValid = nil;

        if (endpointResponseData != nil) {
            balanceInfo = [NSJSONSerialization
                    JSONObjectWithData:endpointResponseData
                               options:NSJSONReadingMutableContainers
                                 error:&decodeError];

            queriedBalance = [balanceInfo objectForKey:kTPKeyBalance];
            queriedSecondsValid = [balanceInfo objectForKey:@"seconds_valid"];

            if (decodeError != nil) {
                TPCustomerError(@"TrialPay API Balance Query Error", @"TrialPay API Balance Query Error: %@", decodeError);
                __lastError = decodeError;
                return nil;
            }

            if (queriedBalance == nil) {
                TPCustomerLog(@"Balance not returned from TrialPay API", @"Balance not returned from TrialPay API");
                __lastError = [NSError errorWithDomain:@"TrialpayBalanceAPI" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Balance not returned from TrialPay API", @"Balance not returned from TrialPay API"), NSLocalizedDescriptionKey, nil]];
                return nil;
            }

            _lastQueryInfo = [[NSMutableDictionary dictionaryWithDictionary: balanceInfo] TP_RETAIN];
            _timeoutInSeconds = [queriedSecondsValid doubleValue];
            _lastQueryTime = currentTime;

        } else {
            TPCustomerError(@"Trialpay Balance API did not return balance data: Please verify setup and parameters are correct", @"Trialpay Balance API did not return balance data: Please verify setup and parameters are correct");
            __lastError = [NSError errorWithDomain:@"TrialpayBalanceAPI" code:2 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Trialpay Balance API did not return balance data: Please verify setup and parameters are correct", @"Trialpay Balance API did not return balance data: Please verify setup and parameters are correct"), NSLocalizedDescriptionKey, nil]];
            return nil;
        }
#if defined(__TRIALPAY_USE_EXCEPTIONS)
    } @catch (NSException *exception) {
#if DEBUG
        TPLog(@"%@\n%@", exception, [exception callStackSymbols]);
#endif
        TPCustomerError(@"Trialpay Balance API executed with errors: {}", @"Trialpay Balance API executed with errors: %@", exception);
        __lastError = [NSError errorWithDomain:@"TrialpayBalanceAPI" code:3 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:exception.description, NSLocalizedDescriptionKey, nil]];
        return nil;
    }
#endif
    return balanceInfo;
}

/**
 acknowledgeBalance
 Pings the TrialPay Balance API in acknowledgement mode with the vic and sid with which the class was initialized.
 parameters:
    NSDictionary balanceInfo: The NSDictionary returned from queryBalanceInfo. This will contain at the very least a key 'balance' with NSNumber Type
 
 return:
    BOOL: True if successful, false otherwise
 **/

-(BOOL) acknowledgeBalanceInfo:(NSDictionary *)balanceInfo {
    NSNumber* balance = [balanceInfo objectForKey:kTPKeyBalance];

#if defined(__TRIALPAY_USE_EXCEPTIONS)
    @try {
#endif
        // If the ack is happening with 0 balance, just automatically return true
        if ([balance intValue] == 0) {
            return true;
        }

        NSString *acknowledgeEndpoint = [TpUrlManager balancePathWithVic:_vic andSid:_sid usingBalanceInfo:balanceInfo];
        NSError* ackError;
        NSString* ackResponseString = [NSString stringWithContentsOfURL:[NSURL URLWithString:acknowledgeEndpoint] encoding:NSUTF8StringEncoding error:&ackError];
        
        if (ackResponseString == nil) {
            TPCustomerError(@"Trialpay Ack Balance API error: Please verify your account setup and parameters", @"Trialpay Ack Balance API error: Please verify your account setup and parameters");
            _timeoutInSeconds = 0;
            return false;
        }
        
        if ([ackResponseString isEqualToString:@"1"]) {
            [_lastQueryInfo setObject: [NSNumber numberWithInt:0] forKey:kTPKeyBalance];
            return true;
        }
        _timeoutInSeconds = 0;
#if defined(__TRIALPAY_USE_EXCEPTIONS)
    } @catch (NSException *exception) {
#if DEBUG
        TPLog(@"%@\n%@", exception, [exception callStackSymbols]);
#endif
        TPCustomerError(@"Trialpay Balance API executed with errors: {}", @"Trialpay Balance API executed with errors: %@", exception);
        __lastError = [NSError errorWithDomain:@"TrialpayBalanceAPI" code:3 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:exception.description, NSLocalizedDescriptionKey, nil]];
        return false;
    }
#endif
    return false;
}

@end
