/**
 * Created 12.9.2022..
 */

import {api, LightningElement} from 'lwc';

export default class MemSignUpRow extends LightningElement {

    @api isAdult;
    @api identifier;
    @api row;


    handleEdit()
    {
        this.dispatchEvent(new CustomEvent('edit', {detail: this.identifier}));
    }

    handleRemove()
    {
        this.dispatchEvent(new CustomEvent('remove', {detail: this.identifier}));
    }

}