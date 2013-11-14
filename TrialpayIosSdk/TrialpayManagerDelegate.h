//
// Created by Daniel Togni on 10/24/13.
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
*/
typedef enum {
    TPUnknownAction,        /*! Unknown action */
    TPBalanceUpdateAction,  /*! The device user balance was updated, check TrialpayManager::withdrawBalanceForTouchpoint:*/
    TPOfferwallCloseAction, /*! The Trialpay offerwall was closed */
    TPDealspotTouchointShowAction,  /*! The Trialpay dealspot touchpoint was shown */
    TPDealspotTouchointHideAction,  /*! The Trialpay dealspot touchpoint was hidden*/
} TPMessageAction;

/*!
     Protocol to respond to Trialpay events (TPMessageAction).
*/
@protocol TrialpayManagerDelegate
/*!
     Announces Trialpay events.
     @param trialpayManager the trialpay manager object which triggered the event
     @param action the action being notified
*/
- (void)trialpayManager:(TrialpayManager *)trialpayManager withAction:(TPMessageAction)action;
@end

#endif //__TrialpayManagerDelegate_H_
