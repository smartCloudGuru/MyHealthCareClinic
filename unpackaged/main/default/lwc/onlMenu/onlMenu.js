/**
 * Created 22.3.2021..
 */

import {LightningElement, api} from 'lwc';

export default class OnlMenu extends LightningElement {

    @api currentActiveOption = 'covid';
    @api storeConfig = {};

    get showMenu(){
        let count =0;
        if (this.storeConfig)
        {
            if (this.storeConfig.forceDisplayTabs) {
                count = 2;
            }
            if (this.storeConfig.covid) count++;
            if (this.storeConfig.product) count++;
            if (this.storeConfig.appointment) count++;
        }
        return count>1;
    }


    handleSelectedOption(e)
    {
        // console.log(e.currentTarget.dataset.option);
        this.dispatchEvent(new CustomEvent('menuoption', {detail: e.currentTarget.dataset.option}));
    }
}