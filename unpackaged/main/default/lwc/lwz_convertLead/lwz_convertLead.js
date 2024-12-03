/**
 * Created by Matija on 14.9.2023..
 */

import {api, LightningElement} from 'lwc';

import {
    FlowAttributeChangeEvent, FlowNavigationBackEvent,
    FlowNavigationFinishEvent,
    FlowNavigationNextEvent
} from 'lightning/flowSupport';

import getPotentialDuplicates from '@salesforce/apex/LeadConvertCtrl.getPotentialDuplicates';

export default class LwzConvertLead extends LightningElement {
    @api recordId;
    @api selectedAccount;

    loading;
    options;
    hasDuplicates = false;

    get canProceed() {
        return !!this.selectedAccount;
    }

    connectedCallback() {
        this.checkForConversionCandidates();
    }

    checkForConversionCandidates() {
        this.loading = true;
        console.log('rc.rid:', this.recordId);
        if (this.loading)
            if (this.recordId) {
                console.log('::cc:this.recordId', this.recordId);
                getPotentialDuplicates({leadId: this.recordId})
                    .then(results => {
                        console.log('::getPotentialDuplicates:result', results);
                        if (results) {
                            this.options = [];

                            let duplicates = JSON.parse(results);

                            if (duplicates.length > 0) {
                                this.hasDuplicates = true;
                            }

                            if (this.hasDuplicates) {

                                for (const duplicate of duplicates) {
                                    let shownLabel = '[' + duplicate.Patient_Id__c + '] ' + duplicate.FirstName + ' ' + duplicate.LastName
                                    if (duplicate.FirstName == null) duplicate.FirstName = '';
                                    if (duplicate.LastName == null) duplicate.LastName = '';
                                    if (duplicate.Date_of_Birth__c == null) duplicate.Date_of_Birth__c = '';
                                    if (duplicate.PersonEmail == null) duplicate.PersonEmail = '';
                                    if (duplicate.Phone == null) duplicate.Phone = '';
                                    if (duplicate.PersonMobilePhone == null) duplicate.PersonMobilePhone = '';
                                    if (duplicate.Patient_Type__c == null) duplicate.Patient_Type__c = '';

                                    duplicate.url = '/' + duplicate.Id;

                                    duplicate.Name = duplicate.FirstName + ' ' + duplicate.LastName

                                    if (duplicate.Date_of_Birth__c.length === 10) {
                                        let splits = duplicate.Date_of_Birth__c.split('-');
                                        duplicate.Date_of_Birth__c = splits[2] + '/' + splits[1] + '/' + splits[0];
                                    }

                                    this.options.push({value: duplicate.Id, label: shownLabel, obj: duplicate});
                                }

                                //this.options.push({value: 'new', label: 'Convert to a New Patient', obj:{}})
                                console.log('::convert:options', this.options);
                            } else {
                                // no possible duplicates, so continue to the next screen
                                this.dispatchEvent(new FlowNavigationNextEvent());
                            }
                        }
                    })
                    .catch(error => {
                        console.error('::getPotentialDuplicates:failed', error);
                        this.hasDuplicates = false;
                    })
                    .finally(() => {
                        this.loading = false;
                    });
            }
    }

    handleSelectedChosen(e) {

        e.preventDefault();

        //console.log(':hsc1:' + e.target.checked);

        let fields = this.template.querySelectorAll('[data-fieldid]');

        if (e.target.checked === false) {
            this.selectedAccount = e.target.dataset.fieldid;
            console.log('set selected to ' + this.selectedAccount);
            //clear all other buttons
            for (let f of fields) {
                f.checked = f.dataset.fieldid === this.selectedAccount;
            }
        } else {
            this.selectedAccount = null;
            //clear all buttons
            for (let f of fields) {
                f.checked = false;
            }
            console.log('set selected to ' + this.selectedAccount);
        }
    }

    handlePrevious()
    {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    handleConvert() {
        if (this.selectedAccount) this.dispatchEvent(new FlowNavigationNextEvent());
    }

}