/**
 * Created 8.3.2021..
 */

import {LightningElement, api} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Onl2ProductRow extends LightningElement {

    @api product;
    @api locations;

    quantity = 1;
    formFactor = FORM_FACTOR;

    _adding = false;
    _justadded = false;



    get classColor()
    {
        if (this.product && this.product.Online_Color__c)
            return 'class-wrapper class-' + this.product.Online_Color__c;
        else return 'class-wrapper class-default'
    }

    get classCellName()
    {
        if (this.product && this.product.Online_Color__c)
            return 'cell-name class-' + this.product.Online_Color__c;
        else return 'cell-name class-default'
    }

    get classCellPrice()
    {
        if (this.product && this.product.Online_Color__c)
            return 'cell-price class-' + this.product.Online_Color__c;
        else return 'cell-price class-default'
    }


    get adding() {
        return this._adding || this._justadded;
    }

    @api stopspinner(success) {
        if (this._adding && success) {
            this._justadded = true;
            setTimeout(this.stopAdding.bind(this), 800);
        }
        this._adding = false;
    }

    stopAdding() {
        this._justadded = false;
        this._adding = false;
    }

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
        if (this.quantity > 0) {
            this._adding = true;
            this.dispatchEvent(new CustomEvent('add', {
                detail: {product: this.product, quantity: this.quantity}
            }));
        }
    }

    handleChangePicklistQuantity(event) {
        this.quantity = parseInt(event.target.value);
    }


}