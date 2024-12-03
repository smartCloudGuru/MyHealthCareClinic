/**
 * Created 10.3.2021.
 */

import {api, wire, LightningElement} from 'lwc';

import getCustomSettings from '@salesforce/apex/OnlBookUI.getCustomSettings';
import getServiceCentersForWTGAsJSON from '@salesforce/apex/OnlBookUI.getServiceCentersForWTGAsJSON';
import doBook from '@salesforce/apex/OnlBookUI.doBookByProxy';
import addAttachments from '@salesforce/apex/OnlBookUI.addAttachmentsToOpportunity';
import doResolveAccount from '@salesforce/apex/OnlBookUI.resolveAccount';
import getAvailableSlots from '@salesforce/apex/OnlBookUI.aura_getAvailableSlotsByWorkTypeGroupDateRange';
import getAllServiceResources from '@salesforce/apex/OnlBookUI.getAllServiceResources';
import getStripeSession from '@salesforce/apex/onl_CheckoutCtrl.getStripeSession';
import checkQuoteCalculated from '@salesforce/apex/OnlBookUI.checkQuoteCalculated';
import closeOpportunity from '@salesforce/apex/OnlBookUI.aura_closeAndGetOpportunity';
import findAccountsByEmailOfAccount from '@salesforce/apex/OnlBookUI.findAccountsByEmailOfAccount';
import validateCoupon from '@salesforce/apex/DiscountCodeManager.aura_validateCoupon';
import trackOnlineOpportunity from '@salesforce/apex/OnlBookUI.trackOnlineOpportunity';

import LOCALE from '@salesforce/i18n/locale';
import FORM_FACTOR from '@salesforce/client/formFactor';

import {
    getLoggedInCookie,
    getReferralCookie,
    getRulerCookie,
    getLeadCookie
} from 'c/onl2Basket';

/**  */
export default class Onl2BookModal extends LightningElement {

    @api storeConfig;
    @api defaultPersonalDetails;
    @api bookContext;
    @api dev;
    @api bookSession;
    @api queryParameters;
    @api direct;
    @api branding;

    @wire(getCustomSettings)
    myCustomSettings;

    attachRequired;
    attachText;

    showTheoForm;

    productMetadata;

    hasAddressLine2 = false;
    hasAddressLine3 = false;
    hasCounty = false;

    searchingForAlternativeDates = false;
    // will be set to true if at any point hte user encounters a need to show next availability, and will then be used to keep next availability visible
    forceShowNextAvailability = false;

    get productMetaData() {

        if (this.bookContext && this.bookContext.book) {
            let ret = {};
            ret.n = this.bookContext.book.productName;
            ret.c = this.bookContext.book.productCode;
            ret.b = this.bookContext.book.businessUnit;
            ret.s = this.bookContext.book.serviceType;
            this.productMetadata = JSON.stringify(ret);
        }

        return this.productMetadata;

    }

    get theoSelectedOrLoggedIn() {
        return this.showTheoForm || getLoggedInCookie();
    }

    get loggedIn() {
        return getLoggedInCookie();
    }

    // css if it's going to be modal or not
    get modalCss() {
        if (!!this.storeConfig.hideDirectBookBackdrop && this.direct) return "mhc2 dialog-background " + this.branding;
        else return "mhc2 slds-modal slds-modal_large slds-fade-in-open " + this.branding;
    }

    // css if it's going to be modal or not
    get addressLine2Class() {
        if (this.hasAddressLine2) return "pad-05";
        else return "display-none";
    }

    // css if it's going to be modal or not
    get addressLine3Class() {
        if (this.hasAddressLine3) return "pad-05";
        else return "display-none";
    }

    // css if it's going to be modal or not
    get countyClass() {
        if (this.hasCounty) return "pad-05";
        else return "display-none";
    }

    get modalContainerCss() {
        if (!!this.storeConfig.hideDirectBookBackdrop && this.direct) return "mhc2 slds-modal__container wide-as-possible small-top-bottom-padding page-direct";
        else if (this.direct) return "mhc2 slds-modal__container wide-as-possible page-direct";
        return "mhc2 slds-modal__container wide-as-possible";
    }

    get isTLCStore() {
        return this.storeConfig?.storeName === 'TheLondonClinic';
    }

    get hasAttachments() {
        return this.attachments && this.attachments.length > 0;
    }

    get selectedWTGId() {
        return this.bookContext?.book?.wtgId;
    }


    theoForm = {};

    ddOptions;
    mmOptions;
    yyOptions;

    genderOptions = [
        {"value": "Male", "label": "Male"},
        {"value": "Female", "label": "Female"}
    ];

    formFactor = FORM_FACTOR;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    get datePickerText() {
        return 'Select a Date';
        // if (this.formFactor === 'Small') return 'Select a Date:';
        // else return 'Select a Date:';
    }

    dataReady;

    loadedBookSession;

    productName;
    selectedLocation;
    _reservationHeldTime = 60;
    allServiceCenters;

    connectedAccounts;
    promoCode;
    promoCodeValidity;

    counterName;

    membershipDiscount = 20;

    /*
    steps (state machine showing different parts of the component):
    - location
    - confirm
    - booking
    - postChoice
     */
    step = {location: true};

    locations = [];
    daysQueried = 0;

    errorMessage = null;

    loading = false;
    loadingSlots = false;

    serviceCenterOptions;
    serviceCenterNotices;
    selectedLocationNotice;

    selectedServiceCenterId = null;

    get selectedIdOrVideoCall() {
        return this.selectedServiceCenterId || this.videoOrTelApp;
    }

    selectedDate = null;

    selectedDateP0 = null;
    selectedDateP1 = null;
    selectedDateP2 = null;

    selectedSlot = null;

    currentSlotsDay0 = [];
    currentSlotsDay1 = [];
    currentSlotsDay2 = [];

    subtitle = '';

    allResources = []; // will contain an id and name of all resources found

    bookRequest = {};

    bookingResult;

    // potential out-of-membership surcharge returned after booking
    oomsInfo;

    maxCounter = 0;

    resourceSelected;
    resourceOptions;
    filterByResource;
    receivedSlots;

    selectedPractitionerName;

    ampm = false;

    videoOrTelApp = false;

    selectedAccountToBook;
    reasonForVisit = ' ';

    productId;

    serviceType;

    theoLoading;

    hideBackdrop;

    attachment1 = {};
    attachments = [];

    get numOomsFreeAppointments() {
        if (this.oomsInfo) {

            if (!this.oomsInfo.nextFreeDate && (this.oomsInfo.pricebookEntry)) return null;

            if (!this.oomsInfo.spentFree) this.oomsInfo.spentFree = 0;

            if (this.oomsInfo.maxFree && this.oomsInfo.maxFree > 0) {
                let ret = this.oomsInfo.maxFree - this.oomsInfo.spentFree;
                if (ret <= 0) return null;
                return ret;
            }
        }
        return null;
    }

    get showMembershipDiscount() {
        return (this.oomsInfo && this.bookingResult && this.bookingResult.chargeAmount > 0);
    }

    get serviceTypeDental() {
        return this.serviceType && this.serviceType === 'Dental';
    }

    get hasSpentAllFreeBenefits() {
        return (this.oomsInfo != null) && (this.oomsInfo.spentFree != null) && (this.oomsInfo.maxFree != null) && (this.oomsInfo.spentFree >= this.oomsInfo.maxFree);
    }

    get hasOomsSurcharge() {
        return (this.oomsInfo != null) && (this.oomsInfo.pricebookEntry != null);
    }

    get confirmEnabled() {
        let isReasonForVisitNotEmpty = true; //!!this.reasonForVisit && this.reasonForVisit.length > 0;
        if (!this.attachRequired) {
            return isReasonForVisitNotEmpty;
        } else {
            let attachmentsExist = this.attachments && this.attachments.length > 0;
            return isReasonForVisitNotEmpty && attachmentsExist;
        }
    }

    get showResources() {
        return false;
        //return this.resourceOptions != null;
    }

    get showConnectedAccounts() {
        return this.connectedAccounts != null && this.connectedAccounts.length > 1;
    }

    get hasSlotsDay0() {
        return (this.currentSlotsDay0 && this.currentSlotsDay0.length > 0);
    }

    get hasSlotsDay1() {
        return (this.currentSlotsDay1 && this.currentSlotsDay1.length > 0);
    }

    get hasSlotsDay2() {
        return (this.currentSlotsDay2 && this.currentSlotsDay2.length > 0);
    }

    get showAvailableSlots() {
        return !this.searchingForAlternativeDates;
    }

    get showNextAvailability() {
        return this.forceShowNextAvailability
            ||
            (
                !this.videoOrTelApp
                && this.receivedSlots
                && !this.loading
                && !this.loadingSlots
                && (this.currentSlotsDay0 && this.currentSlotsDay0.length === 0)
                && (this.currentSlotsDay1 && this.currentSlotsDay1.length === 0)
                && (this.currentSlotsDay2 && this.currentSlotsDay2.length === 0));
    }

    get hasAnyAvailability() {
        return this.receivedSlots
            && !this.loading
            && !this.loadingSlots
            &&
            (
                (this.currentSlotsDay0 && this.currentSlotsDay0.length > 0)
                || (this.currentSlotsDay1 && this.currentSlotsDay1.length > 0)
                || (this.currentSlotsDay2 && this.currentSlotsDay2.length > 0)
            );
    }


    get showPaymentButton() {
        return !this.loading && this.step.postChoice && this.bookingResult && this.bookingResult.chargeAmount > 0;
    }

    get showFinishButton() {
        return !this.loading && this.step.postChoice && this.bookingResult && this.bookingResult.chargeAmount <= 0;
    }

    get hasLocations() {
        return this.serviceCenterOptions && this.serviceCenterOptions.length > 0;
    }

    get showBigLocations() {
        return this.serviceCenterOptions && this.serviceCenterOptions.length > 0 && !this.selectedServiceCenterId && !this.queryParameters.defloc;
    }

    get showPractitionerList() {
        return !this.bookContext?.book?.hidePractitionerList;
    }

    getNameForSelectedPractitioner() {
        if (this.allResources && this.resourceSelected) {
            return this.allResources[this.resourceSelected];
        }
        return null;
    }

    throwTrackingEvent(evName) {
        try {
            let metadata = {};
            if (this.bookContext && this.bookContext.book) {
                metadata.n = this.bookContext.book.productName;
                metadata.c = this.bookContext.book.productCode;
                metadata.b = this.bookContext.book.businessUnit;
                metadata.s = this.bookContext.book.serviceType;
                metadata.d = this.direct;
            }

            this.dispatchEvent(new CustomEvent('sessionchange', {
                detail: {
                    stage: evName,
                    metadata: metadata
                }
            }));
        } catch (ignore) {}

    }

    connectedCallback() {

        this.ddOptions = [];
        this.mmOptions = [];
        this.yyOptions = [];

        for (let i = 1; i <= 31; i++) {
            this.ddOptions.push({"value": '' + i, "label": '' + i})
        }

        // BOOK FLOW START
        this.throwTrackingEvent('bookStart')

        this.mmOptions.push({"value": '1', "label": 'January'});
        this.mmOptions.push({"value": '2', "label": 'February'});
        this.mmOptions.push({"value": '3', "label": 'March'});
        this.mmOptions.push({"value": '4', "label": 'April'});
        this.mmOptions.push({"value": '5', "label": 'May'});
        this.mmOptions.push({"value": '6', "label": 'June'});
        this.mmOptions.push({"value": '7', "label": 'July'});
        this.mmOptions.push({"value": '8', "label": 'August'});
        this.mmOptions.push({"value": '9', "label": 'September'});
        this.mmOptions.push({"value": '10', "label": 'October'});
        this.mmOptions.push({"value": '11', "label": 'November'});
        this.mmOptions.push({"value": '12', "label": 'December'});


        let yearNow = new Date().getFullYear();
        for (let i = yearNow; i > yearNow - 123; i--) {
            this.yyOptions.push({"value": '' + i, "label": '' + i})
        }

        Date.prototype.isSameAs = function (y, m, d) {
            if (this.getTime() !== this.getTime()) return false;

            if (this.getFullYear() !== y) return false;
            if ((this.getMonth() + 1) !== m) return false;
            if (this.getDate() !== d) return false;

            return true;
        };


        this.productId = this.bookContext?.book?.productId;
        this.attachRequired = this.bookContext?.book?.attachmentRequired || this.bookContext?.book?.attachRequired;
        this.attachText = this.bookContext?.book?.attachmentText;

        this.videoOrTelApp = (this.bookContext?.book?.appointmentType === 'VIDEO' || this.bookContext?.book?.appointmentType === 'TELEPHONE');

        //if it's video or tel, track as if location was selected
        if (this.videoOrTelApp === true) {// LOCATION SELECTED
            this.throwTrackingEvent('locationSelected');
        }

        this._reservationHeldTime = 10;
        this.retrievePractitioners();
        this.retrieveConnectedAccounts();
        this.retrieveServiceCenters();

        // if we have pre-existing session provided, then load it and process to confirm
        if (this.dev) console.log(':obm:bookSession', this.bookSession);
        if (this.dev) console.log(':obm:direct', this.direct);
        if (this.dev) {
            if (this.bookContext) console.log('::OBM:bookctx', JSON.parse(JSON.stringify(this.bookContext)));
            else console.log(':obm:bookctx', null);
        }

        if (this.direct && this.storeConfig.hideDirectBookBackdrop) this.hideBackdrop = true;

        if (this.bookSession) {
            this.loadedBookSession = JSON.parse(this.bookSession);
            this.selectedPractitionerName = this.loadedBookSession.selectedPractitionerName;
            this.selectedLocation = this.loadedBookSession.selectedLocation;
            this.selectedSlot = this.loadedBookSession.selectedSlot;
            this.videoOrTelApp = this.loadedBookSession.videoOrTelApp;
            //this.doConfirmBook(); // removed 2023-10-20 as we need to ask for promo code and reason
            this.step = {confirm: true};
            this.dataReady = true;
            return;
        }


        if (!this.selectedDate) {
            this.selectedDate = this.today();

            //2023-04-20 preselect first day of when this is available in the future (Invisalign Open Days that run only some days)
            if (this.bookContext?.book?.availableFrom != null && this.bookContext?.book?.availableFrom > this.selectedDate) {
                this.selectedDate = this.bookContext?.book?.availableFrom;
            }
        }


        if (this.dev) console.log('::cc:videoOrTelApp', this.videoOrTelApp);

    }

    parseNextSlotsToArrays(nextSlots) {

        this.currentSlotsDay0 = [];
        this.currentSlotsDay1 = [];
        this.currentSlotsDay2 = [];

        let day0date = new Date(Date.parse(this.selectedDate));
        let day1date = new Date(Date.parse(this.selectedDate) + 1000 * 60 * 60 * 24);
        let day2date = new Date(Date.parse(this.selectedDate) + 2000 * 60 * 60 * 24);

        this.selectedDateP0 = day0date.getTime();
        this.selectedDateP1 = day1date.getTime();
        this.selectedDateP2 = day2date.getTime();

        let day0 = (day0date.getDate() < 10 ? '0' + day0date.getDate() : '' + day0date.getDate()) + 'T';
        let day1 = (day1date.getDate() < 10 ? '0' + day1date.getDate() : '' + day1date.getDate()) + 'T';
        let day2 = (day2date.getDate() < 10 ? '0' + day2date.getDate() : '' + day2date.getDate()) + 'T';

        //if (this.dev) console.log(day0 + ' ' + day1 + ' ' + day2);

        if (this.dev) console.log('::receivedSlots', nextSlots);

        if (nextSlots && nextSlots.territorySlots) {

            this.buildResourceOptions(nextSlots.territorySlots);

            for (let nextSlot of nextSlots.territorySlots) {

                if (nextSlot.startTime) {
                    let label = new Intl.DateTimeFormat(LOCALE,
                        {
                            timeZone: "Europe/London",
                            hour: "2-digit",
                            minute: "2-digit",
                            hour12: false,
                        })
                        .format(Date.parse(nextSlot.startTime));

                    let passResourceFilter = false;
                    if (this.filterByResource != null) {
                        passResourceFilter = false;
                        for (let res of nextSlot.resources) {
                            if (res === this.filterByResource) {
                                passResourceFilter = true;
                                break;
                            }
                        }
                    } else {
                        passResourceFilter = true;
                    }

                    if (passResourceFilter) {
                        if (nextSlot.startTime.indexOf(day0) > 0) {
                            //console.log('... ... added to slots0');
                            this.currentSlotsDay0.push({
                                label: label,
                                startTime: nextSlot.startTime,
                                endTime: nextSlot.endTime,
                                resources: nextSlot.resources,
                                resource_locations: nextSlot.resource_locations
                            });
                        } else if (nextSlot.startTime.indexOf(day1) > 0) {
                            //console.log('... ... added to slots1');
                            this.currentSlotsDay1.push({
                                label: label,
                                startTime: nextSlot.startTime,
                                endTime: nextSlot.endTime,
                                resources: nextSlot.resources,
                                resource_locations: nextSlot.resource_locations
                            });
                        } else if (nextSlot.startTime.indexOf(day2) > 0) {
                            //console.log('... ... added to slots2');
                            this.currentSlotsDay2.push({
                                label: label,
                                startTime: nextSlot.startTime,
                                endTime: nextSlot.endTime,
                                resources: nextSlot.resources,
                                resource_locations: nextSlot.resource_locations
                            });
                        }
                    }
                }
            }

            if (this.dev) console.log('current slots by days', this.currentSlotsDay0, this.currentSlotsDay1, this.currentSlotsDay2);
        }
    }

    renderedCallback() {
        //if (this.dev) console.log('::bm:rc:ctx', JSON.parse(JSON.stringify(this.bookContext)));
        if (this.productName !== this.bookContext.book.productName) this.productName = this.bookContext.book.productName;
    }

    retrieveConnectedAccounts() {
        this.selectedAccountToBook = getLoggedInCookie();
        if (this.selectedAccountToBook) {
            findAccountsByEmailOfAccount({accountUID: this.selectedAccountToBook})
                .then(results => {
                    if (this.dev) console.log('::findAccountsByEmailOfAccount:result', results);

                    if (results) {
                        let responseAccounts = JSON.parse(results);

                        this.connectedAccounts = [];

                        for (let acc of responseAccounts) {

                            //Store_UUID__c, FirstName, LastName, Date_of_Birth__c
                            let dob = '';
                            if (acc.Date_of_Birth__c) {
                                try {
                                    dob = ' (' + acc.Date_of_Birth__c.substring(8, 10) + '/' + acc.Date_of_Birth__c.substring(5, 7) + '/' + acc.Date_of_Birth__c.substring(0, 4) + ')';
                                } catch (ignore) {}
                            }
                            this.connectedAccounts.push({
                                label: acc.FirstName + ' ' + acc.LastName + dob,
                                value: acc.Store_UUID__c
                            });
                        }

                        // this.connectedAccounts.push({
                        //     label: 'Other',
                        //     value: 'other'
                        // });

                        if (this.dev) console.log('::findAccountsByEmailOfAccount:connectedAccounts', this.connectedAccounts);
                    }

                })
                .catch(error => {
                    console.error('::findAccountsByEmailOfAccount:failed', error);
                    this.connectedAccounts = null;
                })
                .finally(() => {

                });
        }
    }

    retrieveServiceCenters() {

        if (!this.videoOrTelApp) {
            getServiceCentersForWTGAsJSON({wtgId: this.bookContext.book.wtgId})
                .then(results => {
                    if (this.dev) console.log('::getServiceCentersForWTGAsJSON:' + this.bookContext.book.wtgId + ':result', results);

                    if (results) {
                        this.allServiceCenters = JSON.parse(results);

                        this.serviceCenterOptions = [];
                        this.serviceCenterNotices = [];

                        if (this.videoOrTelApp) this.serviceCenterOptions.push({label: 'ANY', value: null});

                        for (let sc of this.allServiceCenters) {

                            this.serviceCenterOptions.push({
                                name: sc.Name,
                                street: sc.Street,
                                address: sc.PostalCode + ' ' + sc.City,
                                label: sc.Name + ', ' + sc.PostalCode + ' ' + sc.City,
                                value: sc.Id
                            });

                            if (!!sc.Store_Notice__c) {
                                this.serviceCenterNotices[sc.Id] = sc.Store_Notice__c;
                            }


                            if (!this.videoOrTelApp) {
                                if (this.dev) console.log('defloc:', this.queryParameters.defloc);
                                if (this.queryParameters != null && this.queryParameters.defloc != null && sc.Site__c === this.queryParameters.defloc) {
                                    this.selectedServiceCenterId = sc.Id;
                                }
                            }
                        }

                        //if it's only one service center, make it default
                        if (this.serviceCenterOptions.length === 1) {
                            this.selectedServiceCenterId = this.serviceCenterOptions[0].value;
                            this.selectedLocation = this.getServiceCenter(this.selectedServiceCenterId);
                            //console.log('---only one ' + this.selectedServiceCenterId);
                            this.throwTrackingEvent('locationSelected');
                        }
                    }

                })
                .catch(error => {
                    console.error('::getServiceCentersForWTGAsJSON:failed', error);
                    this.showServiceCenters = false;
                })
                .finally(() => {
                    this.searchSlots();
                });
        } else {
            this.serviceCenterOptions = [];
            this.serviceCenterOptions.push({
                label:
                    (
                        this.bookContext.book.appointmentType === 'VIDEO' ? 'Video Call' : 'Telephone Call'
                    ),
                value: 'video_tel_loc'
            });
            this.selectedLocation = {Id: 'video_tel_loc'};
            this.selectedServiceCenterId = 'video_tel_loc';
            this.searchSlots();
        }

    }

    retrievePractitioners() {
        getAllServiceResources()
            .then(result => {
                //if (this.dev) console.log('::getAllServiceResources:result', result);

                if (result) {
                    let response = JSON.parse(result);
                    response.forEach(res => {
                        this.allResources[res.Id] = res.Name;
                    });
                }
            })
            .catch(error => {
                console.error('::getAllServiceResources:failed', error);
                this.showServiceCenters = false;
            })
            .finally(() => {
                if (this.dev) console.log('::bm:allResources', this.allResources);
            });

    }

    getServiceCenter(serviceCenterId) {
        if (this.allServiceCenters) {
            for (let sc of this.allServiceCenters) {
                if (sc.Id === serviceCenterId) return sc;
            }
        }
        return {};
    }

    handleClose() {
        if (this.dev) console.log('::onl2book:handleClose');
        //if(!this.direct)
        this.dispatchEvent(new CustomEvent('close'));
    }

    searchSlots() {

        if (!this.productId) return;

        this.resourceOptions = null;
        this.filterByResource = null;


        if (!this.selectedDate) {
            this.selectedDate = this.dateToDatepickerDate(new Date());
        }

        if (!this.videoOrTelApp) {
            // [2023-02-03] removing initial search with all locations
            if (!this.selectedServiceCenterId) {
                this.loadingSlots = false;
                this.dataReady = true;
                return;
            }
        }

        let req =
            {
                workTypeGroupId: this.bookContext.book.wtgId,
                serviceCenterId: this.selectedServiceCenterId,
                fromDate: this.selectedDate,
                toDate: this.dateToDatepickerDate(new Date(Date.parse(this.selectedDate) + 2000 * 60 * 60 * 24))
            }
        if (this.dev) console.log('::getAvailableSlots:req', req);

        if (!this.bookContext.book.wtgId) return;

        this.loadingSlots = true;

        getAvailableSlots(req)
            .then(results => {
                if (this.dev) console.log('::getAvailableSlots:result', results);
                this.receivedSlots = JSON.parse(results);
                if (this.dev) console.log('::getAvailableSlots:territorySlots', this.receivedSlots.territorySlots);
                this.parseNextSlotsToArrays(this.receivedSlots);
            })
            .catch(error => {
                console.error('::getAvailableSlots:failed', error);
                this.currentSlotsDay0 = [];
                this.currentSlotsDay1 = [];
                this.currentSlotsDay2 = [];
            })
            .finally(() => {
                this.loadingSlots = false;
                this.dataReady = true;
            });
    }

    buildResourceOptions(territorySlots) {

        this.resourceSelected = null;
        this.resourceOptions = [];
        this.resourceOptions.push({label: 'Any Practitioner', value: null});

        if (this.dev) console.log('::bro:territorySlots:', territorySlots);
        if (!territorySlots) {
            return;
        }

        let mentionedResources = [];
        for (let rs of territorySlots) {
            for (let res of rs.resources) {
                if (!mentionedResources.includes(res)) mentionedResources.push(res);
            }
        }
        if (this.dev) console.log('::bro:mentionedResources:', mentionedResources);

        if (mentionedResources) {
            for (let res of mentionedResources) {
                this.resourceOptions.push(
                    {
                        label: this.allResources[res],
                        value: res
                    });
            }
        }

        if (this.dev) console.log('::buildResourceOptions:resourceOptions', this.resourceOptions);
    }

    handleLocationChanged(e) {

        this.searchingForAlternativeDates = false;
        this.forceShowNextAvailability = false;

        this.selectedServiceCenterId = e.target.value;
        this.selectedLocation = this.getServiceCenter(this.selectedServiceCenterId);
        this.selectedLocationNotice = this.serviceCenterNotices[e.target.value];

        //scroll to top of page
        let scr_div = this.template.querySelector('.scrollable-div');
        if (scr_div) {
            scr_div.scrollTop = 0;
        }

        this.searchSlots();
    }


    handleTimeSlotSelected(e) {
        this.errorMessage = null;

        //find the slot by start date
        this.selectedSlot = null;

        // SLOT SELECTED
        this.throwTrackingEvent('slotSelected');

        for (let sl of this.currentSlotsDay0) {
            if (sl.startTime === e.currentTarget.dataset.start) {
                this.selectedSlot = sl;
                break;
            }
        }
        if (!this.selectedSlot) for (let sl of this.currentSlotsDay1) {
            if (sl.startTime === e.currentTarget.dataset.start) {
                this.selectedSlot = sl;
                break;
            }
        }
        if (!this.selectedSlot) for (let sl of this.currentSlotsDay2) {
            if (sl.startTime === e.currentTarget.dataset.start) {
                this.selectedSlot = sl;
                break;
            }
        }

        if (!this.selectedSlot) {
            console.error('::htss:ns');
            return;
        }

        if (this.dev) console.log('::htss:selectedSlot', this.selectedSlot);

        //by default choose the first GP
        if (!this.filterByResource) this.resourceSelected = this.selectedSlot.resources[0];
        else this.resourceSelected = this.filterByResource;

        if (this.dev) console.log('::htss:resourceSelected', this.resourceSelected);

        this.selectedPractitionerName = this.getNameForSelectedPractitioner(this.resourceSelected);

        if (this.dev) console.log('::htss:selectedPractitionerName', this.selectedPractitionerName);

        //by default choose the first Location if ANY was specified

        if (!this.selectedServiceCenterId || this.videoOrTelApp) {
            this.selectedServiceCenterId = this.selectedSlot.resource_locations[this.resourceSelected][0];
        }
        this.selectedLocation = this.getServiceCenter(this.selectedServiceCenterId);
        if (!this.selectedLocation) this.selectedLocation = {};
        this.selectedLocation.Id = this.selectedServiceCenterId;

        if (this.dev) console.log('::htss:selectedLocation', this.selectedLocation);

        this.step = {confirm: true};
        if (!!this.storeConfig.hideRegistering) this.handleShowTheoForm();
    }

    handleBackToLocations() {
        this.showTheoForm = false;
        this.step = {prebook: true}
    }

    handleBackToSlots() {
        this.showTheoForm = false;
        this.errorMessage = null;
        this.step = {location: true};
        this.searchSlots();
    }

    handleDateInputChange(event) {
        this.selectedDate = event.currentTarget.value;
        this.forceShowNextAvailability = false;
        this.searchSlots();
    }

    addDays(dte, days) {
        let dte2 = dte ? new Date(Date.parse(dte)) : new Date();
        dte2.setDate(dte2.getDate() + days);

        // console.log('::addDays:dte2', dte2);
        return this.dateToDatepickerDate(dte2);
    }

    doConfirmBook(isWithoutLogin) {

        if (this.dev) console.log('::onl2book:doConfirmBook');
        if (isWithoutLogin !== true) {
            isWithoutLogin = false;
        }
        let params_string;

        // BOOK CONFIRMED
        this.throwTrackingEvent('bookConfirmed');

        if (this.dev) console.log('::dcb:loadedBookSession', this.loadedBookSession);

        if (!this.loadedBookSession) {
            if (this.dev) console.log('::doConfirmBook:selectedSlot', this.selectedSlot);
            if (this.dev) console.log('::doConfirmBook:selectedLocation.Id:', this.selectedLocation.Id);
            if (!this.resourceSelected && !!this.selectedSlot?.resources && this.selectedSlot?.resources.length > 0) this.resourceSelected = this.selectedSlot?.resources[0];
            if (this.dev) console.log('::doConfirmBook:resourceSelected:', this.resourceSelected);

            this.bookingResult = null;
            this.bookRequest = {};
            this.bookRequest.recordId = null;
            this.bookRequest.accountUID = this.selectedAccountToBook;
            this.bookRequest.productSelected = this.bookContext.book.productId;
            this.bookRequest.randoxPID = this.bookContext.book.randoxPID;
            this.bookRequest.voucherTag = this.bookContext.book.voucherTag;
            this.bookRequest.resourceSelected = this.resourceSelected;
            this.bookRequest.wtgIdSelected = this.bookContext.book.wtgId;
            this.bookRequest.selectedLocation = this.selectedLocation;
            this.bookRequest.locationSelected = this.selectedLocation.Id;
            this.bookRequest.discountSelected = null;
            this.bookRequest.discountName = null;
            this.bookRequest.selectedDate = this.selectedDate;
            this.bookRequest.selectedSlot = this.selectedSlot;
            this.bookRequest.timeSelected = this.selectedSlot.startTime;
            this.bookRequest.timeSelectedEnd = this.selectedSlot.endTime;
            this.bookRequest.reasonForVisit = this.reasonForVisit;
            this.bookRequest.selectedPractitionerName = this.selectedPractitionerName;
            this.bookRequest.videoOrTelApp = this.videoOrTelApp;
            if (this.queryParameters.ld) this.bookRequest.existingLeadId = this.queryParameters.ld;
            else this.bookRequest.existingLeadId = getLeadCookie();
        } else {
            this.loadedBookSession.accountUID = this.selectedAccountToBook;
            this.bookRequest = this.loadedBookSession;
        }

        this.bookRequest.withoutLogin = isWithoutLogin;


        //this.bookRequest.onlineSessionId = this.bookSessionId;
        this.bookRequest.mode = 'Online Booking';
        if (!this.bookRequest.referralCode) this.bookRequest.referralCode = getReferralCookie();
        if (!this.bookRequest.referralCode) this.bookRequest.trackingCookie = getRulerCookie();
        this.bookRequest.discountName = this.promoCode;

        this.bookRequest.storeName = this.storeConfig.storeName;
        this.bookRequest.thirdPartyRef = this.queryParameters.tref;

        // this.bookRequest.attachments = [];
        // for (let att of this.attachments) {
        //     if (att && att.fileData) this.bookRequest.attachments.push(att.fileData);
        // }

        if (this.dev) console.log('::doConfirmBook:bookRequest:', this.bookRequest);

        params_string = JSON.stringify(this.bookRequest);

        if (this.dev) console.log('::doBook:params', params_string);

        if (getLoggedInCookie() || this.selectedAccountToBook) {
            this.step = {booking: true}
            this.serviceType = null;
            doBook({request: params_string})
                .then(result => {
                    if (this.dev) console.log('::doBook:result', result);
                    if (result) {
                        this.bookingResult = JSON.parse(result);

                        if (this.bookingResult && !this.bookingResult.error) {

                            this.oomsInfo = this.bookingResult.oomSurcharge;
                            this.serviceType = this.bookingResult.serviceType;
                            this.counterName = this.bookingResult.oomCounter;
                            if (!this.counterName) this.counterName = 'Appointments';
                            if (this.counterName === 'Dental Cleans') this.counterName = 'Hygiene Treatment(s)';
                            this.uploadEventualAttachments(this.bookingResult);
                        } else {
                            this.errorMessage = 'Unable to schedule at this time. Please try again with a different time.';
                            this.step = {confirm: true};
                            if (this.bookingResult.message) this.errorMessage = this.bookingResult.message;
                        }


                    } else {
                        this.errorMessage = 'Unable to schedule at this time. Please try again with a different time.';
                        this.step = {confirm: true};
                    }

                })
                .catch(error => {
                    if (this.dev) console.error('::doBook:failed', error);
                    this.errorMessage = 'Unable to schedule at this time. Please try again with a different time.';
                    this.step = {confirm: true};
                })
                .finally(() => {

                });
        } else {
            this.dispatchEvent(new CustomEvent('dologin', {detail: {context: params_string}}));
        }
    }

    uploadEventualAttachments(bookingResult) {
        if (this.attachments && this.attachments.length > 0) {
            if (this.dev) console.log('upload files', this.attachments.length);

            for (let att of this.attachments) {
                let addRequest = {};
                addRequest.oppId = bookingResult.oppId;
                addRequest.serviceType = bookingResult.serviceType;
                addRequest.filenames = [];
                addRequest.base64 = [];

                if (att && att.fileData) {
                    addRequest.filenames.push(att.fileData.filename);
                    addRequest.base64.push(att.fileData.base64);
                }

                addAttachments(addRequest)
                    .then(result => {
                        if (this.dev) console.log('::addAttachments:result', result);
                    })
                    .catch(error => {
                        if (this.dev) console.error('::addAttachments:failed', error);
                    })
                    .finally(() => {

                    });
            }
        }

        this.maxCounter = 0;
        this.waitForQuoteCalculation();
    }

    // every 1250ms query quote if it's updated, if it is, update local chargeAmount value and go to next
    waitForQuoteCalculation() {
        console.log('::waiting for quote calculation..');
        this.maxCounter++;
        if (this.maxCounter >= 30) return;
        checkQuoteCalculated({quoteId: this.bookingResult.quoteId, appId: this.bookingResult.appId})
            .then(results => {
                if (this.dev) console.log('::waitForQuoteCalculation:calculated:', results);
                let resp = JSON.parse(results);
                if (!resp.quoteCalculated) setTimeout(this.waitForQuoteCalculation.bind(this), 1250);
                else {
                    this.bookingResult.chargeAmount = resp.amount;
                    this.step = {postChoice: true};
                    this.trackOpportunity(this.bookingResult.oppId, 'Quote Calculated');
                    // QUOTE CALCULATED
                    this.throwTrackingEvent('quoteCalculated');
                }
            })
            .catch(error => {
                console.error('::waitForQuoteCalculation:failed', error);
            })
            .finally(() => {
            });
    }

    today() {
        return this.dateToDatepickerDate(new Date());
    }

    dateToDatepickerDate(dte) {
        if (!dte) dte = new Date();
        let month = dte.getMonth() + 1 < 10 ? '0' + (dte.getMonth() + 1) : (dte.getMonth() + 1);
        let day = dte.getDate() < 10 ? '0' + dte.getDate() : dte.getDate();
        return dte.getFullYear() + '-' + month + '-' + day;
    }

    handleContinueToPayment() {
        if (!this.bookingResult || !this.bookingResult.oppId) {
            console.error('::hctp:no booking info, can not proceed with payment');
            return;
        }

        // PROCEEDED TO PAYMENT
        this.throwTrackingEvent('proceededToPayment');


        this.trackOpportunity(this.bookingResult.oppId, 'Proceeded to Payment');

        if (this.dev) console.log('::hctp:oppId', this.bookingResult.oppId);

        this.loading = true;

        // CONFIRM ORDER
        let requestStripe = {opportunityId: this.bookingResult.oppId};
        if (this.dev) console.log('::c:getStripeSession:request', JSON.stringify(requestStripe));

        // RECALC STRIPE SESSION
        getStripeSession(requestStripe)
            .then(sessionId => {
                if (this.dev) console.log('::getStripeSession:sessionId', sessionId);
                if (sessionId != null) this.dispatchEvent(new CustomEvent('payment', {detail: {session: sessionId}}));
                else {
                    console.error('::getStripeSession:returned null', sessionId);
                    this.loading = false;
                }
            })
            .catch(error => {
                console.error('::getStripeSession:failed', error);
                this.loading = false;
            })
            .finally(() => {

            });

    }

    handleFinish() {

        if (!this.bookingResult || !this.bookingResult.oppId) {
            console.error('::hf:no booking info, can not proceed with payment');
            return;
        }

        if (this.dev) console.log('::hf:oppId', this.bookingResult.oppId);

        this.loading = true;

        let request = {oppId: this.bookingResult.oppId, paidByPos: false};

        closeOpportunity(request)
            .then(result => {
                if (this.dev) console.log('::closeOpportunity:result', result);
                if (result) {
                    setTimeout(this.finishFreeOrder.bind(this), 2000);
                }
            })
            .catch(error => {
                console.error('::closeOpportunity:ex', error);
                this.loading = false;
            })
            .finally(() => {

            });
    }

    finishFreeOrder() {
        // WON
        this.throwTrackingEvent('won');
        window.open('?page=capp&stripe_session_id=NA', '_self');
    }

    handleFilteredResourceChanged(e) {
        this.filterByResource = e.currentTarget.value
        if (this.dev) console.log(':::filterByResource', this.filterByResource);
        this.parseNextSlotsToArrays(this.receivedSlots);
    }

    handleAccountChanged(e) {
        this.selectedAccountToBook = e.currentTarget.value;
        if (this.dev) console.log(':::selectedAccountToBook', this.selectedAccountToBook);
    }

    handleReasonForVisitBlur(e) {
        this.reasonForVisit = e.currentTarget.value
        //if (this.dev) console.log(':::reasonForVisit', this.reasonForVisit);
        let node = this.template.querySelector('[data-id="reasonForVisitInput"]');
        if (node) node.reportValidity();
    }

    handleTheoReasonForVisitBlur(e) {
        this.reasonForVisit = e.currentTarget.value
        //if (this.dev) console.log(':::reasonForVisit', this.reasonForVisit);
        this.validateTheoForm();
    }

    validateForm() {
        let node = this.template.querySelector('[data-id="reasonForVisitInput"]');
        if (node) node.reportValidity();
        if (this.attachRequired) {
            let nodeAttach = this.template.querySelector('[data-id="attachment"]');
            if (nodeAttach) nodeAttach.reportValidity();
        }
    }

    doTheoSubmit(e) {

        this.errorMessage = null;

        let valid = this.validateTheoForm();
        if (this.dev) console.log('::dTb:tf', this.theoForm);
        if (!valid) return;

        // BOOK FORM CONFIRMED
        this.throwTrackingEvent('formConfirmed');

        let req = JSON.stringify(this.theoForm);
        if (this.dev) console.log('::dTb:doResolveAccount:request:' + req);
        this.theoLoading = true;
        doResolveAccount({request: req})
            .then(result => {
                if (this.dev) console.log('::doResolveAccount:result', result);
                if (result) {
                    let acc = JSON.parse(result);
                    this.selectedAccountToBook = acc.Store_UUID__c;
                    this.theoLoading = false;
                    this.doConfirmBook(true);
                } else {
                    this.errorMessage = 'Unable to schedule at this time. Please try again with a different time.';
                    this.step = {confirm: true};
                }

            })
            .catch(error => {
                if (this.dev) console.error('::doResolveAccount:failed', error);
                this.errorMessage = 'We are unable to process your request at this time, please contact us to complete your booking.';
                this.step = {confirm: true};
            })
            .finally(() => {
                this.theoLoading = false;
            });

    }

    validateTheoForm() {

        let ret = true;

        this.theoForm = {};

        let nodeIds = ["firstName",
            "lastName",
            "dob_d",
            "dob_m",
            "dob_y",
            "gender",
            "theoEmail",
            "theoPhone",
            "theoReasonForVisitInput",
            "promoCode",
            "county",
            "city",
            "postalCode",
            "address3",
            "address2",
            "address1"
        ];

        for (let fid of nodeIds) {
            let node = this.template.querySelector('[data-formfield="' + fid + '"]');
            if (!!node && !!node.reportValidity) {
                let v = node.reportValidity();
                ret = ret && v;
                this.theoForm[fid] = node.value;
            }
        }

        ret = ret && this.validateDOB();

        if (this.attachRequired) {
            let nodeAttach = this.template.querySelector('[data-id="attachment"]');
            if (nodeAttach) nodeAttach.reportValidity();

            ret = ret && this.attachments.length > 0;
        }

        return ret;
    }

    handlePromoCodeBlur(e) {
        if (e.currentTarget.value === this.promoCode) return;
        this.promoCode = e.currentTarget.value;
        this.promoCodeValidity = null;
        if (this.promoCode) {
            let params = {
                couponCode: this.promoCode.toUpperCase(),
                store: this.storeConfig.storeName,
                productId: this.productId,
                locationId: this.selectedServiceCenterId,
                startTime: this.selectedSlot?.startTime
            }
            if (this.dev) console.log('::validateCoupon:coupon', params);
            validateCoupon(params)
                .then(results => {
                    console.log('::validateCoupon:result', results);
                    if (!results) {
                        this.promoCodeValidity = 'Not a valid code';
                        this.promoCode = null;
                    } else {
                        let coupon = JSON.parse(results);

                        if (!coupon || !coupon.Name || !coupon.Id) {
                            this.promoCodeValidity = 'Not a valid code';
                            this.promoCode = null;
                        } else {
                            this.promoCodeValidity = '✓';
                            //this.promoCode = coupon.Coupon_Code__c;
                        }
                    }

                })
                .catch(error => {
                    if (this.dev) console.error('::validateCoupon:failed', error);
                    this.promoCodeValidity = 'Not a valid code';
                    this.promoCode = null;
                });
        } else {
            this.promoCodeValidity = 'Not a valid code';
            this.promoCode = null;
        }

        if (this.dev) console.error('::promoCode', this.promoCode);
    }

    handleDayPlus(e) {
        if (this.selectedDate) {
            this.selectedDate = this.addDaysToISODate(this.selectedDate, 3);
            this.searchSlots();
        }
    }

    handleDayMinus(e) {
        if (this.selectedDate) {
            this.selectedDate = this.addDaysToISODate(this.selectedDate, -3);
            this.searchSlots();
        }
    }

    addDaysToISODate(dateStr, days) {
        const date = new Date(dateStr);
        date.setDate(date.getDate() + days);
        return date.toISOString().slice(0, 10);
    }

    handleTheoFormChange(e) {

    }

    validateDOB() {

        this.dobDateValid = false;

        let f_dobD = this.template.querySelector('[data-formfield="dob_d"]');
        let f_dobM = this.template.querySelector('[data-formfield="dob_m"]');
        let f_dobY = this.template.querySelector('[data-formfield="dob_y"]');

        if (!f_dobD || !f_dobY || !f_dobM) return false;

        if (f_dobD && f_dobM && f_dobY && f_dobD.value && f_dobM.value && f_dobY.value) {
            this.inputDobDate = this.checkDateIsValid(
                parseInt(f_dobY.value),
                parseInt(f_dobM.value),
                parseInt(f_dobD.value));
        }

        this.dobDateValid = (this.inputDobDate != null);

        if (!this.dobDateValid) {
            f_dobY.setCustomValidity('nope');
            f_dobM.setCustomValidity('nope');
            f_dobD.setCustomValidity('nope');
        } else {
            f_dobY.setCustomValidity('');
            f_dobM.setCustomValidity('');
            f_dobD.setCustomValidity('');
        }

        f_dobY.showHelpMessageIfInvalid();
        f_dobM.showHelpMessageIfInvalid();
        f_dobD.showHelpMessageIfInvalid();

        return this.dobDateValid;

    }

    checkDateIsValid(y, m, d) {
        let dte = new Date(y + '/' + m + '/' + d);

        if (!dte.isSameAs(y, m, d)) return null; else return (
            y + '-' +
            (m < 10 ? '0' + m : m)
            + '-' +
            (d < 10 ? '0' + d : d));
    }

    handleShowTheoForm() {
        this.showTheoForm = true;
    }

    handleShowLogin() {
        if (this.dev) console.log('::onl2book:handleClosehandleShowLogin');
        this.showTheoForm = false;
        this.doConfirmBook(false);
    }

    trackOpportunity(oppId, state) {
        if (this.dev) console.log('::bm:track:' + oppId + ":" + state);
        trackOnlineOpportunity({oppId: oppId, state: state})
            .then(results => {
            })
            .catch(error => {
            });
    }

    handlePostcodeSelection(event) {

        let al1Node = this.template.querySelector('[data-formfield="address1"]');
        let al2Node = this.template.querySelector('[data-formfield="address2"]');
        let al3Node = this.template.querySelector('[data-formfield="address3"]');
        let postalcodeNode = this.template.querySelector('[data-formfield="postalCode"]');
        let cityNode = this.template.querySelector('[data-formfield="city"]');
        let countyNode = this.template.querySelector('[data-formfield="county"]');

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
                this.hasAddressLine2 = (hit.line_2 != null) && (hit.line_2 !== "")
            }
            if (al3Node) {
                al3Node.value = hit.line_3;
                al3Node.showHelpMessageIfInvalid();
                this.hasAddressLine3 = (hit.line_3 != null) && (hit.line_3 !== "")
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
                this.hasCounty = (hit.county != null) && (hit.county !== "")
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

    handlePostcodeSearch(event) {

        if (!event || !event.detail || !event.detail.searchTerm) return;
        const target = event.target;

        let query = event.detail.searchTerm;

        if (query && query.length >= 2) {
            if (query.length > 16) query = query.substring(0, 16);

            this.provisionalPostCode = query;

            query = query.replace(/[^a-z0-9 ]/gi, ''); //.replace(/[ ]/gi,'+');

            let xmlHttp = new XMLHttpRequest();
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
                    //console.log(xmlHttp.responseText);
                    let res = JSON.parse(xmlHttp.responseText);
                    let list = [];
                    if (res && res.result && res.result.total > 0 && res.result.hits && res.result.hits.length > 0) {

                        for (let hit of res.result.hits) {
                            list.push({
                                id: hit.postcode + '#' + hit.uprn,
                                title: hit.postcode,
                                subtitle: hit.line_1 + ' ' + hit.line_2,
                                data: hit
                            });
                        }
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

    // on file-upload control finished, add name and documentIds to local arrays
    handleFilesChange(event) {
        if (this.dev) console.log('::hfc:len:' + event.target.files.length);
        if (event.target.files.length > 0) {
            for (let f of event.target.files) {
                if (this.dev) console.log('::hfc:push:', f);
                this.attachments.push(f);
                if (this.attachments.length >= 6) break;
            }
            this.attachments = [...this.attachments];
            this.attachmentToFileData();
        }
        if (this.attachRequired) {
            let nodeAttach = this.template.querySelector('[data-id="attachment"]');
            if (nodeAttach) nodeAttach.reportValidity();
        }
    }

    attachmentToFileData() {
        if (this.dev) console.log('::a2fd');
        let numAtts = this.attachments.length;
        if (this.dev) console.log('::a2fd:numAtts:' + numAtts);
        if (numAtts === 0) return;

        for (let att of this.attachments) {
            if (this.dev) console.log('::a2fd:att:', att);
            if (this.dev) console.log('::a2fd:att.name:', att.name);
            if (!att || !att.name) continue;
            if (att.fileData) continue;
            let reader = new FileReader();
            reader.onload = () => {
                let base64 = reader.result.split(',')[1];
                if (this.dev) console.log('::a2fd:setting fileData for ', att.name);
                att.fileData = {
                    'filename': att.name,
                    'base64': base64,
                }
            }
            reader.readAsDataURL(att);
        }

    }

    handleRemoveAttachment(e) {
        //console.log('::hra:e', e);
        //console.log('::hra:e', e.target.dataset.fid);

        //filter out the attachment by name
        this.attachments = this.attachments.filter(a => a.fileData.filename !== e.target.dataset.fid);

    }

    handleAvailableDateSelected(e) {
        console.log('::handleAvailableDateSelected:.d', e.detail);
        this.selectedDate = e.detail;
        this.searchSlots();
    }

    //find next slots finished searching
    handleFindNextStart(e) {
        this.searchingForAlternativeDates = true;
        this.forceShowNextAvailability = true;
    }

    //find next slots finished searching
    handleFindNextDone(e) {
        this.searchingForAlternativeDates = false;
    }

    handleBigLocationSelected(e) {
        // LOCATION SELECTED
        this.throwTrackingEvent('locationSelected');

        this.selectedServiceCenterId = e.currentTarget.dataset.locid;
        this.selectedLocation = this.getServiceCenter(this.selectedServiceCenterId);
        this.selectedLocationNotice = this.serviceCenterNotices[e.currentTarget.dataset.locid];
        this.searchSlots();
    }


}