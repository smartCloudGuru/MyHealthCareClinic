/**
 * Created 14.3.2021..
 */

import {api, LightningElement} from 'lwc';

import updatePersonalInfo from '@salesforce/apex/onl_CheckoutCtrl.updatePersonalInfo';

export default class OnlEditModal extends LightningElement {

    @api test;
    @api testIds;

    isBundleEdit = false;
    _form;

    errorMessage=null;

    connectedCallback() {
        if (!this.test) this.test={};
        if (this.testIds) this.isBundleEdit = true;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSave() {
        this._form = {};
        this.errorMessage = null;
        let inputs = this.template.querySelectorAll('[data-formfield]');
        if (inputs) {
            for (let input of inputs) {
                this._form[input.getAttribute('data-formfield')] = input.value;
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }

        //if all present
        if (!!this._form.lastName && !!this._form.firstName && !!this._form.email && !!this._form.phone) {

            let testIds = [];

            if (!this.isBundleEdit) testIds.push(this.test.Id);
            else testIds = this.testIds;

            let params = {
                covidTestIds: testIds,
                firstName: this._form.firstName,
                lastName: this._form.lastName,
                email: this._form.email,
                phone: this._form.phone,
                mobile: this._form.mobile
            };

            updatePersonalInfo(params)
                .then(results => {
                    // console.log('::updatePersonalInfo:result', results);
                    this.dispatchEvent(new CustomEvent('updated', {detail:params}));
                })
                .catch(error => {
                    console.error('::updatePersonalInfo:failed', error);
                    this.errorMessage='Please try again later';
                });
        }
    }

}