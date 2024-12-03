/**
 * Created 8.3.2021..
 */

import {LightningElement, wire, api} from 'lwc';

import searchProducts from '@salesforce/apex/onl_CheckoutCtrl.searchProducts';

import LOCALE from '@salesforce/i18n/locale';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class OnlFindProducts extends LightningElement {

    @api queryParameters;
    @api storeConfig;


    formFactor = FORM_FACTOR;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    foundProducts = [];
    noResults = false;
    loading = false;
    searchDone = false;

    _defaults = {};
    _form = {};

    get smallFactorAndNavigationShown() {
        return this.formFactor === 'Small' && (this.searchDone || this.basket_count > 0);
    }

    get hideForSmallFF() {
        return this.formFactor === 'Small' && (this.loading || this.searchDone);
    }

    connectedCallback() {
        if (this.queryParameters) this._defaults = this.queryParameters;
        this.doSearch();
    }

    /**
     * DO SEARCH
     * */
    doSearch() {

        if (!this.storeConfig.product) return;

        this.loading = true;
        this.searchDone = false;
        this.foundProducts = [];

        console.log('::doSearch:searchParams');


        searchProducts({store: this.storeConfig.storeName})
            .then(results => {
                console.log('::searchProducts:result', results);
                this.foundProducts = JSON.parse(results);
                if (this.foundProducts) for (let p of this.foundProducts) p.type = 'product';
                this.checkIfAnyProductsFound();
            })
            .catch(error => {
                console.error('::searchProducts:failed', error);
                this.foundProducts = [];
                this.checkIfAnyProductsFound();

                this.foundProducts.sort((a, b) => {
                    if (!a.product || !a.product.Store_Sort_Order__c) return -1;
                    if (!b.product || !b.product.Store_Sort_Order__c) return 1;

                    return a.product.Store_Sort_Order__c - b.product.Name.Store_Sort_Order__c;
                });
            })
            .finally(() => {
                this.loading = false;
                this.searchDone = true;
            });
    }

    checkIfAnyProductsFound() {
        this.noResults = !this.foundProducts || this.foundProducts.length === 0;
    }

    handleAddToBasket(e) {
        this.dispatchEvent(new CustomEvent('add', {
            detail: e.detail
        }));
    }

    handleBackToSearch() {
        this.searchDone = false;
    }


}