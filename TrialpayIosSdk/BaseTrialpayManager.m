#import "BaseTrialpayManager.h"

// Create NSDLog - a debug call available on debug mode only
#ifdef DEBUG
#define NSDLog(FORMAT, ...) fprintf(stderr,"[TpBaseManager] %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSDLog(...)
#endif


@interface BaseTrialpayManager()
- (NSMutableDictionary *) getDataDictionary;
- (BOOL) saveDataDictionary;
- (BOOL) setDataWithValue:(id)value forKey:(NSString *)key;

@property (strong, nonatomic) NSCondition *balanceUpdateCondition;
@end

static BaseTrialpayManager *baseTrialpayManagerInstance;

@implementation BaseTrialpayManager
@synthesize delegate;
@synthesize balanceUpdateCondition;

NSLock *trialpayManagerDictionaryLock;

/* ************* Initialization ************* */

- (id)init {
    NSDLog(@"init");
    self = [super init];
    trialpayManagerDictionaryLock = [[NSLock alloc] init];
    return self;
}

+ (BaseTrialpayManager *)getInstance {
    return baseTrialpayManagerInstance;
}

+ (void)setInstance:(BaseTrialpayManager*)instance {
    baseTrialpayManagerInstance = instance;
}

/* ************* Get SDK Version ************* */
- (NSString*) getSdkVer {
    return @"ios.2.73652";
}

/* ************* Handling dictionary in TrialpayManager.plist ************* */
NSMutableDictionary *trialpayManagerDictionary = nil;

- (NSMutableDictionary *) getDataDictionary {
    NSDLog(@"getDataDictionary");
    if (nil == trialpayManagerDictionary) {
        // Get path
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        path = [path stringByAppendingPathComponent:@"TrialpayManager.plist"];
        
        // If the file exists - get the content from there. If not, create an empty dictionary
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            trialpayManagerDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
        } else {
            trialpayManagerDictionary = [[NSMutableDictionary alloc] init];
        }
    }
    return trialpayManagerDictionary;
}

- (BOOL) saveDataDictionary {
    NSDLog(@"saveDataDictionary");
    if (nil != trialpayManagerDictionary) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        path = [path stringByAppendingPathComponent:@"TrialpayManager.plist"];
        return [trialpayManagerDictionary writeToFile:path atomically:YES];
    }
    return NO;
}

- (BOOL) setDataWithValue:(NSObject *)value forKey:(NSString *)key {
    NSDLog(@"setDataWithValue:%@ forKey:%@)", value, key);
    [trialpayManagerDictionaryLock lock];
    NSMutableDictionary* dict = [self getDataDictionary];
    [dict setValue:value forKey:key];
    BOOL res = [self saveDataDictionary];
    [trialpayManagerDictionaryLock unlock];
    return res;
}

- (id) getDataValueForKey:(NSString *)key {
    NSDLog(@"getDataValueForKey:%@", key);
    NSDictionary *trialpayManagerDictionary = [self getDataDictionary];
    return [trialpayManagerDictionary valueForKey:key];
}

/* ************* BaseTrialpayManager getter/setter ************* */

- (void) setSid:(NSString *)sid {
    NSDLog(@"setSid:%@", sid);
    [self setDataWithValue:sid forKey:@"sid"];
}

- (NSString *) getSid {
    NSString *sid = [self getDataValueForKey:@"sid"];
    if (nil == sid) {
        sid = [TpUtils getIdfa];
        if ([@"" isEqual:sid]) {
            sid = [TpUtils getMacAddress];
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

- (NSMutableDictionary *) getTouchpointNames {
    NSMutableDictionary *touchpointNames = [self getDataValueForKey:@"touchpointNames"];
    if (nil == touchpointNames) {
        touchpointNames = [[NSMutableDictionary alloc] init];
    }
    return touchpointNames;
}

- (NSMutableArray *) getVics {
    NSMutableArray *vics = [self getDataValueForKey:@"vics"];
    if (nil == vics) {
        vics = [[NSMutableArray alloc] init];
    }
    return vics;
}

- (NSMutableDictionary *) getBalances {
    NSMutableDictionary *balances = [self getDataValueForKey:@"balances"];
    if (nil == balances) {
        balances = [[NSMutableDictionary alloc] init];
    }
    return balances;
}

- (void) registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName {
    NSDLog(@"registerVic:%@, withTouchpoint:%@", vic, touchpointName);
    // Get preregistered names
    NSMutableDictionary *touchpointNames = [self getTouchpointNames];
    // If the name is there and is set correctly - skip
    if ([vic isEqualToString:[touchpointNames valueForKey:touchpointName]]) {
        return;
    }
    // Get the list of vics
    NSMutableArray *vics = [self getVics];
    // If the new VIC name does not exist in the list (expected) add the vic to the vic list
    if (![vics containsObject:vic]) {
        [vics addObject:vic];
        [self setDataWithValue:vics forKey:@"vics"];
    }
    // Register the vic under the given touchpointName
    [touchpointNames setValue:vic forKey:touchpointName];
    [self setDataWithValue:touchpointNames forKey:@"touchpointNames"];
}

/* ************* Offerwall ************* */

- (void) openOfferwallForTouchpoint:(NSString *)touchpointName {
    NSDLog(@"openOfferwallForTouchpoint:%@", touchpointName);
    NSDictionary *touchpointNames = [self getTouchpointNames];
    NSString *vic = [touchpointNames valueForKey:touchpointName];
    if (nil == vic) {
        NSLog(@"TrialpayManager: Could not find VIC for %@. Skipping offerwall.", touchpointName);
        return;
    }
    NSString *sid = [self getSid];
    
    TpOfferwallViewController *tpOfferwall = [[TpOfferwallViewController alloc] initWithVic:vic sid:sid];
    tpOfferwall.delegate = self;
    
    UIViewController * root = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    [root presentModalViewController:tpOfferwall animated:YES];
}

- (void) openOfferwallWithVic:(NSString *)vicValue sid:(NSString *)sidValue {
    [self setSid:sidValue];
    [self registerVic:vicValue withTouchpoint:vicValue];
    [self openOfferwallForTouchpoint:vicValue];
}

/* ************* Balance ************* */

static NSThread* balanceQueryAndWithdrawThread;
static NSMutableDictionary *tpBalances;

- (void) add:(int)differentialBalance toBalanceWithVic:(NSString *)vic {
    NSMutableDictionary *balances = [self getBalances];
    NSNumber *existingBalance = [balances valueForKey:vic];
    if (nil == existingBalance) {
        existingBalance = [[NSNumber alloc] initWithInt:0];
    }
    existingBalance = [NSNumber numberWithInt:[existingBalance intValue] + differentialBalance];
    [balances setValue:existingBalance forKey:vic];
    [self setDataWithValue:balances forKey:@"balances"];
}

int balanceApiErrorWait = 10;
- (int) checkBalance {
    NSDLog(@"checkBalance");
    int minSecondsValid = -1;
    NSMutableArray *vics = [self getVics];
    for (NSString *vic in vics) {
        TpBalance* tpBalanceObject = [tpBalances valueForKey:vic];
        if (nil == tpBalanceObject) {
            NSString *sid = [self getSid];
            tpBalanceObject = [[TpBalance alloc] initWithVic:vic sid:sid];
            if (nil == tpBalanceObject) {
                NSLog(@"TrialpayManager ERROR: could not allocate a TpBalance object for vic=%@", vic);
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
        
        int differentialBalance = [[latestBalanceInfo objectForKey:@"balance"] intValue];
        int secondsValid = [[latestBalanceInfo objectForKey:@"seconds_valid"] intValue];
        
        if (differentialBalance > 0) {
            Boolean ackSuccess = [tpBalanceObject acknowledgeBalanceInfo: latestBalanceInfo];
            if (ackSuccess) {
                [self add:differentialBalance toBalanceWithVic:vic];
                if (delegate) {
                    [delegate TrialpayManager:self handleMessage:@"balance_update"];
                }
            }
        }
        if ((minSecondsValid < 0) || (minSecondsValid > secondsValid)) {
            minSecondsValid = secondsValid;
            balanceApiErrorWait = minSecondsValid;
        }
    }
    if (minSecondsValid<0) return balanceApiErrorWait;
    return minSecondsValid;
}

- (void) balanceQueryAndWithdraw {
    NSDLog(@"balanceQueryAndWithdraw");
    
    [balanceUpdateCondition lock];
    while([[NSThread currentThread] isCancelled] == NO) {
        int secondsValid = [self checkBalance];
        if (secondsValid < 0) {
            secondsValid = 10;
        }
        NSDLog(@"balanceQueryAndWithdraw before wait for %d", secondsValid);
        [balanceUpdateCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:secondsValid]];
    }
    [balanceUpdateCondition unlock];
}

- (void) initiateBalanceChecks {
    NSDLog(@"initiateBalanceChecks");
    if (nil != balanceQueryAndWithdrawThread) {
        [balanceQueryAndWithdrawThread cancel];
    }
    
    balanceUpdateCondition = [[NSCondition alloc] init];
    balanceQueryAndWithdrawThread = [[NSThread alloc] initWithTarget:self
                                                            selector:@selector(balanceQueryAndWithdraw)
                                                              object:nil];
    
    [balanceQueryAndWithdrawThread start];  // Actually create the thread
}

- (int) withdrawBalanceForTouchpoint:(NSString *)touchpointName {
    NSDLog(@"withdrawBalanceForTouchpoint:%@", touchpointName);
    NSDictionary *touchpointNames = [self getTouchpointNames];
    NSString *vic = [touchpointNames valueForKey:touchpointName];
    if (nil == vic) {
        NSLog(@"TrialpayManager: Could not find VIC for %@. Skipping offerwall.", touchpointName);
        return 0;
    }
    [balanceUpdateCondition lock];
    NSMutableDictionary *balances = [self getBalances];
    NSNumber *existingBalance = [balances valueForKey:vic];
    if (nil == existingBalance || 0 == [existingBalance intValue]) {
        [balanceUpdateCondition unlock];
        return 0;
    }
    
    [balances setValue:0 forKey:vic];
    [self setDataWithValue:balances forKey:@"balances"];
    [balanceUpdateCondition unlock];
    return [existingBalance intValue];
}

/* ************* Delegate ************* */

- (void) tpOfferwallViewController:(TpOfferwallViewController *)tpOfferwallViewController close:(id)sender {
    // the offerwall container just got closed. wake up the balance check
    [balanceUpdateCondition signal];
    if (delegate) {
        [delegate TrialpayManager:self handleMessage:@"offerwall_close"];
    }
}

@end