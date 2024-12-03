/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import {
    getBasketIdFromCookie,
    storeBasketIdToCookie,
    clearBasketIdCookie
} from 'c/onlBasket2';

import validateCouponAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.validateCouponAndAddToBasket';
import getTestDetails from '@salesforce/apex/onl_CheckoutCtrl.getTestDetails';
import getOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getOpportunity';
import getProductsCountOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getProductsCountOpportunity';
import FORM_FACTOR from '@salesforce/client/formFactor';

const OPP_STATE_DRAFT = 'Draft';
const OPP_STATE_CONFIRMED = 'Confirmed';
const OPP_STATE_COMPLETED = 'Completed';

export default class OnlMain extends LightningElement {

    @api opportunityId;
    @api queryParameters;
    @api storeConfig;


    formFactor = FORM_FACTOR;

    basketCount = 0;
    basketState = OPP_STATE_DRAFT;

    defaultPersonalDetails = {};

    triggerOpenScheduleModal;
    testProductToSchedule;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    /* state machine for shopping */

    // defaults
    sm_page = {main: true};
    sm_menuSelection = 'covid';

    get sm_showFulfillmentItems() {
        return this.sm_page.cart && this.step.scheduling;
    }

    get sm_showCheckoutForms() {
        return this.sm_page.cart && !this.step.scheduling;
    }


    get basketLabel() {
        return 'Your order (' + this.basketCount + ')';
    }

    /* steps:
    - find
    - personal
    - scheduling
     */
    step = {
        find: true,
        covid: true
    };

    step1DefaultLocation = {};
    checkoutParams = {};

    connectedCallback() {
        console.log('::main:cc:queryParameters', JSON.stringify(this.queryParameters));
        let cookie_basketId = getBasketIdFromCookie();
        console.log('::main:cc:cookie_basketId', cookie_basketId);

        this.refreshBasketCount();

        if (this.queryParameters) {
            if (this.queryParameters.opid) {
                this.opportunityId = this.queryParameters.opid;
                this.sm_page = {cart: true};
                this.step = {scheduling: true};
            } else if (this.queryParameters.id) {
                console.log('::main:id', this.queryParameters.id);
                this.copyParamsFrom(this.queryParameters.id);
            } else {

                if (this.queryParameters.coupon) {
                    this.checkCoupon(this.queryParameters.coupon);
                }

                if (this.queryParameters.page) {
                    switch (this.queryParameters.page) {
                        case 'cart' :
                            this.sm_page = {cart: true};
                            if (cookie_basketId) {
                                this.opportunityId = cookie_basketId;
                                this.step = {scheduling: true}
                            }
                            break;
                        default:
                            this.sm_page = {main: true};
                            break;
                    }
                }
                if (this.queryParameters.sub === 'appointment' || this.queryParameters.sub === 'product')
                    this.sm_menuSelection = this.queryParameters.sub;
            }
        }

        console.log('::main:sm_page, step', JSON.stringify(this.sm_page), JSON.stringify(this.step));
    }

    // fill search and personal details with previous test data, when provided in query parameters
    copyParamsFrom(testId) {
        if (testId) {
            console.log('::main:copyParamsFrom:', testId);
            getTestDetails({testId: testId})
                .then(results => {
                    console.log('::main:copyParamsFrom:getTestDetails:result', results);
                    if (results) {
                        let origTest = JSON.parse(results);

                        let newDefaults = {};
                        this.defaultPersonalDetails = {};

                        if (origTest) {

                            this.defaultPersonalDetails.email = origTest.Provided_Email__c;
                            this.defaultPersonalDetails.firstName = origTest.Provided_First_Name__c;
                            this.defaultPersonalDetails.lastName = origTest.Provided_Last_Name__c;
                            this.defaultPersonalDetails.phone = origTest.Provided_Phone_Number__c;

                            //auto select checkboxes for consents
                            this.defaultPersonalDetails.checktac = true;
                            this.defaultPersonalDetails.checkshare = true;

                            // not needed
                            // newDefaults.type = origTest.Test_Type__c;
                            // newDefaults.turnaround = origTest.Turnaround_Time_Global__c;

                            if (origTest.Scheduled_Appointment__r
                                && origTest.Scheduled_Appointment__r.ServiceTerritory
                                && origTest.Scheduled_Appointment__r.ServiceTerritory.Address) {
                                newDefaults.postalcode = origTest.Scheduled_Appointment__r.ServiceTerritory.Address.postalCode
                            }

                            let find_tests_component = this.template.querySelector('[data-cfct]');
                            if (find_tests_component) find_tests_component.defaults(newDefaults);
                        }
                    }
                })
                .catch(error => {
                    console.error('::main:copyParamsFrom:failed', error);
                });
        }
    }

    checkCoupon(coupon) {
        if (coupon) {
            let request = {
                couponCode: coupon.toUpperCase(),
                store: this.storeConfig.storeName,
                oppId: getBasketIdFromCookie()
            }
            console.log('::main:checkCoupon', JSON.stringify(request));
            validateCouponAndAddToBasket(request)
                .then(result => {
                    console.log('::main:checkCoupon:validateCouponAndAddToBasket:result', result);
                    if (result) {
                        if (!result) {
                            console.log('::main:checkCoupon:not valid');
                        }
                        else
                        {
                            storeBasketIdToCookie(result);
                        }
                    }
                })
                .catch(error => {
                    console.error('::main:checkCoupon:validateCouponAndAddToBasket:failed', error);
                });
        }
    }

    //on main menu option selected
    handleMenuOption(e) {
        this.sm_menuSelection = e.detail;
    }

    // on Continue from Checkout page info
    //   go to step order overview
    handleDoCheckout(e) {
        this.checkoutParams = e.detail.params;
        this.checkoutParams.basketId = getBasketIdFromCookie();
        this.step = {scheduling: true};
    }

    handleContinueToPayment(event) {
        console.log('::handleContinueToPayment', JSON.stringify(event.detail));
        this.dispatchEvent(new CustomEvent('continuetopayment', {
            detail: {session: event.detail.session}
        }));
    }

    navigateToCheckout() {
        window.open("?page=cart", "_self");
    }

    handleBackFromCart() {
        window.open("?page=main", "_self");
    }

    /** on schedule event from find covid test result row v2
     * Example event.detail:
     * {
    "product": {
        "attributes": {
            "type": "Product2",
            "url": "/services/data/v52.0/sobjects/Product2/01t3H0000013S9oQAE"
        },
        "Id": "01t3H0000013S9oQAE",
        "Quantity_of_COVID_Tests__c": 1,
        "Store_Sort_Order__c": -100,
        "Turnaround_Time_Global__c": "Same Day",
        "Requires_scheduling__c": true,
        "Requires_delivery__c": false,
        "Product_Sub_Family__c": "PCR Test",
        "Work_Type_Group__c": "0VS4H0000000006WAA",
        "Non_Membership_Price__c": 149,
        "Name": "PCR Test Same Day",
        "Default_COVID_Tests__r": {
            "totalSize": 1,
            "done": true,
            "records": [
                {
                    "attributes": {
                        "type": "Default_COVID_Test__c",
                        "url": "/services/data/v52.0/sobjects/Default_COVID_Test__c/a2i3H000000McrRQAS"
                    },
                    "Product__c": "01t3H0000013S9oQAE",
                    "Id": "a2i3H000000McrRQAS",
                    "COVID_Test_Type__c": "PCR Test",
                    "Name": "DCT-000017",
                    "Number_of_Tests__c": 1,
                    "Turnaround_Time__c": "Same Day",
                    "Work_Type_Group__c": "0VS4H0000000006WAA",
                    "First_Available__c": false
                }
            ]
        },
        "type": "covid"
    },
    "quantity": 1,
    "defaultLocation": {
        "postalcode": "SW6 1AY",
        "distance": "1"
    },
    firstAvailable":"2021-05-31"
}

     * @param event
     */
    handleScheduleTest(event) {
        console.log('::main2:handleSceduleTest:event.detail', JSON.stringify(event.detail));

        try {
            this.testProductToSchedule = {};
            this.testProductToSchedule.product = event.detail.product;
            this.testProductToSchedule.defaultLocation = event.detail.defaultLocation;
            this.testProductToSchedule.defaultLocation.firstAvailable = event.detail.firstAvailable;

            this.openScheduleModal();
        } catch (e) {
            console.error(e);
        }
    }

    handleBooked() {
        this.refreshBasketCount();
    }

    openScheduleModal() {
        this.triggerOpenScheduleModal = true;
    }

    closeScheduleModal() {
        this.refreshBasketCount();
        this.triggerOpenScheduleModal = false;
    }

    refreshBasketCount() {
        let basketId = getBasketIdFromCookie();
        if (basketId) {
            let request = {oppid: basketId};
            console.log('::getProductsCountOpportunity', JSON.stringify(request));
            getProductsCountOpportunity(request)
                .then(result => {
                    console.log('::getProductsCountOpportunity:result', result);
                    let respObj = JSON.parse(result);
                    this.basketState = respObj.status;
                    if (this.basketState === OPP_STATE_CONFIRMED) {
                        clearBasketIdCookie();
                    } else {
                        this.basketCount = respObj.productCount;
                    }

                })
                .catch(error => {
                    console.error('::getProductsCountOpportunity:failed', error);
                })
                .finally(() => {

                });
        }
    }

}