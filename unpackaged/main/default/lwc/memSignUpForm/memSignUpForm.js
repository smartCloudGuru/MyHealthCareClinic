/**
 * Created 12.9.2022..
 */

import contactPhone from '@salesforce/label/c.Store_Contact_Phone';

import {api, LightningElement, wire} from 'lwc';

import getCustomSettings from '@salesforce/apex/memSignUpCtrl.getCustomSettings';
import getPrices from '@salesforce/apex/memSignUpCtrl.aura_getPrices';
import getAccount from '@salesforce/apex/memSignUpCtrl.aura_getAccount';
import processSignupRequest from '@salesforce/apex/memSignUpCtrl.processSignupRequest';
import checkDiscountCodeForMonths from '@salesforce/apex/memSignUpCtrl.aura_checkDiscountCodeForMonths';

export default class MemSignUpForm extends LightningElement {

    @api queryParameters;
    @api config;

    @wire(getCustomSettings)
    myCustomSettings;

    enabledGoCardless = true;

    genderOptions = [
        {"value": "Male", "label": "Male"},
        {"value": "Female", "label": "Female"}
    ];

    loading = false;
    saving = false;
    saved = false;
    dataReady = false;
    saveError = false;
    _contactPhone = contactPhone;
    dobDateValid;
    memberEdit;
    memberRemove;
    memberRemoveText;

    needsDDSetup = true;

    refCodeResponse;

    preselectedAccountId;
    prefilled = false;

    form;

    tierOptions = [
        {label: 'Dental', value: 'Dental'},
        {label: 'GP', value: 'GP'},
        {label: 'Complete', value: 'Complete'},
        {label: 'Premium', value: 'Premium'}
    ];

    ddebitOptions = [
        {label: 'Setup direct debit online', value: '1'},
        {label: 'Contact me to set up direct debit', value: '0'}
    ]

    ddOptions;
    mmOptions;
    yyOptions;

    adultMembers = [];
    childMembers = [];

    triggerOpenModal;
    triggerOpenConfirmRemoveModal;
    triggerTACModal;

    planSelected;
    pricesPerPlan;

    get totalPrice() {
        return (1 + this.adultMembers.length) * this.pricesPerPlan[this.planSelected].adult + (this.childMembers.length) * this.pricesPerPlan[this.planSelected].child;
    }

    get css_box_planSelected() {
        return 'box2 ' + this.planSelected;
    }

    get showAddChild() {
        return this.childMembers.length <= this.adultMembers.length;
    }

    get adultsAndChildren() {
        let ret = '';
        if (this.adultMembers.length === 0) ret = '1 adult';
        else ret = (this.adultMembers.length + 1) + ' adults'

        if (this.childMembers.length === 1) ret += ' and 1 child';
        else if (this.childMembers.length > 1) ret += ' and ' + this.childMembers.length + ' children';
        return ret;
    }

    connectedCallback() {
        console.log('cc', JSON.stringify(this.queryParameters));
        this.form = {};

        this.ddOptions = [];
        this.mmOptions = [];
        this.yyOptions = [];

        this.adultMembers = [];
        this.childMembers = [];

        for (let i = 1; i <= 31; i++) {
            this.ddOptions.push({"value": '' + i, "label": '' + i})
        }

        for (let i = 1; i <= 12; i++) {
            this.mmOptions.push({"value": '' + i, "label": '' + i})
        }

        let yearNow = new Date().getFullYear();
        for (let i = yearNow; i > yearNow - 120; i--) {
            this.yyOptions.push({"value": '' + i, "label": '' + i})
        }

        this.getPricesPerPlan();

        if (this.queryParameters.a && this.queryParameters.b)
        {
            this.getExistingAccount();
        }

        Date.prototype.isSameAs = function (y, m, d) {
            if (this.getTime() !== this.getTime()) return false;

            if (this.getFullYear() !== y) return false;
            if ((this.getMonth() + 1) !== m) return false;
            if (this.getDate() !== d) return false;

            return true;
        };
    }

    getExistingAccount()
    {
        getAccount({id:this.queryParameters.a, pid:this.queryParameters.b})
            .then(results => {
                console.log('::getAccount:results', results);
                //prefill data if this form was used inside SF with a preselected main payer account
                if (results) {
                    let acc = JSON.parse(results);
                    this.prefilled = true;
                    this.preselectedAccountId = acc.Id;
                    this.form = {};
                    this.form.firstName = acc.FirstName;
                    this.form.lastName = acc.LastName;
                    this.form.email = acc.PersonEmail;
                    this.form.email2 = acc.PersonEmail;
                    this.form.gender = acc.Gender__c;
                    this.form.phone = acc.Phone;
                    this.form.address1 = acc.BillingStreet;
                    this.form.city = acc.BillingCity;
                    this.form.postalCode = acc.BillingPostalCode;
                    if (acc.Date_of_Birth__c)
                    {
                        let dobParts = acc.Date_of_Birth__c.split('-');
                        if (dobParts.length===3)
                        {
                            this.form.dob_d = '' + parseInt(dobParts[2]);
                            this.form.dob_m = '' + parseInt(dobParts[1]);
                            this.form.dob_y = '' + parseInt(dobParts[0]);
                        }
                    }
                }
            })
            .catch(error => {
                console.error('::getAccount:failed', error);
            })
            .finally(() => {
                //
            });
    }


    getPricesPerPlan() {
        getPrices()
            .then(results => {
                //console.log('::getPrices:results', results);
                if (results) {
                    this.pricesPerPlan = JSON.parse(results);
                    this.dataReady = true;
                }
            })
            .catch(error => {
                console.error('::getPrices:failed', error);
            })
            .finally(() => {
                //
            });
    }

    renderedCallback() {
        //console.log('as:', this.adultMembers);
        //console.log('cs:', this.childMembers);
    }

    handleAddAdult(e) {

        this.memberEdit = {};
        this.memberEdit.isAdult = true;
        this.memberEdit.isAdd = true;

        // console.log('ha:memberEdit', this.memberEdit);
        this.openModal();


        // this.adultMembers.push({id: 'A' + this.adultMembers.length, isAdult: true});
        // console.log('a:', this.adultMembers);
        // this.adultMembers = this.adultMembers.splice(0);
        // console.log('a2:', this.adultMembers);

        // this.childMembers.push({id: 'C' + this.childMembers.length, isAdult: false});
        // this.childMembers = this.childMembers.splice(0);
        // console.log('c:', this.childMembers);
    }

    handleAddChild(e) {

        //can not add more than 1 child per adult
        if (this.childMembers.length > this.adultMembers.length) {
            return;
        }

        this.memberEdit = {};
        this.memberEdit.isChild = true;
        this.memberEdit.isAdd = true;
        // console.log('hc:memberEdit', this.memberEdit);
        this.openModal();


    }

    checkDateIsValid(y, m, d) {
        let dte = new Date(y + '/' + m + '/' + d);

        if (!dte.isSameAs(y, m, d)) return null; else return (
            y + '-' +
            (m < 10 ? '0' + m : m)
            + '-' +
            (d < 10 ? '0' + d : d));
    }

    // validates if the entered date + month + year is a valid date
    validateDOB18() {

        this.dobDateValid = false;

        let f_dobD = this.template.querySelector('[data-id="dob_d"]');
        let f_dobM = this.template.querySelector('[data-id="dob_m"]');
        let f_dobY = this.template.querySelector('[data-id="dob_y"]');

        if (f_dobD && f_dobM && f_dobY && f_dobD.value && f_dobM.value && f_dobY.value) {
            this.inputDobDate = this.checkDateIsValid(
                parseInt(f_dobY.value),
                parseInt(f_dobM.value),
                parseInt(f_dobD.value));
        }

        this.dobDateValid = (this.inputDobDate != null);

        if (this.dobDateValid) {
            if (new Date().getFullYear() - parseInt(f_dobY.value) < 18) this.dobDateValid = false;
            else if ((new Date().getFullYear() - parseInt(f_dobY.value)) === 18) {
                if (((new Date().getMonth() + 1) < parseInt(f_dobM.value))) this.dobDateValid = false;
                else if (((new Date().getMonth() + 1) === parseInt(f_dobM.value))) {
                    if (((new Date().getDate()) < parseInt(f_dobD.value))) this.dobDateValid = false;
                }
            }

        }

        if (!this.dobDateValid) {
            f_dobY.setCustomValidity('nope');
            f_dobM.setCustomValidity('nope');
            f_dobD.setCustomValidity('nope');
        } else {
            f_dobY.setCustomValidity('');
            f_dobM.setCustomValidity('');
            f_dobD.setCustomValidity('');
        }

        f_dobY.showHelpMessageIfInvalid();
        f_dobM.showHelpMessageIfInvalid();
        f_dobD.showHelpMessageIfInvalid();

        return this.dobDateValid;

    }

    handlePostcodeSearch(event) {

        if (!event || !event.detail || !event.detail.searchTerm) return;
        const target = event.target;

        let query = event.detail.searchTerm;

        // console.log('query0', query);
        // console.log('this.myCustomSettings', this.myCustomSettings);

        if (query && query.length >= 2) {
            if (query.length > 16) query = query.substring(0, 16);

            this.provisionalPostCode = query;

            query = query.replace(/[^a-z0-9 ]/gi, ''); //.replace(/[ ]/gi,'+');

            //if (this.dev) console.log('query1', query);

            let xmlHttp = new XMLHttpRequest();
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
                    //if (this.dev) console.log(xmlHttp.responseText);
                    let res = JSON.parse(xmlHttp.responseText);
                    let list = [];
                    if (res && res.result && res.result.total > 0 && res.result.hits && res.result.hits.length > 0) {

                        for (let hit of res.result.hits) {
                            // if (this.dev) console.log('hit', hit);
                            list.push({id: hit.postcode + '#' + hit.uprn, title: hit.postcode, subtitle: hit.line_1 + ' ' + hit.line_2, data: hit});
                        }
                        // if (this.dev) console.log('list', list);
                    }

                    target.setSearchResults(list);
                } else {
                    // console.error(':handlePostcodeSearch:onreadystatechange:status', xmlHttp.status);
                }
            }

            let apikey = '';
            if (this.myCustomSettings && this.myCustomSettings.data) {
                apikey = this.myCustomSettings.data;
                xmlHttp.open("GET", 'https://api.ideal-postcodes.co.uk/v1/addresses?api_key=' + apikey + '&query=' + query, true); // true for asynchronous
                xmlHttp.send(null);
            }
        }
    }

    handlePostcodeSelection(event) {

        let subform = event.target.name;

        let al1Node = this.template.querySelector('[data-id="address1"]');
        let al2Node = this.template.querySelector('[data-id="address2"]');
        let al3Node = this.template.querySelector('[data-id="address3"]');
        let postalcodeNode = this.template.querySelector('[data-id="postalCode"]');
        let cityNode = this.template.querySelector('[data-id="city"]');
        let countyNode = this.template.querySelector('[data-id="county"]');

        if (event && event.detail && event.detail.length > 0 && event.detail[0].id && event.detail[0].data) {
            let hit = event.detail[0].data;
            if (this.dev) console.log('selected ev', JSON.stringify(hit));


            if (al1Node) {
                al1Node.value = hit.line_1;
                al1Node.showHelpMessageIfInvalid();
            }
            if (al2Node) {
                al2Node.value = hit.line_2;
                al2Node.showHelpMessageIfInvalid();
            }
            if (al3Node) {
                al3Node.value = hit.line_3;
                al3Node.showHelpMessageIfInvalid();
            }
            if (cityNode) {
                cityNode.value = hit.post_town;
                cityNode.showHelpMessageIfInvalid();
            }
            if (postalcodeNode) {
                postalcodeNode.value = hit.postcode;
                postalcodeNode.showHelpMessageIfInvalid();
            }
            if (countyNode) {
                countyNode.value = hit.county;
                countyNode.showHelpMessageIfInvalid();
            }
        } else {
            if (al1Node) {
                al1Node.value = null;
                al1Node.showHelpMessageIfInvalid();
            }
            if (al2Node) {
                al2Node.value = null;
                al2Node.showHelpMessageIfInvalid();
            }
            if (al3Node) {
                al3Node.value = null;
                al3Node.showHelpMessageIfInvalid();
            }
            if (cityNode) {
                cityNode.value = null;
                cityNode.showHelpMessageIfInvalid();
            }
            if (postalcodeNode) {
                postalcodeNode.value = null;
                postalcodeNode.showHelpMessageIfInvalid();
            }
            if (countyNode) {
                countyNode.value = null;
                countyNode.showHelpMessageIfInvalid();
            }

        }
    }

    openModal() {
        this.triggerOpenModal = true;
    }

    closeModal() {
        this.triggerOpenModal = false;
    }

    openConfirmRemoveModal() {
        this.triggerOpenConfirmRemoveModal = true;
    }

    closeConfirmRemoveModal() {
        this.triggerOpenConfirmRemoveModal = false;
    }

    handleAddFromModal(e) {
        let modalData = JSON.parse(JSON.stringify(e.detail));
        this.closeModal();
        if (modalData.isAdd) {
            //console.log('::mf:onadd:isAdd', modalData);
            if (modalData.isAdult) {
                modalData.id = 'A' + this.adultMembers.length + Date.now();
                this.adultMembers.push(modalData);
                this.adultMembers = this.adultMembers.splice(0);
                //console.log('a2:', this.adultMembers);
            } else {
                modalData.id = 'C' + this.childMembers.length + Date.now();
                this.childMembers.push(modalData);
                this.childMembers = this.childMembers.splice(0);
                //console.log('c:', this.childMembers);
            }
        } else {
            // console.log('::mf:onadd:isEdit', modalData);
            this.memberRemove = modalData;
            this.handleYesRemove();
            if (modalData.isAdult) {
                this.adultMembers.push(modalData);
                this.adultMembers = this.adultMembers.splice(0);
                //console.log('a2:', this.adultMembers);
            } else {
                this.childMembers.push(modalData);
                this.childMembers = this.childMembers.splice(0);
                //console.log('c:', this.childMembers);
            }
        }
    }

    handlePlanChange(e) {
        this.planSelected = e.target.value;
    }

    handleRowEdit(e) {
        //console.log('edit', e.detail);
        this.memberEdit = null;

        for (let ad of this.adultMembers) {
            // console.log(ad);
            if (ad.id === e.detail) {
                this.memberEdit = ad;
                break;
            }
        }

        if (!this.memberEdit) {
            for (let ad of this.childMembers) {
                // console.log(ad);
                if (ad.id === e.detail) {
                    this.memberEdit = ad;
                    break;
                }
            }
        }

        //console.log(this.memberEdit);
        if (!!this.memberEdit) {
            this.memberEdit.isAdd = false;
            this.openModal();
        }

    }

    handleRowRemove(e) {
        // console.log('remove', e.detail);

        this.memberRemove = null;

        for (let ad of this.adultMembers) {
            if (ad.id === e.detail) {
                this.memberRemove = ad;
                break;
            }
        }

        if (!this.memberRemove) {
            for (let ad of this.childMembers) {
                if (ad.id === e.detail) {
                    this.memberRemove = ad;
                    break;
                }
            }
        }

        //console.log(this.memberRemove);
        if (!!this.memberRemove) {
            let text = this.memberRemove.firstName + ' ' + this.memberRemove.lastName;
            this.memberRemoveText = 'Are you sure you wish to remove ' + text + ' from the list?';
            this.openConfirmRemoveModal();
        }
    }

    handleYesRemove() {

        this.adultMembers2 = [];
        for (let ad of this.adultMembers) {
            if (ad.id !== this.memberRemove.id) {
                this.adultMembers2.push(ad);
            }
        }
        this.adultMembers = this.adultMembers2.splice(0);

        this.childMembers2 = [];
        for (let ad of this.childMembers) {
            if (ad.id !== this.memberRemove.id) {
                this.childMembers2.push(ad);
            }
        }
        this.childMembers = this.childMembers2.splice(0);

        this.closeConfirmRemoveModal();
    }

    handleSubmit(e) {

        let fields = this.template.querySelectorAll('[data-id]');

        this.form = {};

        for (let f of fields) {

            if (f.dataset.id) {
                this.form[f.dataset.id] = f.value;
                if (('' + f.getAttribute('class')).indexOf('onl-check') >= 0) this.form[f.dataset.id] = f.checked;
            }
        }

        this.form.adultMembers = this.adultMembers;
        this.form.childMembers = this.childMembers;

        if (!this.enabledGoCardless) this.form.ddselected = '0';
        // console.log('::msf:form', this.form);

        if (!this.validateForm()) return;

        for (let am of this.form.adultMembers) {
            if (am.checkAddressSame === true) {
                am.address1 = this.form.address1;
                am.address2 = this.form.address2;
                am.address3 = this.form.address3;
                am.city = this.form.city;
                am.postalCode = this.form.postalCode;
            }
        }

        for (let am of this.form.childMembers) {
            if (am.checkAddressSame === true) {
                am.address1 = this.form.address1;
                am.address2 = this.form.address2;
                am.address3 = this.form.address3;
                am.city = this.form.city;
                am.postalCode = this.form.postalCode;
            }
        }

        this.form.ddselected = '1';

        this.form.accountId = this.preselectedAccountId;

        let formAsString = JSON.stringify(this.form);


        this.saving = true;

        //processSignupRequest({params: formAsString})
        processSignupRequest({params: formAsString})
            .then(results => {
                // console.log('::processSignupRequest:results', results);
                if (results) {
                    let res = JSON.parse(results);
                    if (res.errorCode) {
                        console.error('::msf:psr:res', results);
                        this.saveError = true;
                        this.saving = false;
                    } else {
                        if (res.redirectUrl) window.location = res.redirectUrl;
                        else {
                            this.saved = true;
                            this.saving = false;
                        }
                    }
                } else {
                    console.error('::msf:psr:res null', results);
                    this.saveError = true;
                    this.saving = false;
                }
            })
            .catch(error => {
                this.saveError = true;
                console.error('::processSignupRequest:failed', error);
                this.saving = false;
            })
            .finally(() => {

            });

    }

    validateForm() {
        let fields = this.template.querySelectorAll('[data-id]');
        //console.log('::mdl:vld:fs', fields);

        let valid = true;

        for (let f of fields) {

            if (f.showHelpMessageIfInvalid) f.showHelpMessageIfInvalid();
            if (f.validateRequired) f.validateRequired();
            if (f.reportValidity) f.reportValidity();
            //console.log(f.value, ':validation: ', (f.dataset) ? f.dataset.id : null);

            if ((f.required === true) && (f.value == null || f.value.length === 0)) {

                //if it's checkbox, treat its value as checked state
                if (('' + f.getAttribute('class')).indexOf('onl-check') >= 0) {
                    if (!f.checked) {
                        //console.log('::mdl:vld:failed required', (f.dataset) ? f.dataset.id : null);
                        valid = false;
                    }
                } else {
                    //console.log('::mdl:vld:failed required', (f.dataset) ? f.dataset.id : null);
                    valid = false;
                }
            }
        }

        valid = valid && this.validateDOB18();

        valid = valid && this.validateEmail2();

        //console.log('::mdl:vld:ret', valid);
        return valid;
    }

    handleDDSelectedChange(e) {
        let value = e.target.value;
        this.needsDDSetup = (value === '1');
    }

    validateEmail2() {
        let f1 = this.template.querySelector('[data-id=email]');
        let f2 = this.template.querySelector('[data-id=email2]');

        let valid = true;
        if (f1 && f2) {
            valid = (f1.value === f2.value);
            if (valid) {
                f2.setCustomValidity('');
            } else {
                f2.setCustomValidity('nope');
            }

            f2.showHelpMessageIfInvalid();
            f2.reportValidity();
        }

        return valid;
    }

    openTACModal() {
        this.triggerTACModal = true;
    }

    closeTACModal() {
        this.triggerTACModal = false;
    }

    handleRefCodeBlur(e) {
        let value = e.currentTarget.value;
        if (value == null || value.trim() === '') {
            this.refCodeResponse = null;
            return;
        }
        checkDiscountCodeForMonths({code: value})
            .then(results => {
                    //console.log('::checkDiscountCodeForMonths:results', results);
                    if (results && results.indexOf('✓') === 0) {
                        if (results.indexOf(' 1 ') > 0) {
                            this.refCodeResponse = results.replace(' 1 ', ' 1 month Free Membership Activated – your Direct debit will start one month from now');
                        } else {
                            this.refCodeResponse = results + ' months Free Membership Activated';
                        }
                    } else {
                        this.refCodeResponse = 'Not a valid code';
                    }
                }
            )
            .catch(error => {
                    this.refCodeResponse = null;
                    console.error('::checkDiscountCode:failed', error);
                }
            )
            .finally(() => {
            });


    }

}