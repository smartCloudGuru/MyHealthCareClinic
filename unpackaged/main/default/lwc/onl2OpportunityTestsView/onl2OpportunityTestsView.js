/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import getOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getOpportunity';
import getStripeSession from '@salesforce/apex/onl_CheckoutCtrl.getStripeSession';
import validateCouponAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.validateCouponAndAddToBasket';
import removeProductFromOpportunity from '@salesforce/apex/onl_CheckoutCtrl.removeProductFromOpportunity';
import confirmOrder from '@salesforce/apex/onl_CheckoutCtrl.confirmOrder';
import getReservationHeldTime from '@salesforce/apex/onl_CheckoutCtrl.getReservationHeldTime';

import {
    getBasketIdFromCookie
} from 'c/onl2Basket';

export default class Onl2OpportunityTestsView extends LightningElement {

    @api storeConfig;
    @api opportunityId;
    @api dev;

    @api showProducts;

    @api refresh() {
        this.loadOpportunity(true);
    }

    selectedBundleTests;

    get hasAnyItems() {
        return (this.tests && this.tests.length > 0);
    }

    get hasTests() {
        return this.tests && this.tests.length > 0;
    }

    get hasProducts() {
        return this.showProducts && this.products && this.products.length > 0;
    }

    get hasAppointments()
    {
        return this.appointments && this.appointments.length > 0;
    }

    opportunityPaid = false;
    opportunityClosed = false;
    allTestsScheduled = false;
    allAppointmentsScheduled  = false; //todo

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

    triggerOpenEditModal = false;

    total;

    _reservationHeldTime;

    connectedCallback() {
        this.loading = true;
        this.retrieveReservationHeldTime();

        if (!this.opportunityId)
            this.opportunityId = getBasketIdFromCookie();

        if (!!this.opportunityId) {
            this.loadOpportunity(true);
        } else {
            // nothing to display
            this.loading = false;
        }


    }

    retrieveReservationHeldTime() {
        getReservationHeldTime()
            .then(result => {
                console.log('::getReservationHeldTime:result', result);

                if (result) {
                    this._reservationHeldTime = result;
                }

            })
            .catch(error => {
                console.error('::getReservationHeldTime:failed', error);
                this.showServiceCenters = false;
            })
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
        // console.log('::o2otv:checkForRemainingTests:allTestsScheduled', this.allTestsScheduled);
        if (this.allTestsScheduled) this.dispatchEvent(new CustomEvent('alltestsscheduled'));
        else this.dispatchEvent(new CustomEvent('notalltestsscheduled'));
    }

    processResults(results) {
        let result = JSON.parse(results);
        this._opportunitySession = result.opportunitySession;
        this.opportunityPaid = result.opportunityPaid;
        this.opportunityClosed = result.opportunityClosed;
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

        let defaultPostalCode;
        let defaultServiceCenterId;
        for (let d of this.tests) {
            // console.log('::dbg::', d.Id);
            d.type = 'covid';

            // it's a "bundle" if it contains more than 1 test
            d.isBundle = d.COVID_Tests__r && d.COVID_Tests__r.records && (d.COVID_Tests__r.records.length > 1);

            // if it's a bundle, and has at least one test scheduled, introduce "defaultPostalCode" so that subsequent schedules can be done with
            // the same location pre-populated
            if (!defaultPostalCode && d.isBundle) {
                for (let subTest of d.COVID_Tests__r.records) {
                    if (subTest.Scheduled_Appointment__r
                        && subTest.Scheduled_Appointment__r.ServiceTerritory
                        && subTest.Scheduled_Appointment__r.ServiceTerritory.Address
                        && subTest.Scheduled_Appointment__r.ServiceTerritory.Address.postalCode) {
                        //console.log('::dbg::setting default postal code', subTest.Scheduled_Appointment__r.ServiceTerritory.Address.postalCode)
                        {
                            defaultPostalCode = subTest.Scheduled_Appointment__r.ServiceTerritory.Address.postalCode;
                            defaultServiceCenterId = subTest.Scheduled_Appointment__r.ServiceTerritory.Id;
                            break;
                        }
                    }
                }
                if (defaultPostalCode && defaultServiceCenterId)
                    for (let subTest of d.COVID_Tests__r.records) {
                        subTest.defaultPostalCode = defaultPostalCode;
                        subTest.defaultServiceCenterId = defaultServiceCenterId;
                    }
            }
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

        // console.log('::processResults:tests', this.tests);
        // console.log('::processResults:products', this.products);
        // console.log('::processResults:appointments', this.appointments);
        // console.log('::processResults:discounts', this.discounts);
        // console.log('::processResults:defaultLocation', this.defaultLocation);

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
                    this.dispatchEvent(new CustomEvent('updatedbasket'));
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
    handleBooked(e) {
        this.loadOpportunity(true);
        this.dispatchEvent(new CustomEvent('opportunitychanged', {detail: e.detail}));
    }

    handleUpdated() {
        this.closeEditModal();
        this.loadOpportunity(false);
    }

}