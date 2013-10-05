//  Copyright (C) 2013 TrialPay, Inc All Rights Reserved
//
//  TrialpayManager.h
//

#import <Foundation/Foundation.h>
#import "BaseTrialpayManager.h"
#import "TpConstants.h"

@interface TrialpayManager : BaseTrialpayManager

+ (TrialpayManager*) getInstance;
+ (NSString*) sdkVersion;

@end
