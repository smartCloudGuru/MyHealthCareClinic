/**
 * Created by Matija on 22.10.2024..
 */

import {api, LightningElement} from 'lwc';

export default class Onl2CategoriesModal extends LightningElement {

    @api storeConfig;
    @api dev;
    @api medcategories;
    @api dentcategories;
    @api division;

    get showMedical() {
        return this.division == null || this.division === '' || this.division === 'Medical';
    }

    get showDental() {
        return this.division == null || this.division === '' || this.division === 'Dental';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleNOP(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    handleChoice(e) {
        let category = e.currentTarget.dataset.cat;
        this.dispatchEvent(new CustomEvent('category', {
            detail: {
                cat: category
            }
        }));
    }


}