/**
 * Created 10.3.2021..
 */

import {LightningElement, api} from 'lwc';

export default class OnlBasketItem extends LightningElement {

    @api item;

    get typeClass() {
        if (!this.item) return 'typeclass';
        return 'typeclass ' + this.item.type;
    }

    get itemIsCoupon() {
        return (this.item && (this.item.type === 'discount'));
    }

    get itemName() {

        if (this.itemIsCoupon)
        {
            return this.item.Description;
        }
        else if (this.item) {
            if (this.item.Product2) return this.item.Product2.Name;
            if (!!this.item.product) return this.item.product.Name;
        }
        return '';
    }

    inEdit = false;
    inRemove = false;
    inChange = false;

    connectedCallback() {
        // console.log('::onlBI2:item', JSON.stringify(this.item));
    }

    handleRemove() {
        this.inEdit = true;
        this.inRemove = true;
    }

    handleRemoveYes() {
        //remove from basket
        this.dispatchEvent(new CustomEvent('remove', {detail: {id: this.item.Id}}));
    }

    handleQuantityPlus() {
        this.dispatchEvent(new CustomEvent('plusone', {detail: {id: this.item.Id}}));
    }

    handleQuantityMinus() {
        if (this.item && this.item.quantity <= 1) {
            this.handleRemove();
        } else
            this.dispatchEvent(new CustomEvent('minusone', {detail: {id: this.item.Id}}));
    }

    handleRemoveCancel() {
        this.inEdit = false;
        this.inRemove = false;
    }
}