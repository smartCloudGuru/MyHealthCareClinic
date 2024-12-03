/**
 * Created 30.5.2021..
 */

import {LightningElement} from 'lwc';

import {
    clearBasketIdCookie,
    getBasketIdFromCookie
} from 'c/onl2Basket';

import closeOrder from '@salesforce/apex/onl_CheckoutCtrl.closeOrder';

export default class OnlCookieClear extends LightningElement {

    connectedCallback() {
        console.log('::onlCookieClear:cc');
        let bid = getBasketIdFromCookie();
        if (bid)
        {
            console.log('::closeOrder:oppId', bid); // result is stripe session id

            closeOrder({oppId:bid})
                .then(result => {
                    console.log('::closeOrder:result', result); // result is oppid
                })
                .catch(error => {
                    console.error('::closeOrder:failed', error);
                    this.loading = false;
                })
                .finally(() => {

                });
        }
        clearBasketIdCookie();
    }
}