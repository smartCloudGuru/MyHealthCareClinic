/**
 * Created 20.7.2022..
 */

import {api, LightningElement} from 'lwc';

import changePassword from '@salesforce/apex/OnlBookUI.changePassword';
import checkPassCodeValidity from '@salesforce/apex/OnlBookUI.checkPassCodeValidity';

export default class Onl2ForgotPasswordActivation extends LightningElement {

    @api queryParameters;
    @api storeConfig;

    loading;
    success;
    error;
    doneChange;
    msgError;

    passwordPattern = '.{8,}';

    connectedCallback() {
        this.loading = true;
        // console.log('::checkPassCodeValidity:a', this.queryParameters?.a);
        // console.log('::checkPassCodeValidity:b', this.queryParameters?.b);
        checkPassCodeValidity({code: this.queryParameters?.a, email: this.queryParameters?.b})
            .then(results => {
                console.log('::checkPassCodeValidity:result', results);

                if (results === true) {
                    this.success = true;
                    this.error = false;
                } else {
                    this.error = true;
                    this.msgError = 'The link to request password change is not valid or has already been used'
                    this.success = false;
                }

            })
            .catch(error => {
                console.error('::checkPassCodeValidity:failed', error);
                this.error = true;
                this.msgError = 'We can not process your request at this time, please try later'
                this.success = false;
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handlePassChangeConfirm(e) {
        let nodePass1 = this.template.querySelector('[data-formfield="password1"]');
        let nodePass2 = this.template.querySelector('[data-formfield="password2"]');

        let passSame = true;
        if (nodePass1.value !== nodePass2.value) {
            nodePass2.setCustomValidity('Password fields must match');
            passSame = false;
        } else {
            nodePass2.setCustomValidity('');
        }
        nodePass1.reportValidity();
        nodePass2.reportValidity();
        if (!passSame) return;


        this.loading = true;
        changePassword({
            code: this.queryParameters?.a,
            newPassword: nodePass1.value,
            email: this.queryParameters?.b
        })
            .then(results => {
                console.log('::changePassword:result', results);

                if (results === true) {
                    this.doneChange = true;
                    this.error = false;
                    this.success = false;
                } else {
                    this.error = true;
                    this.msgError = 'The link to request password change is not valid or has already been used'
                    this.success = false;
                }

            })
            .catch(error => {
                console.error('::changePassword:failed', error);
                this.error = true;
                this.success = false;
                this.doneChange =false;
                this.msgError = 'The link to request password change is not valid or has already been used'
            })
            .finally(() => {
                this.loading = false;
            });
    }
}