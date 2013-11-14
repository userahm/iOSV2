//
// Created by Daniel Togni on 11/4/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//


#import <Foundation/Foundation.h>

#ifndef __has_feature
#define __has_feature(x) 0 /* for non-clang compilers */
#endif

// Define Non-ARC utilities for compiling with Unity (no need to change .h files)
#if __has_feature(objc_arc)
#define TP_RETAIN self
#define TP_AUTORELEASE self
#define TP_RELEASE self
#define TP_DEALLOC self
#define TP_ARC_RELEASE(obj) self.obj = nil;
#else
#define TP_RETAIN retain
#define TP_AUTORELEASE autorelease
#define TP_RELEASE release
#define TP_DEALLOC dealloc
#define TP_ARC_NAME(obj) _##obj
#define TP_ARC_RELEASE(obj) [TP_ARC_NAME(obj) release]; TP_ARC_NAME(obj) = nil;
#endif
