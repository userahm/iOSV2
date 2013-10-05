#import <Foundation/Foundation.h>
#import "TpUtils.h"
#import "TpOfferwallViewController.h"
#import "TpBalance.h"
#import "TpSdkConstants.h"

@class TrialpayManager;

typedef void (^TPDelegateBlock)(TrialpayManager*);

typedef enum {
    TPBalanceUpdateAction,
    TPOfferwallCloseAction,
    TPUnknownAction,
} TPMessageAction;

@protocol TrialpayManagerDelegate
- (void)trialpayManager:(TrialpayManager *)trialpayManager withAction:(TPMessageAction)action;
@end


@interface BaseTrialpayManager : NSObject <TpOfferwallViewControllerDelegate>

+ (BaseTrialpayManager *)sharedInstance;

- (void)appLoaded;
+ (NSString*)sdkVersion;

- (void)setSid:(NSString *)sid;
- (NSString *)sid;

- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName;
- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName onOfferwallClose:(TPDelegateBlock)onOfferwallClose onBalanceUpdate:(TPDelegateBlock)onBalanceUpdate;
- (NSString *)vicForTouchpoint:(NSString *)touchpointName;
- (void)openOfferwallForTouchpoint:(NSString *)touchpointName;
- (void)initiateBalanceChecks;
- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName;
- (void)setAge:(int)age;
- (void)setGender:(Gender)gender;
- (void)updateLevel:(int)level;
- (void)setCustomParamValue:(NSString *)paramValue forName:(NSString *)paramName;
- (void)clearCustomParamWithName:(NSString *)paramName;
- (NSDictionary *)consumeCustomParams:(BOOL)clear;
- (void)updateVcPurchaseInfoForTouchpoint:(NSString *)touchpointName dollarAmount:(float)dollarAmount vcAmount:(int)vcAmount;
- (void)updateVcBalanceForTouchpoint:(NSString *)touchpointName vcAmount:(int)vcAmount;

@property (strong, nonatomic) id<TrialpayManagerDelegate> delegate;

@end
