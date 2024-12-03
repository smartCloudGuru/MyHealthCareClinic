/**
 * Created 8.3.2021..
 */

import {LightningElement, api} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

//import getEarliestFreeSlotsForProduct from '@salesforce/apex/OnlBookUI.aura_getEarliestFreeSlotsForProduct';

export default class Onl2AppProductResultRow extends LightningElement {

    @api dev;
    @api product;
    @api storeConfig;
    @api defaultPersonalDetails;
    @api branding;

    formFactor = FORM_FACTOR;

    productAppType;

    nextSlots;

    backgroundImageStyle;

    upsellAvailable;

    triggerConfirmRequirementsModal;
    allRequirementsAccepted;

    get boxClass() {
        let ret = 'box product-row';
        if (this.product?.product?.Store_Image__c != null) ret += ' has-image';
        else ret += ' no-image';
        if (this.product?.product?.Store_Highlight__c != null) {
            if (this.product.product.Store_Highlight__c.toLowerCase().indexOf('membership')>=0) {
                ret += ' has-highlight membership';
            }
            else ret += ' has-highlight';
        }
        else ret += ' no-highlight';
        if (this.product?.product?.Price_Description__c != null) ret += ' has-pricing';
        else ret += ' no-pricing';
        return ret;
    }

    get pricingOfferPrice() {
        if (this.product?.product?.Offer_Price__c!=null) return this.product.product.Offer_Price__c;
        else return null;
    }

    get pricing() {
        if (this.product?.product?.Price_Description__c != null) {
            return this.product.product.Price_Description__c
                .replaceAll('\n', '<br/>');
        }
        return null;
    }

    get hasImage() {
        return this.product?.product?.Store_Image__c != null;
    }

    get hasHighlight() {
        return this.product?.product?.Store_Highlight__c != null && this.product.product.Store_Highlight__c.toLowerCase().indexOf('membership')<0;
    }

    get hasMembershipHighlight() {
        return this.product?.product?.Store_Highlight__c != null && this.product.product.Store_Highlight__c.toLowerCase().indexOf('membership')>=0;
    }

    get productMetaData() {
        let ret = {};

        if (this.product && this.product.product) {
            ret.n = this.product.product.Name;
            ret.c = this.product.product.ProductCode;
            ret.b = this.product.product.Business_Unit__c;
            ret.s = this.product.product.Work_Type_Group__r?.Service_Type__c;
        }
        return JSON.stringify(ret);
    }

    connectedCallback() {
        if (this.dev) console.log('::product', JSON.parse(JSON.stringify(this.product)));
        this.productAppType = this.product?.product?.Work_Type_Group__r?.Appointment_Type__c;

        this.backgroundImageStyle = 'background-image: url(/resource/' + this.product?.product?.Store_Image__c + ');';
        //this.getEarliestInfo(this.product.product.Id);
        this.upsellAvailable = this.product?.hasUpsells;
        if (this.dev) console.log('::Onl2AppProductResultRow:cc:' + this.product?.product?.ProductCode + ':upsellAvailable:' + this.upsellAvailable);
    }

    get smallFactor() {
        return this.formFactor === 'Small';
    }


    // Button Schedule and add to basket
    handleSchedule(event) {

        let productId = this.product.product.Id;
        let wtgId = this.product.defaultWTGId;
        let dappId = this.product.defaultAppointmentID;
        let productName = this.product.product.Name;
        let appointmentType = this.productAppType;

        if (this.product?.product?.Requirements__c && !this.allRequirementsAccepted) {
            this.openConfirmRequirementsModal();
            return;
        }

        if (!this.upsellAvailable) {
            this.dispatchEvent(new CustomEvent('book', {
                detail: {
                    productName: productName,
                    productId: productId,
                    productCode: this.product?.product?.ProductCode,
                    wtgId: wtgId,
                    dappId: dappId,
                    appointmentType: appointmentType,
                    nextSlots: this.nextSlots,
                    availableFrom: this.product?.availableFrom,
                    hidePractitionerList: this.product?.product?.Store_Hide_Practitioner_List__c,
                    attachmentRequired: this.product?.product?.Store_Attachment_Required__c,
                    attachmentText: this.product?.product?.Store_Attachment_Text__c,
                    businessUnit: this.product?.product?.Business_Unit__c,
                    branding: this.branding
                }
            }));
        } else {
            this.dispatchEvent(new CustomEvent('offerupsell', {
                detail: {
                    productName: productName,
                    productId: productId,
                    productCode: this.product?.product?.ProductCode,
                    wtgId: wtgId,
                    dappId: dappId,
                    appointmentType: appointmentType,
                    nextSlots: this.nextSlots,
                    availableFrom: this.product?.availableFrom,
                    upsellDescription: this.product?.product?.Store_Upsell_Description__c,
                    upsells: this.product?.upsells,
                    hidePractitionerList: this.product?.product?.Store_Hide_Practitioner_List__c,
                    attachmentRequired: this.product?.product?.Store_Attachment_Required__c,
                    attachmentText: this.product?.product?.Store_Attachment_Text__c,
                    businessUnit: this.product?.product?.Business_Unit__c,
                    branding: this.branding
                }
            }));
        }
    }

    openConfirmRequirementsModal() {
        this.triggerConfirmRequirementsModal = true;
    }

    closeConfirmRequirementsModal() {
        this.triggerConfirmRequirementsModal = false;
    }

    handleProceedFromRequirements() {
        this.closeConfirmRequirementsModal();
        this.allRequirementsAccepted = true;
        this.handleSchedule(null);
    }


}