import {api, wire, LightningElement} from 'lwc';

import getWTGs from '@salesforce/apex/TLPController.getTLCPortalWorkTypeGroups';
import getCustomSettings from '@salesforce/apex/TLPController.getCustomSettings';
import getAvailableSlots from '@salesforce/apex/TLPController.aura_getTlpAvailability';
import getServiceTerritoryMembers from '@salesforce/apex/TLPController.getServiceTerritoryMembers';
import doSubmit from '@salesforce/apex/TLPController.doSubmit';
import LOCALE from '@salesforce/i18n/locale';

export default class TLPMain extends LightningElement {

    @api queryParameters;
    @api storeConfig;

    selectedDate;
    selectedWorkTypeGroupId;
    selectedAppointmentName;
    loadingSlots;
    loading;
    submitting;

    resourceSelected;
    resourceOptions;
    selectedSlot;

    currentSlotsDay0;
    currentSlotsDay1;
    currentSlotsDay2;

    selectedDateP0;
    selectedDateP1;
    selectedDateP2;

    appTypeOptions; //appointment types

    ddOptions;
    mmOptions;
    yyOptions;

    @wire(getCustomSettings)
    myCustomSettings;

    errorModalText;
    showErrorModal;
    showSuccessModal;

    dont_clear_form = true;

    formFields = {};

    allResources = []; // will contain an id and name of all resources found

    get hasSlotsDay0() {
        return (this.currentSlotsDay0 && this.currentSlotsDay0.length > 0);
    }

    get hasSlotsDay1() {
        return (this.currentSlotsDay1 && this.currentSlotsDay1.length > 0);
    }

    get hasSlotsDay2() {
        return (this.currentSlotsDay2 && this.currentSlotsDay2.length > 0);
    }

    get canSearch() {
        return (!!this.selectedDate && !!this.selectedWorkTypeGroupId);
    }

    get displayFormCSS() {
        if (this.canSearch) return "form-visible";
        else return "form-not-visible";
    }

    genderOptions = [
        {"value": "Male", "label": "Male"},
        {"value": "Female", "label": "Female"}
    ];

    connectedCallback() {
        //this.searchSlots();
        this.getWorkTypeGroupOptions();
        this.retrievePractitioners();

        this.ddOptions = [];
        this.mmOptions = [];
        this.yyOptions = [];

        for (let i = 1; i <= 31; i++) {
            this.ddOptions.push({"value": '' + i, "label": '' + i})
        }

        this.mmOptions.push({"value": '1', "label": 'January'});
        this.mmOptions.push({"value": '2', "label": 'February'});
        this.mmOptions.push({"value": '3', "label": 'March'});
        this.mmOptions.push({"value": '4', "label": 'April'});
        this.mmOptions.push({"value": '5', "label": 'May'});
        this.mmOptions.push({"value": '6', "label": 'June'});
        this.mmOptions.push({"value": '7', "label": 'July'});
        this.mmOptions.push({"value": '8', "label": 'August'});
        this.mmOptions.push({"value": '9', "label": 'September'});
        this.mmOptions.push({"value": '10', "label": 'October'});
        this.mmOptions.push({"value": '11', "label": 'November'});
        this.mmOptions.push({"value": '12', "label": 'December'});

        let yearNow = new Date().getFullYear();
        for (let i = yearNow; i > yearNow - 123; i--) {
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

    retrievePractitioners() {
        getServiceTerritoryMembers()
            .then(result => {
                console.log('::getServiceTerritoryMembers:result', result);

                if (result) {
                    let response = JSON.parse(result);
                    response.forEach(res => {
                        let gender = '';
                        if (res.ServiceResource.Gender__c === 'Male') gender = ' (M)';
                        if (res.ServiceResource.Gender__c === 'Female') gender = ' (F)';
                        this.allResources[res.ServiceResourceId] = res.ServiceResource?.Name + gender;
                    });
                }
            })
            .catch(error => {
                console.error('::getServiceTerritoryMembers:failed', error);
            })
            .finally(() => {

            });

    }

    getWorkTypeGroupOptions() {
        getWTGs()
            .then(results => {
                console.log('::getWTGs:result', results);
                this.appTypeOptions = JSON.parse(results);
            })
            .catch(error => {
                console.error('::getWTGs:failed', error);
                this.appTypeOptions = [];

            })
            .finally(() => {

            });
    }

    searchSlots() {

        if (!this.selectedDate) {
            this.selectedDate = this.dateToDatepickerDate(new Date());
        }

        console.log('::searchSlots:wtgid', this.selectedWorkTypeGroupId);
        console.log('::searchSlots:sd', this.selectedDate);

        if (!this.selectedWorkTypeGroupId) return;


        let req =
            {
                dateFrom: this.selectedDate,
                selectedWorkTypeGroupId: this.selectedWorkTypeGroupId
            }
        console.log('::getAvailableSlots:req', req);

        this.loadingSlots = true;

        getAvailableSlots(req)
            .then(results => {
                console.log('::getAvailableSlots:result', results);
                this.receivedSlots = JSON.parse(results);
                console.log('::getAvailableSlots:territorySlots', this.receivedSlots.territorySlots);
                this.parseNextSlotsToArrays(this.receivedSlots);
            })
            .catch(error => {
                console.error('::getAvailableSlots:failed', error);
                this.currentSlotsDay0 = [];
                this.currentSlotsDay1 = [];
                this.currentSlotsDay2 = [];
            })
            .finally(() => {
                this.loadingSlots = false;
            });
    }

    parseNextSlotsToArrays(nextSlots) {

        this.currentSlotsDay0 = [];
        this.currentSlotsDay1 = [];
        this.currentSlotsDay2 = [];

        let day0date = new Date(Date.parse(this.selectedDate));
        let day1date = new Date(Date.parse(this.selectedDate) + 1000 * 60 * 60 * 24);
        let day2date = new Date(Date.parse(this.selectedDate) + 2000 * 60 * 60 * 24);

        this.selectedDateP0 = day0date.getTime();
        this.selectedDateP1 = day1date.getTime();
        this.selectedDateP2 = day2date.getTime();

        let day0 = (day0date.getDate() < 10 ? '0' + day0date.getDate() : '' + day0date.getDate()) + 'T';
        let day1 = (day1date.getDate() < 10 ? '0' + day1date.getDate() : '' + day1date.getDate()) + 'T';
        let day2 = (day2date.getDate() < 10 ? '0' + day2date.getDate() : '' + day2date.getDate()) + 'T';

        //if (this.dev) console.log(day0 + ' ' + day1 + ' ' + day2);

        console.log('::receivedSlots', nextSlots);

        if (nextSlots && nextSlots.territorySlots) {

            //this.buildResourceOptions(nextSlots.territorySlots);

            for (let nextSlot of nextSlots.territorySlots) {

                if (nextSlot.startTime) {
                    let label = new Intl.DateTimeFormat(LOCALE,
                        {
                            timeZone: "Europe/London",
                            hour: "2-digit",
                            minute: "2-digit",
                            hour12: false,
                        })
                        .format(Date.parse(nextSlot.startTime));


                    let firstResourceName = '';

                    if (nextSlot.resources && nextSlot.resources.length>0) firstResourceName = this.allResources[nextSlot.resources[0]];

                    if (nextSlot.startTime.indexOf(day0) > 0) {
                        //console.log('... ... added to slots0');
                        this.currentSlotsDay0.push({
                            label: label,
                            startTime: nextSlot.startTime,
                            endTime: nextSlot.endTime,
                            resources: nextSlot.resources,
                            tooltip: firstResourceName,
                            resource_locations: nextSlot.resource_locations
                        });
                    } else if (nextSlot.startTime.indexOf(day1) > 0) {
                        //console.log('... ... added to slots1');
                        this.currentSlotsDay1.push({
                            label: label,
                            startTime: nextSlot.startTime,
                            endTime: nextSlot.endTime,
                            resources: nextSlot.resources,
                            tooltip: firstResourceName,
                            resource_locations: nextSlot.resource_locations
                        });
                    } else if (nextSlot.startTime.indexOf(day2) > 0) {
                        //console.log('... ... added to slots2');
                        this.currentSlotsDay2.push({
                            label: label,
                            startTime: nextSlot.startTime,
                            endTime: nextSlot.endTime,
                            resources: nextSlot.resources,
                            tooltip: firstResourceName,
                            resource_locations: nextSlot.resource_locations
                        });
                    }
                }
            }

            console.log('current slots by days', this.currentSlotsDay0, this.currentSlotsDay1, this.currentSlotsDay2);
        }
    }

    handleDateInputChange(event) {
        this.selectedDate = event.currentTarget.value;
        this.searchSlots();
    }

    handleAppointmentTypeChanged(event) {
        this.selectedWorkTypeGroupId = event.currentTarget.value;
        this.selectedAppointmentName = "";

        for (let option of this.appTypeOptions) {
            if (option.value === this.selectedWorkTypeGroupId) this.selectedAppointmentName = option.label;
        }

        this.searchSlots();
    }

    handleDayPlus(e) {
        if (this.selectedDate) {
            this.selectedDate = this.addDaysToISODate(this.selectedDate, 3);
            this.searchSlots();
        }
    }

    handleDayMinus(e) {
        if (this.selectedDate) {
            this.selectedDate = this.addDaysToISODate(this.selectedDate, -3);
            this.searchSlots();
        }
    }

    handlePostcodeSearch(event) {

        if (!event || !event.detail || !event.detail.searchTerm) return;
        const target = event.target;

        let query = event.detail.searchTerm;

        if (query && query.length >= 2) {
            if (query.length > 16) query = query.substring(0, 16);

            this.provisionalPostCode = query;

            query = query.replace(/[^a-z0-9 ]/gi, ''); //.replace(/[ ]/gi,'+');

            let xmlHttp = new XMLHttpRequest();
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
                    //console.log(xmlHttp.responseText);
                    let res = JSON.parse(xmlHttp.responseText);
                    let list = [];
                    if (res && res.result && res.result.total > 0 && res.result.hits && res.result.hits.length > 0) {

                        for (let hit of res.result.hits) {
                            list.push({
                                id: hit.postcode + '#' + hit.uprn,
                                title: hit.postcode,
                                subtitle: hit.line_1 + ' ' + hit.line_2,
                                data: hit
                            });
                        }
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

        let al1Node = this.template.querySelector('[data-formfield="address1"]');
        let al2Node = this.template.querySelector('[data-formfield="address2"]');
        let al3Node = this.template.querySelector('[data-formfield="address3"]');
        let postalcodeNode = this.template.querySelector('[data-formfield="postalCode"]');
        let cityNode = this.template.querySelector('[data-formfield="city"]');
        let countyNode = this.template.querySelector('[data-formfield="county"]');

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

    handleTimeSlotSelected(e) {
        this.errorMessage = null;

        //find the slot by start date
        this.selectedSlot = null;

        for (let sl of this.currentSlotsDay0) {
            if (sl.startTime === e.currentTarget.dataset.start) {
                this.selectedSlot = sl;
                break;
            }
        }
        if (!this.selectedSlot) for (let sl of this.currentSlotsDay1) {
            if (sl.startTime === e.currentTarget.dataset.start) {
                this.selectedSlot = sl;
                break;
            }
        }
        if (!this.selectedSlot) for (let sl of this.currentSlotsDay2) {
            if (sl.startTime === e.currentTarget.dataset.start) {
                this.selectedSlot = sl;
                break;
            }
        }

        if (!this.selectedSlot) {
            console.error('::htss:ns');
            return;
        }

        console.log('::htss:selectedSlot', this.selectedSlot);

        //by default choose the first GP
        if (!this.filterByResource) this.resourceSelected = this.selectedSlot.resources[0];
        else this.resourceSelected = this.filterByResource;

        console.log('::htss:resourceSelected', this.resourceSelected);

    }

    handleBackToSlots() {
        this.selectedSlot = null;
        this.searchSlots();
    }

    validateForm() {

        let ret = true;

        this.formFields = {};
        this.formFields.addons = '';

        let nodes = this.template.querySelectorAll('[data-formfield]');

        for (let node of nodes) {
            let fieldName = node.getAttribute('data-formfield');
            if (!!node && !!fieldName) {
                if (fieldName.indexOf('addon') >= 0) {
                    if (node.checked) this.formFields.addons += node.label + ';';
                } else this.formFields[fieldName] = node.value;
            }
            if (!!node && !!node.reportValidity) {
                let v = node.reportValidity();
                ret = ret && v;
            }
        }

        ret = ret && this.validateDOB();

        return ret;
    }


    // DO SUBMIT
    doSubmit() {
        let validForm = this.validateForm() && !!this.selectedSlot;

        if (!validForm) return;

        this.formFields.selectedDate = this.selectedDate;
        this.formFields.timeSelected = this.selectedSlot?.startTime;
        this.formFields.timeSelectedEnd = this.selectedSlot?.endTime;
        this.formFields.selectedResource = this.selectedSlot?.resources[0];
        this.formFields.selectedWorkTypeGroupId = this.selectedWorkTypeGroupId;
        this.formFields.cookies = document.cookie;

        console.log('::doSubmit:form', this.formFields);

        this.submitting = true;

        doSubmit({request: JSON.stringify(this.formFields)})
            .then(res => {
                    console.log('::doSubmit:res', res);

                    if (res) {
                        let result = JSON.parse(res);

                        if (result && (result.error !== true)) {
                            this.clearPageData();
                            this.openSuccessModal();
                        } else {
                            if (result && result.error) {
                                if (result.errorMsg != null || result.errorCode != null) {
                                    this.openErrorModal(result.errorCode + ": " + result.errorMsg);
                                } else this.openErrorModal("");
                            } else {
                                this.openErrorModal("");
                            }
                        }
                    } else {
                        this.openErrorModal("Gateway error");
                    }
                }
            )
            .catch(error => {
                    console.error('::error', error);
                    this.openErrorModal("Backend error");
                }
            )
            .finally(() => {
                this.submitting = false;
            });
    }

    clearPageData() {

        this.selectedDate = null;
        this.selectedWorkTypeGroupId = null;
        this.selectedAppointmentName = null;
        this.loadingSlots = false;
        this.loading = false;
        this.submitting = false;
        this.resourceSelected = null;
        this.selectedSlot = null;
        this.currentSlotsDay0 = null;
        this.currentSlotsDay1 = null;
        this.currentSlotsDay2 = null;
        this.selectedDateP0 = null;
        this.selectedDateP1 = null;
        this.selectedDateP2 = null;
        this.errorModalText = null;
        this.showErrorModal = null;
        this.showSuccessModal = null;

        this.formFields = {};

        let nodes = this.template.querySelectorAll('[data-formfield]');

        console.log('::dcf: ' + this.dont_clear_form);
        for (let node of nodes) {
            let fieldName = node.getAttribute('data-formfield');
            let persist_after_submit = node.getAttribute('data-persist');

            if ((!persist_after_submit || persist_after_submit !== "true") || !this.dont_clear_form)
            {
                if (fieldName !== "chkAdditional") {
                    node.value = null;
                    node.checked = false;
                }
            }
        }

        this.dont_clear_form = true;

    }

    handleClearFormCheckChange(e)
    {
        this.dont_clear_form = e.currentTarget.checked;
    }


    // UTILITY
    dateToDatepickerDate(dte) {
        if (!dte) dte = new Date();
        let month = dte.getMonth() + 1 < 10 ? '0' + (dte.getMonth() + 1) : (dte.getMonth() + 1);
        let day = dte.getDate() < 10 ? '0' + dte.getDate() : dte.getDate();
        return dte.getFullYear() + '-' + month + '-' + day;
    }

    addDaysToISODate(dateStr, days) {
        const date = new Date(dateStr);
        date.setDate(date.getDate() + days);
        return date.toISOString().slice(0, 10);
    }

    validateDOB() {

        let dobDateValid = false;
        let inputDobDate;

        let f_dobD = this.template.querySelector('[data-formfield="dob_d"]');
        let f_dobM = this.template.querySelector('[data-formfield="dob_m"]');
        let f_dobY = this.template.querySelector('[data-formfield="dob_y"]');

        if (!f_dobD || !f_dobY || !f_dobM) return false;

        if (f_dobD && f_dobM && f_dobY && f_dobD.value && f_dobM.value && f_dobY.value) {
            inputDobDate = this.checkDateIsValid(
                parseInt(f_dobY.value),
                parseInt(f_dobM.value),
                parseInt(f_dobD.value));
        }

        dobDateValid = (inputDobDate != null);

        if (!dobDateValid) {
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

        return dobDateValid;
    }

    checkDateIsValid(y, m, d) {
        let dte = new Date(y + '/' + m + '/' + d);

        if (!dte.isSameAs(y, m, d)) return null; else return (
            y + '-' +
            (m < 10 ? '0' + m : m)
            + '-' +
            (d < 10 ? '0' + d : d));
    }

    openErrorModal(errmsg) {
        this.errorModalText = errmsg;
        this.showErrorModal = true;
    }

    closeErrorModal() {
        this.errorModalText = null;
        this.showErrorModal = false;
    }

    openSuccessModal() {
        this.showSuccessModal = true;
    }

    closeSuccessModal() {
        this.showSuccessModal = false;
    }


}