/**
 * Created by Matija on 14.9.2023..
 */

import {api, LightningElement} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';

import {
    FlowNavigationFinishEvent,
    FlowNavigationNextEvent
} from 'lightning/flowSupport';


export default class LwzSummaryPage extends NavigationMixin(LightningElement) {

    @api recordId;
    @api success;
    @api message;
    @api conversionRequested;
    @api convertedToAccountId;
    @api convertedToOpportunityId;

    navigateToAccount() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.convertedToAccountId,
                actionName: 'view'
            }
        });
    }

    navigateToOpportunity() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.convertedToOpportunityId,
                actionName: 'view'
            }
        });
    }

}