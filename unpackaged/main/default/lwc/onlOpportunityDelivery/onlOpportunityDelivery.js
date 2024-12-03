/**
 * Created 29.10.2021..
 */

import {LightningElement, api, wire} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {getRecord} from 'lightning/uiRecordApi';
import {refreshApex} from '@salesforce/apex';
import {updateRecord} from 'lightning/uiRecordApi';

import getDeliverableLineItemsForOpportunityId from '@salesforce/apex/onl_OpportunityDeliveryCtrl.getDeliverableLineItemsForOpportunityId';
import getDeliverableOpportunity from '@salesforce/apex/onl_OpportunityDeliveryCtrl.getDeliverableOpportunity';
import markFulfilmentDone from '@salesforce/apex/onl_OpportunityDeliveryCtrl.markFulfilmentDone';
import getMyListLink from '@salesforce/apex/onl_OpportunityDeliveryCtrl.getMyListLink';
import insertShipment from '@salesforce/apex/DPD_Client.insertShipment';


import {ShowToastEvent} from "lightning/platformShowToastEvent";

const columns = [
    {label: 'Quantity', fieldName: 'Quantity', type: 'number', initialWidth: 100},
    {label: 'Product', fieldName: 'Name'}
];

const FIELDS = [
    'Opportunity.Name',
    'Opportunity.Click_and_Collect__c',
    'Opportunity.Pickup_Location__c',
    'Opportunity.Pickup_Location__r.Name',
    'Opportunity.Fulfillment_status__c',
    'Opportunity.Online_Shipping_First_Name__c',
    'Opportunity.Online_Shipping_Last_Name__c',
    'Opportunity.Online_Shipping_Address_Line_1__c',
    'Opportunity.Online_Shipping_Address_Line_2__c',
    'Opportunity.Online_Shipping_Address_Line_3__c',
    'Opportunity.Online_Shipping_City__c',
    'Opportunity.Online_Shipping_Postcode__c',
    'Opportunity.Shipment_Id__c',
    'Opportunity.Package_Weight__c',
    'Opportunity.Delivery_Product__c'
];

export default class OnlOpportunityDelivery extends NavigationMixin(LightningElement) {

    @api recordId;

    columns;
    triggerShowConfirmationModal = false;

    wiredData;

    @wire(getRecord, {recordId: '$recordId', fields: FIELDS})
    wiredRecord({error, data}) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading opportunity',
                    message,
                    variant: 'error',
                }),
            );
        } else if (data) {
            // console.log('data', JSON.stringify(data));
            this.wiredData = data;
            this.opp = {};
            this.isClickCollect = data.fields.Click_and_Collect__c.value;
            this.fulfilmentDone = (data.fields.Fulfillment_status__c.value === 'Done');
            this.opp.Online_Shipping_First_Name__c = data.fields.Online_Shipping_First_Name__c.value;
            this.opp.Online_Shipping_Last_Name__c = data.fields.Online_Shipping_Last_Name__c.value;
            this.opp.Online_Shipping_Address_Line_1__c = data.fields.Online_Shipping_Address_Line_1__c.value;
            this.opp.Online_Shipping_Address_Line_2__c = data.fields.Online_Shipping_Address_Line_2__c.value;
            this.opp.Online_Shipping_Address_Line_3__c = data.fields.Online_Shipping_Address_Line_3__c.value;
            this.opp.Online_Shipping_City__c = data.fields.Online_Shipping_City__c.value;
            this.opp.Online_Shipping_Postcode__c = data.fields.Online_Shipping_Postcode__c.value;
            this.opp.Package_Weight__c = data.fields.Package_Weight__c.value;
            this.opp.Delivery_Product__c = data.fields.Delivery_Product__c.value;
            this.opp.Shipment_Id__c = data.fields.Shipment_Id__c.value;
        }
    }

    lineItems;

    totalQuantity;

    isClickCollect = false;
    hasDelivery = false;

    updating = false;

    get showMarkFulfilmentButton()
    {
        return !this.fulfilmentDone && (this.opp.Shipment_Id__c || this.isClickCollect || this.sentInsertShipment);
    }

    fulfilmentDone;
    sentInsertShipment;

    get showInsertShipmentButton()
    {
        return !this.sentInsertShipment && !this.isClickCollect && !this.fulfilmentDone && !!this.opp && !this.opp.Shipment_Id__c;
    }

    @wire(getMyListLink, {listName: 'Online Orders with Delivery'})
    myListLink;

    connectedCallback() {
        //console.log('::del:cc:id', this.recordId);
        this.opp = {};

        this.columns = columns;
        this.getDeliverableLineItems();
        // this.getOpportunity();

    }

    getDeliverableLineItems() {
        console.log(':getDeliverableLineItemsForOpportunityId:recordId', this.recordId);
        this.totalQuantity = 0;
        getDeliverableLineItemsForOpportunityId({recordId: this.recordId})
            .then(results => {
                // console.log('::getDeliverableLineItemsForOpportunityId:result', results);
                this.lineItems = JSON.parse(results);

                if (this.lineItems && this.lineItems.length > 0) this.hasDelivery = true;
                for (let oli of this.lineItems) {
                    oli.Name = oli.Product2.Name;
                    if (oli.Product2.Quantity_of_COVID_Tests__c && oli.Product2.Quantity_of_COVID_Tests__c>1)
                        this.totalQuantity += (oli.Quantity * oli.Product2.Quantity_of_COVID_Tests__c);
                    else
                        this.totalQuantity += oli.Quantity;
                }
            })
            .catch(error => {
                console.error('::getDeliverableLineItemsForOpportunityId:failed', error);

            })
            .finally(() => {

            });
    }

    getOpportunity() {
        console.log(':getDeliverableOpportunity:recordId', this.recordId);
        getDeliverableOpportunity({recordId: this.recordId})
            .then(results => {
                console.log('::getDeliverableOpportunity:result', results);
                this.opp = JSON.parse(results);
                this.isClickCollect = this.opp.Click_and_Collect__c;
                this.fulfilmentDone = (this.opp.Fulfillment_status__c === 'Done');
            })
            .catch(error => {
                console.error('::getDeliverableOpportunity:failed', error);

            })
            .finally(() => {

            });
    }

    fulfilmentDoneClicked() {
        this.updating = true;
        console.log(':fulfilmentDoneClicked:recordId', this.recordId);
        markFulfilmentDone({recordId: this.recordId})
            .then(results => {
                this.fulfilmentDone = true;
                console.log(this.myListLink.data);
                window.location = this.myListLink.data;
            })
            .catch(error => {
                console.error('::markFulfilmentDone:failed', error);
            })
            .finally(() => {
                this.updating = false;
            });
    }

    printAddressLabelClicked()
    {
        console.log('palc');
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/apex/AddressPrint?Id=' + this.recordId
            }
        })
    }

    insertShipmentClicked()
    {
        this.triggerShowConfirmationModal = true;
    }

    closeConfirmationModal()
    {
        this.triggerShowConfirmationModal = false;
    }

    doInsertShipment()
    {
        if (!this.opp.Package_Weight__c)
        {
            const toastEvent = new ShowToastEvent({
                title: 'Can not proceed',
                message: 'Please enter Package Weight',
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent( toastEvent );
            this.triggerShowConfirmationModal = false;
            return;
        }

        if (!this.opp.Delivery_Product__c)
        {
            const toastEvent = new ShowToastEvent({
                title: 'Can not proceed',
                message: 'Please specify Delivery Product',
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent( toastEvent );
            this.triggerShowConfirmationModal = false;
            return;
        }

        this.updating = true;
        let params = {};
        params.oppId = this.recordId;

        let params_s = JSON.stringify(params);

        console.log(':doInsertShipment:params', params_s);

        insertShipment({params: params_s})
            .then(results => {
                console.log('::doInsertShipment:result', results);
                this.sentInsertShipment = true;
            })
            .catch(error => {
                console.error('::doInsertShipment:failed', error);
                const toastEvent = new ShowToastEvent({
                    title: 'Unable to communicate to DPD',
                    message: error,
                    mode: 'sticky',
                    variant: 'error'
                });
                this.dispatchEvent( toastEvent );
            })
            .finally(() => {
                this.updating = false;
                this.triggerShowConfirmationModal = false;
            });
    }

}