/**
 * Created 8.3.2021..
 */

import {LightningElement, api} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Onl2FindCovidTestResultRow extends LightningElement {

    @api product;
    @api locations;
    @api storeConfig;
    @api defaultPersonalDetails;

    quantity = 1;
    formFactor = FORM_FACTOR;

    quantities = [];
    quantityPairs = [];

    get isBundle()
    {
        return this.product && this.product.Default_COVID_Tests__r && this.product.Default_COVID_Tests__r.totalSize && this.product.Default_COVID_Tests__r.totalSize>1;
    }

    connectedCallback() {
        for (let i = 1; i <= 10; i++) {
            this.quantities.push(i);
            this.quantityPairs.push({label: '' + i, value: '' + i});
        }
    }

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    // Button Schedule and add to basket
    handleSchedule(event) {
        if (this.quantity > 0) {
            let firstAvailable;
            if (this.locations && this.locations.length>0 && this.locations[0].firstAvailableDate)
            {
                console.log('::handleSchedule:location[0]', JSON.stringify(this.locations[0]));
                firstAvailable = this.locations[0].firstAvailableDate;
            }

            let testId = event.currentTarget.dataset.testid;

            let test = {};
            for (let t of this.product.Default_COVID_Tests__r.records)
            {
                // console.log('::dbg:compare', t.Id, testId);
                if (t.Id === testId)
                {
                    test = t;
                    break;
                }
            }

            this.dispatchEvent(new CustomEvent('add', {
                detail: {product: this.product, quantity: this.quantity, firstAvailable: firstAvailable, test: test, isBundle: this.isBundle}
            }));
        }
    }

    handleChangePicklistQuantity(event) {
        this.quantity = parseInt(event.target.value);
    }


}