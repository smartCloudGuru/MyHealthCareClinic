/**
 * Created 3.6.2024..
 */

import {api, LightningElement} from 'lwc';
import updateBusinessUnit from '@salesforce/apex/AeronaTreatmentPlansCtrl.aura_updateBusinessUnit';
import updateProbability from '@salesforce/apex/AeronaTreatmentPlansCtrl.aura_updateProbability';
import updatePaymentMethod from '@salesforce/apex/AeronaTreatmentPlansCtrl.aura_updatePaymentMethod';
import updateParent from '@salesforce/apex/AeronaTreatmentPlansCtrl.aura_updateParent';

export default class DtPlanRow extends LightningElement {

    @api plan;
    @api parentOpportunityId;
    @api isAccountRecord;

    assigned;
    changingAssign;

    bUnits = [{label: 'Dentist', value: 'Dentist'}, {label: 'Hygiene', value: 'Hygiene'}, {
        label: 'Implants',
        value: 'Implants'
    }, {label: 'Orthodontics', value: 'Orthodontics'}];

    pMethods = [

        {label: 'Card', value: 'Card'},
        {label: 'Cash', value: 'Cash'},
        {label: 'Debt', value: 'Debt'},
        {label: 'Direct Debit', value: 'Direct Debit'},
        {label: 'Finance', value: 'Finance'},
        {label: 'Finance - Tabeo', value: 'Finance - Tabeo'}
    ];

    get planURL() {
        return '/' + this.plan?.Id;
    }

    get planProbability() {
        return this.plan.Probability;
    }

    connectedCallback() {
        console.log('::plan', JSON.parse(JSON.stringify(this.plan)));
        this.assigned = this.plan.assigned;
    }

    handleBUChanged(e) {

        updateBusinessUnit({oppId: this.plan.Id, businessUnit: e.detail.value})
            .then(results => {
                console.log('::updateBusinessUnit:ok');
            })
            .catch(error => {
                console.error('::updateBusinessUnit:failed', error);
                this.connectedAccounts = null;
            })
            .finally(() => {
            });
    }


    handleProbabilityChanged(e) {
        let f_prob = this.template.querySelector('[data-field="Probability"]');
        updateProbability({oppId: this.plan.Id, probability: f_prob.value})
            .then(results => {
                console.log('::updateProbability:ok');
            })
            .catch(error => {
                console.error('::updateProbability:failed', error);
                this.connectedAccounts = null;
            })
            .finally(() => {
            });
    }

    handlePMChanged(e) {
        let f_pm = this.template.querySelector('[data-field="DT_Payment_Method__c"]');
        updatePaymentMethod({oppId: this.plan.Id, paymentMethod: f_pm.value})
            .then(results => {
                console.log('::updatePaymentMethod:ok');
            })
            .catch(error => {
                console.error('::updatePaymentMethod:failed', error);
                this.connectedAccounts = null;
            })
            .finally(() => {
            });
    }

    handleAssign(e) {
        this.changingAssign = true;
        let f_prob = this.template.querySelector('[data-field="Probability"]');
        let f_bu = this.template.querySelector('[data-field="Business_Unit__c"]');
        let f_pm = this.template.querySelector('[data-field="DT_Payment_Method__c"]');

        if (!f_bu.value)
        {
            if (f_bu.showHelpMessageIfInvalid) f_bu.showHelpMessageIfInvalid();
            if (f_bu.validateRequired) f_bu.validateRequired();
            if (f_bu.reportValidity) f_bu.reportValidity();
            this.changingAssign = false;
            return;
        }
        updateParent({
            oppId: this.plan.Id,
            parentOppId: this.parentOpportunityId,
            businessUnit: f_bu.value,
            probability: f_prob.value,
            paymentMethod: f_pm.value,
        })
            .then(results => {
                this.assigned = true;
            })
            .catch(error => {
                console.error('::updateParent:failed', error);
                this.connectedAccounts = null;
            })
            .finally(() => {
                this.changingAssign = false;
            });
    }

    handleDeAssign(e) {
        this.changingAssign = true;
        let f_prob = this.template.querySelector('[data-field="Probability"]');
        let f_bu = this.template.querySelector('[data-field="Business_Unit__c"]');
        updateParent({
            oppId: this.plan.Id,
            parentOppId: null,
            businessUnit: f_bu.value,
            probability: f_prob.value
        })
            .then(results => {
                this.assigned = false;
            })
            .catch(error => {
                console.error('::updateParent:failed', error);
                this.connectedAccounts = null;
            })
            .finally(() => {
                this.changingAssign = false;
            });
    }


}