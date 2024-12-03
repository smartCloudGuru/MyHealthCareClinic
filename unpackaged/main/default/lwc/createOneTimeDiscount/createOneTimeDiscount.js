/**
 * Created 27.1.2022..
 */

import {LightningElement, api} from 'lwc';

import {CloseActionScreenEvent} from 'lightning/actions';

import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import createOneTimeDiscount from '@salesforce/apex/createOneTimeDiscountCtrl.createOneTimeDiscount';
import {NavigationMixin} from 'lightning/navigation';

import canRefund from '@salesforce/customPermission/Can_Refund_Covid_Test';
import canCancel from '@salesforce/customPermission/Can_Cancel_Covid_Test';

export default class CreateOneTimeDiscount extends NavigationMixin(LightningElement) {

    @api recordId;

    chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    family = 'Covid Tests';
    amount = 0;
    code = null;
    valid;
    docoupon;
    docancel;
    dorefund;

    get showCancel() {
        return canCancel;
    }

    get showRefund() {
        return canRefund;
    }

    loading;

    allowsave;

    connectedCallback() {

        this.generateRandomCode();
        this.valid = this.in5days();
    }

    renderedCallback() {
        //console.log('rid', this.recordId);
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    generateRandomCode() {
        this.code = '';
        while (this.code.length < 8) {
            let idx = Math.floor(Math.random() * (this.chars.length));
            this.code += this.chars.substring(idx, idx + 1);
        }

    }

    in5days() {
        let nd = new Date(Date.now().valueOf() + 864E5 * 5);
        return nd.getFullYear() + '-' + (nd.getMonth() + 1) + '-' + nd.getDate();
    }

    handleCreate() {
        let form = {};
        form.recordId = this.recordId;
        if (canCancel && this.template.querySelector('[data-id=docancel]'))
            form.docancel = this.template.querySelector('[data-id=docancel]').checked;
        else form.docancel = false;

        //form.docoupon = this.template.querySelector('[data-id=docoupon]').checked;
        form.docoupon = false;

        if (canRefund && this.template.querySelector('[data-id=dorefund]')) {
            form.dorefund = this.template.querySelector('[data-id=dorefund]').checked;
        } else
            form.dorefund = false;

        if (this.docoupon) {
            form.amount = parseFloat(this.template.querySelector('[data-id=amount]').value);
            form.family = this.template.querySelector('[data-id=family]').value;
            form.code = this.template.querySelector('[data-id=code]').value.trim();
            form.valid = this.template.querySelector('[data-id=valid]').value;
        }
        if (this.dorefund) {
            form.amount = parseFloat(this.template.querySelector('[data-id=amount]').value);
        }

        console.log('form', form);

        let form_valid = false;
        if (this.docoupon) {
            if (form.amount <= 0) this.showNotification('Missing information', 'Please enter a valid amount');
            else if (!form.code || form.code.length === 0) this.showNotification('Missing information', 'Please enter a Coupon Code');
            else form_valid = true;
        }
        if (this.dorefund) {
            if (form.amount <= 0) this.showNotification('Missing information', 'Please enter a valid amount');
            else form_valid = true;
        } else {
            form_valid = true;
        }


        if (form_valid) {
            this.loading = true;
            createOneTimeDiscount({
                form: JSON.stringify(form)
            })
                .then(results => {
                    console.log('::createOneTimeDiscount:result', results);
                    if (!results) {
                        this.showNotification('Unable to create a Coupon', 'Please try to use a different Coupon Code');
                    } else {
                        let dcode = JSON.parse(results);
                        if (dcode.errorMessage) {
                            this.showNotification('Error', dcode.errorMessage);
                        } else if (dcode.couponId) {
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: dcode.couponId,
                                    actionName: 'view'
                                }
                            })
                        } else {
                            if (form.dorefund) this.showOK('Refunded', 'Refund performed');
                            this.closeAction();
                        }
                    }
                })
                .catch(error => {
                    console.error('::createOneTimeDiscount:failed', error);
                    this.showNotification('Unable to create a Coupon', 'Please try to use a different Coupon Code');
                })
                .finally(() => {
                    this.loading = false;
                });
        }

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

    handleDoCouponChange() {
        this.docoupon = this.template.querySelector('[data-id=docoupon]').checked;
        this.allowsave = (this.docoupon === true) || (this.docancel === true) || (this.dorefund === true);
    }

    handleDoCancelChange() {
        this.docancel = this.template.querySelector('[data-id=docancel]').checked;
        this.allowsave = (this.docoupon === true) || (this.docancel === true) || (this.dorefund === true);
    }

    handleDoRefund() {
        this.dorefund = this.template.querySelector('[data-id=dorefund]').checked;
        this.allowsave = (this.docoupon === true) || (this.docancel === true) || (this.dorefund === true);
    }


}