/**
 * Created 10.3.2021..
 */

import {api, LightningElement, wire, track} from 'lwc';

import {
    getBasketIdFromCookie,
    storeBasketIdToCookie,
    clearBasketIdCookie,
    enableConsoleOutput,
    getConsoleOutput,
    getLoggedInCookie,
    storeLoggedInToCookie,
    clearLoggedInCookie,
    storeReferralCookie,
    storeRulerCookie,
    getReferralCookie,
    getRulerCookie,
    storeLeadCookie,
    getLeadCookie,
    storeConsentCookie,
    getConsentCookie
} from 'c/onl2Basket';


import validateCouponAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.validateCouponAndAddToBasket';
import getTestDetails from '@salesforce/apex/onl_CheckoutCtrl.getTestDetails';
import getOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getOpportunity';
import getProductsCountOpportunity from '@salesforce/apex/onl_CheckoutCtrl.getProductsCountOpportunity';
import addToBasket from '@salesforce/apex/onl_CheckoutCtrl.addToBasket';
import getContactIdForUUID from '@salesforce/apex/OnlBookUI.getContactIdForUUID';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {setCookieConsent} from 'lightning/userConsentCookie';
import fetchProduct from '@salesforce/apex/OnlBookUI.aura_findProductForDirect';

const OPP_STATE_DRAFT = 'Draft';
const OPP_STATE_CONFIRMED = 'Confirmed';
const OPP_STATE_COMPLETED = 'Completed';

export default class Onl2Main extends LightningElement {

    @api opportunityId;
    @api queryParameters;
    @api storeConfig;
    @api hideBrowsing;

    dev = false;
    mobileApp = false;

    direct;

    formFactor = FORM_FACTOR;

    basketCount = 0;
    basketCountTests = 0;
    basketCountProducts = 0;
    basketCountAppointments = 0;
    basketState = OPP_STATE_DRAFT;

    defaultPersonalDetails = {};

    triggerOpenScheduleModal;
    triggerOpenBookModal;
    triggerOpenLoginModal;
    testProductToSchedule;
    testToSchedule;
    appProductToSchedule;
    appToSchedule;

    bookCtx = {};

    preloginBookSession;

    productCategory;

    _SESSION_TRACKER = {};

    contactId;

    cookiesDefined;

    hideRegistering;

    branding;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    loggedin;

    /* state machine for shopping */

    // defaults
    sm_page = {main: true};
    sm_menuSelection = 'appointment';

    get showAppointmentSearch() {
        return this.sm_page.main && (this.sm_menuSelection === 'appointment');
    }

    get randoxPage() {
        return this.queryParameters.page === 'randox';
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

    connectedCallback() {

        this._SESSION_TRACKER = {};

        this.retrieveContactIdForLogedInUser();

        if (this.queryParameters) {
            this.productCategory = this.queryParameters.c;
            if (this.queryParameters.ref) storeReferralCookie(this.queryParameters.ref);
            if (this.queryParameters.rasash) storeRulerCookie(this.queryParameters.rasash);
            if (this.queryParameters.ld) storeLeadCookie(this.queryParameters.ld);
            if (this.queryParameters.viewport && this.queryParameters.viewport === 'mapp') this.mobileApp = true; else this.mobileApp = false;
        }

        //send tracking session start with a slight delay
        setTimeout(this.sendStartTrackingSession.bind(this), 800);

        try {
            if (this.queryParameters && this.queryParameters.dev) enableConsoleOutput(this.queryParameters.dev);
            this.dev = getConsoleOutput();
            if (this.dev) console.log('::main:dev:', this.dev);
        } catch (ex) {}


        this.hideRegistering = this.storeConfig.hideRegistering;

        // let consent = getConsentCookie();
        //
        // if (consent == null) {
        //     if (this.dev) console.log('::main:cc:consent not yet defined');
        //     this.cookiesDefined = false;
        //     //storeConsentCookie({'statistics': true});
        // } else {
        //     if (this.dev) console.log('::main:cc:consent defined:', JSON.parse(consent));
        //     this.cookiesDefined = true;
        // }

        if (this.dev) console.log('::main:cc:queryParameters', JSON.stringify(this.queryParameters));
        let cookie_basketId = getBasketIdFromCookie();
        if (this.dev) console.log('::main:cc:cookie_basketId', cookie_basketId);

        this.queryParameters = JSON.parse(JSON.stringify(this.queryParameters));
        this.storeConfig = JSON.parse(JSON.stringify(this.storeConfig));

        if (this.dev) console.log('::main:cc:storeConfig-before', JSON.stringify(this.storeConfig));
        // MHC 221
        // override store config if "allowTestModes" is true
        if (this.storeConfig && this.storeConfig.allowTestModes) {
            //if dev cookie is set to 'allow-inclinic', we enable store-config.covid
            if (this.dev && this.dev.indexOf('allow-inclinic') >= 0) this.storeConfig.covid = true;

            let sc = this.storeConfig;
            this.dispatchEvent(new CustomEvent('storeConfigChanged', {
                detail: {sc}
            }));
        }

        if (this.dev) console.log('::main:cc:storeConfig-after', JSON.stringify(this.storeConfig));

        //if only one subsection enabled, force it always
        if (this.storeConfig) {
            if (!this.storeConfig.covid && !this.storeConfig.appointment && this.storeConfig.product) {
                this.queryParameters.sub = 'product';
            }
        }

        if (this.queryParameters) {
            if (this.queryParameters.opid) {
                this.opportunityId = this.queryParameters.opid;
                this.sm_page = {cart: true};
                this.step = {scheduling: true};
            } else if (this.queryParameters.id) {
                if (this.dev) console.log('::main:id', this.queryParameters.id);
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
                        case 'capp' :
                            this.sm_page = {confirmApp: true};
                            break;
                        case 'act' :
                            this.sm_page = {register: true};
                            break;
                        case 'direct' :
                            this.sm_page = {main: true};
                            this.direct = true;
                            break;
                        default:
                            this.sm_page = {main: true};
                            break;
                    }
                }

                if (this.queryParameters.sub === 'appointment' || this.queryParameters.sub === 'product' || this.queryParameters.sub === 'covid')
                    this.sm_menuSelection = this.queryParameters.sub;
            }
        }

        if (this.dev) console.log('::main:sm_page', JSON.stringify(this.sm_page));
        if (this.dev) console.log('::main:step', JSON.stringify(this.step));
        if (this.dev) console.log('::main:sm_menuSelection', this.sm_menuSelection);
        if (this.dev) console.log('::main:product', JSON.stringify(this.queryParameters?.product));
        if (this.dev) console.log('::main:direct', this.direct);

        if (this.direct && this.queryParameters.product) {
            this.loadDirectToProduct(this.queryParameters.product);
        }


    }

    loadDirectToProduct(productCode) {
        if (this.dev) console.log('::loadProduct:productCode', productCode);
        fetchProduct({productCode: productCode, store: this.storeConfig.storeName})
            .then(results => {
                console.log('::loadProduct:result', results);
                if (!results) {
                    //'Not a valid product code';
                    console.log('not a valid product code');
                } else {
                    let product = JSON.parse(results);

                    this.bookCtx =
                        {
                            "action": "book",
                            "book": {
                                "productName": product.Name,
                                "businessUnit": product.Business_Unit__c,
                                "serviceType": product.Work_Type_Group__r?.Service_Type__c,
                                "productId": product.Id,
                                "productCode": product.ProductCode,
                                "wtgId": product.Work_Type_Group__c,
                                "appointmentType": product.Work_Type_Group__r?.Appointment_Type__c,
                                "hidePractitionerList": product.Store_Hide_Practitioner_List__c,
                                "attachmentRequired": product.Store_Attachment_Required__c,
                                "attachmentText": product.Store_Attachment_Text__c,
                            }
                        }
                    this.direct = true;
                    this._SESSION_TRACKER.metadata = {};
                    this._SESSION_TRACKER.metadata.n = this.bookCtx.book.productName;
                    this._SESSION_TRACKER.metadata.c = this.bookCtx.book.productCode;
                    this._SESSION_TRACKER.metadata.b = this.bookCtx.book.businessUnit;
                    this._SESSION_TRACKER.metadata.s = this.bookCtx.book.serviceType;
                    this._SESSION_TRACKER.metadata.d = true;
                    this.openBookModal();
                }

            })
            .catch(error => {
                if (this.dev) console.error('::loadProduct:failed', error);
            }).finally(() => {
            }
        );

    }

    retrieveContactIdForLogedInUser() {
        let ptUuid = getLoggedInCookie();
        if (this.dev) console.log('::main:uuid', ptUuid);
        if (ptUuid && !this.contactId) {
            getContactIdForUUID({uuid: ptUuid})
                .then(result => {
                    if (this.dev) console.log('::main:getContactIdForUUID:result', result);
                    if (result) {

                        let acc = JSON.parse(result);
                        let e = {};
                        e.detail = {};
                        this.contactId = acc.ContactId__c;
                        e.detail.contactId = this.contactId;
                        e.detail.userUUID = acc.Store_UUID__c;
                        e.detail.patientType = acc.Patient_Type__c;
                        e.detail.membershipType = acc.Membership_Type__c;
                        e.detail.email = acc.PersonEmail;
                        e.detail.stage = 'loginOk';

                        this.handleSessionChange(e);

                    } else {
                        clearLoggedInCookie();
                    }
                })
                .catch(error => {
                    console.error('::getContactIdForUUID:failed', error);
                    clearLoggedInCookie();
                })
                .finally(() => {

                });
        }
    }

    sendStartTrackingSession() {
        this._SESSION_TRACKER.category = this.productCategory;
        this.fireTrackingEvent('landing');
    }

    fireTrackingEvent(stageName, detail) {

        if (!this._SESSION_TRACKER) this._SESSION_TRACKER = {};

        let productId;
        let productCode;

        if (stageName === 'bookStart' && this.bookCtx && this.bookCtx.book) {
            let book_clone = JSON.parse(JSON.stringify(this.bookCtx.book));
            productId = book_clone.productId;
            productCode = book_clone.productCode;
            this._SESSION_TRACKER.productId = productId;
            this._SESSION_TRACKER.productCode = productCode;
        }

        this._SESSION_TRACKER.stage = stageName;
        this._SESSION_TRACKER.contactId = this.contactId;
        this._SESSION_TRACKER.store = this.storeConfig.storeName;
        this._SESSION_TRACKER.category = this.productCategory;
        if (!this._SESSION_TRACKER.metadata) this._SESSION_TRACKER.metadata = {};
        if (detail && detail.metadata) this._SESSION_TRACKER.metadata = detail.metadata;

        if (stageName !== 'loginOK') {
            this._SESSION_TRACKER.userUUID = getLoggedInCookie();
        }

        this.dispatchEvent(new CustomEvent('sessionchange', {
            detail: JSON.parse(JSON.stringify(this._SESSION_TRACKER))
        }));

        if (stageName === 'logout') {
            this._SESSION_TRACKER = {};
        }
    }


    renderedCallback() {
        this.loggedin = (getLoggedInCookie() != null);
    }

    // fill search and personal details with previous test data, when provided in query parameters
    copyParamsFrom(testId) {
        if (testId) {
            if (this.dev) console.log('::main:copyParamsFrom:', testId);
            getTestDetails({testId: testId})
                .then(results => {
                    if (this.dev) console.log('::main:copyParamsFrom:getTestDetails:result', results);
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
                    if (this.dev) console.error('::main:copyParamsFrom:failed', error);
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
            if (this.dev) console.log('::main:validateCouponAndAddToBasket', JSON.stringify(request));
            validateCouponAndAddToBasket(request)
                .then(result => {
                    if (this.dev) console.log('::main:checkCoupon:validateCouponAndAddToBasket:result', result);
                    if (result) {
                        if (!result) {
                            if (this.dev) console.log('::main:checkCoupon:not valid');
                        } else {
                            storeBasketIdToCookie(result);
                            this.refreshBasketCount();
                        }
                    }
                })
                .catch(error => {
                    console.error('::main:checkCoupon:validateCouponAndAddToBasket:failed', error);
                });
        }
    }

    handleContinueToPayment(event) {
        if (this.dev) console.log('::handleContinueToPayment', JSON.stringify(event.detail));
        this.dispatchEvent(new CustomEvent('continuetopayment', {
            detail: {session: event.detail.session}
        }));
    }

    handleSessionChange(event) {
        if (this.dev) console.log('::om:handleSessionChange', JSON.stringify(event.detail));

        let detail = JSON.parse(JSON.stringify(event.detail));

        if (detail.stage === 'loginOk') {
            this.contactId = detail.contactId;
            this._SESSION_TRACKER.userUUID = detail.uuid;
            this._SESSION_TRACKER.contactId = detail.contactId;
            this._SESSION_TRACKER.email = detail.email;
            this._SESSION_TRACKER.membershipType = detail.membershipType;
            this._SESSION_TRACKER.patientType = detail.patientType;
        }

        this.fireTrackingEvent(detail.stage, detail);
    }

    navigateToCheckout() {
        window.open('?page=cart&sub=' + this.sm_menuSelection, '_self');
    }

    handleBackFromCart(event) {
        window.open('?page=main&sub=' + this.sm_menuSelection, '_self');
    }

    handleBookAppointment(event) {
        if (this.dev) console.log('::main2:hba:e.detail', JSON.parse(JSON.stringify(event.detail)));

        this.bookCtx.action = 'book';
        this.bookCtx.book = {};
        this.bookCtx.book = event.detail;
        this.branding = event.detail.branding;

        //clear session as we are starting a new booking flow
        this.preloginBookSession = null;

        this.startAppScheduleFlow();

    }

    handleBooked() {
        this.clearSearch();
        this.refreshBasketCount();
    }

    openScheduleModal() {
        this.triggerOpenScheduleModal = true;
    }

    closeScheduleModal() {
        this.refreshBasketCount();
        this.triggerOpenScheduleModal = false;
    }

    openBookModal() {
        //console.log(':main:obm:bookCtx', this.bookCtx);
        //this.fireTrackingEvent('bookStart');
        this.triggerOpenBookModal = true;
    }

    closeBookModal() {
        if (this.dev) console.log('::m::closeBookModal');
        if (this.direct) return; // no close for direct pages!!
        this.fireTrackingEvent('bookStop');
        this.triggerOpenBookModal = false;
    }

    openLoginModal() {
        console.log('::m:olm');
        this.triggerOpenLoginModal = true;
    }

    closeLoginModal() {
        this.triggerOpenLoginModal = false;
        //if wew are in a DIRECT page , we need to reload the page!
        //if (this.direct) location.reload();
    }

    clearSearch() {
        // if (this.dev) console.log('clearsearch');
        let cfct = this.template.querySelector('[data-cfct]');
        if (cfct && cfct.clearSearch) cfct.clearSearch();
    }

    refreshBasketCount() {
        if (this.dev) console.log('::main:refreshBasketCount');
        let opportunityOverview = this.template.querySelector('[data-refreshable]');
        if (opportunityOverview && opportunityOverview.refresh) opportunityOverview.refresh();

        let basketId = getBasketIdFromCookie();
        if (basketId) {
            let request = {oppid: basketId};
            if (this.dev) console.log('::getProductsCountOpportunity', JSON.stringify(request));
            getProductsCountOpportunity(request)
                .then(result => {
                    if (this.dev) console.log('::getProductsCountOpportunity:result', result);
                    let respObj = JSON.parse(result);
                    this.basketState = respObj.status;
                    if (this.basketState === OPP_STATE_CONFIRMED) {
                        clearBasketIdCookie();
                    } else {

                        // {'covidTests':1,'products' :2,'discounts':3}
                        this.basketCountTests = respObj.covidTests;
                        this.basketCountProducts = respObj.products;
                        this.basketCountAppointments = respObj.appointments;
                        this.basketCount = this.basketCountTests + respObj.products + respObj.discounts + respObj.appointments;
                    }

                })
                .catch(error => {
                    console.error('::getProductsCountOpportunity:failed', error);
                })
                .finally(() => {

                });
        }
    }

    startAppScheduleFlow() {
        this.direct = false;
        this.openBookModal();
    }

    handleLoginUID(e) {
        storeLoggedInToCookie(e.detail.ptu);
        this.closeLoginModal();
        if (!this.preloginBookSession) this.startAppScheduleFlow();
        else {
            this.direct = false;
            this.openBookModal();
        }
    }

    handleLogout(e) {
        this.fireTrackingEvent('logout');
        clearLoggedInCookie();
        this.loggedin = false;
    }

    handleLoginNeeded(e) {
        this.closeBookModal();
        this.preloginBookSession = e.detail.context;
        if (this.dev) console.log(':hln:preloginBookSession', this.preloginBookSession);
        this.openLoginModal();
    }

    handleAcceptCookies() {
        storeConsentCookie({statistics: true});
        this.cookiesDefined = true;
    }

    handleRejectCookies() {
        storeConsentCookie({statistics: false});
        this.cookiesDefined = true;
    }

}