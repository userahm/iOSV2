#import "TrialpayManager.h"

// Create NSDLog - a debug call available on debug mode only
#ifdef DEBUG
#define NSDLog(FORMAT, ...) fprintf(stderr,"[TrialpayManager] %s\n", [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSDLog(...)
#endif

@implementation TrialpayManager

/* ************* getInstance ************* */
+ (BaseTrialpayManager *)getInstance {
    NSDLog(@"getInstance");
    if (![super getInstance]) {
        [super setInstance:[[TrialpayManager alloc] init]];
    }
    return [super getInstance];
}

/* ************* Get SDK Version ************* */
- (NSString*) getSdkVer {
    return [NSString stringWithFormat:@"sdk.%@", [super getSdkVer]];
}


@end