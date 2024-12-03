/**
 * Created by Matija on 14.11.2023..
 */

import {api, LightningElement} from 'lwc';

import getDentalTreatmentPlansForOpportunity from '@salesforce/apex/AeronaTreatmentPlansCtrl.aura_getDentalTreatmentPlansForOpportunity';
import getDentalTreatmentPlansForAccount from '@salesforce/apex/AeronaTreatmentPlansCtrl.aura_getDentalTreatmentPlansForAccount';


export default class AppDentalTracker extends LightningElement {

    @api recordId;
    @api recordType;

    plans = [];


    // actions = [
    //     {label: 'Edit', name: 'edit'}
    // ];
    //
    // columns = [
    //     {label: 'Created Date',
    //         fieldName: 'CreatedDate',
    //         type: "date-local",
    //         typeAttributes:{
    //             month: "2-digit",
    //             day: "2-digit"
    //         }
    //     },
    //     {label: 'Name', fieldName: 'Name'},
    //     {
    //         type: 'action',
    //         typeAttributes: {rowActions: this.actions},
    //     },
    // ];

    get isOnAccountRecord() {
        return (this.recordType === 'Account');
    }

    connectedCallback() {
        if (this.recordType == null || this.recordType === 'Opportunity') {
            this.fetchDentalTreatmentPlansByOpportunity();
        } else if (this.recordType === 'Account') {
            this.fetchDentalTreatmentPlansByAccount();
        }
    }

    fetchDentalTreatmentPlansByOpportunity() {

        getDentalTreatmentPlansForOpportunity({oppId: this.recordId})
            .then(result => {
                console.log('::fetchDentalTreatmentPlansByOpportunity:result', result);
                this.plans = JSON.parse(result);

                for (let plan of this.plans) {
                    plan.assigned = (plan.Parent_Opportunity__c === this.recordId);
                }

            })
            .catch(error => {
                console.error('::fetchDentalTreatmentPlansByOpportunity:failed', error);
                this.plans = [];

            })
            .finally(() => {

            });
    }

    fetchDentalTreatmentPlansByAccount() {

        getDentalTreatmentPlansForAccount({accountId: this.recordId})
            .then(result => {
                console.log('::getDentalTreatmentPlansForAccount:result', result);
                this.plans = JSON.parse(result);

                for (let plan of this.plans) {
                    plan.assigned = (plan.Parent_Opportunity__c === this.recordId);
                }

            })
            .catch(error => {
                console.error('::getDentalTreatmentPlansForAccount:failed', error);
                this.plans = [];

            })
            .finally(() => {

            });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'edit':
                console.log('todo edit');
                break;
            default:
        }
    }

}