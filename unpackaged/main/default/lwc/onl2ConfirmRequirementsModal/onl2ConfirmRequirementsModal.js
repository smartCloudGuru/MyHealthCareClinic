/**
 * Created by Matija on 29.6.2023..
 */

import {api, LightningElement} from 'lwc';

export default class Onl2ConfirmRequirementsModal extends LightningElement {

    @api storeConfig;
    @api productName;
    @api requirements;
    @api dev;

    requirementOptions;
    allChecked = false;

    connectedCallback() {

        if (this.dev) console.log('requirements', this.requirements);

        if (this.requirements) {
            let reqs = this.requirements.split(';');

            if (this.dev) console.log('reqs', this.reqs);

            this.requirementOptions = [];
            for (let req of reqs) {
                switch (req) {
                    case "Over 18":
                        this.requirementOptions.push({
                            id: 'o18',
                            label: 'This appointment is only available for Adults.',
                            check: 'I confirm I\'m booking this appointment for an Adult.'
                        });
                        break;
                    case "Over 12":
                        this.requirementOptions.push({
                            id: 'o12',
                            label: 'This appointment is only available for patients 12 or older.',
                            check: 'I confirm I\'m booking this appointment for a Patient over 12.'
                        });
                        break;
                    case "Under 18":
                        this.requirementOptions.push({
                            id: 'u18',
                            label: 'This appointment is only available for patients under the age of 18.',
                            check: 'I confirm I\'m booking this appointment for a Patient under 18.'
                        });
                        break;
                    case "Under 12":
                        this.requirementOptions.push({
                            id: 'u12',
                            label: 'This appointment is only available for patients under the age of 12.',
                            check: 'I confirm I\'m booking this appointment for a Patient under 12.'
                        });
                        break;
                    case "New patient":
                        this.requirementOptions.push({
                            id: 'new',
                            label: 'This appointment is only available for new patients.',
                            check: 'I confirm I\'m booking this appointment for a Patient that is new to MyHealthcare Clinic.'
                        });
                        break;
                    case "Returning patient":
                        this.requirementOptions.push({
                            id: 'returning',
                            label: 'This appointment is only available for returning patients.',
                            check: 'I confirm I\'m booking this appointment for an existing Patient.'
                        });
                        break;
                    case "Member":
                        this.requirementOptions.push({
                            id: 'member',
                            label: 'This appointment is only available for MyHealthcare Clinic Members.',
                            check: 'I confirm I\'m booking this appointment for a Patient that is a Member of MyHealthcare Clinic.'
                        });
                        break;
                }
            }
        }


        if (this.dev) console.log('reqOptions', this.requirementOptions);
    }

    handleReqChange(e) {
        // console.log('rc1', e.target.dataset.checkfield);
        // console.log('rc2', e.target.checked);

        for (let req of this.requirementOptions) {
            if (req && req.id === e.target.dataset.checkfield) {
                req.checked = e.target.checked;
                break;
            }
        }

        this.allChecked = true;
        for (let req of this.requirementOptions) {
            if (req) {
                this.allChecked = this.allChecked && req.checked;
            }
        }

        if (this.dev) console.log('allchecked: ', this.allChecked);
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleProceed() {
        this.dispatchEvent(new CustomEvent('proceed'));
    }


}