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


    handleChangeQuantity(event) {
        if (event.target.value && event.target.value > 0)
            this.quantity = event.target.value;
        else this.quantity = 0;
    }

    handleAdd(event) {
        if (this.quantity > 0)
            this.dispatchEvent(new CustomEvent('add', {
                detail: {product: this.product, quantity: this.quantity}
            }));
    }

    handleChangePicklistQuantity(event) {
        this.quantity = parseInt(event.target.value);
    }


}