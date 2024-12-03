/**
 * Created 8.3.2021..
 */

import {LightningElement, wire, api} from 'lwc';
import {getPicklistValues} from "lightning/uiObjectInfoApi";

import searchCovidTests from '@salesforce/apex/onl_CheckoutCtrl.searchCovidTests';

const _defaultRecordType = '012000000000000AAA';

import LOCALE from '@salesforce/i18n/locale';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {defaultRecordType, parsePicklistData} from 'c/onlCommon';

export default class OnlFindCovidTests extends LightningElement {

    @api queryParameters;
    @api storeConfig;

    formFactor = FORM_FACTOR;

    distanceOptions = [
        {label: '5 miles', value: '5'},
        {label: '10 miles', value: '10'},
        {label: '25 miles', value: '25'},
        {label: '50 miles', value: '50'},
        {label: '100 miles', value: '100'}
        // {label: 'Any distance', value: null}
    ];

    typeOptions = [
        {
            label: 'GP',
            value: 'GP'
        },
        {
            label: 'Dentist',
            value: 'Dentist'
        },
        {
            label: 'Implants',
            value: 'Implants'
        },
        {
            label: 'Orthodontics',
            value: 'Orthodontics'
        }
        ,
        {
            label: 'Blood tests',
            value: 'Blood tests'
        }
        ,
        {
            label: 'Sexual health',
            value: 'Sexual health'
        }
    ];

    foundProducts = [];
    noResults = false;
    loading = false;
    searchDone = false;

    _defaults = {};

    _form = {};

    get hideForSmallFF() {
        return this.formFactor === 'Small' && (this.loading || this.searchDone);
    }

    @wire(getPicklistValues, {recordTypeId: defaultRecordType, fieldApiName: "Product2.Turnaround_Time_Global__c"})
    getPicklistValues_TurnaroundTime({error, data}) {
        this.turnaroundOptions = parsePicklistData(data, error );
        // console.log('::getPicklistValues_Type:typeOptions', this.typeOptions);
    }


    connectedCallback() {
        // console.log('::OnlFindCovidTests:cc:queryParameters', this.queryParameters);

        if (this.queryParameters) this._defaults = this.queryParameters;

    }

    validateForm() {
        let inputs = this.template.querySelectorAll('[data-formfield]');
        if (inputs) {
            for (let input of inputs) {
                this._form[input.getAttribute('data-formfield')] = input.value;
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }
        return !!this._form.postalcode && !!this._form.distance && !!this._form.type && !!this._form.turnaround;
    }

    /** DO SEARCH */
    doSearch() {
        if (!this.validateForm()) return;

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
                if (this.foundProducts)
                    for (let product of this.foundProducts) {

                        for (let location of product.locations) {
                            if (location.firstAvailable == null) {
                                if (!product.daysQueried) {
                                    location.firstAvailable = 'Availability not known at this time';
                                } else {
                                    location.firstAvailable = 'Not available within next ' + product.daysQueried + ' days';
                                }

                                location.red = true;
                            } else {
                                location.firstAvailable = new Intl.DateTimeFormat(LOCALE,
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
                            }
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
        this.noResults = !this.foundProducts || this.foundProducts.length === 0;
    }

    doAddToBasket(event) {

    }




    handleBackToSearch() {
        this.searchDone = false;
    }

    handleContinueToBooking() {
        let params = {};

        params.basket = [];

        params.personalDetails = {}

        params.personalDetails.lastName = 'last name';
        params.personalDetails.firstName = 'first name';
        params.personalDetails.email = 'email';
        params.personalDetails.phone = 'phone12313';

        for (let i of this._basket) {
            params.basket.push({
                id: i.product.Id,
                quantity: i.quantity
            });
        }

        this.dispatchEvent(new CustomEvent('continue', {
                detail:
                    {
                        basket: this._basket,
                        defaultLocation:
                            {
                                postalcode: this._form.postalcode,
                                distance: this._form.distance
                            }
                    }

            }
        ));
    }




}