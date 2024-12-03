/**
 * Created 22.2.2022..
 */

import {api, LightningElement} from 'lwc';

import getCovidTestData from '@salesforce/apex/OnlProductChange.getCovidTestData';
import getCovidTestProducts from '@salesforce/apex/OnlProductChange.getCovidTestProducts';
import doChange from '@salesforce/apex/OnlProductChange.doChange';
import getDefaultCovidTestForProduct from '@salesforce/apex/OnlProductChange.getDefaultCovidTestForProduct';
import getServiceCenters from '@salesforce/apex/onl_CheckoutCtrl.getServiceCenters';
import getAvailableSlotsByWorkTypeGroup from '@salesforce/apex/onl_CheckoutCtrl.getAvailableSlotsByWorkTypeGroup';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CloseActionScreenEvent} from 'lightning/actions';

import LOCALE from '@salesforce/i18n/locale';

export default class Onl2OamChangeProduct extends LightningElement {

    @api recordId;

    loading;

    productChangeAvailable;

    doRebook;
    doChangeType;

    currentProductId;
    currentProductName;

    currentAppId;
    currentAppLocation;

    changeToSelected;
    newProductName;

    changeOptions;

    ctest;

    locationSelected;
    locationOptions;
    timeSelected;
    timeSelectedEnd;
    resourceSelected;

    newStartTime;
    newLocationName;

    slotsErrorMessage;

    newWorkTypeGroupId;

    loadingSlots;
    currentSlots;


    // 1 = initial
    // 2 = choose a new appointment location and time
    // 3 = confirm changes
    step = 1;

    get showInitialScreen() {
        return this.step === 1;
    }

    get showBookingScreen() {
        return this.step === 2;
    }

    get showConfirmScreen() {
        return this.step === 3;
    }

    get hasTimeSlots() {
        return this.currentSlots && this.currentSlots.length > 0;
    }

    connectedCallback() {
        this.retrieveServiceCenters();
    }

    renderedCallback() {
        if (this.recordId && !this.currentProductName) {
            this.loadRecord();
        }
    }

    loadRecord() {
        console.log('::oamChangeProduct::loadRecord', this.recordId);
        this.loading = true;
        getCovidTestData({
            ctId: this.recordId
        })
            .then(results => {
                console.log('::oamChangeProduct:loadRecord', results);
                if (!results) {
                    console.log('::oamChangeProduct:loadRecord: returns empty results')
                } else {
                    this.ctest = JSON.parse(results);

                    this.currentProductId = this.ctest?.Opportunity_Product__r?.Product2Id;
                    this.currentProductName = this.ctest?.Opportunity_Product__r?.Product2?.Name;

                    this.currentAppId = this.ctest?.Scheduled_Appointment__c;
                    this.currentAppLocation = this.ctest?.Scheduled_Appointment__r?.ServiceTerritory?.Name

                    this.loadProductsTo();
                }
            })
            .catch(error => {
                console.error('::oamChangeProduct:loadRecord', error);
            })
            .finally(() => {
                this.productChangeAvailable = !!this.currentProductName;
                this.loading = false;
            });
    }

    retrieveServiceCenters() {
        console.log('::retrieveServiceCenters');
        getServiceCenters()
            .then(results => {
                //console.log('::getServiceCenters:result', results);

                if (results) {
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


    loadProductsTo() {
        if (!!this.currentProductId) {
            console.log('::oamChangeProduct::loadProductsTo:currentProductId', this.currentProductId);
            getCovidTestProducts({
                oldId: this.currentProductId
            })
                .then(results => {
                    //console.log('::oamChangeProduct:loadProductsTo', results);
                    if (!results) {
                        console.log('::oamChangeProduct:loadProductsTo: returns empty results')
                    } else {
                        let products = JSON.parse(results);
                        this.changeOptions = [];
                        for (let product of products) {
                            this.changeOptions.push(
                                {
                                    value: product.Id,
                                    label: product.Name
                                }
                            )
                        }

                    }
                })
                .catch(error => {
                    console.error('::oamChangeProduct:loadProductsTo', error);
                })
                .finally(() => {

                });
        }
    }

    loadWTGForNewProduct() {
        if (!!this.changeToSelected) {
            console.log('::oamChangeProduct::loadWTGForNewProduct', this.recordId);
            getDefaultCovidTestForProduct({
                productId: this.changeToSelected
            })
                .then(results => {
                    console.log('::oamChangeProduct:loadWTGForNewProduct', results);
                    if (!results) {
                        console.log('::oamChangeProduct:loadWTGForNewProduct: returns empty results')
                    } else {
                        this.newWorkTypeGroupId = JSON.parse(results).Work_Type_Group__c;
                    }
                })
                .catch(error => {
                    console.error('::oamChangeProduct:loadWTGForNewProduct', error);
                })
                .finally(() => {
                    console.log('::oamChangeProduct:newWorkTypeGroupId', this.newWorkTypeGroupId);
                });
        }
    }

    searchSlots() {
        this.timeSelected = null;
        console.log('::searchSlots:doChangeType', this.doChangeType);
        this.currentSlots = [];
        this.slotsErrorMessage = null;

        let wtgId = this.newWorkTypeGroupId;
        if (!this.doChangeType) wtgId = this.ctest.Work_Type_Group__c;

        console.log('::searchSlots', wtgId, this.locationSelected, this.selectedDate);


        if (wtgId && this.locationSelected && this.selectedDate) {
            this.loadingSlots = true;

            getAvailableSlotsByWorkTypeGroup({
                workTypeGroupId: wtgId,
                serviceCenterId: this.locationSelected,
                slotDate: this.selectedDate
            })
                .then(results => {
                    // console.log('::getAvailableSlotsByWorkTypeGroup:result', results);

                    let receivedSlots = JSON.parse(results);

                    this.currentSlots = [];

                    for (let rs of receivedSlots) {
                        rs.label = new Intl.DateTimeFormat(LOCALE,
                            {
                                timeZone: "Europe/London",
                                hour: "2-digit",
                                minute: "2-digit",
                                hour12: false,
                            })
                            .format(Date.parse(rs.startTime));
                        rs.value = rs.startTime;
                        this.currentSlots.push(
                            {
                                label: rs.label,
                                value: rs.value,
                                resource: rs.resources[0],
                                endTime: rs.endTime
                            }
                        )
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

    handleDoChangeTypeChange(e) {
        this.doChangeType = this.template.querySelector('[data-id=doChangeType]').checked;
        //console.log('doChangeType', this.doChangeType);
    }

    handleDoRebookChange(e) {
        this.doRebook = this.template.querySelector('[data-id=doRebook]').checked;
        //console.log('doRebook', this.doRebook);
    }

    handleChangeToChanged(e) {
        this.changeToSelected = e.detail.value;
        for (let p of this.changeOptions) {
            if (p.value === this.changeToSelected) {
                this.newProductName = p.label;
                break;
            }
        }
        this.loadWTGForNewProduct();
        console.log('::changeToSelected', this.changeToSelected);
    }

    handleLocationChanged(e) {
        this.locationSelected = e.detail.value;
        console.log(':::locationSelected', this.locationSelected);
        for (let loc of this.locationOptions) {
            if (loc.value === this.locationSelected) {
                this.newLocationName = loc.label;
                break;
            }
        }
        console.log(':::newLocationName', this.newLocationName);
        this.searchSlots();
    }


    handleDateInputChange(e) {
        this.selectedDate = e.currentTarget.value;
        console.log('::handleDateInputChange:selectedDate', this.selectedDate);
        this.searchSlots();
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
        console.log(':::timeSelectedEnd', this.timeSelectedEnd);
        console.log(':::resourceSelected', this.resourceSelected);
    }

    handleNext() {
        if (this.step === 1) {
            //2 or 3
            if (this.doRebook) this.step = 2;
            else this.step = 3;
        } else if (this.step === 2) {
            this.step = 3;
        } else if (this.step === 3) {
            //todo commit
            this.commitChanges();
            this.step = 3;
        }
        //console.log('step after next',this.step);
    }

    handleBack() {

        if (this.step === 1) {
            this.step = 1
        } else if (this.step === 2) {
            this.step = 1
        } else if (this.step === 3) {
            //2 or 1
            if (this.doRebook) this.step = 2;
            else this.step = 1;
        }
        //console.log('step after back',this.step);
    }

    get allowNext() {
        if (this.step === 1) {
            if (this.doChangeType && !this.changeToSelected) return false;
            return (this.doChangeType && this.changeToSelected) || (this.doRebook)
        } else if (this.step === 2) {
            return (this.doRebook && this.locationSelected && this.selectedDate && this.timeSelected)
        } else if (this.step === 3) {
            return true;
        }

        return false;
    }

    commitChanges() {
        let params = {};

        this.loading = true;
        params.ctestId = this.ctest.Id;
        params.doRebook = this.doRebook;
        params.doChangeType = this.doChangeType;
        params.changeToProduct = this.changeToSelected;
        params.locationSelected = this.locationSelected;
        params.timeSelected = this.timeSelected;
        params.timeSelectedEnd = this.timeSelectedEnd;
        params.newWorkTypeGroupId = this.newWorkTypeGroupId;
        params.resourceSelected = this.resourceSelected;

        let req = JSON.stringify(params)
        console.log('::oamChangeProduct:doChange:request', req);
        doChange({request: req})
            .then(results => {
                console.log('::oamChangeProduct:doChange', results);
                if (!results) {
                    this.showOK('Success', 'Operation done.');
                    this.closeAction();
                    clearTimeout(this.timeoutId); // no-op if invalid id
                    this.timeoutId = setTimeout(this.pageReload.bind(this), 1000);
                } else {
                    this.showNotification('Error', results);
                }
            })
            .catch(error => {
                console.error('::oamChangeProduct:doChange', error);
                this.showNotification('Error', error);
            })
            .finally(() => {
                this.loading = false;
            });

    }

    pageReload() {
        window.location.reload();
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showNotification(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    showOK(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

}