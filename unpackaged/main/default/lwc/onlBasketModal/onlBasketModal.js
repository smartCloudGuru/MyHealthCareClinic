/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

export default class OnlBasketModal extends LightningElement {

    @api basket;
    @api message;

    get hasTestsInBasket() {
        return this.basket && this.basket.length > 0;
    }

    get basketSum() {
        let basket_sum = 0;
        if (this.basket) {
            for (let item of this.basket) {
                if (item.product)
                    basket_sum += item.quantity * item.product.Non_Membership_Price__c;
            }
        }
        return basket_sum;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleRemoveItemFromBasket(event) {
        // console.log('::handleRemoveItemFromBasket', event.detail.id);
        if (this.basket) {
            this.basket = this.basket.filter(function (i) {
                return (i.id !== event.detail.id);
            });

            this.basket = JSON.parse(JSON.stringify(this.basket));
        } else this.basket = [];

        this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: this.basket}}));
    }

    handlePlusOne(event)
    {
        if (this.basket) {
            this.basket = JSON.parse(JSON.stringify(this.basket));
            for (let i of this.basket)
            {
                if (i.id === event.detail.id)
                {
                    if (i.quantity<=29) i.quantity++;
                    break;
                }
            }

        } else this.basket = [];

        this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: this.basket}}));
    }

    handleMinusOne(event)
    {
        if (this.basket) {
            this.basket = JSON.parse(JSON.stringify(this.basket));
            for (let i of this.basket)
            {
                if (i.id === event.detail.id)
                {
                    if (i.quantity>1) i.quantity--;
                    break;
                }
            }
            this.basket = JSON.parse(JSON.stringify(this.basket));
        } else this.basket = [];

        this.dispatchEvent(new CustomEvent('updatedbasket', {detail: {basket: this.basket}}));
    }

}