/**
 * Created 21.3.2022..
 * SF UI for booking, under Patient screen
 */

import {LightningElement, api, wire} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import getProducts from '@salesforce/apex/OnlBookUI.getAppointmentProducts';
import getMedicalProducts from '@salesforce/apex/OnlBookUI.getMedicalProducts';
import getDentalProducts from '@salesforce/apex/OnlBookUI.getDentalProducts';
import getServiceCentersForWTG from '@salesforce/apex/OnlBookUI.getServiceCentersForWTGAsJSON';
import getDiscountCodesForProduct from '@salesforce/apex/DiscountCodeManager.aura_getDiscountCodes';
import checkQuoteCalculated from '@salesforce/apex/OnlBookUI.checkQuoteCalculated';
import closeOpportunity from '@salesforce/apex/OnlBookUI.closeOpportunity';
import getAvailableSlotsByWorkTypeGroup from '@salesforce/apex/OnlBookUI.aura_getAvailableSlotsByWorkTypeGroup';
import performBooking from '@salesforce/apex/OnlBookUI.aura_doBook';
import getPriceBookEntry from '@salesforce/apex/OnlBookUI.getPriceBookEntryForAccountAndProductAndDate';
import getServiceResourcesForTerritoryAndWorkTypeSkill from '@salesforce/apex/OnlBookUI.getServiceResourcesForTerritoryAndWorkTypeSkill';
import getSpecialInstructionsForProduct from '@salesforce/apex/OnlBookUI.getSpecialInstructionsForProduct';
import getAllServiceResources from '@salesforce/apex/OnlBookUI.getAllServiceResources';
import checkOOMS from '@salesforce/apex/OnlBookUI.aura_checkForOutOfMembershipSurcharge';
import getPatientType from '@salesforce/apex/OnlBookUI.aura_getPatientType';

import LOCALE from '@salesforce/i18n/locale';
import {
    FlowAttributeChangeEvent,
    FlowNavigationFinishEvent,
    FlowNavigationNextEvent
} from 'lightning/flowSupport';


export default class Onl2BookUI extends NavigationMixin(LightningElement) {
    @api recordId;
    @api chargeDescription;

    @api chargeAmount;
    @api opportunityId;
    @api productId;
    @api finalScreen;
    @api noChargeFinalScreen;
    @api appointmentId;
    @api quoteId;

    @api transactionID;
    @api paymentMethodId;

    @api paidByPos;

    @api patientTypeSelected;
    @api reasonForVisit;

    loading;
    opportunityClosed;

    // 1 = initial
    // 9 = opportunity being created
    @api step = 1;

    serviceTypeOptions = [
        {label: 'Medical', value: 'MEDICAL'},
        {label: 'Dental', value: 'DENTAL'}
    ];

    defaultEmptySlots = [];

    serviceTypeSelected = 'MEDICAL';


    productOptions;
    allProductDefaultOptions;
    productSelected;
    wtgIdSelected;
    wtIdSelected;

    discountOptions;
    discountSelected = null;

    locationOptions;
    locationSelected;
    locationSelectedName;

    resourceSelected;
    timeSelectedEnd;

    selectedDate;
    timeSelected;

    currentSlots;

    loadingSlots;
    slotsErrorMessage;

    bookResult;

    quoteCalculated;

    resourceOptions;
    resourceFilterOptions;
    filterByResource;

    allResources = []; // will contain an id and name of all resources found

    noPaymentDone;

    applicablePBE;

    specialInstructions;

    receivedSlots;

    patientTypeOptions = [{label: 'New Patient', value: 'New'}, {label: 'Returning Patient', value: 'Returning'}, {label: 'Member', value: 'Member'}];

    selectedVideoOrTelProduct;

    oomsInfo;

    getHasSpentAllFreeBenefits() {
        return (this.oomsInfo != null) && (this.oomsInfo.spentFree != null) && (this.oomsInfo.maxFree != null) && (this.oomsInfo.spentFree >= this.oomsInfo.maxFree);
    }

    get showInitialScreen() {
        return this.step === 1 && !(this.finalScreen || this.noChargeFinalScreen);
    }

    get showWaitScreen() {
        return this.step === 9;
    }

    get showResultScreen() {
        return !!this.finalScreen || !!this.noChargeFinalScreen;
    }

    get hasTimeSlots() {
        return this.currentSlots && this.currentSlots.length > 0;
    }

    get hasDiscounts() {
        return this.discountOptions && this.discountOptions.length > 0;
    }

    get readyToBook() {
        return this.recordId
            && this.productSelected
            && this.resourceSelected
            && this.wtgIdSelected
            && this.locationSelected
            && this.selectedDate
            && this.timeSelected
            && this.timeSelectedEnd;
    }

    get showResources() {
        return this.resourceOptions != null;
    }

    get testMode() {
        return this.reasonForVisit === 'test';
    }

    connectedCallback() {
        // console.log('cc:' + this.recordId);
        //this.retrieveServiceCenters();

        this.loadProductOptions();
        /*
        if (this.serviceTypeSelected) {
            if (this.serviceTypeSelected === 'MEDICAL' || this.serviceTypeSelected == null) {
                this.loadMedicalOptions();
            }
        }
         */

        this.retrievePractitioners();
        this.retrievePatientType();

        if (this.productId) this.productSelected = this.productId;
    }

    renderedCallback() {

        if (!this.paidByPos) this.paidByPos = false;

        //console.log('::obui:rr:finalScreen', this.finalScreen);
        //console.log('::obui:rr:noChargeFinalScreen', this.noChargeFinalScreen);
        if (!this.opportunityClosed && (this.finalScreen || this.noChargeFinalScreen)) {

            console.log('::obui:rr:no_payment:paidByPos', this.paidByPos);

            if (this.finalScreen && (!this.transactionID || !this.paymentMethodId)) {
                if (!this.paidByPos) {
                    console.log('::obui:rr:no_payment:transactionID', this.transactionID);
                    console.log('::obui:rr:no_payment:paymentMethodId', this.paymentMethodId);
                    this.noPaymentDone = true;
                    return;
                } else {
                    console.log('::obui:rr:no_payment:was paidByPos');
                }
            }

            console.log('closing opportunity', this.opportunityId);
            closeOpportunity({oppId: this.opportunityId, txId: this.transactionID, paidByPos: this.paidByPos})
                .then(results => {
                    console.log('::closeOpportunity:result', results);
                    if (results) {
                        this.opportunityClosed = true;
                    }
                })
                .catch(error => {
                    console.error('::closeOpportunity:failed', error);
                })
                .finally(() => {

                });
        }
    }


    retrievePatientType() {
        getPatientType({pid: this.recordId})
            .then(result => {
                if (this.dev) console.log('::getPatientType:result', result);

                if (result) {
                    this.patientTypeSelected = result;
                }

            })
            .catch(error => {
                console.error('::getPatientType:failed', error);
                this.showServiceCenters = false;
            })
            .finally(() => {

            });
    }

    retrievePractitioners() {
        getAllServiceResources()
            .then(result => {
                if (this.dev) console.log('::getAllServiceResources:result', result);

                if (result) {
                    let response = JSON.parse(result);
                    response.forEach(res => {
                        this.allResources[res.Id] = res.Name;
                    });
                }
                console.log('::allResources:', this.allResources);
            })
            .catch(error => {
                console.error('::getAllServiceResources:failed', error);
                this.showServiceCenters = false;
            })
            .finally(() => {
                if (this.dev) console.log('::bm:allResources', this.allResources);
            });

    }

    handleDiscountChanged(e) {
        this.discountSelected = e.detail.value;
    }

    handlePatientTypeChanged(e) {
        this.patientTypeSelected = e.detail.value;
    }

    handleReasonForVisitChanged(e) {
        this.reasonForVisit = e.detail.value;
    }

    handleLocationChanged(e) {
        this.locationSelected = e.detail.value;
        console.log(':::locationSelected', this.locationSelected);
        for (let loc of this.locationOptions) {
            if (loc.value === this.locationSelected) {
                this.locationSelectedName = loc.label;
                break;
            }
        }
        console.log(':::locationSelectedName', this.locationSelectedName);
        this.retrieveServiceResourcesForTerritory(this.locationSelected);
        this.searchSlots();
    }

    handleDateInputChange(e) {
        this.selectedDate = e.currentTarget.value;
        console.log('::handleDateInputChange:selectedDate', this.selectedDate);
        this.retrievePriceBookEntry();
        this.searchSlots();
    }

    retrieveServiceResourcesForTerritory(stid) {
        this.resourceFilterOptions = null;
        this.filterByResource = null;

        if (stid == null) {
            this.resourceFilterOptions = [];
            this.resourceFilterOptions.push({label: 'No Preference', value: null});
            return;
        }

        console.log('getServiceResourcesForTerritoryAndWorkTypeSkill:req', {stid: stid, wtid: this.wtIdSelected});
        getServiceResourcesForTerritoryAndWorkTypeSkill({stid: stid, wtid: this.wtIdSelected})
            .then(result => {
                console.log('::getServiceResourcesForTerritoryAndWorkTypeSkill:result', result);

                if (result) {
                    let response = JSON.parse(result);
                    this.resourceFilterOptions = [];
                    this.resourceFilterOptions.push({label: 'No Preference', value: null});
                    response.forEach(res => {
                        this.resourceFilterOptions.push({
                            label: res.Name, value: res.Id
                        })
                    });
                }
                console.log('::resourceFilterOptions:', this.resourceFilterOptions);
            })
            .catch(error => {
                console.error('::getServiceResourcesForTerritoryAndWorkTypeSkill:failed', error);
                this.resourceFilterOptions = [];
                this.filterByResource = null;
            })
            .finally(() => {

            });
    }

    retrievePriceBookEntry() {
        const params = {accId: this.recordId, productId: this.productSelected, dt: this.selectedDate};
        console.log('::retrievePriceBookEntry:params', params);
        getPriceBookEntry(params)
            .then(result => {
                console.log('::retrievePriceBookEntry:result', result);
                this.applicablePBE = result;
            })
            .catch(error => {
                console.error('::retrievePriceBookEntry:failed', error);

            })
            .finally(() => {

            });
    }

    retrieveOomsInfo() {
        const params = {accountId: this.recordId, productId: this.productSelected};
        console.log('::checkOOMS:params', params);
        checkOOMS(params)
            .then(result => {
                console.log('::checkOOMS:result', result);
                if (result) this.oomsInfo = JSON.parse(result);
                else this.oomsInfo = null;
            })
            .catch(error => {
                console.error('::checkOOMS:failed', error);
                this.oomsInfo = null;
            })
            .finally(() => {

            });
    }


    retrieveDiscountCodes() {
        console.log('::retrieveDiscountCodes');
        getDiscountCodesForProduct({productId: this.productSelected, store: null, locationId: this.locationSelected, accountId: this.recordId})
            .then(results => {
                //console.log('::getDiscountCodesForProduct:result', results);

                this.discountOptions = [];
                if (results) {
                    console.log('::getDiscountCodesForProduct:result:', results);
                    let resObj = JSON.parse(results);

                    this.discountOptions = resObj;
                }
                let a = this.hasDiscounts;
            })
            .catch(error => {
                console.error('::getDiscountCodesForProduct:failed', error);
            })
            .finally(() => {

            });
    }

    retrieveServiceCenters() {
        console.log('::retrieveServiceCenters');
        getServiceCentersForWTG({wtgId: this.wtgIdSelected})
            .then(results => {
                //console.log('::getServiceCenters:result', results);

                if (results) {
                    console.log('::getServiceCentersForWTG:result:', results);
                    let resObj = JSON.parse(results);

                    this.locationOptions = [];
                    for (let sc of resObj) {
                        this.locationOptions.push({
                            label: sc.Name + ", " + sc.Street + ", " + sc.City + ", " + sc.PostalCode,
                            value: sc.Id
                        })
                    }
                }
            })
            .catch(error => {
                console.error('::getServiceCenters:failed', error);
            })
            .finally(() => {

            });
    }

    retrieveSpecialInstructions() {
        console.log('::retrieveSpecialInstructions');
        this.specialInstructions = null;
        if (!!this.productSelected) {
            getSpecialInstructionsForProduct({pid: this.productSelected})
                .then(results => {
                    this.specialInstructions = results;
                    console.log('::specialInstructions: ' + this.specialInstructions);
                })
                .catch(error => {
                    console.error('::retrieveSpecialInstructions:failed', error);
                })
                .finally(() => {

                });
        }
    }

    loadMedicalOptions() {
        if (!!this.serviceTypeSelected) {
            getMedicalProducts()
                .then(results => {
                    console.log('::getMedicalProducts:result:', results);
                    if (!results) {
                        console.log('::getMedicalProducts: returns empty results')
                    } else {
                        this.productOptions = JSON.parse(results);
                        if (this.productOptions) {
                            this.allProductDefaultOptions = [];
                            this.productOptions.forEach(res => {
                                //console.log(JSON.stringify(res));
                                this.allProductDefaultOptions.push(
                                    {
                                        id: res.value,
                                        title: res.label
                                    }
                                );
                            });
                        }
                    }
                })
                .catch(error => {
                    console.error('::getMedicalProducts:', error);
                })
                .finally(() => {
                    console.info('::productOptions', this.productOptions);
                });
        }
    }

    loadProductOptions() {
        getProducts()
            .then(results => {
                console.log('::getProducts:result:', results);
                if (!results) {
                    console.log('::getProducts: returns empty results')
                } else {
                    this.productOptions = JSON.parse(results);
                    if (this.productOptions) {
                        this.allProductDefaultOptions = [];
                        this.productOptions.forEach(res => {
                            //console.log(JSON.stringify(res));
                            this.allProductDefaultOptions.push(
                                {
                                    id: res.value,
                                    title: res.label
                                }
                            );
                        });
                    }
                }
            })
            .catch(error => {
                console.error('::getProducts:', error);
            })
            .finally(() => {
                console.info('::productOptions', this.productOptions);
            });

    }

    loadDentalOptions() {
        if (!!this.serviceTypeSelected) {
            getDentalProducts()
                .then(results => {
                    console.log('::getDentalProducts:result:', results);
                    if (!results) {
                        console.log('::getDentalProducts: returns empty results')
                    } else {
                        this.productOptions = JSON.parse(results);
                        if (this.productOptions) {
                            this.allProductDefaultOptions = [];
                            this.productOptions.forEach(res => {
                                //console.log(JSON.stringify(res));
                                this.allProductDefaultOptions.push(
                                    {
                                        id: res.value,
                                        title: res.label
                                    }
                                );
                            });
                        }
                    }
                })
                .catch(error => {
                    console.error('::getDentalProducts:', error);
                })
                .finally(() => {
                    console.info('::productOptions', this.productOptions);
                });
        }
    }

    handleFilteredResourceChanged(e) {
        this.filterByResource = e.currentTarget.value
        console.log(':::filterByResource', this.filterByResource);
        this.buildCurrentSlots(this.filterByResource);
    }

    handleStartTimeChanged(e) {
        this.timeSelected = e.detail.value;
        console.log(':::timeSelectedStart', this.timeSelected);
        for (let sl of this.currentSlots) {
            if (sl.value === this.timeSelected) {
                this.resourceSelected = sl.resource;
                this.timeSelectedEnd = sl.endTime;
                break;
            }
        }
        console.log('::timeSelectedEnd', this.timeSelectedEnd);
        console.log('::resourceSelected', this.resourceSelected);
    }

    searchSlots() {
        this.timeSelected = null;
        this.currentSlots = [];
        this.slotsErrorMessage = null;
        this.resourceOptions = null;
        this.filterByResource = null;

        try {
            let cmp_findAvailableSlots = this.template.querySelector('[data-componentid="find-available-dates"]');
            if (cmp_findAvailableSlots) cmp_findAvailableSlots.reset();
        } catch (e) {}

        console.log('::searchSlots', this.wtgIdSelected, this.locationSelected, this.selectedDate);

        if (this.selectedVideoOrTelProduct) this.locationSelected = null;

        if (this.wtgIdSelected && (this.locationSelected || this.selectedVideoOrTelProduct) && this.selectedDate) {
            this.loadingSlots = true;

            getAvailableSlotsByWorkTypeGroup({
                workTypeGroupId: this.wtgIdSelected,
                serviceCenterId: this.locationSelected,
                slotDate: this.selectedDate,
                ctxInsideSF: true
            })
                .then(results => {
                    console.log('::getAvailableSlotsByWorkTypeGroup:res', results);
                    if (results) {
                        this.receivedSlots = JSON.parse(results);

                        let mentionedResources = [];

                        for (let rs of this.receivedSlots.territorySlots) {
                            rs.label = new Intl.DateTimeFormat(LOCALE,
                                {
                                    timeZone: "Europe/London",
                                    hour: "2-digit",
                                    minute: "2-digit",
                                    hour12: false,
                                })
                                .format(Date.parse(rs.startTime));
                            rs.value = rs.startTime;

                            rs.endTimeLabel = new Intl.DateTimeFormat(LOCALE,
                                {
                                    timeZone: "Europe/London",
                                    hour: "2-digit",
                                    minute: "2-digit",
                                    hour12: false,
                                })
                                .format(Date.parse(rs.endTime));

                            // rs.resourceNames = '';
                            for (let res of rs.resources) {
                                //     if (rs.resourceNames.length>0) rs.resourceNames += ', ';
                                //     rs.resourceNames += this.allResources[res];
                                if ((rs.startTime + '').startsWith(this.selectedDate + '')) {
                                    if (!mentionedResources.includes(res)) mentionedResources.push(res);
                                }
                            }
                        }

                        this.buildResourceOptions(mentionedResources);

                        this.buildCurrentSlots(null);

                        console.log('::getAvailableSlotsByWorkTypeGroup:currentSlots', this.currentSlots);
                    } else {
                        this.receivedSlots = null;
                        this.currentSlots = [];
                    }


                })
                .catch(error => {
                    console.error('::getAvailableSlotsByWorkTypeGroup:failed', error);
                    this.currentSlots = [];
                })
                .finally(() => {
                    // console.log('::getAvailableSlots:currentSlots', this.currentSlots);
                    this.loadingSlots = false;
                });
        }
    }

    doBook(e) {
        this.step = 9;

        let bookReq = {};

        bookReq.recordId = this.recordId;
        bookReq.productSelected = this.productSelected;
        bookReq.resourceSelected = this.resourceSelected;
        bookReq.wtgIdSelected = this.wtgIdSelected;
        bookReq.locationSelected = this.locationSelected;
        bookReq.selectedDate = this.selectedDate;
        bookReq.timeSelected = this.timeSelected;
        bookReq.timeSelectedEnd = this.timeSelectedEnd;
        bookReq.discountSelected = this.discountSelected;
        bookReq.reasonForVisit = this.reasonForVisit;
        bookReq.patientType = this.patientTypeSelected;
        bookReq.mode = 'SF';
        bookReq.existingOpportunityId = this.opportunityId;

        let req = JSON.stringify(bookReq);
        console.log('::performBooking:request', req)
        performBooking({request: req})
            .then(results => {
                console.log('::performBooking:results', results)
                this.bookResult = JSON.parse(results);
                this.appointmentId = this.bookResult.appId;
                this.opportunityId = this.bookResult.oppId;
                this.chargeAmount = this.bookResult.amount;
                if (this.chargeAmount < 0) this.chargeAmount = 0;
                this.quoteId = this.bookResult.quoteId;
                const amountChangeEvent = new FlowAttributeChangeEvent('chargeAmount', this.chargeAmount);
                console.log('dispatching ' + JSON.stringify(amountChangeEvent));
                this.dispatchEvent(amountChangeEvent);
                //this.goFlowNext();
                //now periodically query for quote calculation
                this.waitForQuoteCalculation();
            })
            .catch(error => {
                console.error('::performBooking:failed', error);
                this.opportunityId = null;
                this.appointmentId = null;
                let errMsg = '' + error;
                if (error && error.body && error.body.message) error = error.body.message;
                if (error && ('' + error).indexOf('PBL-') > 0) this.showNotification('Unable to book, this patient is BLOCKED');
                else this.showNotification('Error creating a booking', error);
                this.step = 1;
            })
            .finally(() => {

            });
    }

    // every 1500ms query quote if it's updated, if it is, update local chargeAmount value and go to next
    waitForQuoteCalculation() {
        console.log('::waiting for quote calculation..');
        checkQuoteCalculated({quoteId: this.quoteId, appId: this.appointmentId})
            .then(results => {
                console.log('::waitForQuoteCalculation:calculated:', results)
                let resp = JSON.parse(results);
                this.quoteCalculated = resp.quoteCalculated;
                if (!this.quoteCalculated) setTimeout(this.waitForQuoteCalculation.bind(this), 1500);
                else {
                    this.chargeAmount = resp.amount;
                    //this.chargeAmount = this.bookResult.amount;
                    if (this.chargeAmount < 0) this.chargeAmount = 0;
                    console.log(':onl2BUI:wfqc:chargeAmount:' + this.chargeAmount);
                    const amountChangeEvent = new FlowAttributeChangeEvent('chargeAmount', this.chargeAmount);
                    console.log('dispatching ' + JSON.stringify(amountChangeEvent));
                    this.dispatchEvent(amountChangeEvent);
                    this.goFlowNext();
                }
            })
            .catch(error => {
                console.error('::waitForQuoteCalculation:failed', error);
            })
            .finally(() => {

            });
    }


    showNotification(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    goToOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.opportunityId,
                actionName: 'view'
            }
        })
    }

    closeAction() {
        this.goFlowFinish();
    }

    goFlowNext() {
        this.dispatchEvent(new FlowNavigationNextEvent());
    }

    goFlowFinish() {
        this.dispatchEvent(new FlowNavigationFinishEvent());
    }

    handleTimeSlotSelected(e) {
        console.log(':::handleTimeSlotSelected:ds', e.currentTarget.dataset.start);
        this.timeSelected = e.currentTarget.dataset.start;
        console.log(':::timeSelectedStart', this.timeSelected);
        for (let sl of this.currentSlots) {
            if (sl.startTime === this.timeSelected) {
                console.log('::dbg:cur_slot', sl);
                if (this.filterByResource == null) {
                    this.resourceSelected = sl.resources[0];
                } else {
                    this.resourceSelected = this.filterByResource;
                }
                this.timeSelectedEnd = sl.endTime;
                //bugfix 2023-06
                if ((this.selectedVideoOrTelProduct === true) && sl.resource_locations) {
                    let loc = sl.resource_locations[this.resourceSelected];
                    if (loc) this.locationSelected = loc[0];
                }
                sl.selected = true;

            } else {
                sl.selected = false;
            }
        }
        console.log(':::timeSelectedEnd', this.timeSelectedEnd);
        console.log(':::resourceSelected', this.resourceSelected);
        console.log(':::locationSelected', this.locationSelected);
    }

    handleResourceChanged(e) {
        this.resourceSelected = e.currentTarget.value;
        console.log(':::resourceSelected', this.resourceSelected);
    }

    buildResourceOptions(resources) {

        this.resourceOptions = [];
        this.resourceOptions.push({label: 'ANY', value: null});
        if (resources) {
            for (let res of resources) {
                this.resourceOptions.push(
                    {
                        label: this.allResources[res],
                        value: res
                    });
            }
        }

        this.resourceSelected = null;
        console.log('::buildResourceOptions:resourceOptions', this.resourceOptions);
    }

    buildCurrentSlots(filterByResource) {
        console.log('::buildCurrentSlots:filter', filterByResource);
        this.resourceSelected = null;
        this.currentSlots = [];

        for (let rs of this.receivedSlots.territorySlots) {

            let passResourceFilter = false;

            if (filterByResource != null) {
                passResourceFilter = false;
                for (let res of rs.resources) {
                    if (res === filterByResource) {
                        passResourceFilter = true;
                        break;
                    }
                }
            } else {
                passResourceFilter = true;
            }

            if (passResourceFilter) {
                //include only if the found slot if for the selected date (it can happen with aerona that we get future slots also)
                if ((rs.startTime + '').startsWith(this.selectedDate + '')) {
                    this.currentSlots.push({
                        label: new Intl.DateTimeFormat(LOCALE,
                            {
                                timeZone: "Europe/London",
                                hour: "2-digit",
                                minute: "2-digit",
                                hour12: false,
                            })
                            .format(Date.parse(rs.startTime)),
                        startTime: rs.startTime,
                        endTime: rs.endTime,
                        resources: rs.resources,
                        resource_locations: rs.resource_locations,
                        endTimeLabel: new Intl.DateTimeFormat(LOCALE,
                            {
                                timeZone: "Europe/London",
                                hour: "2-digit",
                                minute: "2-digit",
                                hour12: false,
                            })
                            .format(Date.parse(rs.endTime)),
                        //resourceNames : rs.resourceNames,
                        selected: false
                    });
                }
            }
        }
    }


    handleProductSearch(e) {
        const target = e.target;
        console.log('::hps:e.detail:' + JSON.stringify(e.detail));
        let searchTerm = e?.detail?.searchTerm?.toLowerCase();
        let ret = [];
        if (this.productOptions) {
            this.productOptions.forEach(res => {
                //console.log(JSON.stringify(res));
                if (res && res.label && res.label.toLowerCase().indexOf(searchTerm) >= 0) {
                    ret.push(
                        {
                            id: res.value,
                            title: res.label
                        }
                    );
                }
            });
        }

        target.setSearchResults(ret);
    }

    handleServiceTypeChanged(e) {
        this.allProductDefaultOptions = null;
        this.serviceTypeSelected = e.currentTarget.value;
        console.log(this.serviceTypeSelected);
        if (this.serviceTypeSelected === 'MEDICAL') this.loadMedicalOptions();
        else if (this.serviceTypeSelected === 'DENTAL') this.loadDentalOptions();
    }

    handleProductSearchChanged(e) {
        // Get the selected ids from the event (same interface as lightning-input-field)
        const selection = e.target.getSelection();

        console.log(selection);

        this.applicablePBE = null;

        if (selection && (selection.length > 0) && selection[0].id != null) {

            this.productSelected = selection[0].id;
            if (this.productOptions)
                for (let product of this.productOptions) {
                    if (product.value === this.productSelected) {
                        this.wtgIdSelected = product.wtgId;
                        this.wtIdSelected = product.wtId;
                        this.selectedVideoOrTelProduct = product.isVideoOrTel;
                        this.chargeDescription = product.label;
                        if (this.chargeDescription != null && this.chargeDescription.length > 36)
                            this.chargeDescription = this.chargeDescription.substring(0, 36) + '...';
                        break;
                    }
                }


            console.log('::productSelected', this.productSelected);
            console.log('::wtgIdSelected', this.wtgIdSelected);
            console.log('::selectedVideoOrTelProduct', this.selectedVideoOrTelProduct);

            this.locationSelected = null;
            this.selectedDate = null;
            this.currentSlots = null;

            this.retrieveServiceCenters();
            this.retrieveDiscountCodes();
            this.retrievePriceBookEntry();
            this.retrieveOomsInfo();
            this.retrieveSpecialInstructions();
        } else {
            this.productSelected = null;
            this.locationSelected = null;
            this.selectedDate = null;
            this.currentSlots = null;
            this.discountOptions = null;
            this.specialInstructions = null;
            this.selectedVideoOrTelProduct = false;
        }
    }

    handleAvailableDateSelected(e) {
        console.log('::handleAvailableDateSelected', e.detail);
        if (e.detail) this.selectedDate = e.detail;
        this.searchSlots();
    }


}