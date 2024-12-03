/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import createOrder from '@salesforce/apex/onl_CheckoutCtrl.createOrder';

import getOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getOpportunity';
import getStripeSession from '@salesforce/apex/onl_CheckoutCtrl.getStripeSession';

import {
    storeOpportunityIdToCookie,
    getOpportunityIdFromCookie,
    clearOpportunityIdCookie,
    getBasketIdFromCookie
} from 'c/onlBasket';

export default class OnlScheduling extends LightningElement {

    @api params;
    @api opportunityId;
    @api defaultLocation;
    @api storeConfig;

    _opportunitySession;

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

    personalDetails;
    shippingInformation;

    total;

    connectedCallback() {
        this.loading = true;

        //check if we have an opp id cookie
        let oppId = getOpportunityIdFromCookie();

        if (oppId) {
            //if there is an opid cookie just load opportunity
            this.opportunityId = oppId;
            this.loadOpportunity(true);
        } else if (this.params && this.params.basket) {

            this.params = JSON.parse(JSON.stringify(this.params));
            if (this.defaultLocation != null) {
                this.defaultLocation = JSON.parse(JSON.stringify(this.defaultLocation));
                this.params.defaultLocation = this.defaultLocation;
            }

            this.params.store = this.storeConfig.storeName;
            let params = JSON.stringify(this.params);

            console.log('::order:cc:createOrder(params)', params);
            createOrder({basketParameters: params})
                .then(result => {
                    console.log('::createOrder:result', result);
                    this.opportunityId = result;
                    storeOpportunityIdToCookie(this.opportunityId);
                    this.loadOpportunity(true);
                })
                .catch(error => {
                    console.error('::createOrder:failed', error);
                    this.tests = [];
                    this.products = [];
                    this.appointments = [];
                    this.discounts = [];
                    this.loading = false;
                })
                .finally(() => {});
        } else if (!!this.opportunityId) {
            this.loadOpportunity(true);
        }
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

        // not needed
        // if (this.tests)
        // {
        //     this.sortedTests = [];
        //     for (let test of this.tests)
        //     {
        //         if (test.COVID_Tests__r && test.COVID_Tests__r.records)
        //         {
        //             this.sortedTests = this.sortedTests.concat(test.COVID_Tests__r.records);
        //         }
        //     }
        // }
        //
        // if (this.sortedTests)
        // {
        //     this.sortedTests.sort(function(a, b) {
        //         if (a.Sort_Order__c && b.Sort_Order__c)
        //             return a.Sort_Order__c - b.Sort_Order__c;
        //         else return 0;
        //     })
        // }

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
            d.isBundle = d.COVID_Tests__r && d.COVID_Tests__r.records && (d.COVID_Tests__r.records.length>1);
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

    handleContinueToPayment() {
        // if no stripe session on opportunity, call apex
        console.log('::handleContinueToPayment:opportunityId', this.opportunityId);
        this.loadingPayment = true;
        if (!this._opportunitySession) {
            console.log('::handleContinueToPayment:no-payment-session');
            getStripeSession({opportunityId: this.opportunityId})
                .then(results => {
                    console.log('::getStripeSession:result', results);
                    this.dispatchEvent(new CustomEvent('payment', {detail: {session: results}}));
                })
                .catch(error => {
                    console.error('::getStripeSession:failed', error);
                    this.loadingPayment = false;
                })
                .finally(() => {

                });

        } else {
            console.log('::handleContinueToPayment:payment-session-already-exists');
            this.dispatchEvent(new CustomEvent('payment', {detail: {session: this._opportunitySession}}));
        }
    }

    openEditModal(event) {

        let itemId = event.currentTarget.dataset.itemid;

        this.selectedBundleTests = [];
        if (this.tests)
        {
            for (let item of this.tests)
            {
                if (item.Id === itemId) {
                    if (item.COVID_Tests__r && item.COVID_Tests__r.records) {
                        for (let tst of item.COVID_Tests__r.records)
                        {
                            this.selectedBundleTests.push(tst.Id);
                        }
                    }
                    break;
                }
            }
        }

        if (this.selectedBundleTests && this.selectedBundleTests.length>0)
        {
            this.triggerOpenEditModal = true;
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
}