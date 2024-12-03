/**
 * Created 14.9.2022..
 */

import {api, LightningElement} from 'lwc';

export default class MemConfirmModal extends LightningElement {

    @api text;
    @api text2;
    @api text3;
    @api modalTitle;
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