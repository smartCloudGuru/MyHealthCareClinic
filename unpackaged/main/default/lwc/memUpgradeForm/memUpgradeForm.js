/**
 * Created by Matija on 29.11.2024..

 */

import contactPhone from '@salesforce/label/c.Store_Contact_Phone';

import {api, LightningElement, wire} from 'lwc';

import createUpgradeEnquiry from '@salesforce/apex/memUpgradeFormCtrl.createUpgradeEnquiry';

export default class MemUpgradeForm extends LightningElement {

    @api queryParameters;
    @api config;


    loading = false;
    saving = false;
    saved = false;
    dataReady = false;
    saveError = false;
    _contactPhone = contactPhone;

    form;

    tierOptions = [
        {label: 'Complete', value: 'Complete'},
        {label: 'Premium', value: 'Premium'}
    ];

    planSelected;

    connectedCallback() {
        //console.log('mu:cc:05', JSON.stringify(this.queryParameters));
        this.form = {};
        if (this.queryParameters && this.queryParameters.email) this.form.email = this.queryParameters.email;
        if (this.queryParameters && this.queryParameters.ref) this.form.ref = this.queryParameters.ref;

    }

    handlePlanChange(e) {
        this.planSelected = e.target.value;
    }

    handleSubmit(e) {

        let fields = this.template.querySelectorAll('[data-id]');

        this.form = {};

        for (let f of fields) {
            if (f.dataset.id) {
                this.form[f.dataset.id] = f.value;
                if (('' + f.getAttribute('class')).indexOf('onl-check') >= 0) this.form[f.dataset.id] = f.checked;
            }
        }


        if (!this.validateForm()) return;


        this.saving = true;

        //processSignupRequest({params: formAsString})
        let params = {
            firstName: this.form.firstName,
            lastName: this.form.lastName,
            email: this.form.email,
            upgradeTo: this.planSelected
        };
        if (this.queryParameters && this.queryParameters.ref) this.form.ref = this.queryParameters.ref;
        if (this.form.ref) params.ref = this.form.ref; else params.ref = null;
        createUpgradeEnquiry(params)
            .then(results => {
                    // console.log('::processSignupRequest:results', results);
                    if (results) {

                        this.saved = true;
                        this.saving = false;
                        console.error('saved', this.saved);
                    } else {
                        console.error('::msf:psr:res null', results);
                        this.saveError = true;
                        this.saving = false;
                    }
                }
            )
            .catch(error => {
                this.saveError = true;
                console.error('::processSignupRequest:failed', error);
                this.saving = false;
            })
            .finally(() => {

            });

    }

    validateForm() {
        let fields = this.template.querySelectorAll('[data-id]');

        let valid = true;

        for (let f of fields) {

            if (f.showHelpMessageIfInvalid) f.showHelpMessageIfInvalid();
            if (f.validateRequired) f.validateRequired();
            if (f.reportValidity) f.reportValidity();
            //console.log(f.value, ':validation: ', (f.dataset) ? f.dataset.id : null);

            if ((f.required === true) && (f.value == null || f.value.length === 0)) {

                //if it's checkbox, treat its value as checked state
                if (('' + f.getAttribute('class')).indexOf('onl-check') >= 0) {
                    if (!f.checked) {
                        //console.log('::mdl:vld:failed required', (f.dataset) ? f.dataset.id : null);
                        valid = false;
                    }
                } else {
                    //console.log('::mdl:vld:failed required', (f.dataset) ? f.dataset.id : null);
                    valid = false;
                }
            }
        }

        return valid;
    }

}