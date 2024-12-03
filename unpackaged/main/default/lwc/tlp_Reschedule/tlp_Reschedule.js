/**
 * Created 3.4.2024..
 */

import {api, wire, LightningElement} from 'lwc';

import getCustomSettings from '@salesforce/apex/TLPController.getCustomSettings';
import getBooking from '@salesforce/apex/TLPController.getBookingDetailsByCode';
import getAvailableSlots from '@salesforce/apex/TLPController.aura_getTlpAvailability';
import doRescheduleByCode from '@salesforce/apex/TLPController.doRescheduleByCode';
import LOCALE from '@salesforce/i18n/locale';

export default class TLPReschedule extends LightningElement {

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

    existingBooking;

    @wire(getCustomSettings)
    myCustomSettings;

    formFields = {};

    errorModalText;
    showErrorModal;

    rescheduleSuccess;

    fetchFailed;

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

    connectedCallback() {
        if (!!this.queryParameters.a && !!this.queryParameters.id) {
            this.getExistingBooking(this.queryParameters.id);
        }
    }

    getExistingBooking(appId) {
        this.loading = true;
        this.fetchFailed = false;
        getBooking({code: appId})
            .then(results => {
                console.log('::getBooking:result', results);
                this.existingBooking = JSON.parse(results);
                this.selectedWorkTypeGroupId = this.existingBooking.Work_Type_Group__c;
            })
            .catch(error => {
                console.error('::getBooking:failed', error);
                this.existingBooking = null;
                this.fetchFailed = true;
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handleDateInputChange(event) {
        this.selectedDate = event.currentTarget.value;
        this.searchSlots();
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


                    if (nextSlot.startTime.indexOf(day0) > 0) {
                        //console.log('... ... added to slots0');
                        this.currentSlotsDay0.push({
                            label: label,
                            startTime: nextSlot.startTime,
                            endTime: nextSlot.endTime,
                            resources: nextSlot.resources,
                            resource_locations: nextSlot.resource_locations
                        });
                    } else if (nextSlot.startTime.indexOf(day1) > 0) {
                        //console.log('... ... added to slots1');
                        this.currentSlotsDay1.push({
                            label: label,
                            startTime: nextSlot.startTime,
                            endTime: nextSlot.endTime,
                            resources: nextSlot.resources,
                            resource_locations: nextSlot.resource_locations
                        });
                    } else if (nextSlot.startTime.indexOf(day2) > 0) {
                        //console.log('... ... added to slots2');
                        this.currentSlotsDay2.push({
                            label: label,
                            startTime: nextSlot.startTime,
                            endTime: nextSlot.endTime,
                            resources: nextSlot.resources,
                            resource_locations: nextSlot.resource_locations
                        });
                    }
                }
            }

            console.log('current slots by days', this.currentSlotsDay0, this.currentSlotsDay1, this.currentSlotsDay2);
        }
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

    // DO RESCHEDULE
    doReschedule() {
        this.formFields.selectedDate = this.selectedDate;
        this.formFields.timeSelected = this.selectedSlot?.startTime;
        this.formFields.timeSelectedEnd = this.selectedSlot?.endTime;
        this.formFields.selectedResource = this.selectedSlot?.resources[0];
        this.formFields.cookies = document.cookie;

        console.log('::doReschedule:form', this.formFields);

        this.submitting = true;

        doRescheduleByCode({code: this.existingBooking.UUID__c, request: JSON.stringify(this.formFields)})
            .then(result => {
                console.log('::doRescheduleByCode:result', result);
                if (result) {
                    this.rescheduleSuccess = true;
                } else {
                    this.openErrorModal("Gateway error");
                    this.rescheduleSuccess = false;
                }

            })
            .catch(error => {
                this.openErrorModal("Backend error");
                this.rescheduleSuccess = false;
            })
            .finally(() => {
                this.submitting = false;
            });
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

}