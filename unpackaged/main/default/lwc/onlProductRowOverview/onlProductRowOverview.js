/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';
import LOCALE from '@salesforce/i18n/locale';

export default class OnlTestToScheduleRow extends LightningElement {

    @api item;

    get isDiscount() {
        return (this.item && this.item.type === 'discount')
    }

    get name() {
        if (!this.item) return '';

        if (this.item.type === 'discount') {
            if (this.item.Description) return this.item.Description;
        } else {
            if (this.item.Product2 && this.item.Product2.Name) return this.item.Product2.Name;
        }

        return '';
    }

    get unitAmount() {
        if (!this.item) return 0;

        if (this.item.UnitPrice) return this.item.UnitPrice;

        return 0;
    }

    get totalAmount() {
        if (!this.item) return 0;

        if (this.item.TotalPrice) return this.item.TotalPrice;

        return 0;
    }
}