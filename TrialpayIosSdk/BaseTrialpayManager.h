#import <Foundation/Foundation.h>
#import "TpUtils.h"
#import "TpOfferwallViewController.h"
#import "TpBalance.h"

@class BaseTrialpayManager;

@protocol TrialpayManagerDelegate
- (void)TrialpayManager:(BaseTrialpayManager *)trialpayManager handleMessage:(NSString *)message;
@end

@interface BaseTrialpayManager : NSObject <TpOfferwallViewControllerDelegate>

+ (BaseTrialpayManager*)getInstance;
+ (void)setInstance:(BaseTrialpayManager*)instance;
- (NSString*) getSdkVer;

- (void) setSid:(NSString *)sid;
- (void) registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName;
- (void) openOfferwallForTouchpoint:(NSString *)touchpointName;
- (void) initiateBalanceChecks;
- (int) withdrawBalanceForTouchpoint:(NSString *)touchpointName;

@property (strong, nonatomic) id<TrialpayManagerDelegate> delegate;

@end