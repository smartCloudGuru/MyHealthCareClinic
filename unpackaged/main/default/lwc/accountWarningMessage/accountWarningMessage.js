/**
 * Created 10.11.2021..
 */

import {api, LightningElement} from 'lwc';

import getNotes from '@salesforce/apex/AccountWarningsController.getPatientWarnings';

export default class AccountWarningMessage extends LightningElement {

    @api recordId;

    hasNotes = false;
    loaded = false;

    notes = [];

    connectedCallback() {
        this.doGetNotes();
    }

    doGetNotes()
    {
        let params = {patientId : this.recordId};
        console.log('::getNotes:params', params);
        getNotes(params)
            .then(result => {
                console.log('::getNotes:result', result);
                if (result!=null)
                {
                    this.notes = JSON.parse(result);
                }
                else
                {
                    this.notes = [];
                }

            })
            .catch(error => {
                console.error('::getNotes:failed', error);
                this.notes = [];
            })
            .finally(() => {
                this.hasNotes = this.notes.length>0;
                this.loaded = true;
            });

    }

    doRefresh()
    {
        this.loaded=false;
        this.doGetNotes();
    }


}