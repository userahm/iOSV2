//
// Created by Daniel Togni on 9/27/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface TpDataStore : NSObject
+ (TpDataStore *)sharedInstance;
- (void)clearDataDictionary;
- (BOOL)setDataWithValue:(NSObject *)value forKey:(NSString *)key;
- (id)dataValueForKey:(NSString *)key;
@end