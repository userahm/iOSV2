#import "BaseTrialpayManager.h"
#import "TpDataStore.h"

// how many UNIX timestamps for the customer's last sessions will be stored
#define TP_MAX_VISIT_TIMESTAMPS 5

@interface BaseTrialpayManager() {
    __block BOOL _isShowingOfferwall; // will be modified by a block
}
@property (strong, nonatomic) NSCondition *balanceUpdateCondition;
@property (strong, nonatomic) TPDelegateBlock balanceUpdateBlock;
@property (strong, nonatomic) TPDelegateBlock offerwallCloseBlock;
@end


@implementation BaseTrialpayManager

#pragma mark - Initialization
BaseTrialpayManager *__baseTrialpayManager;
- (id)init {
    TPLogEnter;
    if ((self = [super init])) {
        _isShowingOfferwall = NO;
        [self appLoaded];
        __baseTrialpayManager = self;
    }
    return self;
}

+ (BaseTrialpayManager *)sharedInstance {
    if (nil == __baseTrialpayManager) {
        TPCustomerError(@"TrialpayManager Instance is not accessible, please invoke TrialpayManager:getInstance", @"TrialpayManager Instance is not accessible, please invoke TrialpayManager:getInstance");
    }
    return __baseTrialpayManager;
}

/*
 * This method should be called after the application has been loaded.
 */
- (void)appLoaded {
    TPLogEnter;
    
    // log the current session time start
    NSNumber *userCreationTime = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyUserCreationTime];

    if (userCreationTime == nil) {
        userCreationTime = [NSNumber numberWithLong:(long)[[NSDate date] timeIntervalSince1970]];
        [[TpDataStore sharedInstance] setDataWithValue:userCreationTime forKey:kTPKeyUserCreationTime];
    }

    NSMutableArray *visitTimestamps = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitTimestamps];
    
    if (visitTimestamps == nil) {
        visitTimestamps = [NSMutableArray array];
    }
    
    NSNumber *currentTimestamp = [NSNumber numberWithLong:(long)[[NSDate date] timeIntervalSince1970]];
    
    if ([visitTimestamps count] == TP_MAX_VISIT_TIMESTAMPS) {
        [visitTimestamps removeLastObject];
    }
    
    [visitTimestamps insertObject:currentTimestamp atIndex:0];
    
    [[TpDataStore sharedInstance] setDataWithValue:visitTimestamps forKey:kTPKeyVisitTimestamps];
}

#pragma mark - Get SDK Version
+ (NSString*)sdkVersion {
    return @"ios.2.76701";
}

#pragma mark - BaseTrialpayManager getter/setter

- (void)setSid:(NSString *)sid {
    TPLog(@"setSid:%@", sid);
    [[TpDataStore sharedInstance] setDataWithValue:sid forKey:kTPSid];
}

- (NSString *)sid {
    NSString *sid = [[TpDataStore sharedInstance] dataValueForKey:kTPSid];
    if (nil == sid) {
        sid = [TpUtils idfa];
        if ([@"" isEqual:sid]) {
            sid = [TpUtils macAddress];
            if ([@"" isEqual:sid]) {
                // since we're using local storage, using the current timestamp and a random number should be fine
                double time = [[NSDate date] timeIntervalSince1970];
                sid = [NSString stringWithFormat:@"%f%d", time, arc4random()];
            }
        }
        sid = [TpUtils sha1:sid];
        [self setSid:sid];
    }
    return sid;
}

- (NSMutableDictionary *)touchpointNames {
    NSMutableDictionary *touchpointNames = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyTouchpointNames];
    if (nil == touchpointNames) {
        touchpointNames = [[NSMutableDictionary alloc] init];
    }
    return touchpointNames;
}

- (NSMutableArray *)vics {
    NSMutableArray *vics = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVICs];
    if (nil == vics) {
        vics = [[NSMutableArray alloc] init];
    }
    return vics;
}

- (NSMutableDictionary *)balances {
    NSMutableDictionary *balances = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyBalances];
    if (nil == balances) {
        balances = [[NSMutableDictionary alloc] init];
    }
    return balances;
}

- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName {
    TPLog(@"registerVic:%@, withTouchpoint:%@", vic, touchpointName);
    // Get preregistered names
    NSMutableDictionary *touchpointNames = [self touchpointNames];
    // If the name is there and is set correctly - skip
    if ([vic isEqualToString:[touchpointNames valueForKey:touchpointName]]) {
        return;
    }
    // Get the list of vics
    NSMutableArray *vics = [self vics];
    // If the new VIC name does not exist in the list (expected) add the vic to the vic list
    if (![vics containsObject:vic]) {
        [vics addObject:vic];
        [[TpDataStore sharedInstance] setDataWithValue:vics forKey:kTPKeyVICs];
    }
    // Register the vic under the given touchpointName
    [touchpointNames setValue:vic forKey:touchpointName];
    [[TpDataStore sharedInstance] setDataWithValue:touchpointNames forKey:kTPKeyTouchpointNames];
}

- (NSString *)vicForTouchpoint:(NSString *)touchpointName {
    TPLog(@"vicForTouchpoint:%@", touchpointName);
    NSDictionary *touchpointNames = [self touchpointNames];
    
    NSString *vic = [touchpointNames valueForKey:touchpointName];
    if (nil == vic) {
        TPLog(@"Could not find VIC for touchpoint %@", touchpointName);
    }
    return vic;
}

/*
 * Should be called on user registration or during initialization.
 *
 * NOTE: affects all touchpoints
 */
- (void)setAge:(int)age {
    TPLog(@"setAge: %d", age);
    [[TpDataStore sharedInstance] setDataWithValue:[NSNumber numberWithInt:age] forKey:kTPKeyAge];
}

/*
 * Should be called on user registration or during initialization.
 *
 * NOTE: affects all touchpoints
 */
- (void)setGender:(Gender)gender {
    TPLog(@"setGender: %u", gender);
    [[TpDataStore sharedInstance] setDataWithValue:[NSNumber numberWithInt:gender] forKey:kTPKeyGender];
}

/*
 * Should be called whenever there's a level/stage update in the game.
 * Can be called right before the touchpoint is being loaded.
 *
 * NOTE: affects all touchpoints
 */
- (void)updateLevel:(int)level {
    TPLog(@"updateLevel: %d", level);
    [[TpDataStore sharedInstance] setDataWithValue:[NSNumber numberWithInt:level] forKey:kTPKeyLevel];
}

/*
 * Should be called when an IAP purchase is done or if the user can gain VC in the game without purchasing it (in this case dollarAmount will be 0).
 */
- (void)updateVcPurchaseInfoForTouchpoint:(NSString*)touchpointName dollarAmount:(float)dollarAmount vcAmount:(int)vcAmount {
    TPLog(@"updateVcPurchaseInfoForTouchpoint:%@ dollarAmount:%@ vcAmount:%@", touchpointName, [NSNumber numberWithFloat:dollarAmount], [NSNumber numberWithInt:vcAmount]);
    
    NSMutableDictionary *vcPurchaseInfo = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVCPurchaseInfo];
    
    // if there is no any VC purchase information at all - initialize it with an empty dictionary
    if (vcPurchaseInfo == nil) {
        vcPurchaseInfo = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *vcPurchaseInfoForTouchpoint = [vcPurchaseInfo objectForKey:touchpointName];
    
    if (vcPurchaseInfoForTouchpoint != nil) {
        // add the passed values to current vales of "dollarAmount" and "vcAmount" for for the touchpoint
        float newDollarAmount = [[vcPurchaseInfoForTouchpoint objectForKey:kTPKeyDollarAmount] floatValue] + dollarAmount;
        int newVcAmount = [[vcPurchaseInfoForTouchpoint objectForKey:kTPKeyVCAmount] intValue] + vcAmount;
        
        [vcPurchaseInfoForTouchpoint setObject:[NSNumber numberWithFloat:newDollarAmount] forKey:kTPKeyDollarAmount];
        [vcPurchaseInfoForTouchpoint setObject:[NSNumber numberWithInt:newVcAmount] forKey:kTPKeyVCAmount];
    } else {
        // we don't have any information for the touchpoint yet, so initialize it with the passed parameters
        vcPurchaseInfoForTouchpoint = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithFloat:dollarAmount], kTPKeyDollarAmount,
                                       [NSNumber numberWithInt:vcAmount], kTPKeyVCAmount,
                                       nil];
        [vcPurchaseInfo setObject:vcPurchaseInfoForTouchpoint forKey:touchpointName];
    }

    [[TpDataStore sharedInstance] setDataWithValue:vcPurchaseInfo forKey:kTPKeyVCPurchaseInfo];
}

/*
 * Should be called whenever there's a VC activity (or right before the touchpoint is being loaded).
 */
- (void)updateVcBalanceForTouchpoint:(NSString*)touchpointName vcAmount:(int)vcAmount {
    TPLog(@"updateVcBalanceForTouchpoint:%@ vcAmount:%@", touchpointName, [NSNumber numberWithInt:vcAmount]);

    NSMutableDictionary *vcBalance = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVCBalance];
    
    // if there is no any VC balance information at all - initialize it with an empty dictionary
    if (vcBalance == nil) {
        vcBalance = [NSMutableDictionary dictionary];
    }

    int newVcAmount = 0;
    
    if ([vcBalance objectForKey:touchpointName] != nil) {
        newVcAmount = [[vcBalance objectForKey:touchpointName] intValue] + vcAmount;
    } else {
        newVcAmount = vcAmount;
    }

    [vcBalance setObject:[NSNumber numberWithInt:newVcAmount] forKey:touchpointName];
    
    [[TpDataStore sharedInstance] setDataWithValue:vcBalance forKey:kTPKeyVCBalance];
}

#pragma mark - Offerwall

- (void)openOfferwallForTouchpoint:(NSString *)touchpointName {
    TPLog(@"openOfferwallForTouchpoint:%@", touchpointName);
    _isShowingOfferwall = YES;
    TpOfferwallViewController *tpOfferwall = [[TpOfferwallViewController alloc] initWithTouchpointName:touchpointName];
    tpOfferwall.delegate = self;
    
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
  
    if ([root respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [root presentViewController:tpOfferwall animated:YES completion:nil];
    } else {
        // if iOS version < 6 is used
        [root presentModalViewController:tpOfferwall animated:YES];
    }
}

#pragma mark - Balance

static NSThread* balanceQueryAndWithdrawThread;
static NSMutableDictionary *tpBalances;

- (void)addDifferentialBalance:(int)differentialBalance toVic:(NSString *)vic {
    NSMutableDictionary *balances = [self balances];
    NSNumber *existingBalance = [balances valueForKey:vic];
    if (nil == existingBalance) {
        existingBalance = [[NSNumber alloc] initWithInt:0];
    }
    existingBalance = [NSNumber numberWithInt:[existingBalance intValue] + differentialBalance];
    [balances setValue:existingBalance forKey:vic];
    [[TpDataStore sharedInstance] setDataWithValue:balances forKey:kTPKeyBalances];
}

int balanceApiErrorWait = 10;
- (int)checkBalance {
    TPLogEnter;
    int minSecondsValid = -1;
    NSMutableArray *vics = [self vics];
    for (NSString *vic in vics) {
        TpBalance *tpBalanceObject = [tpBalances valueForKey:vic];
        if (nil == tpBalanceObject) {
            NSString *sid = [self sid];
            tpBalanceObject = [[TpBalance alloc] initWithVic:vic sid:sid];
            if (nil == tpBalanceObject) {
                TPCustomerError(@"could not allocate a TpBalance object for vic={vic}", @"could not allocate a TpBalance object for vic=%@", vic);
                balanceApiErrorWait *= 1.2;
                continue; // try to work with other vics.
            }
            [tpBalances setValue:tpBalanceObject forKey:vic];
        }
        NSDictionary *latestBalanceInfo = [tpBalanceObject queryBalanceInfo];
        if (nil == latestBalanceInfo) {
            balanceApiErrorWait *= 1.2;
            return balanceApiErrorWait;
        }
        
        int differentialBalance = [[latestBalanceInfo objectForKey:kTPKeyBalance] intValue];
        int secondsValid = [[latestBalanceInfo objectForKey:kTPKeySecondsValid] intValue];
        
        if (differentialBalance > 0) {
            Boolean ackSuccess = [tpBalanceObject acknowledgeBalanceInfo: latestBalanceInfo];
            if (ackSuccess) {
                [self addDifferentialBalance:differentialBalance toVic:vic];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_delegate) {
                        [_delegate trialpayManager:(TrialpayManager*)self withAction:TPBalanceUpdateAction];
                    }
                    if (_balanceUpdateBlock) {
                        _balanceUpdateBlock((TrialpayManager*)self);
                    }
                });
            }
        }
        if ((minSecondsValid < 0) || (minSecondsValid > secondsValid)) {
            minSecondsValid = secondsValid;
            balanceApiErrorWait = minSecondsValid;
        }
    }
    if (minSecondsValid < 0) return balanceApiErrorWait;
    return minSecondsValid;
}

- (void)balanceQueryAndWithdraw {
    TPLogEnter;
    @autoreleasepool {
        int defaultSecondsValid = 10;
        int secondsValid = defaultSecondsValid;// start with 5s
        [_balanceUpdateCondition lock];
        while([[NSThread currentThread] isCancelled] == NO) {
            if (!_isShowingOfferwall) {
                secondsValid = [self checkBalance];
                if (secondsValid < 0) {
                    secondsValid = defaultSecondsValid;
                }
            }
            TPLog(@"balanceQueryAndWithdraw before wait for %d", secondsValid);
            [_balanceUpdateCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:secondsValid]];
        }
        [_balanceUpdateCondition unlock];
    }
}

- (void)initiateBalanceChecks {
    TPLogEnter;
    if (nil != balanceQueryAndWithdrawThread) {
        [balanceQueryAndWithdrawThread cancel];
    }
    if (nil != _balanceUpdateCondition) {
        [_balanceUpdateCondition lock];
        [_balanceUpdateCondition signal];
        [_balanceUpdateCondition unlock];
    } else {
        _balanceUpdateCondition = [[NSCondition alloc] init];
    }
    balanceQueryAndWithdrawThread = [[NSThread alloc] initWithTarget:self
                                                            selector:@selector(balanceQueryAndWithdraw)
                                                              object:nil];
    
    [balanceQueryAndWithdrawThread start];  // Actually create the thread
}

- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName {
    TPLog(@"withdrawBalanceForTouchpoint:%@", touchpointName);
    NSString *vic = [self vicForTouchpoint:touchpointName];
    if (nil == vic) {
        TPCustomerWarning(@"Could not find VIC for {vic}. Skipping offerwall.", @"Could not find VIC for %@. Skipping offerwall.", touchpointName);
        return 0;
    }
    [_balanceUpdateCondition lock];
    NSMutableDictionary *balances = [self balances];
    NSNumber *existingBalance = [balances valueForKey:vic];
    if (nil == existingBalance || 0 == [existingBalance intValue]) {
        [_balanceUpdateCondition unlock];
        return 0;
    }
    
    [balances setValue:[NSNumber numberWithInt:0] forKey:vic];
    [[TpDataStore sharedInstance] setDataWithValue:balances forKey:kTPKeyBalances];
    [_balanceUpdateCondition unlock];
    return [existingBalance intValue];
}

/* ************* Custom Params ************* */

NSMutableDictionary *customParams = nil;

- (void)setCustomParamValue:(NSString *)paramValue forName:(NSString *)paramName {
    // make sure that the parameter name is set.
    if (paramName == nil || [paramName isEqualToString:@""]) {
        TPLog(@"Cannot set a parameter without a parameter name. Skips.");
        return;
    }
    // create the custom param dictionary
    if (customParams == nil) {
        customParams = [[NSMutableDictionary alloc] init];
    }
    // if the value is nil, store an empty string
    if (paramValue == nil) {
        paramValue = @"";
    }
    // store value for given name
    [customParams setValue:paramValue forKey:paramName];
}

- (void)clearCustomParamWithName:(NSString *)paramName {
    // avoid errors
    if (paramName == nil) {
        return;
    }
    // remove value from map
    [customParams removeObjectForKey:paramName];
}

- (NSDictionary *)consumeCustomParams:(BOOL)clear {
    NSDictionary *result = customParams;
    if (clear) {
        customParams = nil;
    }
    return result;
}


#pragma mark - Delegate

// allow response by blocks
- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName onOfferwallClose:(TPDelegateBlock)onOfferwallClose onBalanceUpdate:(TPDelegateBlock)onBalanceUpdate {
    [self registerVic:vic withTouchpoint:touchpointName];
    self.balanceUpdateBlock = onBalanceUpdate;
    self.offerwallCloseBlock = onOfferwallClose;
}

- (void)tpOfferwallViewController:(TpOfferwallViewController *)tpOfferwallViewController close:(id)sender {
    // the offerwall container just got closed. wake up the balance check
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate) {
            [_delegate trialpayManager:(TrialpayManager*)self withAction:TPOfferwallCloseAction];
        }
        if (_offerwallCloseBlock) {
            _offerwallCloseBlock((TrialpayManager*)self);
        }
    });

    // wait for the navigation animation ~ 300ms
    double delayInSeconds = 0.4;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        _isShowingOfferwall = NO;
        [_balanceUpdateCondition signal];
    });
}

@end
