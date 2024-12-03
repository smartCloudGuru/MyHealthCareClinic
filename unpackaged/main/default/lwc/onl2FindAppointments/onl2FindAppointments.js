/**
 * Created 8.3.2021..
 */

import {LightningElement, wire, api} from 'lwc';

import getProducts from '@salesforce/apex/OnlBookUI.getProducts';
import getAvailableCategories from '@salesforce/apex/OnlBookUI.getAvailableCategories';

import LOCALE from '@salesforce/i18n/locale';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class Onl2FindAppointments extends LightningElement {

    @api queryParameters;
    @api storeConfig;
    @api defaultPersonalDetails;
    @api dev;
    @api mobileApp = false;

    @api stopspinner(success) {}

    formFactor = FORM_FACTOR;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    get parentClass()
    {
        let ret = "width-limited";
        if (this.mobileApp) ret += " mobile-app";
        return ret
    }

    get noCategorySelected() {
        return this.queryParameters != null && this.queryParameters.c === '_';
    }

    foundProducts = [];
    foundProductsBySub = [];
    subCategories = new Set();
    noResults = false;
    loading = false;
    searchDone = false;

    _defaults = {turnaround: null};
    _form = {};

    category;
    division;

    categories;
    //divisions = [{label: 'Medical', value: 'Medical'}, {label: 'Dental', value: 'Dental'}, {label: 'OFFERS', value: 'OFFERS'}];
    divisions = [{label: 'Medical', value: 'Medical'}, {label: 'Dental', value: 'Dental'}];


    triggerOpenUpsellModal;
    inputForUpsellModal;


    @api defaults(defaults) {
        if (defaults) {
            if (this.dev) console.log('::fct:defaults', JSON.stringify(defaults));
            this._defaults = defaults;
            if (!this._defaults.turnaround) this._defaults.turnaround = null;
        }
    }

    @api clearSearch() {
        let inputs = this.template.querySelectorAll('[data-formfield]');
        if (inputs) {
            for (let input of inputs) {
                input.value = null;
            }
        }
        this.clearFound();
        this.noResults = false;
    }

    get smallFactorAndNavigationShown() {
        return this.formFactor === 'Small' && this.searchDone;
    }

    get hideForSmallFF() {
        return this.formFactor === 'Small' && (this.loading || this.searchDone);
    }

    // @wire(getPicklistValues, {recordTypeId: defaultRecordType, fieldApiName: "Product2.Test_Type__c"})
    // getPicklistValues_Type({error, data}) {
    //     this.typeOptions = parsePicklistData(data, error);
    //     // if (this.dev) console.log('::getPicklistValues_Type:typeOptions', this.typeOptions);
    // }


    connectedCallback() {

        if (this.queryParameters) this._defaults = JSON.parse(JSON.stringify(this.queryParameters));
        if (!this._defaults.turnaround) this._defaults.turnaround = null;


        if (!this.queryParameters) this.queryParameters = {};
        else this.queryParameters = JSON.parse(JSON.stringify(this.queryParameters));
        if (!this.queryParameters.c) {
            this.category = 'GP Consultation';
            this.queryParameters.c = 'GP Consultation';
            this.division = 'Medical';
        }

        this.category = this.queryParameters.c;

        this.categories = [];
        this.categories.push({label: 'GP Consultation', value: 'GP Consultation'});
        this.getCategories();
        this.doSearch(true); //prefilled values
    }

    clearFound() {
        this.foundProducts = [];
        this.foundProductsBySub = [];
        this.subCategories = new Set();
    }

    validateForm() {
        let inputs = this.template.querySelectorAll('[data-formfield]');
        if (inputs) {
            for (let input of inputs) {
                this._form[input.getAttribute('data-formfield')] = input.value;
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }
        if (this.showServiceCenters) this._form.distance = "1";

        return this._form.postalcode && !!this._form.distance && !!this._form.type;
    }


    handleSearchFieldChanged() {
        this.doSearch();
    }

    getCategories() {
        if (!this.division) return;
        let params = {store: this.storeConfig.storeName, division: this.division};
        if (this.dev) console.log('::getCategories:params', params);
        getAvailableCategories(params)
            .then(results => {
                if (results) {
                    if (this.dev) console.log('::getCategories:results', results);
                    let cats = JSON.parse(results);
                    this.categories = [];
                    for (let cat of cats) {
                        this.categories.push({label: cat, value: cat});
                    }
                }
            })
            .catch(error => {
                console.error('::getAvailableCategories:failed', error);
            })
            .finally(() => {

            });
    }

    /**
     * DO SEARCH
     * */
    doSearch(useprefill) {

        this.loading = true;
        this.searchDone = false;
        this.clearFound();

        if (!this.queryParameters.c) {
            if (this.division === 'Medical') {
                this.category = 'GP Consultation';
                this.queryParameters.c = 'GP Consultation';
            }
            if (this.division === 'Dental') {
                this.category = 'Dental Examination';
                this.queryParameters.c = 'Dental Examination';
            }
        }


        let params = {};
        params.storeName = this.storeConfig.storeName;
        //params.wtgServiceType = 'Medical'
        params.category = this.queryParameters.c;
        params.dev = this.dev;

        let searchParams = JSON.stringify(params);
        if (this.dev) console.log(':ofa:searchparams:', params);

        this.doGetProducts(searchParams);
    }


    checkIfAnyProductsFound() {
        if (this.dev) console.info('::checkIfAnyProductsFound:foundProducts', JSON.parse(JSON.stringify(this.foundProducts)));
        this.noResults = !this.foundProducts || this.foundProducts.length === 0;
    }

    handleBook(e) {
        this.closeUpsellModal();
        this.dispatchEvent(new CustomEvent('book', {
            detail: e.detail
        }));
    }

    handleOfferUpsell(e) {
        if (this.dev) console.log('::o2fa:handleOfferUpsell:', JSON.parse(JSON.stringify(e.detail)));
        this.inputForUpsellModal = e.detail;
        this.openUpsellModal();
    }

    handleBackToSearch() {
        this.searchDone = false;
    }

    handleCategoryChanged(e) {
        if (e.target.value && (e.target.value !== '_')) {
            this.category = e.target.value;

            let params = {};
            params.storeName = this.storeConfig.storeName;
            params.wtgServiceType = this.division;
            params.category = this.category;
            params.dev = this.dev;

            let searchParams = JSON.stringify(params);
            if (this.dev) console.log(':ofa:searchparams:', params);

            this.doGetProducts(searchParams);

        }
    }

    doGetProducts(searchParams) {
        this.clearFound();
        getProducts({params: searchParams})
            .then(results => {
                //if (this.dev) if (this.dev) console.log('::getProducts:results', results);
                this.foundProducts = JSON.parse(results);

                let division_guessing = false;
                if (this.foundProducts) {
                    for (let p of this.foundProducts) {
                        //"guess" the Service type for Products received
                        if (!this.division && p && p.product && p.product.Work_Type_Group__r && p.product.Work_Type_Group__r.Service_Type__c) {
                            this.division = p.product.Work_Type_Group__r.Service_Type__c;
                            if (this.dev) console.log(':doGetProducts:guessed division as:',this.division);
                            division_guessing = true;
                        }

                        let subcategory = '-';
                        if (p.product.Store_Sub_Category__c) {
                            subcategory = p.product.Store_Sub_Category__c.toLowerCase();
                        }

                        if (!this.subCategories.has(subcategory)) {
                            this.subCategories.add(subcategory);
                        }

                        let foundSub = null;
                        for (let sub of this.foundProductsBySub) {
                            if (sub.subCategory === subcategory) {
                                foundSub = sub;
                                break;
                            }
                        }

                        if (!foundSub) {
                            foundSub = {};
                            foundSub.subCategory = subcategory;
                            foundSub.isDefault = (subcategory === '-');
                            foundSub.products = [];
                            foundSub.products.push(p);
                            this.foundProductsBySub.push(foundSub);
                        } else {
                            foundSub.products.push(p);
                        }

                    }
                }

                if (division_guessing && this.division) this.getCategories();

                if (this.dev) console.log('subs:', this.subCategories);

                this.foundProductsBySub = JSON.parse(JSON.stringify(this.foundProductsBySub));
                if (this.dev) console.log('foundProductsBySub:', this.foundProductsBySub);

                this.checkIfAnyProductsFound();
            })
            .catch(error => {
                console.error('::getProducts:failed', error);
                this.clearFound();
                this.checkIfAnyProductsFound();
            })
            .finally(() => {
                this.loading = false;
                this.searchDone = true;
            });
    }

    handleDivisionChanged(e) {
        this.division = e.target.value;
        if (this.division === 'OFFERS') this.getOffers();
        else {
            this.category = null;
            this.getCategories();
            this.clearFound();
        }
    }

    openUpsellModal() {
        this.triggerOpenUpsellModal = true;
    }

    closeUpsellModal() {
        this.triggerOpenUpsellModal = false;
    }

    handleGoToOffers() {
        // this.division = 'OFFERS';
        // this.category = null;
        // this.categories = [{label: 'All offers', value: null}];
        // this.clearFound();
        // this.getOffers();
    }

    getOffers() {
        // let params = {};
        // params.storeName = this.storeConfig.storeName;
        // params.dev = this.dev;
        // //params.category = 'Promoted';
        //
        // let searchParams = JSON.stringify(params);
        // if (this.dev) console.log(':getoffers:searchparams:', params);
        //
        // this.doGetProducts(searchParams);
    }


}