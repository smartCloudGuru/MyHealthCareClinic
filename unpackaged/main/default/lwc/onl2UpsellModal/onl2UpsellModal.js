/**
 * Created 10.5.2023..
 */

import {api, LightningElement} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Onl2UpsellModal extends LightningElement {

    @api storeConfig;
    @api bookContext;
    @api dev;
    @api bookSession;

    formFactor = FORM_FACTOR;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    dataReady;
    baseProductName;
    baseDescription;
    upsellsData;

    connectedCallback() {
        this.dataReady = true;
        if (this.bookContext) {
            this.baseProductName = this.bookContext.productName;
            this.baseDescription = this.bookContext.upsellDescription;
        }

        this.upsellsData = [];

        if (this.bookContext.upsells) {
            this.upsellsData = this.bookContext.upsells;
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleScheduleBase(e) {

        this.dispatchEvent(new CustomEvent('book', {
            detail: this.bookContext
        }));
    }

    handleScheduleUpgrade(e) {
        const clickedId = e.currentTarget.dataset.pid;

        let productToBook = null;
        for (let uprod of this.upsellsData) {
            if (uprod.product.Id === clickedId) {
                productToBook = uprod;
                break;
            }
        }

        if (productToBook) {
            this.dispatchEvent(new CustomEvent('book', {
                detail: {
                    productName: productToBook.product.Name,
                    productId: productToBook.product.Id,
                    productCode: productToBook.product.ProductCode,
                    wtgId: productToBook.defaultWTGId,
                    availableFrom: productToBook.availableFrom
                }
            }));
        }


    }


}