/**
 * Created 2.11.2021..
 */

import {api, LightningElement} from 'lwc';

export default class OnlOkModal extends LightningElement {

    @api text;
    @api text2;
    @api text3;
    @api modalTitle = "Are you sure?";
    @api variantYesNo = false;

    handleOK() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleYes() {
        this.dispatchEvent(new CustomEvent('yes'));
    }

    handleNo() {
        this.dispatchEvent(new CustomEvent('no'));
    }

}