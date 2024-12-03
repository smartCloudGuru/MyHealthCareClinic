/**
 * Created 24.1.2023..
 */

import {LightningElement, api} from "lwc";
import {NavigationMixin} from 'lightning/navigation';
import generateMembershipSignupUrl from '@salesforce/apex/memSignUpCtrl.generateMembershipSignupUrl';

export default class ActionNewMembership extends NavigationMixin(LightningElement) {

    @api recordId;

    @api invoke() {
        console.log('redirecting to membership signup page for', this.recordId);

        generateMembershipSignupUrl({id: this.recordId})
            .then(results => {
                console.log('::generateMembershipSignupUrl:results', results);
                if (results) {
                    window.open(results, '_blank');
                }
            })
            .catch(error => {
                console.error('::generateMembershipSignupUrl:error', error);
            })
            .finally(() => {

            });
    }
}