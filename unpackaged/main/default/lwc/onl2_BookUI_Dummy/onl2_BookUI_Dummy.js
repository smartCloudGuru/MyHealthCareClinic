/**
 * Created 17.6.2022..
 */

import {api, LightningElement} from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';

import getServiceResourcesForTerritory from '@salesforce/apex/OnlBookUI.getServiceResourcesForTerritory';
import doSimpleReservation from '@salesforce/apex/OnlBookUI.doSimpleReservation';

export default class Onl2BookUiDummy extends NavigationMixin(LightningElement) {
    @api recordId;
    @api chargeDescription;

    @api chargeAmount;
    @api opportunityId;
    @api finalScreen;
    @api noChargeFinalScreen;
    @api appointmentId;
    @api quoteId;

    @api transactionID;
    @api paymentMethodId;

    loading;
    opportunityClosed;

    // 1 = initial
    // 9 = opportunity being created
    @api step = 1;


    productSelected;
    wtgIdSelected;


    locationSelected;

    resourceSelected;
    timeSelectedEnd;

    selectedDate;
    timeSelected;

    bookResult;

    quoteCalculated;

    resourceOptions;
    resourceFilterOptions;

    reservationDone;


    get showInitialScreen() {
        return this.step === 1 && !(this.finalScreen || this.noChargeFinalScreen);
    }

    get showWaitScreen() {
        return this.step === 9 && !this.reservationDone;
    }

    get showResultScreen() {
        return this.reservationDone;
    }

    get readyToBook() {
        return this.recordId && this.resourceSelected && this.timeSelected && this.timeSelectedEnd;
    }

    connectedCallback() {

        this.retrieveServiceResourcesForTerritory();

    }

    renderedCallback() {

    }


    retrieveServiceResourcesForTerritory() {

        console.log('::retrieveServiceResourcesForTerritory:recordId', this.recordId);
        if (this.recordId == null) {
            this.resourceFilterOptions = [];
            return;
        }

        getServiceResourcesForTerritory({stid: this.recordId})
            .then(result => {
                console.log('::getServiceResourcesForTerritory:result', result);

                if (result) {
                    let response = JSON.parse(result);
                    this.resourceOptions = [];
                    response.forEach(res => {
                        this.resourceOptions.push({
                            label: res.Name, value: res.Id
                        })
                    });
                }
                console.log('::resourceOptions:', this.resourceOptions);
            })
            .catch(error => {
                console.error('::getServiceResourcesForTerritory:failed', error);
                this.resourceOptions = [];
            })
            .finally(() => {

            });
    }


    handleResourceChanged(e) {
        this.resourceSelected = e.detail.value;
        console.log(':::resourceSelected', this.resourceSelected);
    }

    handleFromDateTimeChange(e) {
        this.timeSelected = e.detail.value;
        console.log(':::timeSelected', this.timeSelected);
    }

    handleToDateTimeChange(e) {
        this.timeSelectedEnd = e.detail.value;
        console.log(':::timeSelectedEnd', this.timeSelectedEnd);
    }


    doBook(e) {
        this.step = 9;

        let bookReq = {};


        bookReq.resourceSelected = this.resourceSelected;
        bookReq.locationSelected = this.recordId;
        bookReq.timeSelected = this.timeSelected;
        bookReq.timeSelectedEnd = this.timeSelectedEnd;

        let req = JSON.stringify(bookReq);
        console.log('::doSimpleReservation:request', req)
        doSimpleReservation({request: req})
            .then(results => {
                console.log('::doSimpleReservation:results', results)
                this.bookResult = JSON.parse(results);
                this.appointmentId = this.bookResult.appId;
                this.opportunityId = this.bookResult.oppId;
                this.reservationDone = true;

            })
            .catch(error => {
                console.error('::performBooking:failed', error);
                this.opportunityId = null;
                this.appointmentId = null;
                this.showNotification('Error creating a booking', error);
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



}