/**
 * Created 8.6.2021..
 */

import {LightningElement, api} from 'lwc';

export default class Onl2RemoveItem extends LightningElement {

    @api itemId;

    inEdit = false;
    inRemove = false;
    inChange = false;

    connectedCallback() {
        //console.log('::o2removeItem:cc:id', this.itemId);
    }

    handleRemove() {
        this.inEdit = true;
        this.inRemove = true;
    }

    handleRemoveYes() {
        //remove from basket
        this.dispatchEvent(new CustomEvent('remove', {detail: {id: this.itemId}}));
    }

    handleRemoveCancel() {
        this.inEdit = false;
        this.inRemove = false;
    }


}