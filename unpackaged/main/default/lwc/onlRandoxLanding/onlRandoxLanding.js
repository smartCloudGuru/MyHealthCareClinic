/**
 * Created by Matija on 5.2.2024..
 */

import {api, LightningElement} from 'lwc';
import checkVoucherIsAvailable from '@salesforce/apex/RandoxEligibilityCtrl.checkVoucherIsAvailable';
import getProducts from '@salesforce/apex/OnlBookUI.getProducts';

export default class OnlRandoxLanding extends LightningElement {

    @api queryParameters;
    @api storeConfig;

    @api dev;

    loading;
    success;
    error;
    msgError;

    randoxPatientId;

    noAccess;

    selectedRandoxVoucherTag;

    productsShown;

    loadingProducts;

    noResults;
    foundProducts = [];
    subCategories = new Set();
    searchDone = false;

    loggedin;
    showCheckoutButtonOnMain;



    handleRandoxProceed(e) {
        this.noAccess = false;
        let nodeRandoxId = this.template.querySelector('[data-formfield="randoxId"]');

        if (nodeRandoxId) {
            if (!nodeRandoxId.reportValidity()) return;

            this.loading = true;

            this.randoxPatientId = nodeRandoxId.value;

            if (this.dev) console.log('::checkVoucherIsAvailable:id', this.randoxPatientId);

            checkVoucherIsAvailable({randoxPatientId: this.randoxPatientId})
                .then(results => {
                        if (this.dev) console.log('::checkVoucherIsAvailable:result', results);
                        if (!results) {
                            this.loading = false;
                            this.noAccess = true;
                        } else {
                            this.selectedRandoxVoucherTag = results;
                            this.showRandoxProducts();
                        }
                    }
                )
                .catch(error => {
                    console.error('::checkVoucherIsAvailable:failed', error);
                    this.loading = false;
                })
                .finally(() => {

                });
        }
    }



    showRandoxProducts()
    {
        this.loading = false;
        this.productsShown = true;

        //load products with specific voucher tag
        this.loadingProducts = true;
        let searchParams = {
            voucherTag:this.selectedRandoxVoucherTag,
            storeName : this.storeConfig.storeName,
            showHidden : true,
            dev : this.dev
        };
        this.doGetProducts(JSON.stringify(searchParams));

        console.log('products shown');
    }

    clearFound() {
        this.foundProducts = [];
        this.subCategories = new Set();
    }

    doGetProducts(searchParams) {
        this.clearFound();
        getProducts({params: searchParams})
            .then(results => {
                if (this.dev) if (this.dev) console.log('::getProducts:results', results);
                this.foundProducts = JSON.parse(results);
                this.checkIfAnyProductsFound();
            })
            .catch(error => {
                console.error('::getProducts:failed', error);
                this.clearFound();
                this.checkIfAnyProductsFound();
            })
            .finally(() => {
                this.loadingProducts = false;
                this.searchDone = true;
            });
    }

    checkIfAnyProductsFound() {
        if (this.dev) console.info('::checkIfAnyProductsFound:foundProducts', JSON.parse(JSON.stringify(this.foundProducts)));
        this.noResults = !this.foundProducts || this.foundProducts.length === 0;
    }

    handleBook(e) {
        //if (this.dev) console.log('::handleBook:event:', JSON.stringify(e.detail));
        e.detail.voucherTag = this.selectedRandoxVoucherTag;
        e.detail.randoxPID = this.randoxPatientId;
        this.dispatchEvent(new CustomEvent('book', {
            detail: e.detail
        }));
    }
}