//
//  TpOfferwallViewController.m
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import "BaseTrialpayManager.h"
#import "TpDataStore.h"
#import "TpArcSupport.h"
#import "TpDealspotView.h"
#import "TpUtils.h"
#import "TpUrlManager.h"
#import "TpVideo.h"
#import "TpConstants.h"

// how many UNIX timestamps for the customer's last sessions will be stored
#define TP_MAX_VISIT_TIMESTAMPS 5
// defaut validity_time for availability results, in seconds
#define TP_AVAILABILITY_DEFAULT_VALIDITY_TIME 86400

NSString *TPOfferwallOpenActionString  = @"offerwall_open";
NSString *TPOfferwallCloseActionString  = @"offerwall_close";
NSString *TPBalanceUpdateActionString  = @"balance_update";

@interface BaseTrialpayManager ()
- (int)checkBalance;
- (int)checkAvailabilityForTouchpoint:(NSString *)touchpointName;
- (void)stopAvailabilityCheckForTouchpoint:(NSString *)touchpointName;
- (int)availabilityErrorTimeForTouchpoint:(NSString *)touchpointName;

@property (nonatomic) NSTimeInterval userSessionTimeout; // To allow change on value
@end

@interface TPBalanceCheckOperation : NSOperation
@end

@implementation TPBalanceCheckOperation
- (void) main {
    TPLogEnter;
    @autoreleasepool {
        int defaultSecondsValid = 10;
        int secondsValid = defaultSecondsValid; // start with default
        while (!self.isCancelled) {
#if defined(__TRIALPAY_USE_EXCEPTIONS)
            @try {
#endif
                TPLog(@"Loop balance check %@", self);
                if (![BaseTrialpayManager sharedInstance].isShowingOfferwall) {
                    secondsValid = [[BaseTrialpayManager sharedInstance] checkBalance];
                    if (secondsValid < 0) {
                        secondsValid = defaultSecondsValid;
                    }
                } else {
                    TPLog(@"Skip balance update while offerwall is open");
                }
                TPLog(@"balanceQueryAndWithdraw before wait for %d", secondsValid);
                
                [TpUtils operation:self sleepFor:secondsValid];
#if defined(__TRIALPAY_USE_EXCEPTIONS)
            }
            @catch (NSException *exception) {
                TPLog(@"%@\n%@", exception, [exception callStackSymbols]);
            }
#endif
        }
        TPLog(@"Exitting balance check");
    }
}
@end

@interface TpAvailabilityCheckOperation : NSOperation
@property (strong, nonatomic) NSString *touchpointName;
@end

@implementation TpAvailabilityCheckOperation
- (void) main {
    @autoreleasepool {
        int secondsValid = TP_AVAILABILITY_DEFAULT_VALIDITY_TIME; // start with default
        while (!self.isCancelled) {
#if defined(__TRIALPAY_USE_EXCEPTIONS)
            @try {
#endif
                TPLog(@"Loop availability check for touchpoint %@", self.touchpointName);
                secondsValid = [[BaseTrialpayManager sharedInstance] checkAvailabilityForTouchpoint:self.touchpointName];
                if (secondsValid <= 0) {
                    secondsValid = TP_AVAILABILITY_DEFAULT_VALIDITY_TIME;
                }
                TPLog(@"availabilityCheckOperation for touchpoint %@ before wait for %d", self.touchpointName, secondsValid);
                [TpUtils operation:self sleepFor:secondsValid];
#if defined(__TRIALPAY_USE_EXCEPTIONS)
            }
            @catch (NSException *exception) {
                TPLog(@"%@\n%@", exception, [exception callStackSymbols]);
                // check if operation should be cancelled - needed to prevent running operation on invalid touchpoint for example.
                if ([[[NSThread currentThread].threadDictionary valueForKey:@"cancelOperation"] boolValue]) {
                    [self cancel];
                }
            }
#endif
        }
        TPLog(@"Exitting Availability Check");
    }
}
@end

@implementation BaseTrialpayManager {
    NSOperationQueue *_tpOperationQueue;
    NSDate *_lastBackground;
    NSDate *_lastForeground;
    NSMutableDictionary *_openDealspotViews;
}

#pragma mark - Initialization
BaseTrialpayManager *__baseTrialpayManager;

- (id)init {
    TPLogEnter;
    if ((self = [super init])) {
        _isShowingOfferwall = NO;
        __baseTrialpayManager = self;
        _useWebNavigationBar = YES;
        
        // queue is needed so operation runs on background
        _tpOperationQueue = [[NSOperationQueue alloc] init];
        _tpOperationQueue.name = @"TP Operation Queue";

        // We may be called after foreground, so lets force the call,
        // It may run right after this (forced) call when the application:didFinishLaunchingWithOptions: finishes
        [self applicationDidBecomeActiveNotification];
        [self startListeningToAppStateNotifications];

        _openDealspotViews = [NSMutableDictionary new];

        [[TpVideo sharedInstance] pruneVideoStorage];
    }
    return self;
}

NSMutableDictionary *customParams = nil;
// store the availability operations so that they can be cancelled and cleared before restarting them
NSMutableDictionary *__interstitialAvailabilityChecks = nil;
NSMutableDictionary *_interstitialAvailabilityErrorWaitTimes = nil;

- (void)dealloc {
    [_tpOperationQueue TP_RELEASE];
    [_lastBackground TP_RELEASE];
    [_lastForeground TP_RELEASE];
    [(NSObject*)_delegate TP_RELEASE];
    [customParams TP_RELEASE];
    customParams = nil;
    [__interstitialAvailabilityChecks TP_RELEASE];
    __interstitialAvailabilityChecks = nil;
    [_interstitialAvailabilityErrorWaitTimes TP_RELEASE];
    _interstitialAvailabilityErrorWaitTimes = nil;
    [super TP_DEALLOC];
}

- (void)startListeningToAppStateNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector
    (applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector
    (applicationDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector
    (applicationWillTerminateNotification) name:UIApplicationWillTerminateNotification object:NULL];
}

+ (BaseTrialpayManager *)sharedInstance {
    if (nil == __baseTrialpayManager) {
        TPCustomerError(@"TrialpayManager Instance is not accessible, please invoke TrialpayManager:getInstance", @"TrialpayManager Instance is not accessible, please invoke TrialpayManager:getInstance");
    }
    return __baseTrialpayManager;
}

- (void)applicationDidBecomeActiveNotification {
    TPLogEnter;

    if (self.userSessionTimeout == 0) {
        self.userSessionTimeout = 30*60; // defaults to 30 min
    }

    // Only call appLoaded if we were in bkg for a long time, as if device user completes an offer on browser it would
    // cause this function to be called.
    NSTimeInterval elapsedSinceLastBackground = -[_lastBackground timeIntervalSinceNow];
    TPLog(@"Elapsed %.0f (to=%.0f)", elapsedSinceLastBackground, self.userSessionTimeout);

    if (!_lastBackground || elapsedSinceLastBackground > self.userSessionTimeout) {
        // lets prevent calling twice (didfinishloading ends up calling this)
        if (!_lastBackground && _lastForeground) {return;}
        [_lastForeground TP_RELEASE];
        _lastForeground = [NSDate new];

        // log the current session time start whenever the app returns to foreground, note that it may happen after going back from server
        NSNumber *userCreationTime = [NSNumber numberWithLong:(long)[[NSDate date] timeIntervalSince1970]];
        [[TpDataStore sharedInstance] setDataWithValue:userCreationTime forKey:kTPKeyUserCreationTime];
        TPLog(@"[AUTOSETUP] userCreationTime %@", userCreationTime);

        // store last visit length
        if (_lastBackground) {
            [self closeLastVisit];
        }
        [self appLoaded];
    }
}

- (void)applicationDidEnterBackgroundNotification {
    TPLogEnter;
    [_lastBackground TP_RELEASE];
    _lastBackground = [NSDate new];
}

- (void)applicationWillTerminateNotification {
    TPLogEnter;
    [_lastBackground TP_RELEASE];
    _lastBackground = [NSDate new];
    [self closeLastVisit];
}

/*
 * This method should be called after the application has been loaded.
 */
- (void)appLoaded {
    TPLogEnter;
    TPCustomerLog(@"Loading Trialpay iOS SDK API version %@", [self sdkVersion]);

    NSMutableArray *visitTimestamps = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitTimestamps];
    if (visitTimestamps == nil) {
        visitTimestamps = [NSMutableArray array];
    }

    NSNumber *currentTimestamp = [NSNumber numberWithLong:(long)[[NSDate date] timeIntervalSince1970]];
    if ([visitTimestamps count] == TP_MAX_VISIT_TIMESTAMPS) {
        [visitTimestamps removeLastObject];
    }

    [visitTimestamps insertObject:currentTimestamp atIndex:0];
    TPLog(@"[AUTOSETUP] save last visitTimestamp %@", currentTimestamp);

    [[TpDataStore sharedInstance] setDataWithValue:visitTimestamps forKey:kTPKeyVisitTimestamps];
}

/**
 * get last visit timestamp, calculate last visit length, than save.
 */
- (void)closeLastVisit {
    TPLogEnter;

    NSMutableArray *visitTimestamps = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitTimestamps];
    NSNumber *lastVisitTimestamp = [[visitTimestamps objectEnumerator] nextObject];
    NSNumber *visitLength = [NSNumber numberWithLong:(long) ([[NSDate date] timeIntervalSince1970] - [lastVisitTimestamp
            longValue])];

    NSMutableArray *visitLengths = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVisitLengths];
    if (nil == visitLengths) {
        visitLengths = [[NSMutableArray new] TP_AUTORELEASE];
    }

    if ([visitLengths count] == TP_MAX_VISIT_TIMESTAMPS) {
        [visitLengths removeLastObject];
    }

    [visitLengths insertObject:visitLength atIndex:0];
    TPLog(@"[AUTOSETUP] save last visitLength %@", visitLength);

    [[TpDataStore sharedInstance] setDataWithValue:visitLengths forKey:kTPKeyVisitLengths];
}

#pragma mark - Get SDK Version
- (NSString*)sdkVersion {
    return @"ios.2.2014391";
}

#pragma mark - BaseTrialpayManager getter/setter

- (void)setSid:(NSString *)sid {
    TPLog(@"setSid:%@", sid);
    [[TpDataStore sharedInstance] setDataWithValue:sid forKey:kTPSid];
}

- (NSString *)sid {
    NSString *sid = [[TpDataStore sharedInstance] dataValueForKey:kTPSid];
    if (nil == sid) {
        sid = [TpUtils macAddress];
        if ([@"" isEqual:sid]) {
            // since we're using local storage, using the current timestamp and a random number should be fine
            double time = [[NSDate date] timeIntervalSince1970];
            sid = [NSString stringWithFormat:@"%f%d", time, arc4random()];
        }
        sid = [TpUtils sha1:sid];
        [self setSid:sid];
    }
    return sid;
}

- (NSMutableDictionary *)touchpointNames {
    NSMutableDictionary *touchpointNames = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyTouchpointNames];
    if (nil == touchpointNames) {
        touchpointNames = [[[NSMutableDictionary alloc] init] TP_AUTORELEASE];
    }
    return touchpointNames;
}

- (NSMutableArray *)vics {
    NSMutableArray *vics = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVICs];
    if (nil == vics) {
        vics = [[[NSMutableArray alloc] init] TP_AUTORELEASE];
    }
    return vics;
}

- (NSMutableDictionary *)balances {
    NSMutableDictionary *balances = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyBalances];
    if (nil == balances) {
        balances = [[[NSMutableDictionary alloc] init] TP_AUTORELEASE];
    }
    return balances;
}

- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName {
    if (nil == vic || [vic length] == 0) {
        [NSException raise:@"TrialpayAPIException" format:@"Provide a valid (non-null) VIC for registerVic:withTouchpoint:"];
    }
    if (nil == touchpointName || [touchpointName length] == 0) {
        [NSException raise:@"TrialpayAPIException" format:@"Provide a valid (non-null) touchpoint name for registerVic:withTouchpoint:"];
    }

    TPLog(@"registerVic:%@, withTouchpoint:%@", vic, touchpointName);
    // Get preregistered names
    NSMutableDictionary *touchpointNames = [self touchpointNames];
    // Confirm that the name is not already present.
    NSString *oldVic = [touchpointNames valueForKey:touchpointName];
    if (![vic isEqualToString:oldVic]) {
        if (nil != oldVic) {
            TPCustomerWarning(@"Reassigning touchpoint [] to vic", @"Reassigning touchpoint to vic '%@' (previously '%@')", vic, oldVic);
        }

        // Are we trying to reassign vic to another touchpoint?
        NSString *oldTouchpoint = [self touchpointForVic:vic];
        if (nil != oldTouchpoint) {
            // Than lets warn and remove old association...
            TPCustomerWarning(@"Reassigning vic [] to touchpoint", @"Reassigning vic to touchpoint '%@' (previously '%@')", touchpointName, oldTouchpoint);
            [touchpointNames removeObjectForKey:oldTouchpoint];
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

    // Check availability. For interstitial touchpoints this determines which offer we show. For other touchpoints this
    // preloads any video trailer offers.
    [self startAvailabilityCheckForTouchpoint:touchpointName];
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

- (NSString *)touchpointForVic:(NSString *)vic {
    TPLog(@"touchpointForVic:%@", vic);
    NSDictionary *touchpointNames = [self touchpointNames];

    NSArray *touchpoints = [touchpointNames allKeysForObject:vic];
    if ([touchpoints count] == 0) {
        TPLog(@"Could not find touchpoint for VIC %@", vic);
        return nil;
    }
    if ([touchpoints count] > 1) {
        TPLog(@"Found more than one touchpoint for VIC %@", vic);
    }
    return [touchpoints firstObject];
}

- (void)registerDealspotURL:(NSString *)urlString forTouchpoint:(NSString *)touchpointName {
    if (nil == touchpointName) {
        // We have to cancel the availability operation (dont have pointer to operation here)
        [[NSThread currentThread].threadDictionary setValue:@YES forKey:@"cancelOperation"];
        [NSException raise:@"TrialpayAPIException" format:@"Provide a valid (non-null) touchpointName name for registerDealspotURL:forTouchpoint:"];
    }
    if (nil == [[self touchpointNames] objectForKey:touchpointName]) {
        [[NSThread currentThread].threadDictionary setValue:@YES forKey:@"cancelOperation"];
        [NSException raise:@"TrialpayAPIException" format:@"TouchpointName (%@) must be registered with registerVic:withTouchpoint:", touchpointName];
    }

    NSMutableDictionary *dsUrls = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyDealspotURLs];
    if (nil == dsUrls) {
        dsUrls = [[[NSMutableDictionary alloc] init] TP_AUTORELEASE];
    }
    if (nil == urlString) {
        [dsUrls removeObjectForKey:touchpointName];
    } else {
        [dsUrls setObject:urlString forKey:touchpointName];
    }

    [[TpDataStore sharedInstance] setDataWithValue:dsUrls forKey:kTPKeyDealspotURLs];
}

// It should happen that only a dealspot or interstitial touchpoint will have a dealspotURL registered,
// but this is not guaranteed. (Exceptions include remapped touchpoints.) To determine whether this is
// a dealspot touchpoint, call getIntegrationTypeForTouchpoint:.
//
// Return value may be nil.
- (NSString *)urlForDealspotTouchpoint:(NSString *)touchpointName {
    TPLog(@"urlForDealspotTouchpoint:%@", touchpointName);
    NSDictionary *dsUrls = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyDealspotURLs];

    NSString *urlString = [dsUrls valueForKey:touchpointName];
    return urlString;
}

- (void)setIntegrationType:(NSString *)typeString forTouchpoint:(NSString *)touchpointName {
    NSMutableDictionary *integrationTypes = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyIntegrationTypes];
    if (integrationTypes == nil) {
        integrationTypes = [[[NSMutableDictionary alloc] init] TP_AUTORELEASE];
    }
    [integrationTypes setObject:typeString forKey:touchpointName];
    [[TpDataStore sharedInstance] setDataWithValue:integrationTypes forKey:kTPKeyIntegrationTypes];
}

- (NSString *)getIntegrationTypeForTouchpoint:(NSString *)touchpointName {
    NSDictionary *integrationTypes = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyIntegrationTypes];
    NSString *typeString = [integrationTypes valueForKey:touchpointName];
    if (typeString == nil) {
        typeString = @"unknown";
    }
    return typeString;
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
   Should be called whenever there's a VC activity (or right before the touchpoint is being loaded).
 */
- (void)updateVcBalanceForTouchpoint:(NSString*)touchpointName vcAmount:(int)vcAmount {
    TPLog(@"updateVcBalanceForTouchpoint:%@ vcAmount:%@", touchpointName, [NSNumber numberWithInt:vcAmount]);

    NSMutableDictionary *vcBalance = [[TpDataStore sharedInstance] dataValueForKey:kTPKeyVCBalance];
    
    // if there is no any VC balance information at all - initialize it with an empty dictionary
    if (vcBalance == nil) {
        vcBalance = [NSMutableDictionary dictionary];
    }

    // balance is the current balance of device user
    [vcBalance setObject:[NSNumber numberWithInt:vcAmount] forKey:touchpointName];
    
    [[TpDataStore sharedInstance] setDataWithValue:vcBalance forKey:kTPKeyVCBalance];
}

#pragma mark - Dealspot

- (TpDealspotView *)createDealspotViewForTouchpoint:(NSString *)touchpointName withFrame:(CGRect)touchpointFrame {
    // auto stop previous view, if we are recreating for the same touchpoint
    [self stopDealspotViewForTouchpoint:touchpointName];
    TpDealspotView *trialpayDealspotObject = [[[TpDealspotView alloc] initWithFrame:touchpointFrame forTouchpoint:touchpointName] TP_AUTORELEASE];
    [_openDealspotViews setObject:trialpayDealspotObject forKey:touchpointName];
    return trialpayDealspotObject;
}

- (void)stopDealspotViewForTouchpoint:(NSString *)touchpointName {
    TpDealspotView *dsView = [_openDealspotViews objectForKey:touchpointName];
    if (dsView != nil) {
        [dsView stopLoading];
        [dsView removeFromSuperview];
        [_openDealspotViews removeObjectForKey:touchpointName];
    } else {
        TPCustomerWarning(@"Dealspot view not found", @"Dealspot view not found for touchpoint %@", touchpointName);
    }
}

#pragma mark - openTouchpoint

- (void)openTouchpoint:(NSString *)touchpointName {
    [self openTouchpoint:touchpointName withMode:TPViewModeFullscreen];
}

- (void)openTouchpoint:(NSString *)touchpointName withMode:(TPViewMode)mode {
    TPLog(@"openTouchpoint:%@ withMode:%@", touchpointName, [TpUtils viewModeString:mode]);
    BOOL isAvailable = [self isAvailableTouchpoint:touchpointName];
    if (!isAvailable) {
        TPCustomerWarning(@"Touchpoint is not available and will not be opened", @"Touchpoint %@ is not available and will not be opened", touchpointName);
        return;
    }
    // TODO: rename several items here (isShowingOfferwall, TpOfferwallViewController, trialpayManager:offerwallDidOpenForTouchpoint, etc) to
    // no longer mention the offerwall, because their use now extends beyond the offerwall.
    _isShowingOfferwall = YES;
    TPLog(@"isShowingOfferwall YES");

    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;

    // dispatch_async performs a copy on the block, on our behalf, so we don't need to copy it ourselves.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            TPLog(@"Dispatching offerwallDidOpen to %@", self.delegate);
            // methods are now optional, so we have to check for existence
            if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:withAction:)]) {
                TPLog(@"Dispatching withAction");
                [self.delegate trialpayManager:(TrialpayManager *)self withAction:TPOfferwallOpenAction];
            }
            if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:offerwallDidOpenForTouchpoint:)]) {
                TPLog(@"Dispatching offerwallDidOpenForTouchpoint");
                [self.delegate trialpayManager:(TrialpayManager *)self offerwallDidOpenForTouchpoint:touchpointName];
            }
        }
    });

    // Check for the video trailer interstitial flow, which does not use the normal webview.
    NSString *integrationType = [self getIntegrationTypeForTouchpoint:touchpointName];
    if ([integrationType isEqualToString:@"interstitial"]) {
        NSString *dealspotURL = [self urlForDealspotTouchpoint:touchpointName];
        if ([dealspotURL hasPrefix:kTPKeyVideoPrefix]) {
            NSString *videoResourceURL = [dealspotURL substringFromIndex:[kTPKeyVideoPrefix length]];
            void (^completionBlock)(void) = ^{
                [[BaseTrialpayManager sharedInstance] closeTouchpoint:touchpointName];
            };
            [[TpVideo sharedInstance] playVideoWithURL:videoResourceURL fromViewController:rootViewController withBlock:[[completionBlock copy] TP_AUTORELEASE]];
            return;
        }
    }

    // Create and present the offerwall view controller (this is also used for dealspot).
    TpOfferwallViewController *tpOfferwall = [[TpOfferwallViewController alloc] initWithTouchpointName:touchpointName];
    tpOfferwall.viewMode = mode;

    // show with previous view on the background
    // TODO: the presentation style actually causes the show animation to not happen
    if (mode == TPViewModePopup) {
        rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    }

    [rootViewController presentViewController:tpOfferwall animated:YES completion:nil];
    tpOfferwall.delegate = self;

    [tpOfferwall TP_RELEASE];

}

#pragma mark - Balance


- (void)addDifferentialBalance:(int)differentialBalance toVic:(NSString *)vic {
    // protecting changes to balances
    @synchronized (self) {
        NSMutableDictionary *balances = [self balances];
        NSNumber *existingBalance = [balances valueForKey:vic];
        if (nil == existingBalance) {
            existingBalance = [[[NSNumber alloc] initWithInt:0] TP_AUTORELEASE];
        }
        existingBalance = [NSNumber numberWithInt:[existingBalance intValue] + differentialBalance];
        [balances setValue:existingBalance forKey:vic];
        [[TpDataStore sharedInstance] setDataWithValue:balances forKey:kTPKeyBalances];
    }
}

static NSMutableDictionary *__tpBalances;
int __balanceApiErrorWait = 10;
- (int)checkBalance {
    TPLogEnter;
    int minSecondsValid = -1;
    NSArray *vics = [self vics];

    // there is a small chance checkBalance will be called multiple times, so lets protect __tpBalances
    @synchronized (__tpBalances) {
        NSArray *vicsCopy = [vics copy];
        for (NSString *vic in vicsCopy) {
            TpBalance *tpBalanceObject = [__tpBalances valueForKey:vic];
            if (nil == tpBalanceObject) {
                NSString *sid = [self sid];
                tpBalanceObject = [[[TpBalance alloc] initWithVic:vic sid:sid] TP_AUTORELEASE];
                if (nil == tpBalanceObject) {
                    TPCustomerError(@"could not allocate a TpBalance object for vic={vic}", @"could not allocate a TpBalance object for vic=%@", vic);
                    __balanceApiErrorWait *= 1.2;
                    continue; // try to work with other vics.
                }
                [__tpBalances setValue:tpBalanceObject forKey:vic];
            }
            NSDictionary *latestBalanceInfo = [tpBalanceObject queryBalanceInfo];
            if (nil == latestBalanceInfo) {
                __balanceApiErrorWait *= 1.2;
//                return __balanceApiErrorWait;
                continue;
            }

            int differentialBalance = [[latestBalanceInfo objectForKey:kTPKeyBalance] intValue];
            int secondsValid = [[latestBalanceInfo objectForKey:kTPKeySecondsValid] intValue];

            if (differentialBalance > 0) {
                Boolean ackSuccess = [tpBalanceObject acknowledgeBalanceInfo: latestBalanceInfo];
                if (ackSuccess) {
                    [self addDifferentialBalance:differentialBalance toVic:vic];
                    // dispatch_async performs a copy on the block, on our behalf, so we don't need to copy it ourselves.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.delegate) {
                            TPLog(@"Dispatching balanceUpdate");
                            // methods are now optional, so we have to check for existence
                            if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:withAction:)]) {
                                [self.delegate trialpayManager:(TrialpayManager*)self withAction:TPBalanceUpdateAction];
                            }
                            if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:balanceWasUpdatedForTouchpoint:)]) {
                                NSString *touchpointName = [self touchpointForVic:vic];
                                [self.delegate trialpayManager:(TrialpayManager *) self balanceWasUpdatedForTouchpoint:touchpointName];
                            }
                        }
                    });
                }
            }
            if ((minSecondsValid < 0) || (minSecondsValid > secondsValid)) {
                minSecondsValid = secondsValid;
                __balanceApiErrorWait = minSecondsValid;
            }
        }
        [vicsCopy TP_RELEASE];
    }
    if (minSecondsValid < 0) return __balanceApiErrorWait;
    return minSecondsValid;
}

static NSOperation *__balanceQueryAndWithdrawOperation;
// Allow unittests to stop balance checks
- (void)stopBalanceChecks {
    [__balanceQueryAndWithdrawOperation cancel];
    [__balanceQueryAndWithdrawOperation TP_RELEASE];
    __balanceQueryAndWithdrawOperation = nil;
}

- (void)initiateBalanceChecks {
    TPLogEnter;
    [self stopBalanceChecks];
    __balanceQueryAndWithdrawOperation = [TPBalanceCheckOperation new];
    [_tpOperationQueue addOperation:__balanceQueryAndWithdrawOperation];
}

- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName {
    TPLog(@"withdrawBalanceForTouchpoint:%@", touchpointName);
    NSString *vic = [self vicForTouchpoint:touchpointName];
    if (nil == vic) {
        TPCustomerWarning(@"Could not find VIC for {vic}. Skipping offerwall.", @"Could not find VIC for %@. Skipping offerwall.", touchpointName);
        return 0;
    }

    // protecting changes to balances
    @synchronized (self) {
        NSMutableDictionary *balances = [self balances];
        NSNumber *existingBalance = [balances valueForKey:vic];
        if (nil == existingBalance || 0 == [existingBalance intValue]) {
            return 0;
        }

        [balances setValue:[NSNumber numberWithInt:0] forKey:vic];
        [[TpDataStore sharedInstance] setDataWithValue:balances forKey:kTPKeyBalances];
        return [existingBalance intValue];
    }
}

#pragma mark - Custom Params

- (void)setCustomParamValue:(NSString *)paramValue forName:(NSString *)paramName {
    // make sure that the parameter name is set.
    if (paramName == nil || [paramName isEqualToString:@""]) {
        TPLog(@"Cannot set a parameter without a parameter name. Skipping.");
        return;
    }
    // create the custom param dictionary
    if (customParams == nil) {
        customParams = [[NSMutableDictionary alloc] init];
    }
    // if the value is nil, store an empty string
    if (paramValue == nil) {
        paramValue = @"";
        TPCustomerWarning(@"Nil value provided while setting a custom parameter, storing an empty string instead",
                          @"Nil value provided while setting a custom parameter, storing an empty string instead");
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
    NSDictionary *result = [customParams TP_RETAIN];
    if (clear) {
        [customParams TP_RELEASE];
        customParams = nil;
    }
    return [result TP_AUTORELEASE];
}


#pragma mark - Delegation

- (void)setDelegate:(id <TrialpayManagerDelegate>)delegate {
    _delegate = delegate;

    // no checks if nil
    if (nil == _delegate) {
        return;
    }

    // We made the delegate methods optional, so we could allow older implementations to not fail.
    // So, lets check that one of the methods is implemented (but not both).
    BOOL hasDelegate = NO;
    if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:withAction:)]) {
        hasDelegate = YES;
        TPCustomerWarning(@"trialpayManager:withAction is deprecated", @"trialpayManager:withAction is deprecated in favor of trialpayManager:offerwallDidOpenForTouchpoint:, trialpayManager:offerwallDidCloseForTouchpoint: and trialpayManager:balanceWasUpdatedForTouchpoint:");
    }
    if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:offerwallDidOpenForTouchpoint:)] ||
            [(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:offerwallDidCloseForTouchpoint:)] ||
            [(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:balanceWasUpdatedForTouchpoint:)]) {
        if (hasDelegate) {
            [NSException raise:@"TrialpayUseOneDelegateInterfaceOnly" format:@"Please update your TrialpayManagerDeleage removing the implementation of trialpayManager:withAction:.\nThe new interfaces are: trialpayManager:offerwallDidOpenForTouchpoint:, trialpayManager:offerwallDidCloseForTouchpoint: and trialpayManager:balanceWasUpdatedForTouchpoint:"];
        }
        hasDelegate = YES;
    } else {
        if (!hasDelegate) { // a warning message was already given with old delegate method.
            TPCustomerWarning(@"Implement at least one delegate", @"Please implement at least one delegate method: trialpayManager:offerwallDidOpenForTouchpoint:, trialpayManager:offerwallDidCloseForTouchpoint: and trialpayManager:balanceWasUpdatedForTouchpoint:");
        }
    }

    // if delegate was set but no methods were implemented, we give up, we cant live with that...
    if (!hasDelegate) {
        [NSException raise:@"TrialpayDelegateMustHaveAtLeastOneMethod" format:@"Please implement at least one delegate method: trialpayManager:offerwallDidOpenForTouchpoint:, trialpayManager:offerwallDidCloseForTouchpoint: and trialpayManager:balanceWasUpdatedForTouchpoint:"];
    }
}

// Conform to TpOfferwallViewControllerDelegate protocol
- (void)closeTouchpoint:(NSString *)touchpointName {
    TPLogEnter;
    // dispatch_async performs a copy on the block, on our behalf, so we don't need to copy it ourselves.
    dispatch_async(dispatch_get_main_queue(), ^(void){
        TPLogEnter;
        _isShowingOfferwall = NO;

        // the offerwall container just got closed. wake up the balance check
        if (self.delegate) {
            // methods are now optional, so we have to check for existence
            TPLog(@"Dispatching offerwallDidClose");
            if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:withAction:)]) {
                [self.delegate trialpayManager:(TrialpayManager*)self withAction:TPOfferwallCloseAction];
            }
            if ([(NSObject*)self.delegate respondsToSelector:@selector(trialpayManager:offerwallDidCloseForTouchpoint:)]) {
                [self.delegate trialpayManager:(TrialpayManager *) self offerwallDidCloseForTouchpoint:touchpointName];
            }
        }

        // recheck only if there is a balance check happening
        if (__balanceQueryAndWithdrawOperation) {
            [self initiateBalanceChecks]; // lets check right now!
        }

        // restart the availability check if one is ongoing
        if ([__interstitialAvailabilityChecks objectForKey:touchpointName]) {
            [self stopAvailabilityCheckForTouchpoint:touchpointName];
            [self startAvailabilityCheckForTouchpoint:touchpointName];
        }
    });
}

#pragma mark - Interstitial Availability


- (void)startAvailabilityCheckForTouchpoint:(NSString *)touchpointName {
    TPLog(@"startAvailabilityCheckForTouchpoint:%@", touchpointName);
    // populate the user agent. we need to do this here because background threads aren't allowed to create a web view.
    [[TpUserAgent sharedInstance] populateUserAgent];
    TpAvailabilityCheckOperation *newOp = [TpAvailabilityCheckOperation new];
    newOp.touchpointName = touchpointName;
    if (__interstitialAvailabilityChecks == nil) {
        __interstitialAvailabilityChecks = [[NSMutableDictionary alloc] init];
    }
    [__interstitialAvailabilityChecks setObject:newOp forKey:touchpointName];
    [_tpOperationQueue addOperation:newOp];
}

- (void)stopAvailabilityCheckForTouchpoint:(NSString *)touchpointName {
    TPLog(@"stopAvailabilityCheckForTouchpoint:%@", touchpointName);
    [[__interstitialAvailabilityChecks objectForKey:touchpointName] cancel];
    [__interstitialAvailabilityChecks removeObjectForKey:touchpointName];
}


// Hit the geo availability API for information on whether the touchpoint is available, or to poll for
// video trailers to preload. (Behavior depends on the integration type.)
//
// This also retrieves and stores the integration type of the touchpoint ('offerwall', 'interstitial', or 'dealspot').
//
// Returns the validity time, in seconds, until we should check availability again.
- (int)checkAvailabilityForTouchpoint:(NSString *)touchpointName {
    int validity_time;
    NSString *integrationType = [self getIntegrationTypeForTouchpoint:touchpointName];

    // Note: we'll only have the integration type if we've previously retrieved availability information. On our
    // first request the integration type is unknown.
    if ([integrationType isEqualToString:@"interstitial"]) {
        // Mark the touchpoint as unavailable until the API request completes.
        [self registerDealspotURL:@"" forTouchpoint:touchpointName];
    }

    // get the availability URL
    NSString *userAgent = [TpUserAgent sharedInstance].userAgent;
    NSString *availabilityURL = [[TpUrlManager sharedInstance] dealspotAvailabilityUrlForTouchpoint:touchpointName userAgent:userAgent];
    TPLog(@"Availability URL for touchpoint %@: %@", touchpointName, availabilityURL);
    if (availabilityURL == nil) {
        validity_time = TP_AVAILABILITY_DEFAULT_VALIDITY_TIME;
        return validity_time;
    }

    // grab contents of the URL
    NSError *downloadError = nil;
    NSData *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:availabilityURL] options:NSDataReadingMappedIfSafe error:&downloadError];
    if (downloadError) {
        TPCustomerError(@"TrialPay API Availability Query Error", @"TrialPay API Availability query error for touchpoint %@: %@", touchpointName, downloadError);
        validity_time = [self availabilityErrorTimeForTouchpoint:touchpointName];
        return validity_time;
    }
    if (responseData == nil) {
        TPCustomerError(@"Trialpay API Availability Query did not return data. Please verify setup and parameters.", @"Trialpay API Availability query for touchpoint %@ did not return data. Please verify setup and parameters.", touchpointName);
        validity_time = [self availabilityErrorTimeForTouchpoint:touchpointName];
        return validity_time;
    }

    // decode the contents
    NSError *decodeError = nil;
    NSDictionary *availabilityInfo = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&decodeError];
    if (decodeError) {
        TPCustomerError(@"TrialPay API Availability Results Error", @"TrialPay API Availability results error for Touchpoint %@: %@", touchpointName, downloadError);
        validity_time = TP_AVAILABILITY_DEFAULT_VALIDITY_TIME;
        return validity_time;
    }
    NSNumber *validity_time_object = [availabilityInfo objectForKey:@"validity_time"];
    // validity_time might not be set on the response. if not set then we fallback to default.
    if (validity_time_object != nil) {
        validity_time = [validity_time_object intValue];
    } else {
        validity_time = TP_AVAILABILITY_DEFAULT_VALIDITY_TIME;
    }

    // remove the error wait time for this touchpoint, if one is stored
    if (_interstitialAvailabilityErrorWaitTimes != nil) {
        [_interstitialAvailabilityErrorWaitTimes removeObjectForKey:touchpointName];
    }

    // Process the response. The integration type determines the actions we take.
    integrationType = [availabilityInfo objectForKey:@"integration_type"];
    if (integrationType == nil) {
        // This should always be returned, but we want to catch it if it somehow isn't.
        // Otherwise the whole app would crash when we try to store a nil value.
        integrationType = @"unknown"; // Mark the touchpoint as unavailable.
    }
    [self setIntegrationType:integrationType forTouchpoint:touchpointName];
    if ([integrationType isEqualToString:@"interstitial"]) {
        NSString *contentType = [availabilityInfo objectForKey:@"type"];
        NSString *dealspotURL;

        if ([contentType isEqualToString:@"web"]) {
            // This is a non-video-trailer offer. Just set the url as the dealspotURL.
            dealspotURL = [availabilityInfo objectForKey:@"url"];
        } else if ([contentType isEqualToString:@"video_trailer"]) {
            // This is a video trailer. Store video offer attributes and begin downloading the video to local storage.
            [[TpVideo sharedInstance] initializeVideoWithParams:availabilityInfo];

            // Assign a dealspot URL which will cause us to enter the video trailer flow when the touchpoint is opened.
            NSString *downloadURL = [availabilityInfo objectForKey:@"dl_url"];
            dealspotURL = [NSString stringWithFormat:@"%@%@", kTPKeyVideoPrefix, downloadURL];
        } else {
            TPLog(@"Received unexpected contentType %@ for interstitial touchpoint. Touchpoint will be unavailable.", contentType);
            dealspotURL = @""; // Mark this touchpoint as unavailable.
        }

        [self registerDealspotURL:dealspotURL forTouchpoint:touchpointName];
    } else {
        // This is either an offerwall or (non-interstitial) dealspot integration. We should get a list (possibly empty) of video offers to preload.
        NSArray *videoTrailers = [availabilityInfo objectForKey:@"video_trailers"];
        if (videoTrailers != nil) {
            // Store video offer attributes and begin downloading the videos to local storage.
            // The videoTrailers array can be empty, which is a valid response.
            for (NSDictionary *videoTrailerData in videoTrailers) {
                [[TpVideo sharedInstance] initializeVideoWithParams:videoTrailerData];
            }
        } else {
            TPLog(@"video_trailers was not set on response to non-interstitial touchpoint %@. This should never happen.", touchpointName);
        }
    }

    return validity_time;
}

// return the time in seconds when we should retry the availability check
- (int)availabilityErrorTimeForTouchpoint:(NSString *)touchpointName {
    if (_interstitialAvailabilityErrorWaitTimes == nil) {
        _interstitialAvailabilityErrorWaitTimes = [[NSMutableDictionary alloc] init];
    }
    // grab the last wait time for this touchpoint.
    NSNumber *error_wait_time_object = [_interstitialAvailabilityErrorWaitTimes objectForKey:touchpointName];
    int error_wait_time;
    if (error_wait_time_object == nil) {
        // this is our first request or the last request was a success. start with a wait of 10 seconds.
        error_wait_time = 10;
    } else {
        error_wait_time = [error_wait_time_object intValue] * 2; // wait twice as long as last time
    }
    if (error_wait_time > TP_AVAILABILITY_DEFAULT_VALIDITY_TIME) {
        error_wait_time = TP_AVAILABILITY_DEFAULT_VALIDITY_TIME;
    }
    // store the current wait time
    [_interstitialAvailabilityErrorWaitTimes setValue:[NSNumber numberWithInt:error_wait_time] forKey:touchpointName];

    return error_wait_time;
}

- (BOOL)isAvailableTouchpoint:(NSString *)touchpointName; {
    NSString *integrationType = [self getIntegrationTypeForTouchpoint:touchpointName];
    if ([integrationType isEqualToString:@"unknown"]) {
        // An unknown integration type means we haven't yet completed an availability check for this touchpoint.
        // Without the integration type we don't have enough information to confirm availability, so return NO.
        return NO;
    } else if ([integrationType isEqualToString:@"offerwall"]) {
        // Return YES - offerwalls are always available.
        return YES;
    } else {
        // This is either an interstitial or dealspot touchpoint. Look at the dealspot URL to determine availability.
        NSString *dealspotURL = [self urlForDealspotTouchpoint:touchpointName];
        if ((dealspotURL == nil) || [dealspotURL isEqualToString:@""]) {
            return NO;
        } else if ([dealspotURL hasPrefix:kTPKeyVideoPrefix]) {
            // This is an interstitial touchpoint loaded with a video trailer offer. Check if the trailer has been preloaded.
            NSString *videoResourceURL = [dealspotURL substringFromIndex:[kTPKeyVideoPrefix length]];
            return [[TpVideo sharedInstance] isResourceReady:videoResourceURL];
        } else {
            return YES;
        }
    }
}

@end
