/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import getOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getOpportunity';
import getStripeSession from '@salesforce/apex/onl_CheckoutCtrl.getStripeSession';
import validateCouponAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.validateCouponAndAddToBasket';
import removeProductFromOpportunity from '@salesforce/apex/onl_CheckoutCtrl.removeProductFromOpportunity';
import confirmOrder from '@salesforce/apex/onl_CheckoutCtrl.confirmOrder';

import {
    getBasketIdFromCookie
} from 'c/onlBasket2';

export default class OnlScheduling extends LightningElement {

    @api params;
    @api opportunityId;
    @api defaultLocation;
    @api storeConfig;

    _opportunitySession;

    _form = {};

    triggerOpenEditModal = false;

    selectedBundleTests;

    get hasAnyItems() {
        return (this.tests && this.tests.length > 0)
            || (this.products && this.products.length > 0)
            || (this.appointments && this.appointments.length > 0);
    }

    get hasTests() {
        return this.tests && this.tests.length > 0;
    }

    get hasProducts() {
        return this.products && this.products.length > 0;
    }

    get hasAppointments() {
        return this.appointments && this.appointments.length > 0;
    }

    get hasDiscounts() {
        return this.discounts && this.discounts.length > 0;
    }

    get showPaymentButton() {
        return this.allTestsScheduled
            && !this.opportunityPaid
            && !this.loading
            && ((this.tests && this.tests.length > 0)
                || (this.products && this.products.length > 0)
                || (this.appointments && this.appointments.length > 0));
    }

    get isZeroAmount() {
        return this.total && this.total === 0;
    }

    get mailtoLink() {
        if (this.storeConfig) return 'mailto:' + this.storeConfig.contactEmail;
        else return '';
    }

    get telLink() {
        if (this.storeConfig) return 'tel:' + this.storeConfig.contactTelFormatted;
        else return '';
    }

    get showCoupon() {
        return !(this.hasDiscounts);
    }


    opportunityPaid = false;
    allTestsScheduled = false;

    loading = false;
    smallloading = false;
    loadingPayment = false;

    tests = [];
    sortedTests = [];
    products = [];
    appointments = [];
    discounts = [];

    personalDetails = {};
    shippingInformation;

    triggerCouponNotValid = false;
    _fieldCoupon = null;

    total;


    connectedCallback() {
        this.loading = true;

        if (!this.opportunityId) {
            this.opportunityId = getBasketIdFromCookie()
        }

        if (!!this.opportunityId) {
            this.loadOpportunity(true);
        } else {
            // nothing to display
            this.loading = false;
        }

    }


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
            this.loading = true;
            validateCouponAndAddToBasket(request)
                .then(result => {
                    console.log('::validateCouponAndAddToBasket:result', result);
                    if (!result) {
                        this.loading = false;
                        this.triggerCouponNotValid = true;
                    } else {
                        if (!result) {
                            this.loading = false;
                            this.triggerCouponNotValid = true;
                        } else {
                            this.loadOpportunity(true);
                        }
                    }
                })
                .catch(error => {
                    console.error('::validateCouponAndAddToBasket:failed', error);
                    this.loading = false;
                    this.triggerCouponNotValid = false;
                });
        } else this.triggerCouponNotValid = false;
    }

    /** fullload: ture or false whether to redisplay entire page or only tests */
    loadOpportunity(fullload) {
        if (fullload) this.loading = true;
        else this.smallloading = true;
        console.log('::order:loadOpportunity(opid)', this.opportunityId);
        getOpportunity({opid: this.opportunityId})
            .then(results => {
                console.log('::getOpportunity:result', results);
                this.processResults(results);
            })
            .catch(error => {
                console.error('::getOpportunity:failed', error);
                this.tests = [];
            })
            .finally(() => {
                if (fullload) this.loading = false;
                else this.smallloading = false;
                this.checkForRemainingTests();
            });
    }

    checkForRemainingTests() {
        this.allTestsScheduled = true;
        for (let test of this.tests) {
            if (test.COVID_Tests__r && test.COVID_Tests__r.records) {
                for (let ctr of test.COVID_Tests__r.records) {
                    if (!ctr.Scheduled_Appointment__r) {
                        this.allTestsScheduled = false;
                        break;
                    }
                }
            }
        }
    }

    processResults(results) {
        let result = JSON.parse(results);
        this._opportunitySession = result.opportunitySession;
        this.opportunityPaid = result.opportunityPaid;
        this.opportunityId = result.opportunityId;
        this.orderId = result.orderNumber;
        this.total = result.total;

        this.tests = result.covidTests;

        this.products = result.products;
        this.appointments = result.appointments;
        this.discounts = result.discounts;

        this.personalDetails = result.personalDetails;

        this.shippingInformation = result.shippingInformation;

        if (!this.defaultLocation || !this.defaultLocation.postalcode) {
            this.defaultLocation = result.defaultLocation;
        }

        if (!this.defaultLocation) this.defaultLocation = [];
        if (!this.tests) this.tests = [];
        if (!this.products) this.products = [];
        if (!this.appointments) this.appointments = [];
        if (!this.discounts) this.discounts = [];

        for (let d of this.tests) {
            d.type = 'covid';
            d.isBundle = d.COVID_Tests__r && d.COVID_Tests__r.records && (d.COVID_Tests__r.records.length > 1);
        }
        for (let d of this.products) {
            d.type = 'product';
        }
        for (let d of this.appointments) {
            d.type = 'appointment';
        }
        for (let d of this.discounts) {
            d.type = 'discount';
        }

        console.log('::processResults:tests', this.tests);
        console.log('::processResults:products', this.products);
        console.log('::processResults:appointments', this.appointments);
        console.log('::processResults:discounts', this.discounts);
        console.log('::processResults:defaultLocation', this.defaultLocation);
    }

    // handleContinueToPayment() {
    //     // if no stripe session on opportunity, call apex
    //     console.log('::handleContinueToPayment:opportunityId', this.opportunityId);
    //     this.loadingPayment = true;
    //     if (!this._opportunitySession) {
    //         console.log('::handleContinueToPayment:no-payment-session');
    //         getStripeSession({opportunityId: this.opportunityId})
    //             .then(results => {
    //                 console.log('::getStripeSession:result', results);
    //                 this.dispatchEvent(new CustomEvent('payment', {detail: {session: results}}));
    //             })
    //             .catch(error => {
    //                 console.error('::getStripeSession:failed', error);
    //                 this.loadingPayment = false;
    //             })
    //             .finally(() => {
    //
    //             });
    //
    //     } else {
    //         console.log('::handleContinueToPayment:payment-session-already-exists');
    //         this.dispatchEvent(new CustomEvent('payment', {detail: {session: this._opportunitySession}}));
    //     }
    // }

    handleContinueToPayment() {
        console.log('::handleContinueToPayment:opportunityId', this.opportunityId);
        if (!this.validateForm()) return;
        this.loading = true;


        let request = {
            basketParameters: JSON.stringify(
                {
                    personalDetails: this._form,
                    shippingInformation: null, //todo
                    oppid: this.opportunityId,
                    checkMarketing: this._form.check_marketing,
                    checkTerms: this._form.check_terms,
                    checkShare: this._form.check_share
                }
            )
        }

        // CONFIRM ORDER
        console.log('::c:confirmOrder:request', JSON.stringify(request));
        confirmOrder(request)
            .then(result => {
                console.log('::confirmOrder:result', result); // result is stripe session id

                let requestStripe = {opportunityId: this.opportunityId};
                console.log('::c:getStripeSession:request', JSON.stringify(requestStripe));

                // RECALC STRIPE SESSION
                getStripeSession(requestStripe)
                    .then(sessionId => {
                        console.log('::getStripeSession:sessionId', sessionId);
                        this.dispatchEvent(new CustomEvent('payment', {detail: {session: sessionId}}));
                    })
                    .catch(error => {
                        console.error('::getStripeSession:failed', error);
                        this.loading = false;
                    })
                    .finally(() => {

                    });
            })
            .catch(error => {
                console.error('::confirmOrder:failed', error);
                this.loading = false;
            })
            .finally(() => {

            });

    }

    openEditModal(event) {

        let itemId = event.currentTarget.dataset.itemid;

        this.selectedBundleTests = [];
        if (this.tests) {
            for (let item of this.tests) {
                if (item.Id === itemId) {
                    if (item.COVID_Tests__r && item.COVID_Tests__r.records) {
                        for (let tst of item.COVID_Tests__r.records) {
                            this.selectedBundleTests.push(tst.Id);
                        }
                    }
                    break;
                }
            }
        }

        if (this.selectedBundleTests && this.selectedBundleTests.length > 0) {
            this.triggerOpenEditModal = true;
        }

    }

    handleRemoveItemFromBasket(e) {
        console.log('::checkout:handleRemoveItemFromBasket:id', e.detail.id);
        this.removeItemFromBasket(e.detail.id);
    }

    removeItemFromBasket(id) {
        if (id) {
            let request = {lineItemId: id};
            console.log('::c:removeProductFromOpportunity', JSON.stringify(request));
            this.loading = true;
            removeProductFromOpportunity(request)
                .then(result => {
                    console.log('::c:removeProductFromOpportunity:result', result);
                    this.loadOpportunity(true);
                })
                .catch(error => {
                    console.error('::removeProductFromOpportunity:failed', error);
                    this.loading = false;
                })
                .finally(() => {

                });
        }
    }

    closeEditModal() {
        this.selectedBundleTests = [];
        this.triggerOpenEditModal = false;
    }

    //on booked reload page
    handleBooked() {
        this.loadOpportunity(true);
    }

    handleUpdated() {
        this.closeEditModal();
        this.loadOpportunity(false);
    }

    validateForm() {
        let inputs = this.template.querySelectorAll('[data-formfield]');

        // console.log('::dbg::1', inputs);
        this._form = {};

        if (inputs) {
            for (let input of inputs) {
                // console.log('::dbg::2', input.value);
                this._form[input.getAttribute('data-formfield')] = input.checked ? input.checked : this.limitLength(input.value);
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }

        let shippingOK = true;
        console.log('::oo2:validate:form', this._form);

        if (!this._form.check_terms || this._form.check_terms.length === 0) this._form.check_terms = false;
        if (!this._form.check_share || this._form.check_share.length === 0) this._form.check_share = false;
        if (!this._form.check_marketing || this._form.check_marketing.length === 0) this._form.check_marketing = false;

        // if (getBasketRequiresDelivery()) shippingOK = !!this._form.street && !!this._form.city && !!this._form.postalcode;

        return shippingOK && !!this._form.lastName && !!this._form.firstName && !!this._form.email && !!this._form.phone && !!this._form.check_terms && !!this._form.check_share;
    }

    revalidate(e) {
        if (e.currentTarget.showHelpMessageIfInvalid) {
            e.currentTarget.showHelpMessageIfInvalid();
        }
    }

    limitLength(s) {
        if (s && s.length > 50) return s.substring(0, 50);
        return s;
    }
}