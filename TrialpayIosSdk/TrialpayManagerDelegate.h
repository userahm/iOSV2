//
// Created by Trialpay, Inc. on 10/24/13.
// Copyright (c) 2013 TrialPay Inc. All rights reserved.
//

#ifndef __TrialpayManagerDelegate_H_
#define __TrialpayManagerDelegate_H_

@class TrialpayManager;

/*!
    @brief Trialpay block methods interface (alternative to delegate).
    @param[in/out/in,out] TrialpayManager
*/
typedef void (^TPDelegateBlock)(TrialpayManager*);

/*!
    @var typedef enum TPMessageAction
    Trialpay actions used by TrialpayManagerDelegate::trialpayManager::withAction.
    @deprecated
*/
typedef enum {
    TPUnknownAction=0,        /*! Unknown action */
    TPOfferwallOpenAction=1, /*! The Trialpay offerwall was opened */
    TPOfferwallCloseAction=2, /*! The Trialpay offerwall was closed */
    TPBalanceUpdateAction=3,  /*! The device user balance was updated, check TrialpayManager::withdrawBalanceForTouchpoint:*/
} TPMessageAction;

/*!
     Protocol to respond to Trialpay events (TPMessageAction).
*/
@protocol TrialpayManagerDelegate
@optional

// NOTE: Using <method> __attribute__((deprecated)), but it generates warnings on compile time on our own code, not only
// when user implements function, so using TPCustomerWarnings if delegate respondsTo, see BaseTPM::setDelegate:
/*!
     Announces Trialpay events.
     @param trialpayManager the trialpay manager object which triggered the event
     @param action the action being notified
     @deprecated Use trialpayManager:offerwallDidOpenForTouchpoint:, trialpayManager:offerwallDidCloseForTouchpoint: and trialpayManager:balanceWasUpdatedForTouchpoint:
*/
- (void)trialpayManager:(TrialpayManager *)trialpayManager withAction:(TPMessageAction)action;

/*!
     Announces Trialpay offerwall was open.
     @param trialpayManager the trialpay manager object which triggered the event
     @param touchpointName the touchpointName that triggered the offerwall to open
*/
- (void)trialpayManager:(TrialpayManager *)trialpayManager offerwallDidOpenForTouchpoint:(NSString*)touchpointName;

/*!
     Announces Trialpay offerwall was closed.
     @param trialpayManager the trialpay manager object which triggered the event
     @param touchpointName the touchpointName that triggered the offerwall to open
*/
- (void)trialpayManager:(TrialpayManager *)trialpayManager offerwallDidCloseForTouchpoint:(NSString*)touchpointName;

/*!
     Announces Trialpay a balance update was received from Trialpay servers.
     @param trialpayManager the trialpay manager object which triggered the event
     @param touchpointName the touchpointName related to the balance update.
*/
- (void)trialpayManager:(TrialpayManager *)trialpayManager balanceWasUpdatedForTouchpoint:(NSString*)touchpointName;

@end

#endif //__TrialpayManagerDelegate_H_
