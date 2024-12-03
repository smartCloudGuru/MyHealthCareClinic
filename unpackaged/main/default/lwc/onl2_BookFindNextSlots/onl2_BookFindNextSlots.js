/**
 * Created by Matija on 8.8.2023..
 */

import {api, LightningElement} from 'lwc';

import getAvailableSlots from '@salesforce/apex/OnlBookUI.aura_getAvailableSlotsByWorkTypeGroupDateRange';
import LOCALE from '@salesforce/i18n/locale';

export default class Onl2BookFindNextSlots extends LightningElement {

    @api storeBooking; // styling differs online vs inside sf
    @api chosenDate;
    @api selectedServiceCenterId;
    @api selectedWorkTypeGroupId;
    @api instantSearch;
    @api textBefore;
    @api textAfter;

    numSearches = 0;

    availableDates;
    availableDatesFormatted;

    searching;
    searched;

    maxDates = 6;

    get readyToSearch() {
        return !!this.selectedWorkTypeGroupId && !!this.selectedServiceCenterId;
    }

    get hasAvailabilityDates() {
        return !!this.availableDates && this.availableDates.size > 0;
    }

    @api get reset() {
        console.log('::o2bfn:reset');
        this.availableDates = null;
        this.availableDatesFormatted = null;
    }

    connectedCallback() {
        if (!this.textBefore) this.textBefore = 'No time slots found for specified location and date';
        if (!this.textAfter) this.textAfter = 'Following dates have availability:';

        if (this.instantSearch) {
            this.maxDates = 4;
            this.doSearch();
        }
    }


    doSearch() {
        this.searched = false;
        let now = this.dateToDatepickerDate(new Date());
        console.log('now:' + now);
        if (!this.chosenDate) this.chosenDate = now;
        let fromDate = this.chosenDate;
        if (fromDate < now) {
            fromDate = now;
            this.chosenDate = now;
        }

        console.log(fromDate);

        this.numSearches = 0;

        this.availableDates = new Set();

        this.searching = true;
        this.handleSearchStart();
        this.findSlots(fromDate);

    }

    dateToDatepickerDate(dte) {
        if (!dte) dte = new Date();
        let month = dte.getMonth() + 1 < 10 ? '0' + (dte.getMonth() + 1) : (dte.getMonth() + 1);
        let day = dte.getDate() < 10 ? '0' + dte.getDate() : dte.getDate();
        return dte.getFullYear() + '-' + month + '-' + day;
    }

    findSlots(fromDate) {

        let toDate = this.addDaysToISODate(fromDate, 4);

        this.numSearches++;

        if (this.numSearches >= 9 || this.availableDates.size >= this.maxDates) {
            this.searching = false;
            this.searched = true;
            this.handleSearchDone();
            return;
        }

        let searchparams = {
            workTypeGroupId: this.selectedWorkTypeGroupId,
            serviceCenterId: this.selectedServiceCenterId,
            fromDate: fromDate,
            toDate: toDate
        };

        console.log('::getAvailableSlots:params', searchparams);

        getAvailableSlots(searchparams)
            .then(results => {
                //console.log('::getAvailableSlots:res', results);
                if (results) {
                    let receivedSlots = JSON.parse(results);
                    if (!!receivedSlots && !!receivedSlots.territorySlots && receivedSlots.territorySlots.length > 0) {
                        //console.log('::receivedSlots', receivedSlots.territorySlots.length);
                        this.getAvailableDates(receivedSlots.territorySlots)
                    } else {
                        console.log('::receivedSlots empty');
                    }
                }

            })
            .catch(error => {
                console.error('::getAvailableSlotsByWorkTypeGroup:failed', error);
            })
            .finally(() => {
                //this.loadingSlots = false;

                this.findSlots(this.addDaysToISODate(fromDate, 4));



            });
    }

    addDaysToISODate(dateStr, days) {
        const date = new Date(dateStr);
        date.setDate(date.getDate() + days);
        return date.toISOString().slice(0, 10);
    }

    getAvailableDates(slots) {
        for (let slot of slots) {
            if (slot && slot.startTime) {
                this.availableDates.add(slot.startTime.substring(0, 10));
            }
        }

        //console.log('av dates:', this.availableDates);

        this.availableDatesFormatted = [];
        for (let adate of this.availableDates) {
            this.availableDatesFormatted.push({
                label: new Date(Date.parse(adate)), value: adate
            });
        }

        console.log('avf dates:', this.availableDatesFormatted);
    }

    handleDateSelected(e) {
        const dateSelectedEvent = new CustomEvent('date', {detail: e.currentTarget?.dataset?.date});
        console.log('::fns:event:date', dateSelectedEvent);
        this.dispatchEvent(dateSelectedEvent);
    }

    handleSearchDone(e) {
        const doneEvent = new CustomEvent('done', {});
        console.log('::fns:event:done', doneEvent);
        this.dispatchEvent(doneEvent);
    }

    handleSearchStart(e) {
        const startEvent = new CustomEvent('start', {});
        console.log('::fns:event:start', startEvent);
        this.dispatchEvent(startEvent);
    }

}