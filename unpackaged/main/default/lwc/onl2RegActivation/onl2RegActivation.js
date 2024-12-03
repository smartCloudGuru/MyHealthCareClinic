/**
 * Created 19.7.2022..
 */

import {api, LightningElement} from 'lwc';

import activateRegistration from '@salesforce/apex/OnlBookUI.activateRegistration';
import contactPhone from '@salesforce/label/c.Store_Contact_Phone';

import {
    getConsoleOutput
} from 'c/onl2Basket';

export default class Onl2RegActivation extends LightningElement {
    @api queryParameters;
    @api storeConfig;

    dev;

    loading;

    activationCode;
    hashCode;

    success;
    error;
    msgRegister;

    _contactPhone = contactPhone;

    connectedCallback() {

        this.dev = getConsoleOutput();

        this.activationCode = this.queryParameters.a;
        this.hashCode = this.queryParameters.b;

        if (this.dev)
        {
            console.log('::rega:cc:a', this.activationCode);
            console.log('::rega:cc:b', this.hashCode);
        }

        this.checkRegistration();

    }

    checkRegistration()
    {
        this.loading = true;

        activateRegistration({activationCode: this.activationCode, hashCode: this.hashCode})
            .then(results => {
                if (this.dev) console.log('::activateRegistration:result', results);
                if (results) {

                    this.error = true;
                    if (results.indexOf('EMAIL_ALREADY_REGISTERED_WITH_PASSWORD') >= 0) {
                        this.msgRegister = 'This e-mail of this Account is already registered.';
                    }
                    else if (results.indexOf('DOB_DIFFERENT') >= 0) {
                        this.msgRegister = 'There is already an Account with your e-mail in the system already.';
                    }
                    else if (results.indexOf('MULTIPLE_CANDIDATES') >= 0) {
                        this.msgRegister = 'There are multiple Accounts with your e-mail in the system.';
                    }
                    else {
                        if (this.dev) console.error('::activateRegistration:failed', results);
                        this.msgRegister = 'There was a problem registering your Account. Please try later';
                    }
                } else {
                    //success
                    this.success = true;
                }

            })
            .catch(error => {
                console.error('::activateRegistration:failed', error);
                this.msgRegister = 'There was a problem registering your Account. Please try later';
            })
            .finally(() => {
                this.loading = false;
            });

    }
}