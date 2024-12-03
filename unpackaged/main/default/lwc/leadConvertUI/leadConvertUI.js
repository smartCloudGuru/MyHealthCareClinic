/**
 * Created 20.1.2023..
 */

import {LightningElement, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';

import getPotentialDuplicates from '@salesforce/apex/LeadConvertCtrl.getPotentialDuplicates';
import getClinicValues from '@salesforce/apex/LeadConvertCtrl.getClinicValues';
import doConvert from '@salesforce/apex/LeadConvertCtrl.doConvert';

export default class LeadConvertUI extends NavigationMixin(LightningElement) {

    @api recordId;

    get allSelected() {
        return this.selectedClinic && this.selectedPatient;
    }

    loading;
    saving;

    selectedPatient;
    selectedClinic;

    options;

    clinicOptions;

    hasDuplicates = false;

    connectedCallback() {

        this.loading = true;

        getClinicValues()
            .then(results => {
                console.log('::getClinicValues:result', results);
                if (results) {
                    this.clinicOptions = [];

                    let clinics = JSON.parse(results);

                    if (clinics) {
                        for (const clinic of clinics) {
                            if (clinic.active)
                            this.clinicOptions.push({value: clinic.value, label: clinic.label});
                        }
                    }
                }
            })
            .catch(error => {
                console.error('::getClinicValues:failed', error);
                this.hasDuplicates = false;
            })
            .finally(() => {
                this.loading = false;
            });

    }

    renderedCallback() {

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

                                    this.options.push({value: duplicate.Id, label: shownLabel, obj: duplicate});
                                }

                                this.options.push({value: 'new', label: 'Convert to a New Patient'})
                            }
                            else {
                                this.selectedPatient = 'new';
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


    handleSelectedOption(e) {
        this.selectedPatient = e.detail.value;
        console.log('sp:', this.selectedPatient);
    }

    handleChangeClinic(e) {
        this.selectedClinic = e.detail.value;
        console.log('sc:', this.selectedClinic);
    }

    handleConvert(e) {

        this.saving = true;

        let params = {};
        params.fromId = this.recordId;
        params.toId = this.selectedPatient;
        if (params.toId === 'new') params.toId = null;
        params.clinicName = this.selectedClinic;

        console.log('..doConvert:params:', params);
        doConvert(params)
            .then(results => {
                console.log('::doConvert:result', results);
                if (results) {

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: results,
                            actionName: 'view'
                        }
                    });
                }
            })
            .catch(error => {
                this.showNotification('Unable to Convert',
                    error?.body?.message);
                console.error('::doConvert:failed', error);
            })
            .finally(() => {
                this.saving = false;
            });
    }

    showNotification(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            mode: 'sticky',
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

}

/*

 */