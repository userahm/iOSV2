//  Copyright (C) 2013 TrialPay, Inc All Rights Reserved
//
//  TpBalance.h
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
#import <Foundation/Foundation.h>
#import "BaseTrialpayManager.h"

@interface TpBalance : NSObject {
    @private
        NSString *_sid;
        NSString *_vic;
        NSMutableDictionary *_lastQueryInfo;
        double _lastQueryTime;
        double _timeoutInSeconds;
}

-(TpBalance*) initWithVic: (NSString*) vic sid: (NSString*) sid ;
-(void) setSid: (NSString*) sid;
-(void) setVic: (NSString*) vic;
-(NSDictionary*) queryBalanceInfo;
-(Boolean) acknowledgeBalanceInfo: (NSDictionary*) balanceInfo;

@end
