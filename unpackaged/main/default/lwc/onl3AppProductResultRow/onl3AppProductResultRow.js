/**
 * Created 8.3.2021..
 */

import {LightningElement, api} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

//import getEarliestFreeSlotsForProduct from '@salesforce/apex/OnlBookUI.aura_getEarliestFreeSlotsForProduct';

export default class Onl3AppProductResultRow extends LightningElement {

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
    triggerMoreInfoModal;
    allRequirementsAccepted;

    get boxClass() {
        let ret = 'box product-row';
        if (this.product?.product?.Store_Image__c != null) ret += ' has-image';
        else ret += ' no-image';
        if (this.product?.product?.Store_Highlight__c != null) {
            if (this.containsBlackHighlight()) {
                ret += ' has-highlight black';
            } else if (this.containsPopularHighlight()) {
                ret += ' has-highlight popular';
            } else if (this.containsMembershipHighlight()) {
                ret += ' has-highlight membership';
            } else ret += ' has-highlight';
        } else ret += ' no-highlight';
        if (this.product?.product?.Price_Description__c != null) ret += ' has-pricing';
        else ret += ' no-pricing';
        return ret;
    }

    get pricingOfferPrice() {
        if (this.product?.product?.Offer_Price__c != null) return this.product.product.Offer_Price__c;
        else return null;
    }

    get pricing() {
        if (this.product?.product?.Price_Description__c != null) {
            return this.product.product.Price_Description__c
                .replaceAll('\n', '<br/>');
        }
        return null;
    }

    get hasMoreInfo() {
        return this.product?.product?.Store_Info__c != null;
    }

    get hasImage() {
        return this.product?.product?.Store_Image__c != null;
    }

    containsMembershipHighlight() {
        return this.product?.product?.Store_Highlight__c != null
            && this.product.product.Store_Highlight__c.toLowerCase().indexOf('membership') >= 0;
    }

    containsBlackHighlight() {
        return this.product?.product?.Store_Highlight__c != null
            && this.product.product.Store_Highlight__c.toLowerCase().indexOf('black friday') >= 0;
    }

    containsPopularHighlight() {
        return this.product?.product?.Store_Highlight__c != null
            && this.product.product.Store_Highlight__c.toLowerCase().indexOf('popular') >= 0;
    }

    get hasHighlight() {
        return this.product?.product?.Store_Highlight__c != null
            && !this.containsBlackHighlight()
            && !this.containsMembershipHighlight()
            && !this.containsPopularHighlight();
    }

    get hasMembershipHighlight() {
        return this.product?.product?.Store_Highlight__c != null
            && !this.containsBlackHighlight()
            && this.containsMembershipHighlight()
            && !this.containsPopularHighlight();
    }

    get hasPopularHighlight() {
        return this.product?.product?.Store_Highlight__c != null
            && !this.containsBlackHighlight()
            && !this.containsMembershipHighlight()
            && this.containsPopularHighlight();
    }

    get hasBlackHighlight() {
        return this.product?.product?.Store_Highlight__c != null
            && this.containsBlackHighlight()
            && !this.containsMembershipHighlight()
            && !this.containsPopularHighlight();
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
        this.backgroundImageStyle = this.imagePositioningStyle(this.product?.product?.Store_Image__c);
        this.upsellAvailable = this.product?.hasUpsells;
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

        // October 24 removing upsells
        // if (!this.upsellAvailable) {
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
        // } else {
        //     this.dispatchEvent(new CustomEvent('offerupsell', {
        //         detail: {
        //             productName: productName,
        //             productId: productId,
        //             productCode: this.product?.product?.ProductCode,
        //             wtgId: wtgId,
        //             dappId: dappId,
        //             appointmentType: appointmentType,
        //             nextSlots: this.nextSlots,
        //             availableFrom: this.product?.availableFrom,
        //             upsellDescription: this.product?.product?.Store_Upsell_Description__c,
        //             upsells: this.product?.upsells,
        //             hidePractitionerList: this.product?.product?.Store_Hide_Practitioner_List__c,
        //             attachmentRequired: this.product?.product?.Store_Attachment_Required__c,
        //             attachmentText: this.product?.product?.Store_Attachment_Text__c,
        //             businessUnit: this.product?.product?.Business_Unit__c,
        //             branding: this.branding
        //         }
        //     }));
        // }
    }

    openConfirmRequirementsModal() {
        this.triggerConfirmRequirementsModal = true;
    }

    closeConfirmRequirementsModal() {
        this.triggerConfirmRequirementsModal = false;
    }

    closeMoreInfoModal() {
        this.triggerMoreInfoModal = false;
    }

    handleProceedFromRequirements() {
        this.closeConfirmRequirementsModal();
        this.allRequirementsAccepted = true;
        this.handleSchedule(null);
    }

    //some images have issues displaying where they should at mobile view :(
    imagePositioningStyle(imgname) {
        if (!imgname) return ''

        let perc = 28;

        if (imgname === 'dental_impant') perc = 50;
        else if (imgname === 'dental_exam_adult') perc = 50;
        else if (imgname === 'dental_exam_child') perc = 50;
        else if (imgname === 'invisalign') perc = 39;
        else if (imgname === 'onl_blood_nurse') perc = 50;
        else if (imgname === 'onl_blood_gp') perc = 38;
        else if (imgname === 'invisalign') perc = 34;
        else if (imgname === 'productimg_gp_inclinic') perc = 9;
        else if (imgname === 'productimg_gp_video') perc = 25;
        else if (imgname === 'productimg_gp_telephone') perc = 0;
        else if (imgname === 'hygiene_adult') perc = 54;
        else if (imgname === 'hygiene_child') perc = 40;
        else if (imgname === 'hygiene_super') perc = 62;
        else if (imgname === 'hygiene_ultra') perc = 41;

        let ret = 'background-image: url(/resource/' + imgname + '); background-position-y: ' + perc + '%;';


        return ret;

    }

    handleMoreInfo(e) {
        this.triggerMoreInfoModal = true;
    }

    handleBookFromModal(e) {
        //todo
    }


}