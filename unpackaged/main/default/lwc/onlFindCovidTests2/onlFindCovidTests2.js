/**
 * Created 8.3.2021..
 */

import {LightningElement, wire, api} from 'lwc';
import {getPicklistValues} from "lightning/uiObjectInfoApi";

import {parsePicklistData, distanceOptions, defaultRecordType} from 'c/onlCommon';

import searchCovidTests from '@salesforce/apex/onl_CheckoutCtrl.searchCovidTests';
import getServiceCenters from '@salesforce/apex/onl_CheckoutCtrl.getServiceCenters';

import LOCALE from '@salesforce/i18n/locale';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class OnlFindCovidTests extends LightningElement {

    @api queryParameters;
    @api storeConfig;

    formFactor = FORM_FACTOR;

    get smallFactor() {
        return this.formFactor === 'Small';
    }

    serviceCenterOptions = []
    showServiceCenters = false;

    typeOptions = [];
    turnaroundOptions = [];

    distanceOptions = distanceOptions;

    foundProducts = [];
    noResults = false;
    loading = false;
    searchDone = false;

    quantityOptions;

    _defaults = {turnaround: null};
    _form = {};

    @api defaults(defaults) {
        console.log('::fct:defaults', defaults);
        this._defaults = defaults;
        if (!this._defaults.turnaround) this._defaults.turnaround = null;
        console.log('::fct:defaults', defaults);
    }

    get smallFactorAndNavigationShown() {
        return this.formFactor === 'Small' && (this.searchDone || this.basket_count > 0);
    }

    get hideForSmallFF() {
        return this.formFactor === 'Small' && (this.loading || this.searchDone);
    }

    @wire(getPicklistValues, {recordTypeId: defaultRecordType, fieldApiName: "Product2.Test_Type__c"})
    getPicklistValues_Type({error, data}) {
        this.typeOptions = parsePicklistData(data, error);
        // console.log('::getPicklistValues_Type:typeOptions', this.typeOptions);
    }

    @wire(getPicklistValues, {recordTypeId: defaultRecordType, fieldApiName: "Product2.Turnaround_Time_Global__c"})
    getPicklistValues_TurnaroundTime({error, data}) {
        this.turnaroundOptions = [{
            label: 'All Options', value: null
        }];
        let _ops = parsePicklistData(data, error);
        for (let o of _ops)
            this.turnaroundOptions.push(o);

    }

    connectedCallback() {
        if (this.queryParameters) this._defaults = JSON.parse(JSON.stringify(this.queryParameters));
        if (!this._defaults.turnaround) this._defaults.turnaround = null;

        if (this.storeConfig && this.storeConfig.displayLocations) {
            this.showServiceCenters = true;
            this.retrieveServiceCenters();
        }

        this.quantityOptions = [];
        for (let i = 1; i < 11; i++) {
            this.quantityOptions.push({label: '' + i, value: '' + i});
        }
    }

    retrieveServiceCenters() {
        getServiceCenters()
            .then(results => {
                console.log('::getServiceCenters:result', results);

                if (results) {
                    let resObj = JSON.parse(results);

                    this.serviceCenterOptions = [];
                    for (let sc of resObj) {
                        this.serviceCenterOptions.push({
                            label: sc.Name + ", " + sc.PostalCode,
                            value: sc.PostalCode
                        })
                    }
                }

                this.showServiceCenters = this.serviceCenterOptions.length > 0;

            })
            .catch(error => {
                console.error('::getServiceCenters:failed', error);
                this.showServiceCenters = false;
            })
            .finally(() => {

            });
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

    /**
     * DO SEARCH
     * */
    doSearch() {
        if (!this.storeConfig.covid) return;

        if (!this.validateForm()) {
            // console.log(':dbg:form not valid');
            return;
        }

        this._defaults = this._form;

        this.loading = true;
        this.searchDone = false;
        this.foundProducts = [];
        this._form.store = this.storeConfig.storeName;

        let searchParams = JSON.stringify(this._form);
        console.log('::doSearch:searchParams', searchParams);
        searchCovidTests({params: searchParams})
            .then(results => {
                console.log('::searchCovidTests:result', results);
                this.foundProducts = JSON.parse(results);

                //beautify dates
                if (this.foundProducts) {
                    for (let product of this.foundProducts) {
                        if (product && product.product) product.product.type = 'covid';
                        for (let location of product.locations) {
                            if (location.firstAvailable == null) {
                                if (!product.daysQueried) {
                                    location.formattedFirstAvailable = 'Availability not known at this time';
                                } else {
                                    location.formattedFirstAvailable = 'Not available within next ' + product.daysQueried + ' days';
                                }

                                location.red = true;
                            } else {

                                location.formattedFirstAvailable = new Intl.DateTimeFormat(LOCALE,
                                    {
                                        year: "numeric",
                                        month: "2-digit",
                                        day: "2-digit",
                                        timeZone: "Europe/London",
                                        hour: "2-digit",
                                        minute: "2-digit",
                                        hour12: false,
                                    })
                                    .format(Date.parse(location.firstAvailable));

                                let d = new Date(Date.parse(location.firstAvailable));
                                location.firstAvailableDate =
                                    d.getFullYear()
                                    + '-' + ("0" + (d.getMonth() + 1)).slice(-2)
                                    +'-' + ("0" + d.getDate()).slice(-2);
                            }
                        }
                    }

                    this.foundProducts.sort((a, b) => {
                        if (!a.product || !a.product.Store_Sort_Order__c) return -1;
                        if (!b.product || !b.product.Store_Sort_Order__c) return 1;

                        return a.product.Store_Sort_Order__c - b.product.Name.Store_Sort_Order__c;
                    });
                }


                this.checkIfAnyProductsFound();
            })
            .catch(error => {
                console.error('::searchCovidTests:failed', error);
                this.foundProducts = [];
                this.checkIfAnyProductsFound();
            })
            .finally(() => {
                this.loading = false;
                this.searchDone = true;
            });
    }

    checkIfAnyProductsFound() {
        console.info('::checkIfAnyProductsFound:foundProducts', JSON.parse(JSON.stringify(this.foundProducts)));
        this.noResults = !this.foundProducts || this.foundProducts.length === 0;
    }

    handleAdd(e) {
        //enrich with default location
        e.detail.defaultLocation = {
            postalcode: this._form.postalcode,
            distance: this._form.distance
        }
        this.dispatchEvent(new CustomEvent('add', {
            detail: e.detail
        }));
    }

    handleBackToSearch() {
        this.searchDone = false;
    }


}