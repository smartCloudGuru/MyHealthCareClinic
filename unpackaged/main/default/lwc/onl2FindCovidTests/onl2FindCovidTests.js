/**
 * Created 8.3.2021..
 */

import {LightningElement, wire, api} from 'lwc';
import {getPicklistValues} from "lightning/uiObjectInfoApi";

import {parsePicklistData, distanceOptions, defaultRecordType} from 'c/onlCommon';

import searchCovidTests from '@salesforce/apex/onl_CheckoutCtrl.searchCovidTests';
import getServiceCenters from '@salesforce/apex/onl_CheckoutCtrl.getServiceCenters';

import getPicklistOptions from '@salesforce/apex/onl_CheckoutCtrl.getFindByTestTypeOptions';

import LOCALE from '@salesforce/i18n/locale';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class OnlFindCovidTests extends LightningElement {

    @api queryParameters;
    @api storeConfig;
    @api defaultPersonalDetails;
    @api dev;

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
    directProductName;

    _defaults = {turnaround: null};
    _form = {};


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
        this.foundProducts = [];
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
    //     let _typeOptions = parsePicklistData(data, error);
    //     this.typeOptions = [];
    //     //2022-01-12 exclude some values from this dropdown
    //     //2022-03-24 exclude some values from this dropdown
    //     for (let opt of _typeOptions) {
    //         if (opt.label && opt.label.toLowerCase().indexOf('uk entry test') >= 0) continue;
    //         if (opt.label && opt.label.toLowerCase().indexOf('lateral flow') >= 0) continue;
    //         if (opt.label && opt.label.toLowerCase().indexOf('day 2') >= 0) continue;
    //         if (opt.label && opt.label.toLowerCase().indexOf('day 5') >= 0) continue;
    //         if (opt.label && opt.label.toLowerCase().indexOf('day 8') >= 0) continue;
    //         if (opt.label && opt.label.toLowerCase().indexOf('travel package') >= 0) continue;
    //         this.typeOptions.push(opt);
    //     }
    //
    //     // if (this.dev) console.log('::getPicklistValues_Type:typeOptions', this.typeOptions);
    // }

    fetchPicklistOptions() {
        getPicklistOptions()
            .then(result => {
                console.log('::htf:fetchPicklistOptions:result', result);
                this.typeOptions = JSON.parse(result);
            })
            .catch(error => {
                console.error('::htf:fetchPicklistOptions:failed', error);
            })
            .finally(() => {
                }
            );
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
        if (this.queryParameters) {
            this._defaults = JSON.parse(JSON.stringify(this.queryParameters));
            this.directProductName = this.queryParameters.product;
        }

        if (this.dev) console.log('::m2fct:cc:directProductName', this.directProductName);

        if (!this._defaults.turnaround) this._defaults.turnaround = null;

        if (this.storeConfig && this.storeConfig.displayLocations) {
            this.showServiceCenters = true;
            this.retrieveServiceCenters();
        }

        this.fetchPicklistOptions();

        if (this._defaults.postalcode && this._defaults.type) this.doSearch(true); //prefilled values
    }

    retrieveServiceCenters() {
        getServiceCenters()
            .then(results => {
                if (this.dev) console.log('::getServiceCenters:result', results);

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

    handleSearchFieldChanged() {
        this.doSearch();
    }

    handleSearchFieldChangedClearProduct() {
        this.directProductName = null;
        this.doSearch();
    }

    /**
     * DO SEARCH
     * */
    doSearch(useprefill) {
        if (!this.storeConfig.covid) return;

        if (!useprefill) {
            if (!this.validateForm()) return;
            this._defaults = this._form;
        } else {
            this._form =
                {
                    postalcode: this._defaults.postalcode,
                    type: this._defaults.type,
                    turnaround: this._defaults.turnaround,
                    distance: "1"
                }
            if (this.dev) console.log('::fct:doSearch:prefilled-form', JSON.stringify(this._form));
        }

        this.loading = true;
        this.searchDone = false;
        this.foundProducts = [];
        this._form.store = this.storeConfig.storeName;


        let params = JSON.parse(JSON.stringify(this._form));
        if (params.turnaround == null) params.turnaround = '';

        let searchParams = JSON.stringify(params);
        if (this.dev) console.log('::doSearch:searchParams', searchParams);
        searchCovidTests({params: searchParams})
            .then(results => {
                if (this.dev) console.log('::searchCovidTests:results', results);
                this.foundProducts = JSON.parse(results);


                //beautify dates
                if (this.foundProducts) {
                    for (let product of this.foundProducts) {

                        // sort records
                        if (product.product && product.product.Default_COVID_Tests__r && product.product.Default_COVID_Tests__r.records) {
                            product.product.Default_COVID_Tests__r.records.sort((a, b) => {
                                if (!a.Sort_Order__c) return -1;
                                if (!b.Sort_Order__c) return 1;

                                return a.Sort_Order__c - b.Sort_Order__c;
                            });
                        }

                        if (product && product.product) product.product.type = 'covid';
                        //keep only 1st location
                        if (product.locations && product.locations.length > 1) {
                            product.locations.length = 1;
                        }

                        // for (let location of product.locations) {
                        //     if (location.firstAvailable == null) {
                        //         if (!product.daysQueried) {
                        //             location.formattedFirstAvailable = 'Availability not known at this time';
                        //         } else {
                        //             location.formattedFirstAvailable = 'Not available within next ' + product.daysQueried + ' days';
                        //         }
                        //
                        //         location.red = true;
                        //     } else {
                        //
                        //         location.formattedFirstAvailable = new Intl.DateTimeFormat(LOCALE,
                        //             {
                        //                 year: "numeric",
                        //                 month: "2-digit",
                        //                 day: "2-digit",
                        //                 timeZone: "Europe/London",
                        //                 hour: "2-digit",
                        //                 minute: "2-digit",
                        //                 hour12: false,
                        //             })
                        //             .format(Date.parse(location.firstAvailable));
                        //
                        //         let d = new Date(Date.parse(location.firstAvailable));
                        //         location.firstAvailableDate =
                        //             d.getFullYear()
                        //             + '-' + ("0" + (d.getMonth() + 1)).slice(-2)
                        //             + '-' + ("0" + d.getDate()).slice(-2);
                        //     }
                        // }
                    }

                    if (this.directProductName)
                        this.foundProducts = this.foundProducts.filter(element => {
                            return element.product.Name.indexOf(this.directProductName) >= 0;
                        });

                    if (this.foundProducts) {
                        this.foundProducts.sort((a, b) => {
                            let av = 0;
                            let bv = 0;

                            if (a.product.Quantity_of_COVID_Tests__c) av = 10000 * a.product.Quantity_of_COVID_Tests__c;
                            if (b.product.Quantity_of_COVID_Tests__c) bv = 10000 * b.product.Quantity_of_COVID_Tests__c;
                            if (a.product.Non_Membership_Price__c) av = av + a.product.Non_Membership_Price__c;
                            if (b.product.Non_Membership_Price__c) bv = bv + b.product.Non_Membership_Price__c;

                            return av - bv;
                        });
                    }

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

    handleBasketUpdated(e) {
        this.dispatchEvent(new CustomEvent('basketupdated'));
    }

    handleBackToSearch() {
        this.searchDone = false;
    }


}