/**
 * Created 13.9.2022..
 */

import {api, LightningElement, wire} from 'lwc';

export default class MemAddModal extends LightningElement {

    @api memberToEdit;
    @api myCustomSettings;

    isAdult;
    isAdd;

    dobDateValid;

    initialValidationDone;

    ddOptions;
    mmOptions;
    yyOptions;

    sameAddressChecked;

    genderOptions = [
        {"value": "Male", "label": "Male"},
        {"value": "Female", "label": "Female"}
    ];

    connectedCallback() {
        this.memberToEdit = JSON.parse(JSON.stringify(this.memberToEdit));
        this.sameAddressChecked = this.memberToEdit.checkAddressSame;

        this.isAdult = !!this.memberToEdit && !!this.memberToEdit.isAdult;
        this.isAdd = !!this.memberToEdit && !!this.memberToEdit.isAdd;


        this.ddOptions = [];
        this.mmOptions = [];
        this.yyOptions = [];


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

        Date.prototype.isSameAs = function (y, m, d) {
            if (this.getTime() !== this.getTime()) return false;

            if (this.getFullYear() !== y) return false;
            if ((this.getMonth() + 1) !== m) return false;
            if (this.getDate() !== d) return false;

            return true;
        };
    }

    renderedCallback() {
        this.isAdult = !!this.memberToEdit && !!this.memberToEdit.isAdult;
        this.isAdd = !!this.memberToEdit && !!this.memberToEdit.isAdd;
        if (!this.isAdd && !this.initialValidationDone)
        {
            this.initialValidationDone = true;
            this.validateDOB();
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleAdd() {

        if (!this.validateForm()) return;

        //collect fields
        this.memberToEdit.dob = this.inputDobDate;

        let fields = this.template.querySelectorAll('[data-id]');
        for (let f of fields) {
            this.memberToEdit[f.dataset.id] = f.value;
        }

        this.memberToEdit.checkAddressSame = this.sameAddressChecked;

        this.dispatchEvent(new CustomEvent('add', {detail: this.memberToEdit}));
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

        valid = valid && this.validateDOB();

        valid = valid && this.validateEmail2();

        //console.log('::mdl:vld:ret', valid);
        return valid;
    }

    checkDateIsValid(y, m, d) {
        let dte = new Date(y + '/' + m + '/' + d);

        if (!dte.isSameAs(y, m, d)) return null; else return (
            y + '-' +
            (m < 10 ? '0' + m : m)
            + '-' +
            (d < 10 ? '0' + d : d));
    }

    validateDOB() {

        this.dobDateValid = false;

        let f_dobD = this.template.querySelector('[data-id="dob_d"]');
        let f_dobM = this.template.querySelector('[data-id="dob_m"]');
        let f_dobY = this.template.querySelector('[data-id="dob_y"]');

        if (!f_dobD || !f_dobY || !f_dobM) return;

        if (f_dobD && f_dobM && f_dobY && f_dobD.value && f_dobM.value && f_dobY.value) {
            this.inputDobDate = this.checkDateIsValid(
                parseInt(f_dobY.value),
                parseInt(f_dobM.value),
                parseInt(f_dobD.value));
        }

        this.dobDateValid = (this.inputDobDate != null);

        if (this.dobDateValid) {
            if (this.isAdult) {
                if (new Date().getFullYear() - parseInt(f_dobY.value) < 18) this.dobDateValid = false;
                else if ((new Date().getFullYear() - parseInt(f_dobY.value)) === 18) {
                    if (((new Date().getMonth() + 1) < parseInt(f_dobM.value))) this.dobDateValid = false;
                    else if (((new Date().getMonth() + 1) === parseInt(f_dobM.value))) {
                        if (((new Date().getDate()) < parseInt(f_dobD.value))) this.dobDateValid = false;
                    }
                }
            } else {
                if (new Date().getFullYear() - parseInt(f_dobY.value) > 18) {
                    this.dobDateValid = false;
                } else if ((new Date().getFullYear() - parseInt(f_dobY.value)) === 18) {
                    if (((new Date().getMonth() + 1) > parseInt(f_dobM.value))) {
                        this.dobDateValid = false;
                    } else if (((new Date().getMonth() + 1) === parseInt(f_dobM.value))) {
                        if (((new Date().getDate()) >= parseInt(f_dobD.value))) {
                            this.dobDateValid = false;
                        }
                    }
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

        //console.log('ev', event);
        //console.log('ev.det', event.detail);
        //console.log('ev.det.st', event.detail.searchTerm);
        if (!event || !event.detail || !event.detail.searchTerm) return;
        const target = event.target;

        let query = event.detail.searchTerm;

        // console.log('query0', query);
        // console.log('this.myCustomSettings', this.myCustomSettings);

        if (query && query.length >= 2) {
            if (query.length > 16) query = query.substring(0, 16);
            //console.log('a');
            this.provisionalPostCode = query;

            query = query.replace(/[^a-z0-9 ]/gi, ''); //.replace(/[ ]/gi,'+');

            //console.log('b');
            //if (this.dev) console.log('query1', query);

            let xmlHttp = new XMLHttpRequest();
            xmlHttp.onreadystatechange = function () {
                //console.log('c');
                if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
                    //if (this.dev) console.log(xmlHttp.responseText);
                    //console.log('d');
                    //console.log(xmlHttp.responseText);
                    let res = JSON.parse(xmlHttp.responseText);
                    let list = [];
                    if (res && res.result && res.result.total > 0 && res.result.hits && res.result.hits.length > 0) {

                        for (let hit of res.result.hits) {
                            // if (this.dev) console.log('hit', hit);
                            list.push({id: hit.postcode + '#' + hit.uprn, title: hit.postcode, subtitle: hit.line_1 + ' ' + hit.line_2, data: hit});
                        }
                        //console.log('list', list);
                    }

                    target.setSearchResults(list);
                } else {
                    //console.error(':handlePostcodeSearch:onreadystatechange:status', xmlHttp.status);
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

    handleSameAddress(e)
    {
        this.sameAddressChecked = e.currentTarget.checked;
    }

    validateEmail2() {
        let f1 = this.template.querySelector('[data-id=email]');
        let f2 = this.template.querySelector('[data-id=email2]');

        let valid = true;
        if (f1 && f2) {
            valid = (f1.value === f2.value);
            if  (valid)
            {
                f2.setCustomValidity('');
            } else {
                f2.setCustomValidity('nope');
            }

            f2.showHelpMessageIfInvalid();
            f2.reportValidity();
        }

        return valid;
    }
}