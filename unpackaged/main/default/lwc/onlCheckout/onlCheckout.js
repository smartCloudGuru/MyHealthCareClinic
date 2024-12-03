/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import {
    getBasketHasCoupon,
    setBasket,
    getBasket,
    getBasketCount,
    getBasketSum,
    getBasketRequiresScheduling,
    removeFromBasket,
    addCoupon, getBasketRequiresDelivery
} from 'c/onlBasket';

import validateCoupon from '@salesforce/apex/onl_CheckoutCtrl.validateCoupon';

import FORM_FACTOR from '@salesforce/client/formFactor';

export default class OnlCheckout extends LightningElement {

    @api storeConfig;

    _form = {};
    _defaults = {};

    formFactor = FORM_FACTOR;

    _basket;
    basketProcessed = false; // prevents showing "Your cart is empty" while loading basket
    basketCount = 0;
    basketSum = 0
    triggerCouponNotValid = false;
    _fieldCoupon = null;

    @api set basketWrapper(value) {
        console.log('::onlCheckout:setting basket wrapper', JSON.stringify(value));
        if (value) {
            this._basket = value.basket;

            setBasket(JSON.stringify(value.basket));
            this.basketCount = getBasketCount();
            this.basketSum = getBasketSum();
            this.basketProcessed = true;

            if (value.defaultPersonalDetails) this._defaults = JSON.parse(JSON.stringify(value.defaultPersonalDetails));
            console.log('::onlcheckout:basketWrapper:_defaults:', this._defaults);
        }
    }

    get basketWrapper() {
        return {basket: this._basket};
    }

    get hasItemsInBasket() {
        return this.basketCount > 0;
    }

    get basketRequiresScheduling() {
        return getBasketRequiresScheduling();
    }

    get basketRequiresDelivery() {
        return getBasketRequiresDelivery();
    }

    get showCoupon() {
        return (this.basketSum > 0) && !getBasketHasCoupon();
    }

    connectedCallback() {

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
        if (!this._form.check_share || this._form.check_share.length === 0) this._form.check_share = false;

        if (getBasketRequiresDelivery()) shippingOK = !!this._form.street && !!this._form.city && !!this._form.postalcode;

        return shippingOK && !!this._form.lastName && !!this._form.firstName && !!this._form.email && !!this._form.phone && !!this._form.check_terms || !!this._form.check_share;
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
        params.basket = [];

        if (getBasketRequiresDelivery()) {
            params.shippingInformation = {
                firstName: this._form.lastName,
                lastName: this._form.lastName,
                street: this._form.street,
                city: this._form.city,
                postalcode: this._form.postalcode,
                country: 'UK',
                phone: this._form.phone,
            }
        }
        for (let i of this._basket) {
            params.basket.push({
                id: i.id,
                quantity: i.quantity,
                type: i.type
            })
        }

        params.checkMarketing = this._form.check_marketing;
        params.checkTerms = this._form.check_terms;

        this.dispatchEvent(new CustomEvent('continue', {detail: {params: params}}));
    }


    handleRemoveItemFromBasket(e) {
        console.log('::checkout:handleRemoveItemFromBasket:id', e.detail.id);
        removeFromBasket(e.detail.id);
        this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: getBasket()}}));
    }

    handlePlusOne(event) {
        let __basket = JSON.parse(JSON.stringify(getBasket()));
        if (__basket) {
            for (let i of __basket) {
                if (i.id === event.detail.id) {
                    if (i.quantity <= 29) i.quantity++;
                    break;
                }
            }

        } else __basket = [];

        this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: __basket}}));
    }

    handleMinusOne(event) {
        let __basket = JSON.parse(JSON.stringify(getBasket()));
        if (__basket) {
            for (let i of __basket) {
                if (i.id === event.detail.id) {
                    if (i.quantity > 1) i.quantity--;
                    break;
                }
            }

        } else __basket = [];

        this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: __basket}}));
    }

    couponChanged(e) {
        this._fieldCoupon = e.target.value;
        this.triggerCouponNotValid = false;
    }

    checkCoupon() {
        if (this._fieldCoupon) {
            console.log('::validateCoupon:coupon', this._fieldCoupon.toUpperCase());
            validateCoupon({couponCode: this._fieldCoupon.toUpperCase(), store: this.storeConfig.storeName})
                .then(results => {
                    console.log('::validateCoupon:result', results);
                    if (!results) this.triggerCouponNotValid = true;
                    else {

                        let coupon = JSON.parse(results);

                        if (!coupon || !coupon.Name || !coupon.Id) {
                            this.triggerCouponNotValid = true;
                        } else {
                            let passed = addCoupon(coupon);
                            this.triggerCouponNotValid = (!passed);

                            console.log('::checkout:checkCoupon:basket', getBasket());
                            if (passed) this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: getBasket()}}));
                        }
                    }

                })
                .catch(error => {
                    console.error('::validateCoupon:failed', error);
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