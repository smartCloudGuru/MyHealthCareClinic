/**
 * Created 23.9.2022..
 */

import {LightningElement} from 'lwc';

export default class MemTacPopup extends LightningElement {

    today = new Date();

    handleOK() {
        this.dispatchEvent(new CustomEvent('close'));
    }

}