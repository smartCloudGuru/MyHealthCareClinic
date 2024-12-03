/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import {
    addToBasket,
    setBasket,
    getBasketCount,
    getBasketHasCoupon,
    getCurrentCouponName,
    getBasket,
    getBasketIdFromCookie,
    storeBasketIdToCookie,
    clearBasketIdCookie,
    addCoupon,
    getOpportunityIdFromCookie,
    storeOpportunityIdToCookie,
    clearOpportunityIdCookie
} from 'c/onlBasket';

import persistBasket from '@salesforce/apex/onl_CheckoutCtrl.saveBasket';
import getPersistedBasket from '@salesforce/apex/onl_CheckoutCtrl.getBasket';
import validateCoupon from '@salesforce/apex/onl_CheckoutCtrl.validateCoupon';
import getTestDetails from '@salesforce/apex/onl_CheckoutCtrl.getTestDetails';

import FORM_FACTOR from '@salesforce/client/formFactor';

export default class OnlMain extends LightningElement {

    @api opportunityId;
    @api queryParameters;
    @api storeConfig;

    formFactor = FORM_FACTOR;

    basket = null;
    basketCount = 0;
    basketMessage = null;
    triggerOpenBasketModal = false;

    basketLoaded = false;

    _basketHasCoupon;

    defaultPersonalDetails = {};

    get basketHasCoupon() {
        return this._basketHasCoupon;
    }

    get currentCouponName() {
        return getCurrentCouponName();
    }

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
        return 'Checkout (' + this.basketCount + ')';
    }

    get basketWrapper() {
        if (!this.basket) return null;
        return {
            basket: this.basket,
            defaultPersonalDetails: this.defaultPersonalDetails
        }
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
        let cookie_basketId = getBasketIdFromCookie()
        console.log('::main:cc:cookie_basketId', cookie_basketId);


        this.loadPersistedBasket();

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
                            let opIdCookie = getOpportunityIdFromCookie();
                            console.log('::main:cc:opidCookie', opIdCookie);
                            if (opIdCookie) {
                                this.opportunityId = opIdCookie;
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
            console.log('::main:checkCoupon:coupon', coupon.toUpperCase());
            validateCoupon({couponCode: coupon.toUpperCase(), store: this.storeConfig.storeName})
                .then(results => {
                    console.log('::main:checkCoupon:validateCoupon:result', results);
                    if (results) {
                        let coupon = JSON.parse(results);

                        if (!coupon || !coupon.Name || !coupon.Id) {
                            console.log('::main:checkCoupon:not valid');
                        } else {
                            let passed = addCoupon(coupon);
                            console.log('::main:checkCoupon:addCoupon', passed);
                            console.log('::main:checkCoupon:basket', getBasket());
                            this._basketHasCoupon = getBasketHasCoupon();
                            if (passed) this.doPersistBasket();
                        }
                    }
                })
                .catch(error => {
                    console.error('::main:checkCoupon:validateCoupon:failed', error);
                });
        }
    }

    handleAddToBasket(e) {
        e.preventDefault();
        e.stopPropagation();

        addToBasket(e.detail);
        this.basketCount = getBasketCount();
        this.basket = getBasket();

        if (e.detail.defaultLocation && e.detail.defaultLocation.postalcode && e.detail.defaultLocation.distance) {
            this.step1DefaultLocation = e.detail.defaultLocation;
        }

        this.doPersistBasket(e.detail);
    }

    //on main menu option selected
    handleMenuOption(e) {
        this.sm_menuSelection = e.detail;
    }

    // on Continue from Checkout page info
    handleDoCheckout(e) {
        // console.log('::handlePersonalDone', JSON.stringify(e.detail.params));
        // console.log('::handlePersonalDone:step1DefaultLocation', this.step1DefaultLocation);
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

    openBasketModal(msg) {
        this.basketMessage = msg;
        this.triggerOpenBasketModal = true;
    }

    closeBasketModal() {
        this.triggerOpenBasketModal = false;
    }

    navigateToCheckout() {
        clearOpportunityIdCookie();
        window.open("?page=cart", "_self");
    }

    handleBackFromCart() {
        window.open("?page=main", "_self");
    }

    doPersistBasket(addedDetail) {
        this.basket = getBasket();
        this.basketCount = getBasketCount();
        let basketId = getBasketIdFromCookie();
        let params =
            {
                store: this.storeConfig.storeName,
                basketId: basketId,
                basketJSON: JSON.stringify({
                    basket: this.basket,
                    defaultLocation: this.step1DefaultLocation,
                    defaultPersonalDetails: this.defaultPersonalDetails
                })
            }
        console.log('::basket:addToBasket->persistBasket', params);

        persistBasket(params)
            .then(basketId => {
                console.log('::basket:addToBasket->persistBasket:result', basketId);
                storeBasketIdToCookie(basketId);
                this._basketHasCoupon = getBasketHasCoupon();
                if (addedDetail)
                    this.openBasketModal('Added ' + addedDetail.quantity + 'x of ' + addedDetail.product.Name);
            })
            .catch(error => {
                console.error('::basket:addToBasket->persistBasket:failed', error);
            });
    }

    loadPersistedBasket() {
        let cookie_basketId = getBasketIdFromCookie();

        this.basketLoaded = false;

        if (cookie_basketId) {
            console.log('::main:loadPersistedBasket', cookie_basketId);
            getPersistedBasket({basketId: cookie_basketId})
                .then(result => {
                    console.log('::main:loadPersistedBasket:result', result);
                    let basketJSON = '[]';
                    if (result === null) {
                        clearBasketIdCookie();
                        this.step1DefaultLocation = {};
                    } else {
                        try {
                            let obj_result = JSON.parse(result);
                            basketJSON = JSON.stringify(obj_result.basket);
                            this.step1DefaultLocation = obj_result.defaultLocation;
                            this.defaultPersonalDetails = obj_result.defaultPersonalDetails;
                            if (!this.step1DefaultLocation) this.step1DefaultLocation = {};
                        } catch (e) {
                            console.error('::main:loadPersistedBasket:failed', e);
                            basketJSON = '[]';
                            this.step1DefaultLocation = {};
                        }
                    }
                    // console.log('::main:loadPersistedBasket:setting basket..');
                    setBasket(basketJSON);
                    this.basketCount = getBasketCount();
                    this.basket = getBasket();
                    //if basket was received as empty, invalidate session cookie

                })
                .catch(error => {
                    console.error('::main:loadPersistedBasket:failed', error);

                })
                .finally(() => {
                    this.basketLoaded = true;
                });

        } else {
            this.basket = [];
        }

    }

    //on events that something changed in basket
    handleBasketUpdate(e) {
        console.log('::main:handleBasketUpdate:basket', JSON.stringify(e.detail.basket));
        // console.log('::handleBasketUpdate', event.detail.basket);
        setBasket(JSON.stringify(e.detail.basket));
        this.doPersistBasket();
    }

}