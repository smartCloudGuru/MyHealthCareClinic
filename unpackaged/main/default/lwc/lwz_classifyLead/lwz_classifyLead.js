/**
 * Created by Matija on 22.9.2023..
 */

import {api, LightningElement} from 'lwc';
import {RefreshEvent} from 'lightning/refresh';
import getLead from '@salesforce/apex/LeadWizardController.aura_getLead';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';

export default class LwzClassifyLead extends LightningElement {

    @api recordId;
    @api selectedOutcome;

    showModal;
    modalStarted;

    currentStep;
    loading;

    lastKnownLeadStatus;

    get dialogClass() {
        if (!this.modalStarted)
            return 'slds-modal slds-modal_medium slds-fade-in-open max-height';
        else
            return 'slds-modal slds-modal_medium slds-fade-in-open max-height-unset';
    }

    get cssSelected() {
        return 'selected-' + this.selectedOutcome;
    }

    connectedCallback() {
        console.log('cc:rid:' + this.recordId);
        this.getLead();
    }

    getLead() {
        this.loading = true;
        console.log('rc.rid:', this.recordId);
        if (this.loading)
            if (this.recordId) {
                console.log('::cc:this.recordId', this.recordId);
                getLead({leadId: this.recordId})
                    .then(results => {
                        console.log('::getLead:result', results);
                        if (results) {

                            let ld = JSON.parse(results);

                            if (ld) {
                                switch (ld.Status) {
                                    case('New'):
                                        this.selectedOutcome = 'lead-new';
                                        break;
                                    case('Working'):
                                        this.selectedOutcome = 'lead-working';
                                        break;
                                    case('Waiting List'):
                                        this.selectedOutcome = 'waiting-list';
                                        break;
                                    case('Lost'):
                                        this.selectedOutcome = 'no-sale';
                                        break;
                                    case('Disqualified'):
                                        this.selectedOutcome = 'disqualify';
                                        break;
                                    case('Converted'):
                                        this.selectedOutcome = 'sale';
                                        break;
                                    default:
                                        this.selectedOutcome = 'lead-working';
                                }
                                this.currentStep = this.selectedOutcome;
                                this.lastKnownLeadStatus = this.currentStep;
                            }
                        }
                    })
                    .catch(error => {
                        console.error('::getPotentialDuplicates:failed', error);
                    })
                    .finally(() => {
                        this.loading = false;
                    });
            }
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            },
            {
                name: 'inputChoice',
                type: 'String',
                value: this.selectedOutcome
            }
        ];
    }

    handleModalClose(e) {
        this.showModal = false;
        this.modalStarted = false;
        this.dispatchEvent(new RefreshEvent());
    }

    handleStatusChange(event) {
        console.log('hse', event.detail.status);
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            console.log('hse show fall');
            this.showModal = false;
            this.currentStep = '' + this.selectedOutcome;
            this.dispatchEvent(new RefreshEvent());
            this.getLead();
        } else if (event.detail.status === 'STARTED') {
            this.modalStarted = true;
        }
    }


    handleMark() {
        if (this.selectedOutcome) this.showModal = true;
    }

    handlePathChanged(e) {
        if (e.target.value === this.lastKnownLeadStatus) return; // nothing if no change

        this.selectedOutcome = e.target.value;
        console.log('t.so', this.selectedOutcome);
        this.handleMark();

    }

}