/**
 * Created 8.3.2021..
 */

import {LightningElement, api} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class OnlProduct extends LightningElement {

    @api product;
    @api locations;

    quantity = 1;
    formFactor = FORM_FACTOR;

    quantities = [];
    quantityPairs = []

    connectedCallback() {
        for (let i = 1; i <= 30; i++) {
            this.quantities.push(i);
            this.quantityPairs.push({label: '' + i, value: '' + i});
        }
    }

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    handleSchedule(event) {
        if (this.quantity > 0) {
            let firstAvailable;
            if (this.locations && this.locations.length>0 && this.locations[0].firstAvailableDate)
            {
                console.log('::handleSchedule:location[0]', JSON.stringify(this.locations[0]));
                firstAvailable = this.locations[0].firstAvailableDate;
            }
            this.dispatchEvent(new CustomEvent('add', {
                detail: {product: this.product, quantity: this.quantity, firstAvailable: firstAvailable}
            }));
        }
    }

    handleChangePicklistQuantity(event) {
        this.quantity = parseInt(event.target.value);
    }


}