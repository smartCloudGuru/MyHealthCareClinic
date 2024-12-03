/**
 * Created 9.2.2022..
 */

import {api, LightningElement} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';

import getProductsForOpportunity from '@salesforce/apex/OnlProductUpgradeCtrl.getProductsForOpportunity';
import upgrade from '@salesforce/apex/OnlProductUpgradeCtrl.upgrade';
import getAvailableUpgradesFor from '@salesforce/apex/OnlProductUpgradeCtrl.getAvailableUpgradesFor';
import getAvailableDowngradesFor from '@salesforce/apex/OnlProductUpgradeCtrl.getAvailableDowngradesFor';
import getAppointmentForLineItem from '@salesforce/apex/OnlProductUpgradeCtrl.getAppointmentForLineItem';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CloseActionScreenEvent} from 'lightning/actions';


export default class UpgradeDowngrade extends NavigationMixin(LightningElement) {

    @api recordId;

    loading;
    operationSelected;
    downgradeFromSelected;
    upgradeFromSelected;
    downgradeToSelected;
    upgradeToSelected;
    productsInOpportunity;
    upgradeOptions;
    downgradeOptions;
    upgradeFromSelected_product;
    downgradeFromSelected_product;
    upgradeFromSelected_lineitem;
    downgradeFromSelected_lineitem;

    timeoutId;
    toChangeAppointment;

    get isUpgrade() {
        return this.operationSelected === 'Upgrade';
    }

    get isDowngrade() {
        return this.operationSelected === 'Downgrade';
    }

    get allowsave() {
        return this.operationSelected
            && (this.upgradeFromSelected || this.downgradeFromSelected)
            && (this.upgradeToSelected || this.downgradeToSelected);
    };

    get showUpgradeToList() {
        return this.operationSelected && this.upgradeFromSelected && this.upgradeOptions && this.upgradeOptions.length > 0;
    };

    get showDowngradeToList() {
        return this.operationSelected && (this.downgradeFromSelected) && this.downgradeOptions && this.downgradeOptions.length > 0
    };

    get noAvailableDowngradeOptions() {
        return this.operationSelected && this.downgradeFromSelected && this.downgradeOptions && (this.downgradeOptions.length === 0);
    }

    get noAvailableUpgradeOptions() {
        return this.operationSelected && this.upgradeFromSelected && this.upgradeOptions && (this.upgradeOptions.length === 0);
    }

    get showAppWarnRed()
    {
        if (this.toChangeAppointment
            && this.toChangeAppointment.length>0
            && this.toChangeAppointment[0]
        ) {
            try {
                return parseInt(this.toChangeAppointment[0].SchedStartTime?.substring(11, 13)) >= 15;
            }
            catch (ex)
            {
                return false;
            }
        }
        return false;
    }


    get showAppWarnAmber()
    {
        if (this.toChangeAppointment
            && this.toChangeAppointment.length>0
            && this.toChangeAppointment[0]
        ) {
            try {
                let hour =  parseInt(this.toChangeAppointment[0].SchedStartTime?.substring(11, 13));
                return hour >=14 && hour <15;
            }
            catch (ex)
            {
                return false;
            }
        }
        return false;
    }

    get appLocationName()
    {
        if (this.toChangeAppointment
            && this.toChangeAppointment.length>0
            && this.toChangeAppointment[0]
            && this.toChangeAppointment[0].ServiceTerritory
        ) {
            return this.toChangeAppointment[0].ServiceTerritory.Name
        }
        return 'In-CLinic location';
    }


    operationOptions =
        [
            {
                value: 'Upgrade', label: 'Upgrade a Product'
            },
            {
                value: 'Downgrade', label: 'Downgrade a Product'
            }
        ];


    handleOperationChanged(e) {
        this.operationSelected = e.detail.value;
        this.downgradeFromSelected = null;
        this.upgradeFromSelected = null;
        this.upgradeFromSelected = null;
        this.downgradeToSelected = null;
        this.downgradeOptions = null;
        this.upgradeOptions = null;
        this.toChangeAppointment = null;
    }

    renderedCallback() {
        if (!this.productsInOpportunity && this.recordId) {
            console.log('rid', this.recordId);
            getProductsForOpportunity({
                oppId: this.recordId
            })
                .then(results => {
                    console.log('::getProductsForOpportunity:result', results);
                    if (!results) {
                        console.log('::getProductsForOpportunity: return empty results')
                    } else {
                        let products = JSON.parse(results);
                        this.productsInOpportunity = [];
                        for (let product of products) {
                            this.productsInOpportunity.push(
                                {
                                    value: product.Id + '#' + product.Description,
                                    label: product.Name
                                }
                            )
                        }
                    }
                })
                .catch(error => {
                    console.error('::getProductsForOpportunity:failed', error);
                })
                .finally(() => {

                });
        }
    }

    handleUpgradeFromChanged(e) {
        console.log('::handleUpgradeFromChanged');

        this.downgradeOptions = null;
        this.upgradeOptions = null;

        this.upgradeToSelected = null;
        this.downgradeToSelected = null;

        this.upgradeFromSelected = e.detail.value;
        this.upgradeFromSelected_product = this.upgradeFromSelected.split('#')[0];
        this.upgradeFromSelected_lineitem = this.upgradeFromSelected.split('#')[1];

        this.downgradeFromSelected = null;
        this.downgradeFromSelected_product = null;
        this.downgradeFromSelected_lineitem = null;

        if (this.upgradeFromSelected_product) {
            console.log('upgradeFromSelected', this.upgradeFromSelected_product);
            this.doGetUpgradesFor();
            this.doGetAppointmentFor(this.upgradeFromSelected_lineitem);
        }
    }

    doGetUpgradesFor()
    {
        getAvailableUpgradesFor({
            productId: this.upgradeFromSelected_product
        })
            .then(results => {
                console.log('::getAvailableUpgradesFor:result', results);
                this.upgradeOptions = [];
                if (!results) {
                    console.log('::getAvailableUpgradesFor: return empty results')
                } else {
                    let products = JSON.parse(results);
                    for (let product of products) {
                        this.upgradeOptions.push(
                            {
                                value: product.Id,
                                label: product.Name
                            }
                        )
                    }
                }
            })
            .catch(error => {
                console.error('::getAvailableUpgradesFor:failed', error);
            })
            .finally(() => {

            });
    }

    handleDowngradeFromChanged(e) {
        console.log('::handleDowngradeFromChanged');

        this.downgradeOptions = null;
        this.upgradeOptions = null;

        this.upgradeToSelected = null;
        this.downgradeToSelected = null;

        this.upgradeFromSelected = null;
        this.upgradeFromSelected_product = null;
        this.upgradeFromSelected_lineitem = null;

        this.downgradeFromSelected = e.detail.value;
        this.downgradeFromSelected_product = this.downgradeFromSelected.split('#')[0];
        this.downgradeFromSelected_lineitem = this.downgradeFromSelected.split('#')[1];

        if (this.downgradeFromSelected_product) {
            console.log('downgradeFromSelected', this.downgradeFromSelected_product);
            this.doGetDowngradesFor();
            this.doGetAppointmentFor(this.downgradeFromSelected_lineitem);
        }
    }

    doGetDowngradesFor()
    {
        getAvailableDowngradesFor({
            productId: this.downgradeFromSelected_product
        })
            .then(results => {
                console.log('::getAvailableDowngradesFor:result', results);
                this.downgradeOptions = [];
                if (!results) {
                    console.log('::getAvailableDowngradesFor: return empty results')
                } else {
                    let products = JSON.parse(results);
                    for (let product of products) {
                        this.downgradeOptions.push(
                            {
                                value: product.Id,
                                label: product.Name
                            }
                        )
                    }
                }
            })
            .catch(error => {
                console.error('::getAvailableDowngradesFor:failed', error);
            })
            .finally(() => {

            });
    }

    doGetAppointmentFor(lineItemId)
    {
        console.log('::getAppointmentForLineItem:lineItem', lineItemId);
        this.toChangeAppointment = null;
        getAppointmentForLineItem({
            lineItemId: lineItemId
        })
            .then(results => {
                console.log('::getAppointmentForLineItem:results', results);
                this.toChangeAppointment = JSON.parse(results);
            })
            .catch(error => {
                console.error('::getAppointmentForLineItem:failed', error);
            })
            .finally(() => {

            });
    }

    handleDowngradeToChanged(e) {
        this.upgradeToSelected = null;
        this.downgradeToSelected = e.detail.value;
        console.log('::downgradeToSelected', this.downgradeToSelected);
    }

    handleUpgradeToChanged(e) {
        this.upgradeToSelected = e.detail.value;
        this.downgradeToSelected = null;
        console.log('::upgradeToSelected', this.upgradeToSelected);
    }

    handleRun() {

        let params = {
            opportunityId: this.recordId,
            lineItemId: this.downgradeFromSelected ? this.downgradeFromSelected_lineitem : this.upgradeFromSelected_lineitem,
            toProductId: this.downgradeToSelected ? this.downgradeToSelected : this.upgradeToSelected
        }

        console.log('::handleRun', params)
        this.loading = true;
        upgrade(params)
            .then(results => {
                console.log('::handleRun:result', results);
                if (!results) this.showOK('Success', 'Operation done.');
                else {
                    console.error('::handleRun:failed', results);
                    this.showNotification('Error', results);
                }
                this.closeAction();
                clearTimeout(this.timeoutId); // no-op if invalid id
                this.timeoutId = setTimeout(this.pageReload.bind(this), 1000);

            })
            .catch(error => {
                console.error('::handleRun:failed', error);
                this.showNotification('Error', error);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    pageReload() {
        window.location.reload();
    }

    showNotification(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

    showOK(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}