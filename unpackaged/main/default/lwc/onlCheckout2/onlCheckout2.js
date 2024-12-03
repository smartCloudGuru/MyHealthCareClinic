/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import {
    getBasketIdFromCookie
} from 'c/onl2Basket';

import validateCouponAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.validateCouponAndAddToBasket';
import getOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getOpportunity';
import removeProductFromOpportunity from '@salesforce/apex/onl_CheckoutCtrl.removeProductFromOpportunity';

export default class OnlCheckout extends LightningElement {

    @api storeConfig;

    _form = {};

    // will be filled on load if bid2 exists in cookie
    opportunity;

    _defaults = {};

    loadingOpportunity;

    basketId;

    basketProcessed = false; // prevents showing "Your cart is empty" while loading basket
    basketCount = 0;
    basketSum = 0
    triggerCouponNotValid = false;
    _fieldCoupon = null;

    basketRequiresScheduling;

    showNoBasketWarning;

    get hasAnyItems() {
        return (this.tests && this.tests.length > 0)
            || (this.products && this.products.length > 0)
            || (this.appointments && this.appointments.length > 0);
    }

    get hasTests() {
        return this.opportunity && this.opportunity.covidTests && this.opportunity.covidTests.length > 0;
    }

    get hasProducts() {
        return this.opportunity && this.opportunity.products && this.opportunity.products.length > 0;
    }

    get hasAppointments() {
        return this.opportunity && this.opportunity.appointments && this.opportunity.appointments.length > 0;
    }

    get hasDiscounts() {
        return this.opportunity && this.opportunity.discounts && this.opportunity.discounts.length > 0;
    }

    get showCoupon() {
        return !(this.hasDiscounts);
    }

    connectedCallback() {
        console.log('::onlCheckout2:cc');
        this.basketId = getBasketIdFromCookie();
        if (!this.basketId) {
            this.showNoBasketWarning = true;
        } else {
            this.loadOpportunity();
        }
    }

    loadOpportunity() {
        this.loadingOpportunity = true;
        console.log('::checkout:loadOpportunity', this.basketId);
        getOpportunity({opid: this.basketId})
            .then(results => {
                console.log('::getOpportunity:result', results);
                this.processResults(results);
            })
            .catch(error => {
                console.error('::getOpportunity:failed', error);
                this.showNoBasketWarning = true;
            })
            .finally(() => {
                this.loadingOpportunity = false;
            });
    }

    processResults(results) {
        this.opportunity = JSON.parse(results);

        if (!this.opportunity) this.opportunity = {};

        if (this.opportunity.covidTests)
            for (let d of this.opportunity.covidTests) {
                d.type = 'covid';
                d.isBundle = d.COVID_Tests__r && d.COVID_Tests__r.records && (d.COVID_Tests__r.records.length > 1);
            }

        if (this.opportunity.products)
            for (let d of this.opportunity.products) {
                d.type = 'product';
            }

        if (this.opportunity.appointments)
            for (let d of this.opportunity.appointments) {
                d.type = 'appointment';
            }

        if (this.opportunity.discounts)
            for (let d of this.opportunity.discounts) {
                d.type = 'discount';
            }

        this.basketSum = this.opportunity.total ?  + this.opportunity.total : 0;


        // console.log('::processResults:tests', this.opportunity.covidTests);
        // console.log('::processResults:products', this.opportunity.products);
        // console.log('::processResults:appointments', this.opportunity.appointments);
        // console.log('::processResults:discounts', this.opportunity.discounts);
        // console.log('::processResults:defaultLocation', this.opportunity.defaultLocation);
        console.log('::processResults:opportunity', JSON.stringify(this.opportunity));

    }

    validateForm() {
        let inputs = this.template.querySelectorAll('[data-formfield]');
        if (inputs) {
            for (let input of inputs) {
                this._form[input.getAttribute('data-formfield')] = input.checked ? input.checked : this.limitLength(input.value);
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }

        let shippingOK = true;
        console.log('::checkout:validate:form', this._form);

        if (!this._form.check_terms || this._form.check_terms.length === 0) this._form.check_terms = false;
        if (!this._form.check_marketing || this._form.check_marketing.length === 0) this._form.check_marketing = false;

        // if (getBasketRequiresDelivery()) shippingOK = !!this._form.street && !!this._form.city && !!this._form.postalcode;

        return shippingOK && !!this._form.lastName && !!this._form.firstName && !!this._form.email && !!this._form.phone && !!this._form.check_terms;
    }

    limitLength(s) {
        if (s && s.length > 50) return s.substring(0, 50);
        return s;
    }

    /* DO CONTINUE */
    doContinue() {
        if (!this.validateForm()) return;

        let params = {};
        params.personalDetails =
            {
                lastName: this._form.lastName,
                firstName: this._form.firstName,
                email: this._form.email,
                phone: this._form.phone
            };

        // if (getBasketRequiresDelivery()) {
        //     params.shippingInformation = {
        //         firstName: this._form.lastName,
        //         lastName: this._form.lastName,
        //         street: this._form.street,
        //         city: this._form.city,
        //         postalcode: this._form.postalcode,
        //         country: 'UK',
        //         phone: this._form.phone,
        //     }
        // }


        params.checkMarketing = this._form.check_marketing;
        params.checkTerms = this._form.check_terms;

        this.dispatchEvent(new CustomEvent('continue', {detail: {params: params}}));
    }


    handleRemoveItemFromBasket(e) {
        console.log('::checkout:handleRemoveItemFromBasket:id', e.detail.id);
        this.removeItemFromBasket(e.detail.id);
        //this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: getBasket()}}));
    }

    removeItemFromBasket(id)
    {
        if (id)
        {
            let request = {lineItemId: id};
            console.log('::c:removeProductFromOpportunity', JSON.stringify(request));
            this.loadingOpportunity = true;
            removeProductFromOpportunity(request)
                .then(result => {
                    console.log('::c:removeProductFromOpportunity:result', result);
                    this.loadOpportunity();
                })
                .catch(error => {
                    console.error('::removeProductFromOpportunity:failed', error);
                    this.loadingOpportunity = false;
                })
                .finally(() => {

                });
        }
    }

    // handlePlusOne(event) {
    //     let __basket = JSON.parse(JSON.stringify(getBasket()));
    //     if (__basket) {
    //         for (let i of __basket) {
    //             if (i.id === event.detail.id) {
    //                 if (i.quantity <= 29) i.quantity++;
    //                 break;
    //             }
    //         }
    //
    //     } else __basket = [];
    //
    //     this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: __basket}}));
    // }

    // handleMinusOne(event) {
    //     let __basket = JSON.parse(JSON.stringify(getBasket()));
    //     if (__basket) {
    //         for (let i of __basket) {
    //             if (i.id === event.detail.id) {
    //                 if (i.quantity > 1) i.quantity--;
    //                 break;
    //             }
    //         }
    //
    //     } else __basket = [];
    //
    //     this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: __basket}}));
    // }

    couponChanged(e) {
        this._fieldCoupon = e.target.value;
        this.triggerCouponNotValid = false;
    }

    checkCoupon() {
        if (this._fieldCoupon) {
            let request = {
                couponCode: this._fieldCoupon.toUpperCase(),
                store: this.storeConfig.storeName,
                oppId: getBasketIdFromCookie()
            }
            console.log('::c:validateCouponAndAddToBasket', JSON.stringify(request));
            this.loadingOpportunity = true;
            validateCouponAndAddToBasket(request)
                .then(result => {
                    console.log('::validateCouponAndAddToBasket:result', result);
                    if (!result)
                    {
                        this.loadingOpportunity = false;
                        this.triggerCouponNotValid = true;
                    }
                    else {

                        if (!result) {
                            this.loadingOpportunity = false;
                            this.triggerCouponNotValid = true;
                        }
                        else
                        {
                            this.loadOpportunity();
                        }
                    }
                })
                .catch(error => {
                    console.error('::validateCouponAndAddToBasket:failed', error);
                    this.loadingOpportunity = false;
                    this.triggerCouponNotValid = false;
                });
        } else this.triggerCouponNotValid = false;
    }

    revalidate(e) {
        if (e.currentTarget.showHelpMessageIfInvalid) {
            e.currentTarget.showHelpMessageIfInvalid();
        }
    }

}