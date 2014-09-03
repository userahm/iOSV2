//
// Created by Trialpay, Inc. on 9/27/13.
// Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import "TpSdkConstants.h"

NSString *kTPKeyUserCreationTime = @"userCreationTime";
NSString *kTPKeyVisitTimestamps  = @"visitTimestamps";
NSString *kTPKeyVisitLengths     = @"visitLengths";
NSString *kTPKeyTouchpointNames  = @"touchpointNames";
NSString *kTPKeyDealspotURLs     = @"dealspotURLs";
NSString *kTPKeyIntegrationTypes = @"integrationTypes";
NSString *kTPKeyBalances         = @"balances";
NSString *kTPKeyVICs             = @"vics";
NSString *kTPKeyAge              = @"age";
NSString *kTPKeyGender           = @"gender";
NSString *kTPKeyVCBalance        = @"vcBalance";
NSString *kTPKeyVCPurchaseInfo   = @"vcPurchaseInfo";
NSString *kTPKeyLevel            = @"level";
NSString *kTPKeyDollarAmount     = @"dollarAmount";
NSString *kTPKeyVCAmount         = @"vcAmount";
NSString *kTPSid                 = @"sid";
NSString *kTPKeySecondsValid     = @"seconds_valid";
NSString *kTPKeyBalance          = @"balance";
NSString *kTPKeyUseWebNavigationBar = @"useWebNavigationBar";
NSString *kTPKeyVideoMetaData    = @"videoMetaData";
NSString *kTPKeyVideoPrefix      = @"tpvideo";

NSString *kTPOfferContainer = @"offerContainer";
NSString *kTPOfferwallContainer =  @"offerwallContainer";

NSString *kTPSDKEventTypeKey = @"type";
NSString *kTPSDKEventSourceKey = @"source";
NSString *kTPSDKEventNewStatusKey = @"newStatus";
NSString *kTPSDKEventURLKey = @"url";
NSString *kTPSDKEventTypeContainerStatusChanged = @"containerStatusChanged";
NSString *kTPSDKEventTypePageStatusChanged = @"pageStatusChanged";
NSString *kTPSDKEventStatusLoadingStarted = @"loadingStarted";
NSString *kTPSDKEventStatusLoadingFinished = @"loadingFinished";
NSString *kTPSDKEventStatusClosed = @"closed";

CGFloat const kTpPopupVerticalMargin = 10;
CGFloat const kTpPopupHorizontalMargin = 20;

CGFloat const kTpDownloadNowButtonShadowRadius = 3.0;
const int kTpVideoTypeIOSVideo = 4; // passed as vt to video event tracking (user/html/vt/index.php). must match value in lib/common/biz/video_config.php.
