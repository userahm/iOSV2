//
//  TrialpayManager.h
//
//  Created by Trialpay Inc.
//  Copyright (c) 2013 TrialPay, Inc. All Rights Reserved.
//

#import <Foundation/Foundation.h>
#import "BaseTrialpayManager.h"
#import "TpConstants.h"

@class TpDealspotView;

/*!
    @mainpage

    Trialpay iOS SDK API Reference Documentation.

    Thanks for using Trialpay!

    Follow the @ref SampleIntegration or browse through the @ref TrialpayManager for details on each API feature.

     @see <a href="http://help.trialpay.com/mobile/ios-sdk">Integrating the TrialPay SDK into an iOS app</a>
     @see @ref TrialpayManager
     @see @ref TrialpayManagerDelegate
     @see @ref SampleIntegration

     @page SampleIntegration Sample Integration

 

In your Interface Builder
 1. Create a UIButton that will allow to open the Offer Wall
 2. Create a TpDealspotView element
 
In your view controller header
@code
 
...
#import "TrialpayManager.h"
...
@interface MyViewController : UIViewController <TrialpayManagerDelegate>
...
- (IBAction)openOfferwallWithSender:(id)sender;
@property (weak, nonatomic) IBOutlet TpDealspotView *dealspotView;
 
@endcode

In your view controller module
@code
 
...
@implementation MyViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Load the Trialpay Manager object
    TrialpayManager* trialpayManager = [TrialpayManager getInstance];
    // Set the user id. Not required if you are using Balance API
    [trialpayManager setSid:@"<UNIQUE_USER_ID>"];
    // Register the Offer Wall touchpoint
    [trialpayManager registerVic:@"<OFFERWALL_INTEGRATION_CODE_FROM_TRIALPAY>" withTouchpoint:@"<YOUR_OFFERWALL_TOUCHPOINT_NAME>"];
    // Set the DealSpot touchpoint
    [trialpayManager registerVic:@"<DEALSPOT_INTEGRATION_CODE_FROM_TRIALPAY>" withTouchpoint:@"<YOUR_DEALSPOT_TOUCHPOINT_NAME>"];
    [self.dealspotView setTouchpointName:@"dealspot"];
    // Initiate Balance API checks. Not needed if you accept callbacks to your server
    [trialpayManager initiateBalanceChecks];
    // Get responses from Trialpay
    [trialpayManager setDelegate:self];
}

// Associate this IBAction with the button that triggers the Offer Wall
- (IBAction)openOfferwallWithSender:(id)sender
{
    TrialpayManager *trialpayManager = [TrialpayManager getInstance];
    [trialpayManager openTouchpoint:@"<YOUR_OFFERWALL_TOUCHPOINT_NAME>"];
}

// Listen to TrialPay's balance updates if you're using the Balance API
- (void)trialpayManager:(TrialpayManager *)trialpayManager balanceWasUpdatedForTouchpoint:(NSString*)touchpointName
{
  int balanceToAdd = [trialpayManager withdrawBalanceForTouchpoint:touchpointName];
  // TODO: Add the balanceToAdd amount to the user's credits
}

// Optional: Listen to TrialPay's Close event
- (void)trialpayManager:(TrialpayManager *)trialpayManager offerwallDidCloseForTouchpoint:(NSString*)touchpointName 
{
  // TODO: Implement
}
 
 
...

@end

@endcode

@page AdvancedIntegration Advanced Integration
Passing the following values will improve TrialPay's monetization for your app
 
Demographic information
---
Call this code when the app loads the user information
@code
 [[TrialpayManager getInstance] setAge:userAge];
 [[TrialpayManager getInstance] setGender:userGender];
@endcode

User's progress
---
Every time the user goes into a new level, call the method below.
@code
 [[TrialpayManager getInstance] updateLevel:level];
@endcode
For this scope, level is the numerical ordered value that correlates with the experience that the user gained in the game.
Not sure what the value should be? Ask us.
 
Virtual Currency gaining
---
When users are granted with virtual currency as a result of a purchse, offer based earning or a gifting event in the app, call the following method:
@code
 [[TrialpayManager getInstance] updateVcPurchaseInfoForTouchpoint:@"<TOUCHPOINT_FOR_VC>" dollarAmount:dollarAmount vcAmount:vcAmount];
@endcode
Note:
 1. Pass only dollar amount
 2. If a user gets VC for free, pass 0 as the dollar amount
 3. Call this method even when the credit event was done through TrialPay:
@code
// Listen to Trialpay' balance updates if you're using the Balance API
- (void)trialpayManager:(TrialpayManager *)trialpayManager balanceWasUpdatedForTouchpoint:(NSString*)touchpointName {
  int balanceToAdd = [trialpayManager withdrawBalanceForTouchpoint:touchpointName];
  [trialpayManager updateVcPurchaseInfoForTouchpoint:touchpointName dollarAmount:0 vcAmount:balanceToAdd];
  // TODO: Add the balanceToAdd amount to the user's credits
}
@endcode
 
Update current Virtual Currency state
---
Call this method with the same value that would appear on the screen for the user.
@code
 [[TrialpayManager getInstance] updateVcBalanceForTouchpoint:@"<TOUCHPOINT_FOR_VC>" vcAmount:vcAmount];
@endcode
Note:
 1. The vcAmount is not an incremental change - it is the current Virtual Currency value. It is recommended to call it on the same method that updates the value on the screen.
 2. Calling updateVcPurchaseInfoForTouchpoint:dollarAmount:vcAmount: does not update the balance.

Custom Parameters
---
If you're using the callback method and created a custom parameter on the merchant panel, use the code below in order to set the custom parameter:
@code
// Associate this IBAction with the button that triggers the Offer Wall
- (IBAction)openOfferwallWithSender:(id)sender {
  TrialpayManager *trialpayManager = [TrialpayManager getInstance];
  [trialpayManager setCustomParamValue:@"custom_param_value" forName:@"my_custom_parameter";];
  [trialpayManager openTouchpoint:@"<YOUR_OFFERWALL_TOUCHPOINT_NAME>"];
}
@endcode
Note: the custom parameter value is being reset after opening the Offer Wall
 */



/*!
     This is the class used to perform all SDK tasks.

     Terminology:
     - <b>User</b>: the user that is using the app on the device.
     - <b>VIC</b>: the campaign identification, also called "Integration Code". Find it on your Merchant page/Products, the item "Get integration code" under every campaign.
     - <b>SID</b>: an unique device user identification. Its preferably provided by you, but can be generated by Trialpay.
     - <b>Touchpoint</b>: identifies the button that was clicked to open the Offer Wall - the name is your choice.


     @see <a href="http://help.trialpay.com/mobile/ios-sdk">Integrating the TrialPay SDK into an iOS app</a>
     @see @ref SampleIntegration
*/
@interface TrialpayManager : BaseTrialpayManager

/*!
     Get the Trialpay Manager instance.
     @returns The Trialpay Manager instance.
 */
+ (TrialpayManager*)getInstance;
/*!
     Get the version of the SDK.
     @return The SDK Version.
 */
- (NSString*)sdkVersion;

/*!
     Set SID (device user identification). The SID is an unique user id for each device user. It will be used to uniquely identify your user with Trialpay system for monetization and customer support purposes.
     If you do not maintain a unique user id, we define one for the user by hashing different device identifiers such as IDFA and the device’s MAC address. Please note that choosing this path will prevent us from sending you server side notifications about your users activities.
     Therefore, for completion notification, please make sure to initiate the Balance Check.
    @param sid The device user identifier.
*/
- (void)setSid:(NSString *)sid;

/*!
     Retrieve the SID (device user identification).
    @return The device user identifier.
*/
- (NSString *)sid;

/*!
    Register your VIC (campaign identification) - the campaign integration code, a 32 Hex string that is being used in order to uniquely define your touchpoint.
    This is required to make this touchpoint available.
    @param vic The campaign identifier.
    @param touchpointName The touchpoint to register.
*/
- (void)registerVic:(NSString *)vic withTouchpoint:(NSString *)touchpointName;

/*!
    Open the Trialpay Offer Wall for a given touchpoint.
    @param touchpointName The touchpoint.

    @deprecated - Please use openTouchpoint:
*/
- (void)openOfferwallForTouchpoint:(NSString *)touchpointName __attribute__((deprecated));
/*!
    Open the touchpoint. This function should be used for Offerwall and Interstitial touchpoints.
    @param touchpointName The touchpoint
*/
- (void)openTouchpoint:(NSString *)touchpointName;

/*!
    Create the Trialpay Dealspot for a given touchpoint.
    @param touchpointName The touchpoint.
    @param touchpointFrame The frame for the touchpoint icon
*/
- (TpDealspotView *)createDealspotViewForTouchpoint:(NSString *)touchpointName withFrame:(CGRect)touchpointFrame;

/*!
    Stop and remove from UI the Trialpay Dealspot for a given touchpoint.
    @param touchpointName The touchpoint.
*/
- (void)stopDealspotViewForTouchpoint:(NSString *)touchpointName;

/*!
    Start balance checks. Call this method only once, within your application:didFinishLaunchingWithOptions:.
    @note Only start balance checks if you enabled the Balance Check API
*/
- (void)initiateBalanceChecks;
/*!
    Withdraw a differential balance for a given touchpoint.
    @note The differential balance is only what was earned, it does NOT refer to the total balance the user ever received.
    @param touchpointName The touchpoint to withdraw from.
    @return The differential balance the device user received.
*/
- (int)withdrawBalanceForTouchpoint:(NSString *)touchpointName;

/*!
    Start availability checks. Call this method only once, within your application:didFinishLaunchingWithOptions:.
    @note Only start availability checks for Interstitial flow.
*/
- (void)startAvailabilityCheckForTouchpoint:(NSString *)touchpointName;

/*!
    Check whether a touchpoint is available
    @note Check availability only for Interstitial flows
 */
- (BOOL)isAvailableTouchpoint:(NSString *)touchpointName;

/*!
    Set the age of the device user. Affects all touchpoints.
    This method should be called on device user registration or during initialization.
    @param age The age of device user.
*/
- (void)setAge:(int)age;
/*!
    Set the gender of the device user. Affects all touchpoints.
    This method should be called on device user registration or during initialization.
    @param gender The gender of the device user. Values can be Female, Male or Unknown
 */
- (void)setGender:(Gender)gender;
/*!
    Set the level of the user on this game. Affects all touchpoints.
    This method should be called whenever there's a level/stage update in the game (showing the maximum enabled level for the user). Can be called right before the touchpoint is being loaded.
    @param level The new level of the device user.
 */
- (void)updateLevel:(int)level;

/*!
    This method stores custom parameters. All set parameters (even if they have a value of an empty string) will be passed on API calls.
    If the paramValue is set to Null, the passed value will be "" (empty string).
    @param paramValue The value of the parameter.
    @param paramName The name of the parameter.
*/
- (void)setCustomParamValue:(NSString *)paramValue forName:(NSString *)paramName;

/*!
    This method clears custom parameters.
    @param paramName The name of the parameter to clear.
 */
- (void)clearCustomParamWithName:(NSString *)paramName;
/*!
    Stores, for each touchpoint and aggregate the dollarAmount and vcAmount.
    This method should be called by the developer when an IAP purchase is done.
    It allows to track the life time dollar amount spent by that device user and the life time virtual currency amount purchased.
    It should also be used if the device user can gain virtual currency in the game without purchasing it (dollarAmount can be 0)

    @param touchpointName The touchpoint that is getting credited.
    @param vcAmount The amount of virtual currency to add to the balance.
    @param dollarAmount The amount of currency (dollars) to add to the balance.
 */
- (void)updateVcPurchaseInfoForTouchpoint:(NSString *)touchpointName dollarAmount:(float)dollarAmount vcAmount:(int)vcAmount;
/*!
    Should be called whenever there's a virtual currency activity (or right before the touchpoint is being loaded)
    @param vcAmount The amount of virtual currency to add to the balance.
    @param touchpointName The touchpoint that is getting credited.
 */
- (void)updateVcBalanceForTouchpoint:(NSString *)touchpointName vcAmount:(int)vcAmount;

/*!
    Delegate for Offer Wall close events and Balance update events, See TrialpayManagerDelegate.
    @include updateVcBalanceForTouchpoint.m
*/
@property (strong, nonatomic) id<TrialpayManagerDelegate> delegate;


@end
