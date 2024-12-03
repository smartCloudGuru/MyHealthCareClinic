/**
 * Created by Matija on 25.9.2023..
 */

import {api, LightningElement} from 'lwc';

import getPotentialDuplicates from '@salesforce/apex/LeadConvertCtrl.getPotentialDuplicates';
import copyFromAccount from '@salesforce/apex/LeadWizardController.copyFromAccount';
import {NavigationMixin} from 'lightning/navigation';
import {RefreshEvent} from 'lightning/refresh';

export default class LwzPossiblyRelated extends NavigationMixin(LightningElement) {

    @api recordId;

    loading;
    hasRelated;
    options;

    hoverAccount;
    left;
    top;

    showCopyModal;
    showCopyAccountName;

    get boxClass() {
        return `background-color:white; top:${this.top - 280}px; left:${this.left}px`;
    }

    connectedCallback() {
        this.doRefresh();
    }

    doRefresh() {
        this.options = null;
        this.checkForRelated();
    }

    checkForRelated() {
        this.loading = true;
        console.log('rc.rid:', this.recordId);
        if (this.loading)
            if (this.recordId) {
                console.log('::cc:this.recordId', this.recordId);
                getPotentialDuplicates({leadId: this.recordId})
                    .then(results => {
                        console.log('::checkForRelated:result', results);
                        if (results) {
                            this.options = [];

                            let duplicates = JSON.parse(results);

                            this.hasRelated = !!duplicates && duplicates.length > 0;

                            if (this.hasRelated) {

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

                                    if (!!duplicate.Name && duplicate.Name.length>0) this.options.push({value: duplicate.Id, label: shownLabel, obj: duplicate});
                                }

                                //this.options.push({value: 'new', label: 'Convert to a New Patient', obj:{}})
                                console.log('::checkForRelated:options', this.options);
                            } else {
                                // no possible duplicates

                            }
                        }
                    })
                    .catch(error => {
                        console.error('::checkForRelated:failed', error);
                        this.hasRelated = false;
                    })
                    .finally(() => {
                        this.loading = false;
                    });
            }
    }

    showData(event) {
        this.hoverAccount = event.currentTarget.dataset.accountid;
        this.left = event.clientX;
        this.top = event.clientY;
    }

    hideData(event) {
        this.hoverAccount = null;
    }

    navigateToAccount(e) {
        let navTo = e.currentTarget.dataset.accountid + '';
        console.log('navto', e.currentTarget.dataset.accountid);

        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: navTo,
                objectApiName: 'Account',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });

    }

    handleCopy(e) {
        // console.log(e.currentTarget.dataset.accountname);
        // console.log(e.target.dataset.accountname);
        this.showCopyModal = e.currentTarget.dataset.accountid;
        this.showCopyAccountName = e.currentTarget.dataset.accountname;
    }

    closeCopyModal() {
        this.showCopyModal = false;
    }

    doCopy() {
        this.loading = true;
        let accId = this.showCopyModal + '';
        this.showCopyModal = false;
        console.log('rc.rid:', this.recordId);
        if (this.loading)
            if (this.recordId && accId) {
                console.log('::cc:this.recordId', this.recordId);
                copyFromAccount({leadId: this.recordId, accountId: accId})
                    .then(results => {
                        console.log('::copyFromAccount:result', results);
                    })
                    .catch(error => {
                        console.error('::checkForRelated:failed', error);
                        this.hasRelated = false;
                    })
                    .finally(() => {

                        this.loading = false;
                        this.dispatchEvent(new RefreshEvent());
                    });
            }

    }
}