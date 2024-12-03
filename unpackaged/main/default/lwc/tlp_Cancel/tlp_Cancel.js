/**
 * Created 30.3.2024.
 */

import {api, LightningElement} from 'lwc';

import getBooking from '@salesforce/apex/TLPController.getBookingDetailsByCode';
import doCancelByCode from '@salesforce/apex/TLPController.doCancelByCode';

export default class TLPCancel extends LightningElement {

    @api queryParameters;
    @api storeConfig;

    appointmentToCancel;

    cancellationOK;
    cancellationFailed;
    fetchFailed;

    loading;

    connectedCallback() {
        if (!!this.queryParameters.a && !!this.queryParameters.id) {
            this.fetchAppointment(this.queryParameters.id);
        }

    }

    fetchAppointment(appId) {
        this.fetchFailed = false;
        getBooking({code: appId})
            .then(results => {
                console.log('::getBooking:result', results);
                if (results == null) {
                    this.fetchFailed = true;
                } else {
                    this.appointmentToCancel = JSON.parse(results);
                }
            })
            .catch(error => {
                console.error('::getBooking:failed', error);
                this.appointmentToCancel = null;

            })
            .finally(() => {

            });
    }

    doCancel() {
        this.loading = true;
        this.cancellationFailed = false;
        doCancelByCode({auth: document.cookie, code: this.appointmentToCancel.UUID__c})
            .then(results => {
                console.log('::doCancel:result', results);
                //shows cancelation done msg
                this.cancellationOK = true;
            })
            .catch(error => {
                console.error('::doCancel:failed', error);
                //show error msg
                this.cancellationFailed = true;
            })
            .finally(() => {
                this.loading = false;
            });
    }

}