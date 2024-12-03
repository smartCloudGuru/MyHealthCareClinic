/**
 * Created 31.5.2022..
 */

import {api, LightningElement} from 'lwc';

import closeWinOpportunityIfPaymentPaid from '@salesforce/apex/OnlBookUI.aura_closeAndGetOpportunityIfPaymentPaid';

import {
    clearBasketIdCookie,
    getLoggedInCookie,
    getConsoleOutput
} from 'c/onl2Basket';

export default class Onl2ConfirmationPage extends LightningElement {
    @api queryParameters;
    @api storeConfig;

    dev;

    loading;
    successfulCheck;
    failedCheck;

    get isStoreAppointments() {
        return this.storeConfig.storeName === 'Appointments';
    }

    get isStoreTLC() {
        return this.storeConfig.storeName === 'TheLondonClinic';
    }


    connectedCallback() {

        this.loading = true;

        this.dev = getConsoleOutput();

        if (!this.queryParameters || !this.queryParameters.stripe_session_id) {
            if (this.dev) console.log('::capp:cc:no sid provided');
            this.failedCheck = true;
            return;
        }

        let sid = this.queryParameters.stripe_session_id;

        //NA is provided for orders that were free (no stripe session id)
        if (sid === 'NA') {
            this.successfulCheck = true;
            this.failedCheck = !this.successfulCheck;
            this.loading = false;
            return;
        }

        //ERR is provided for orders that were free (but errored out on closeOpportunity)
        if (sid === 'ERR') {
            this.successfulCheck = false;
            this.failedCheck = !this.successfulCheck;
            this.loading = false;
            return;
        }

        if (this.dev) console.log('::capp:cc:sid:', this.queryParameters.stripe_session_id);

        let request = {
            sessionId: this.queryParameters.stripe_session_id
        };

        //if (this.dev)
        console.log('::capp:closeWinOpportunityIfPaymentPaid:request', request);

        closeWinOpportunityIfPaymentPaid(request)
            .then(result => {
                //if (this.dev)
                console.log('::closeWinOpportunityIfPaymentPaid:result', result);

                if (result) {
                    this.successfulCheck = true;
                    this.failedCheck = false;
                    this.throwTrackingEvent('won', result);
                } else {
                    this.successfulCheck = false;
                    this.failedCheck = true;
                }
            })
            .catch(error => {
                //if (this.dev)
                console.error('::closeWinOpportunityIfPaymentPaid:error', error);
                this.successfulCheck = false;
                this.failedCheck = true;
            })
            .finally(() => {
                this.loading = false;
            });
    }

    throwTrackingEvent(evName, result) {
        try {
            let metadata = {};

            let opp = JSON.parse(result);
            metadata.b = opp.Business_Unit__c;
            if (opp.OpportunityLineItems && opp.OpportunityLineItems.records) {
                metadata.c = opp.OpportunityLineItems.records[0].ProductCode;
            }

            this.dispatchEvent(new CustomEvent('sessionchange', {
                detail: {
                    stage: evName,
                    metadata: metadata
                }
            }));
        } catch (ignore) {}

    }
}