/**
 * Created 8.3.2021..
 */

import {LightningElement, wire, api} from 'lwc';

import searchProducts from '@salesforce/apex/onl_CheckoutCtrl.searchProducts';

import LOCALE from '@salesforce/i18n/locale';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Onl2FindProducts extends LightningElement {

    @api queryParameters;
    @api storeConfig;
    @api dev;

    formFactor = FORM_FACTOR;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    foundProducts = [];
    productOptions = [];
    typeOptions = [];
    noResults = false;
    loading = false;
    searchDone = false;

    searchParamProduct;
    searchParamType;

    _defaults = {};
    _form = {};

    @api stopspinner(success) {
        let rows = this.template.querySelectorAll('[data-needsstop]');
        if (rows) {
            for (let row of rows) {
                row.stopspinner(success);
            }
        }
    }

    get smallFactorAndNavigationShown() {
        return this.formFactor === 'Small' && this.searchDone;
    }

    get hideForSmallFF() {
        return this.formFactor === 'Small' && (this.loading || this.searchDone);
    }

    connectedCallback() {

        this.productOptions.push({value: "Home Self-Tests", label: "Home Self-Tests"});
        this.typeOptions.push({value: null, label: "All test types"});
        this.typeOptions.push({value: "Fit to Fly", label: "Fit to Fly"});
        this.typeOptions.push({value: "Day 2 Test", label: "Day 2 Test"});
        this.typeOptions.push({value: "UK Entry Test", label: "UK Entry Test"});
        this.typeOptions.push({value: "FTF and Day 2 Package", label: "FTF and Day 2 Package"});
        this.typeOptions.push({value: "Lateral Flow Package", label: "Lateral Flow Bundle"});

        if (this.queryParameters) this._defaults = JSON.parse(JSON.stringify(this.queryParameters));
        // console.log(JSON.stringify(this.queryParameters));
        if (!this._defaults) this._defaults = {};
        if (!this._defaults.product) this._defaults.product = "Home Self-Tests";
        if (!this._defaults.type) this._defaults.type = null;

        this.searchParamProduct = this._defaults.product;
        this.searchParamType = this._defaults.type;

        this.doSearch();
    }

    handleSearchFieldChanged() {
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

        let nodeP = this.template.querySelector('[data-formfield="product"]');
        let nodeT = this.template.querySelector('[data-formfield="type"]');
        if (nodeP) this.searchParamProduct = nodeP.value;
        if (nodeT) this.searchParamType = nodeT.value;

        if (this.dev) console.log('::doSearch:searchParamType', this.searchParamType);
        if (this.dev) console.log('::doSearch:searchParams');

        searchProducts({store: this.storeConfig.storeName})
            .then(results => {
                if (this.dev) console.log('::searchProducts:result', results);
                let found = JSON.parse(results);
                if (found) {
                    this.foundProducts = [];
                    for (let p of found) {
                        p.type = 'product';
                        //if (this.dev) console.log('::dbg:cat',p.Store_Categories__c);
                        if (!this.searchParamType || (p.Store_Categories__c && p.Store_Categories__c.indexOf(this.searchParamType) >= 0))
                        {
                            if ((this.searchParamProduct === 'Home Self-Tests') && p.Is_Home_Test__c) {
                                if (p.Description) p.Description = p.Description.replaceAll('\n','<br/>');
                                this.foundProducts.push(p);
                            }
                        }
                    }
                }
                this.checkIfAnyProductsFound();
            })
            .catch(error => {
                console.error('::searchProducts:failed', error);
                this.foundProducts = [];
                this.checkIfAnyProductsFound();


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
        // if (this.dev) console.log('::findproducts:handleAddToBasket');
        this.dispatchEvent(new CustomEvent('add', {
            detail: e.detail
        }));
    }

    handleBackToSearch() {
        this.searchDone = false;
    }


}