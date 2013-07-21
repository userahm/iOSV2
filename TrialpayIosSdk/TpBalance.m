//  Copyright (C) 2013 TrialPay, Inc All Rights Reserved
//
//  TpBalance.m
//
//  Wrapper class for TrialPay Balance API calls
//
//  Recommended usage (Please note, we recommend Steps 2 and 3 be performed asynchronously):
//  (1) Instantiate a TpBalance object with your specific vic + sid combination on
//      view load or on app load (whenever the user wants to see their balance) by calling
//      initWithVic:...sid:...
//  (2) When you want to retrieve the latest balance, make a call to [TpBalance queryBalanceInfo]
//      and store the information returned
//  (3) Acknowledge to the TrialPay servers with the values returned from the call to queryBalanceInfo
//      by calling [TpBalance acknowledgeBalanceInfo:....]
//
//  Sample.m
// - (void)viewDidLoad {
//     ...
//     myTrialpaySampleObject = [[TpBalance alloc] initWithVic:<Your VIC as provided by your AM> sid:<Current User identifier>];
//     ...
//   }
//  ...
//
// - (void)balanceQueryAndWithdraw {
//     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//       NSDictionary *latestBalanceInfo = [myTrialpaySampleObject queryBalanceInfo];
//
//       NSNumber* differentialBalance = [latestBalanceInfo objectForKey:@"balance"];
//
//       Boolean ackSuccess = [myTrialpaySampleObject acknowledgeBalanceInfo: latestBalanceInfo];
//
//       if (ackSuccess) {
//         // Increment the user credits balance here by amount differentialBalance and update the display (You can update display by using performSelectorOnMainThread)
//       }
//    });
//
// }
//
//

#import "TpBalance.h"

#ifdef DEBUG
#define NSDLog(FORMAT, ...) fprintf(stderr,"[TpBalance] %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSDLog(...)
#endif

@implementation TpBalance

/**
 initWithVic: <NSString> sid: <NSString>
 Initializes the TrialPay balance class with vic (vendor integration code - provided by your AM) and 
 sid (User identifier on your system)
 
 return: Initialized TpBalance object with preset vic and sid.
 **/
-(TpBalance*) initWithVic: (NSString*) vic sid: (NSString*) sid {
    self = [super init];
    
    if (self) {
        [self setSid: sid];
        [self setVic: vic];
    }
    
    return self;
}

-(void) setSid: (NSString*) sid {
    _sid = sid;
}

-(void) setVic: (NSString*) vic {
    _vic = vic;
}

/**
 queryBalanceInfo
 Pings the TrialPay Balance API to retrieve current balance for the vic and sid that
 the class is initialized with
 
 return: 
    success: NSDictionary with at the very least entry 'balance' of type NSNumber
    failure: nil
 **/
 
-(NSDictionary*) queryBalanceInfo {
    NSDictionary* balanceInfo = nil;
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    // Check to see if we are in the valid timeframe
    if (_lastQueryTime != 0 && _timeoutInSeconds != 0 && currentTime - _lastQueryTime < _timeoutInSeconds) {
        balanceInfo = [NSDictionary dictionaryWithDictionary:_lastQueryInfo];
        return balanceInfo;
    }
    
    NSString* balanceEndpoint = [NSString stringWithFormat:@"%@?vic=%@&sid=%@", [TpUtils getBalancePath], _vic, _sid];
    NSDLog(@"balanceEndpoint = %@",balanceEndpoint);
    NSData* endpointResponseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:balanceEndpoint]];
    
    NSError* decodeError = nil;
    
    NSNumber *queriedBalance = nil;
    NSNumber *queriedSecondsValid = nil;
    
    if (endpointResponseData != nil) {
       balanceInfo = [NSJSONSerialization
                              JSONObjectWithData:endpointResponseData
                              options:kNilOptions
                              error:&decodeError];
        
        queriedBalance = [balanceInfo objectForKey:@"balance"];
        queriedSecondsValid = [balanceInfo objectForKey:@"seconds_valid"];
        
        if (decodeError != nil) {
            NSLog(@"TrialPay API Balance Query Error: %@", decodeError);
            return nil;
        }
        
        if (queriedBalance == nil) {
            NSLog (@"Balance not returned from TrialPay API");
            return nil;
        }
                
        _lastQueryInfo = [NSMutableDictionary dictionaryWithDictionary: balanceInfo];
        _timeoutInSeconds = [queriedSecondsValid doubleValue];
        _lastQueryTime = currentTime;
        
    } else {
        NSLog (@"Trialpay Balance API did not return balance data: Please verify setup and parameters are correct");
        return nil;
    }
    
    return balanceInfo;
}

/**
 acknowledgeBalance
 Pings the TrialPay Balance API in acknowledgement mode with the vic and sid with which the class was initialized.
 parameters:
    NSDictionary balanceInfo: The NSDictionary returned from queryBalanceInfo. This will contain at the very least a key 'balance' with NSNumber Type
 
 return:
    boolean: True if successful, false otherwise
 **/

-(Boolean) acknowledgeBalanceInfo:(NSDictionary *)balanceInfo {
    NSNumber* balance = [balanceInfo objectForKey:@"balance"];
    
    // If the ack is happening with 0 balance, just automatically return true
    if ([balance intValue] == 0) {
        return true;
    }
    
    NSString *acknowledgeEndpoint = [NSString stringWithFormat:@"%@?vic=%@&sid=%@", [TpUtils getBalancePath], _vic, _sid];
    NSDLog(@"balanceEndpoint = %@",acknowledgeEndpoint);
    for (id key in balanceInfo) {
        id value = [balanceInfo objectForKey: key];
        acknowledgeEndpoint = [NSString stringWithFormat:@"%@&%@=%@", acknowledgeEndpoint, key, value];
    }
    
    NSError* ackError;

    NSString* ackResponseString = [NSString stringWithContentsOfURL:[NSURL URLWithString:acknowledgeEndpoint] encoding:NSUTF8StringEncoding error:&ackError];
    
    if (ackResponseString == nil) {
        NSLog(@"Trialpay Ack Balance API error: Please verify your account setup and parameters");
        _timeoutInSeconds = 0;
        return false;
    }
    
    if ([ackResponseString isEqualToString:@"1"]) {
        [_lastQueryInfo setObject: [NSNumber numberWithInt:0] forKey:@"balance"];
        return true;
    }
    _timeoutInSeconds = 0;
    return false;
}

@end
