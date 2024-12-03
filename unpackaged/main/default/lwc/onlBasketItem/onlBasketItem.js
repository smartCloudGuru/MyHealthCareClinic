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

    get itemIsProduct() {
        return !!this.item.product;
    }

    get itemIsCoupon()
    {
        return !!this.item.coupon;
    }

    get itemName() {
        if (!!this.item.product) {
            return this.item.product.Name;
        } else if (this.item.coupon) {
            return this.item.coupon.Name;
        } else {
            return '';
        }
    }


    inEdit = false;
    inRemove = false;
    inChange = false;

    handleRemove() {
        this.inEdit = true;
        this.inRemove = true;
    }

    handleRemoveYes() {
        //remove from basket
        this.dispatchEvent(new CustomEvent('remove', {detail: {id: this.item.id}}));
    }

    handleQuantityPlus()
    {

        this.dispatchEvent(new CustomEvent('plusone', {detail: {id: this.item.id}}));
    }

    handleQuantityMinus()
    {
        if (this.item && this.item.quantity<=1)
        {
            this.handleRemove();
        }
        else
            this.dispatchEvent(new CustomEvent('minusone', {detail: {id: this.item.id}}));
    }

    handleRemoveCancel() {
        this.inEdit = false;
        this.inRemove = false;
    }
}