/**
 * Created by Matija on 19.11.2024..
 */

import {api, LightningElement} from 'lwc';

export default class Onl3CategoryInfo extends LightningElement {

    @api category;

    get implants() {
        //return true;
        return this.category === 'Implant Consultation';
    }
}