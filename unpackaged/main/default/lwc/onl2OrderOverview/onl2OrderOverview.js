/**
 * Created 10.3.2021..
 */

import {api, LightningElement, wire} from 'lwc';

import getOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getOpportunity';
import getStripeSession from '@salesforce/apex/onl_CheckoutCtrl.getStripeSession';
import validateCouponAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.validateCouponAndAddToBasket';
import removeProductFromOpportunity from '@salesforce/apex/onl_CheckoutCtrl.removeProductFromOpportunity';
import confirmOrder from '@salesforce/apex/onl_CheckoutCtrl.confirmOrder';
import getCustomSettings from '@salesforce/apex/onl_CheckoutCtrl.getCustomSettings';
import getPickupLocations from '@salesforce/apex/onl_CheckoutCtrl.getPickupLocations';
import getDeliveryOptions from '@salesforce/apex/onl_CheckoutCtrl.getDeliveryOptions';

import addDeliveryToBasket from '@salesforce/apex/onl_CheckoutCtrl.addDeliveryToBasket';

import {
    getBasketIdFromCookie, storeBasketIdToCookie
} from 'c/onl2Basket';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Onl2OrderOverview extends LightningElement {

    @api params;
    @api opportunityId;
    @api defaultLocation;
    @api storeConfig;
    @api sm_menuSelection;
    @api dev;

    _opportunitySession;

    basketCount = 0;

    _form = {};
    _formShipping = {};

    _sameShippingChecked = false;
    _clickAndCollectChecked = false;
    _clickCollectLocationId;
    _showSameShippingCheckbox = false;

    triggerOpenEditModal = false;

    selectedBundleTests;

    showRescheduleNotification = false;

    basketRequiresShipping = false;

    retrievedDeliveryOptions = [];
    serviceCenterOptions = []

    showtcerror;
    total;

    selectedDeliveryOption;
    showErrorDeliveryRequired = false;

    formFactor = FORM_FACTOR;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    get shippingVisibilityClass() {
        if (!this.hasPostalDeliveryOptions) return 'display-none';
        else return '';
    }

    get shippingVisibilityClassFormField() {
        if (!this.hasPostalDeliveryOptions) return 'display-none';
        else return 'form-field';
    }

    // earliestDeliveryDate;
    // earliestDeliveryDateHours;

    deliveryOptions = [];

    get hideOnLoading() {
        if (this.loading)
            return "hidden";
        else
            return "shown";
    }

    get notClickAndCollect_And_Priced() {
        return !this._clickAndCollectChecked && this.total > 0;
    }


    @wire(getCustomSettings)
    myCustomSettings;

    get displayOrderBy() {
        return (this.opportunityClosed || this.opportunityPaid);
    }

    get displayBillingDetailsForm() {
        return !this.opportunityPaid &&
            !this.opportunityClosed
            && (
                (this.tests && this.tests.length > 0)
                || (this.products && this.products.length > 0)
                || (this.appointments && this.appointments.length > 0)
                || (this.discounts && this.discounts.length > 0));
    }

    get displayShippingDetailsForm() {
        return !this.opportunityPaid &&
            !this.opportunityClosed
            && this.basketRequiresShipping;

    }

    get hasAnyItems() {
        return (this.tests && this.tests.length > 0)
            || (this.products && this.products.length > 0)
            || (this.appointments && this.appointments.length > 0)
            || (this.discounts && this.discounts.length > 0);
    }

    get hasTests() {
        return this.tests && this.tests.length > 0;
    }

    get hasProducts() {
        return this.products && this.products.length > 0;
    }

    get hasDelivery() {
        return this.delivery && this.delivery.length > 0;
    }

    get hasAppointments() {
        return this.appointments && this.appointments.length > 0;
    }

    get hasDiscounts() {
        return this.discounts && this.discounts.length > 0;
    }

    get showPaymentButton() {
        return (this.total && this.total > 0)
            && this.allTestsScheduled
            && !this.opportunityPaid
            && !this.loading
            && ((this.tests && this.tests.length > 0)
                || (this.products && this.products.length > 0)
                || (this.appointments && this.appointments.length > 0));
    }

    get isZeroAmount() {
        return this.total && this.total === 0;
    }

    get showFinishButton() {
        return !this.opportunityClosed
        && (this.total === 0)
        && this.allTestsScheduled
        && !this.loading
        && ((this.tests && this.tests.length > 0)
            || (this.products && this.products.length > 0)
            || (this.appointments && this.appointments.length > 0));
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
        return (!this.hasDiscounts) && (!this.opportunityPaid && !this.opportunityClosed);
    }


    opportunityPaid = false;
    opportunityClosed = false;
    allTestsScheduled = false;

    loading = false;
    smallloading = false;
    loadingPayment = false;

    tests = [];
    products = [];
    appointments = [];
    discounts = [];
    delivery = [];

    personalDetails = {};
    shippingInformation;

    triggerCouponNotValid = false;
    _fieldCoupon = null;

    hasPostalDeliveryOptions = true;


    connectedCallback() {
        this.loading = true;
        this._showSameShippingCheckbox = true;

        if (!this.opportunityId) {
            this.opportunityId = getBasketIdFromCookie()
        }

        if (!!this.opportunityId) {
            this.loadOpportunity(true);
        } else {
            // nothing to display
            this.loading = false;
        }
        this.retrieveServiceCenters();
        this.retrieveDeliveryOptions();
        if (this.dev) console.log('::oo:cc:sub', this.sm_menuSelection);
    }

    renderedCallback() {
        let nodeC = this.template.querySelector('[data-formfield="checkClickAndCollect"]');
        let nodeS = this.template.querySelector('[data-formfield="check_shipping_same"]');
        if (nodeS) {
            if (this._sameShippingChecked && !nodeS.checked) {
                nodeS.checked = true;
            } else if (!this._sameShippingChecked && nodeS.checked) {
                nodeS.checked = false;
            }
        }
        if (nodeC) {
            if (this._clickAndCollectChecked && !nodeC.checked) {
                nodeC.checked = true;
            } else if (!this._clickAndCollectChecked && nodeC.checked) {
                nodeC.checked = false;
            }
        }
    }


    retrieveServiceCenters() {
        getPickupLocations()
            .then(results => {
                if (this.dev) console.log('::getPickupLocations:result', results);

                if (results) {
                    let resObj = JSON.parse(results);

                    this.serviceCenterOptions = [];
                    for (let sc of resObj) {
                        this.serviceCenterOptions.push({
                            label: sc.Name + ", " + sc.PostalCode,
                            value: sc.Id
                        })
                    }
                }

                this.showServiceCenters = this.serviceCenterOptions.length > 0;

            })
            .catch(error => {
                console.error('::getPickupLocations:failed', error);
                this.showServiceCenters = false;
            })
            .finally(() => {

            });
    }


    retrieveDeliveryOptions() {
        let request = {
            store: this.storeConfig.storeName
        }
        getDeliveryOptions(request)
            .then(results => {
                if (this.dev) console.log('::getDeliveryOptions:result', results);

                if (results) {
                    this.retrievedDeliveryOptions = JSON.parse(results);

                    this.deliveryOptions = [];
                    let label;
                    this.hasPostalDeliveryOptions = false;
                    for (let opt of this.retrievedDeliveryOptions) {
                        label = opt.Description + ' (';
                        if (opt.Description.indexOf('|') > 0) {
                            if (this.formFactor === 'Small') {
                                opt.Description = opt.Description.split('|')[1];

                            } else {
                                opt.Description = opt.Description.split('|')[0];
                            }
                        }

                        label = opt.Description + '\n\u0020\u0020\u0020\u0020\u0020\u0020(';
                        if (opt.Non_Membership_Price__c > 0) label += '£' + opt.Non_Membership_Price__c + ')';
                        else if (opt.Non_Membership_Price__c == 0) label += 'FREE)'
                        else label += 'SAVE £' + (-1 * opt.Non_Membership_Price__c) + ')';

                        if (label.indexOf('Courier') >= 0) this.hasPostalDeliveryOptions = true;

                        this.deliveryOptions.push({
                            label: label,
                            value: opt.Id
                        })

                        if (!this.hasPostalDeliveryOptions) this._sameShippingChecked = true;
                    }
                }
            })
            .catch(error => {
                console.error('::getDeliveryOptions:failed', error);
            })
            .finally(() => {

            });
    }


    couponChanged(e) {
        this._fieldCoupon = e.target.value;
        this.triggerCouponNotValid = false;
    }

    checkCoupon() {

        //this.collectFormData();

        if (this._fieldCoupon) {
            let request = {
                couponCode: this._fieldCoupon.toUpperCase(),
                store: this.storeConfig.storeName,
                oppId: getBasketIdFromCookie()
            }
            if (this.dev) console.log('::c:validateCouponAndAddToBasket', JSON.stringify(request));
            this.loading = true;
            validateCouponAndAddToBasket(request)
                .then(result => {
                    if (this.dev) console.log('::validateCouponAndAddToBasket:result', result);
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
        if (this.dev) console.log('::order:loadOpportunity(opid)', this.opportunityId);
        getOpportunity({opid: this.opportunityId})
            .then(results => {
                if (this.dev) console.log('::getOpportunity:result', results);
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

    setSameShippingChecked(checked) {
        this._sameShippingChecked = checked;
        let node = this.template.querySelector('[data-formfield="checkClickAndCollect"]');
        if (node) node.checked = checked;
    }

    processResults(results) {
        let result = JSON.parse(results);
        this._opportunitySession = result.opportunitySession;
        this.opportunityPaid = result.opportunityPaid;

        this.opportunityClosed = result.opportunityClosed;

        this.opportunityId = result.opportunityId;
        this.orderId = result.orderNumber;
        this.total = result.total;
        if (this.total < 0) this.total = 0;
        // this.earliestDeliveryDate = result.Online_Expected_Delivery_Date__c;

        this.tests = result.covidTests;

        this.products = result.products;
        this.appointments = result.appointments;
        this.discounts = result.discounts;
        this.delivery = result.delivery;

        if (this.delivery && this.delivery.length > 0) {
            this.selectedDeliveryOption = this.delivery[0].Product2Id;
        } else this.selectedDeliveryOption = null;

        // if (this.delivery && this.delivery.length>0 && this.delivery[0].Product2 && result.delivery[0].Product2.Delivery_Product_By_Hours__c!=null && result.delivery[0].Product2.Delivery_Product_By_Hours__c.length>4)
        // {
        //     this.earliestDeliveryDateHours = ('' + result.delivery[0].Product2.Delivery_Product_By_Hours__c).substring(0,5);
        // }
        // else this.earliestDeliveryDateHours = null;

        this._clickAndCollectChecked = result.Click_and_Collect__c;
        this._clickCollectLocationId = result.Pickup_Location__c;

        console.log('pl', this._clickCollectLocationId);
        let nodePL = this.template.querySelector('[data-formfield="clickCollectLocationId"]');
        if (nodePL) nodePL.value = this._clickCollectLocationId;


        this.personalDetails = result.personalDetails;

        this.shippingInformation = result.shippingInformation;

        this.setSameShippingChecked(true);
        this.personalDetails.check_shipping_same = true;

        if (this.personalDetails && this.shippingInformation) {
            if (
                (this.shippingInformation.firstName !== this.personalDetails.firstName)
                ||
                (this.shippingInformation.lastName !== this.personalDetails.lastName)
                ||
                (this.shippingInformation.email !== this.personalDetails.email)
                ||
                (this.shippingInformation.phone !== this.personalDetails.phone)
                ||
                (this.shippingInformation.address1 !== this.personalDetails.address1)
                ||
                (this.shippingInformation.address2 !== this.personalDetails.address2)
                ||
                (this.shippingInformation.address3 !== this.personalDetails.address3)
                ||
                (this.shippingInformation.postalCode !== this.personalDetails.postalCode)
                ||
                (this.shippingInformation.city !== this.personalDetails.city)
            ) {
                this.setSameShippingChecked(false);
                this.personalDetails.check_shipping_same = false;
            }
        }

        if (this._sameShippingChecked && (!this.opportunityClosed && !this.opportunityPaid)) this.shippingInformation = {};

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
            if (d.Product2 && d.Product2.Requires_delivery__c) this.basketRequiresShipping = true;
        }
        for (let d of this.products) {
            d.type = 'product';
            if (d.Product2 && d.Product2.Requires_delivery__c) this.basketRequiresShipping = true;
        }
        for (let d of this.appointments) {
            d.type = 'appointment';
            if (d.Product2 && d.Product2.Requires_delivery__c) this.basketRequiresShipping = true;
        }
        for (let d of this.discounts) {
            d.type = 'discount';
        }

        // if (this.dev) console.log('::processResults:tests', this.tests);
        // if (this.dev) console.log('::processResults:products', this.products);
        // if (this.dev) console.log('::processResults:appointments', this.appointments);
        // if (this.dev) console.log('::processResults:discounts', this.discounts);
        // if (this.dev) console.log('::processResults:defaultLocation', this.defaultLocation);
    }

    handleOpportunityChanged(e) {
        this.showRescheduleNotification = !!(e && e.detail && e.detail.reschedule);
        if (this.dev) console.log('::o2oo:handleOpportunityChanged:' + JSON.stringify(e) + ':showRescheduleNotification:' + this.showRescheduleNotification);
        this.loadOpportunity(true);
    }


    handleContinueToPayment() {
        if (this.dev) console.log('::handleContinueToPayment:opportunityId', this.opportunityId);
        if (!this.validateForm()) return;

        if (this._clickAndCollectChecked && !this._clickCollectLocationId) return;

        this.loading = true;

        let nodeS = this.template.querySelector('[data-formfield="check_shipping_same"]');
        if (nodeS && nodeS.checked) this._formShipping = this._form;


        let request = {
            basketParameters: JSON.stringify(
                {
                    personalDetails: this._form,
                    shippingInformation: this._formShipping,
                    oppid: this.opportunityId,
                    checkMarketing: this._form.check_marketing,
                    checkTerms: this._form.check_terms,
                    checkShare: this._form.check_share,
                    checkClickAndCollect: this._clickAndCollectChecked,
                    clickCollectLocationId: this._clickCollectLocationId
                }
            )
        }

        // CONFIRM ORDER
        //if (this.dev)
        console.log('::c:confirmOrder:request', request);
        confirmOrder(request)
            .then(result => {
                if (this.dev) console.log('::confirmOrder:result', result); // result is stripe session id

                let requestStripe = {opportunityId: this.opportunityId};
                if (this.dev) console.log('::c:getStripeSession:request', JSON.stringify(requestStripe));

                // RECALC STRIPE SESSION
                getStripeSession(requestStripe)
                    .then(sessionId => {
                        if (this.dev) console.log('::getStripeSession:sessionId', sessionId);
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

    handleFinishOrder() {
        if (this.dev) console.log('::handleFinishOrder:opportunityId', this.opportunityId);
        if (!this.validateForm()) return;
        this.loading = true;

        let nodeS = this.template.querySelector('[data-formfield="check_shipping_same"]');
        if (nodeS && nodeS.checked) this._formShipping = this._form;

        let request = {
            basketParameters: JSON.stringify(
                {
                    personalDetails: this._form,
                    shippingInformation: this._formShipping,
                    oppid: this.opportunityId,
                    checkMarketing: this._form.check_marketing,
                    checkTerms: this._form.check_terms,
                    checkShare: this._form.check_share,
                    checkClickAndCollect: this._clickAndCollectChecked,
                    clickCollectLocationId: this._clickCollectLocationId
                }
            )
        }

        // CONFIRM ORDER
        if (this.dev) console.log('::c:confirmOrder:request', request);
        confirmOrder(request)
            .then(result => {
                if (this.dev) console.log('::confirmOrder:result', result); // result is stripe session id

                window.open('?page=confirm', '_self');
            })
            .catch(error => {
                console.error('::confirmOrder:failed', error);
                if (error && error.body && error.body.message && error.body.message.indexOf('PBL') >= 0) {
                    window.open('?page=pbl', '_self');
                }
                this.loading = false;
            })
            .finally(() => {

            });

    }

    handleCollectLocationChange(event) {
        // if (this.dev) console.log('selectd location ' + event.target.value);
        this._clickCollectLocationId = event.target.value;
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
        if (this.dev) console.log('::checkout:handleRemoveItemFromBasket:id', e.detail.id);
        this.removeItemFromBasket(e.detail.id);
    }

    removeItemFromBasket(id) {
        if (id) {
            let request = {lineItemId: id};
            if (this.dev) console.log('::c:removeProductFromOpportunity', JSON.stringify(request));
            this.loading = true;
            removeProductFromOpportunity(request)
                .then(result => {
                    if (this.dev) console.log('::c:removeProductFromOpportunity:result', result);
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
    handleBooked() {
        this.loadOpportunity(true);
    }

    handleUpdated() {
        this.closeEditModal();
        this.loadOpportunity(false);
    }

    handleBackFromCart() {
        window.open('?page=main&sub=' + this.sm_menuSelection, '_self');
    }

    validateForm() {
        let inputs = this.template.querySelectorAll('[data-formfield]');

        // if (this.dev) console.log('::dbg::1', inputs);
        this._form = {};
        this._formShipping = {};

        if (inputs) {
            for (let input of inputs) {
                // if (this.dev) console.log('::dbg::2', input.value);
                if (input.getAttribute('data-form') === 'shipping') {
                    this._formShipping[input.getAttribute('data-formfield')] = input.checked ? input.checked : this.limitLength(input.value);
                } else {
                    this._form[input.getAttribute('data-formfield')] = input.checked ? input.checked : this.limitLength(input.value);
                }
                if (input && input.showHelpMessageIfInvalid) {
                    input.showHelpMessageIfInvalid();
                }
            }
        }

        this.showErrorDeliveryRequired = (!this.selectedDeliveryOption);

        if (this._clickAndCollectChecked && !(this._clickCollectLocationId)) return false;


        if (this.dev) console.log('::oo2:validate:form', this._form);
        if (this._sameShippingChecked) this._formShipping = this._form;
        if (this.dev) console.log('::oo2:validate:formShipping', this._formShipping);

        if (this.dev) console.log('::oo2:validate:basketRequiresShipping', this.basketRequiresShipping);

        if (!this._form.check_terms || this._form.check_terms.length === 0) this._form.check_terms = false;
        if (!this._form.check_share || this._form.check_share.length === 0) this._form.check_share = false;
        if (!this._form.check_marketing || this._form.check_marketing.length === 0) this._form.check_marketing = false;

        this.showtcerror = (!this._form.check_terms || !this._form.check_share);

        let shippingOK = true;
        if (this.basketRequiresShipping) {
            if (this._clickAndCollectChecked) shippingOK = true;
            else shippingOK = !!this._formShipping.address1 && !!this._formShipping.city && !!this._formShipping.postalCode && !!this.selectedDeliveryOption;
        }


        return shippingOK && !!this._form.lastName && !!this._form.firstName && !!this._form.email && !!this._form.phone && !!this._form.check_terms && !!this._form.check_share
            && !!this._form.address1 && !!this._form.city && !!this._form.postalCode;
    }

    revalidate(e) {
        if (e.currentTarget.showHelpMessageIfInvalid) {
            e.currentTarget.showHelpMessageIfInvalid();
        }

        let tick1 = this.template.querySelector('[data-formfield="check_terms"]');
        let tick2 = this.template.querySelector('[data-formfield="check_share"]');

        this.showtcerror = !(tick1 && tick2 && tick1.checked && tick2.checked);

    }

    limitLength(s) {
        if (s && s.length > 50) return s.substring(0, 50);
        return s;
    }

    handlePostcodeSearch(event) {

        if (!event || !event.detail || !event.detail.searchTerm) return;
        const target = event.target;

        let query = event.detail.searchTerm;

        // if (this.dev) console.log('query0', query);

        if (query && query.length >= 2) {
            if (query.length > 16) query = query.substring(0, 16);

            this.provisionalPostCode = query;

            query = query.replace(/[^a-z0-9 ]/gi, ''); //.replace(/[ ]/gi,'+');

            //if (this.dev) console.log('query1', query);

            let xmlHttp = new XMLHttpRequest();
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
                    //if (this.dev) console.log(xmlHttp.responseText);
                    let res = JSON.parse(xmlHttp.responseText);
                    let list = [];
                    if (res && res.result && res.result.total > 0 && res.result.hits && res.result.hits.length > 0) {

                        for (let hit of res.result.hits) {
                            // if (this.dev) console.log('hit', hit);

                            list.push({id: hit.postcode + '#' + hit.uprn, title: hit.postcode, subtitle: hit.line_1 + ' ' + hit.line_2, data: hit});

                        }
                        // if (this.dev) console.log('list', list);
                    }

                    target.setSearchResults(list);
                } else {
                    // console.error(':handlePostcodeSearch:onreadystatechange:status', xmlHttp.status);
                }
            }

            let apikey = '';
            if (this.myCustomSettings && this.myCustomSettings.data) {
                apikey = this.myCustomSettings.data;
                xmlHttp.open("GET", 'https://api.ideal-postcodes.co.uk/v1/addresses?api_key=' + apikey + '&query=' + query, true); // true for asynchronous
                xmlHttp.send(null);
            }
        }
    }

    handlePostcodeSelection(event) {

        let subform = event.target.name;

        let al1Node = this.template.querySelector('[data-form="' + subform + '"][data-formfield="address1"]');
        let al2Node = this.template.querySelector('[data-form="' + subform + '"][data-formfield="address2"]');
        let al3Node = this.template.querySelector('[data-form="' + subform + '"][data-formfield="address3"]');
        let postalcodeNode = this.template.querySelector('[data-form="' + subform + '"][data-formfield="postalCode"]');
        let cityNode = this.template.querySelector('[data-form="' + subform + '"][data-formfield="city"]');
        let countyNode = this.template.querySelector('[data-form="' + subform + '"][data-formfield="county"]');

        if (event && event.detail && event.detail.length > 0 && event.detail[0].id && event.detail[0].data) {
            let hit = event.detail[0].data;
            if (this.dev) console.log('selected ev', JSON.stringify(hit));


            if (al1Node) {
                al1Node.value = hit.line_1;
                al1Node.showHelpMessageIfInvalid();
            }
            if (al2Node) {
                al2Node.value = hit.line_2;
                al2Node.showHelpMessageIfInvalid();
            }
            if (al3Node) {
                al3Node.value = hit.line_3;
                al3Node.showHelpMessageIfInvalid();
            }
            if (cityNode) {
                cityNode.value = hit.post_town;
                cityNode.showHelpMessageIfInvalid();
            }
            if (postalcodeNode) {
                postalcodeNode.value = hit.postcode;
                postalcodeNode.showHelpMessageIfInvalid();
            }
            if (countyNode) {
                countyNode.value = hit.county;
                countyNode.showHelpMessageIfInvalid();
            }
        } else {
            if (al1Node) {
                al1Node.value = null;
                al1Node.showHelpMessageIfInvalid();
            }
            if (al2Node) {
                al2Node.value = null;
                al2Node.showHelpMessageIfInvalid();
            }
            if (al3Node) {
                al3Node.value = null;
                al3Node.showHelpMessageIfInvalid();
            }
            if (cityNode) {
                cityNode.value = null;
                cityNode.showHelpMessageIfInvalid();
            }
            if (postalcodeNode) {
                postalcodeNode.value = null;
                postalcodeNode.showHelpMessageIfInvalid();
            }
            if (countyNode) {
                countyNode.value = null;
                countyNode.showHelpMessageIfInvalid();
            }

        }
    }

    handleShippingSameChange(event) {
        this._sameShippingChecked = event.target.checked;
    }

    // handleClickAndCollectChange(event) {
    //     this._clickAndCollectChecked = event.target.checked;
    //     // this._showSameShippingCheckbox = !this._clickAndCollectChecked;
    // }

    handleDeliveryOptionChange(e) {

        if (e && e.detail && e.detail.value) {
            if (this.dev) console.log(e.detail.value);

            let selectedOpt = {};
            for (let o of this.retrievedDeliveryOptions) {
                if (o.Id === e.detail.value) {
                    if (this.dev) {
                        selectedOpt = o;
                        this.showErrorDeliveryRequired = false;
                    }
                    break;
                }
            }

            this._clickAndCollectChecked = (selectedOpt.Delivery_Class__c === 'Click & Collect');
            this._showSameShippingCheckbox = !this._clickAndCollectChecked;

            let basketId = getBasketIdFromCookie();

            let params = {
                basketId: basketId,
                quantity: 1,
                productId: e.detail.value,
                store: this.storeConfig.storeName
            };

            let params_string = JSON.stringify(params);
            if (this.dev) console.log('::handleAddDelivery:params', params_string);

            let success = false;
            this.loading = true;
            addDeliveryToBasket({params: params_string})
                .then(result => {
                    if (this.dev) console.log('::handleAddDelivery:addDeliveryToBasket:result', result);
                    if (result) {
                        storeBasketIdToCookie(result);
                        success = true;
                        this.loadOpportunity(true);
                    } else {
                        if (this.dev) console.log('::handleAddProduct:addDeliveryToBasket:failed');
                        success = false;
                    }
                })
                .catch(error => {
                    console.error('::addDeliveryToBasket:failed', error);
                    success = false;
                })
                .finally(() => {
                    this.loading = false;
                });
        }
    }

    collectFormData() {
        let inputs = this.template.querySelectorAll('[data-formfield]');

        this._form = {};
        this._formShipping = {};

        if (inputs) {
            for (let input of inputs) {
                if (input.getAttribute('data-form') === 'shipping') {
                    this._formShipping[input.getAttribute('data-formfield')] = input.checked ? input.checked : this.limitLength(input.value);
                } else {
                    this._form[input.getAttribute('data-formfield')] = input.checked ? input.checked : this.limitLength(input.value);
                }
            }
        }
    }


}