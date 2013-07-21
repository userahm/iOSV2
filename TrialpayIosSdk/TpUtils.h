//
//  TpUtils.h
//  baseSdk
//
//  Created by Yoav Yaari on 5/30/13.
//  Copyright (c) 2013 Yoav Yaari. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <CommonCrypto/CommonDigest.h>
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
#import <AdSupport/ASIdentifierManager.h>
#endif

@interface TpUtils : NSObject

+ (NSString*) getAppver;
+ (NSString*) getIdfa;
+ (NSString*) getMacAddress;
+ (NSString*) sha1:(NSString*)input;

+ (NSString*) getDispatchPath;
+ (NSString*) getBalancePath;

@end
