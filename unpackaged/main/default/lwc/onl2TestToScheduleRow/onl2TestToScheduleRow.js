/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';
import LOCALE from '@salesforce/i18n/locale';

export default class Onl2TestToScheduleRow extends LightningElement {

    @api test;
    @api defaultLocation;
    @api storeConfig;
    @api isBundled;
    @api isClosedWon;
    @api dev;

    triggerOpenScheduleModal = false;
    triggerOpenEditModal = false;

    calHref;

    connectedCallback() {
        this.calHref =
            {
                google: '',
                yahoo: '',
                ical: '',
                outlook: ''
            };
        if (this.isClosedWon && this.test && this.test.Scheduled_Appointment__r && this.test.Scheduled_Appointment__r.SchedStartTime)
        {

            let testStartDate = new Date(Date.parse(this.test.Scheduled_Appointment__r.SchedStartTime));
            let testEndDate = new Date((10 * 60 * 1000) + Date.parse(this.test.Scheduled_Appointment__r.SchedStartTime));

            //google
            console.log('1', this.test.Scheduled_Appointment__r.SchedStartTime);
            console.log('2', testStartDate);

            let startTime = this.formatTime(testStartDate);
            let endTime = this.formatTime(testEndDate);
            let title = (this.test.Test_Type__c || 'COVID Test');
            let description = '';

            let location;

            if (this.test.Scheduled_Appointment__r.ServiceTerritory) {
                location = this.test.Scheduled_Appointment__r.ServiceTerritory.Name;
                if (this.test.Scheduled_Appointment__r.ServiceTerritory.Address) {
                    location = location + ', ' + this.test.Scheduled_Appointment__r.ServiceTerritory.Address.street;
                    location = location + ', ' + this.test.Scheduled_Appointment__r.ServiceTerritory.Address.postalCode;
                    location = location + ', ' + this.test.Scheduled_Appointment__r.ServiceTerritory.Address.city;
                }
            }

            this.calHref.google = encodeURI([
                'https://www.google.com/calendar/render',
                '?action=TEMPLATE',
                '&text=' + title,
                '&dates=' + (startTime || ''),
                '/' + (endTime || ''),
                '&details=' + description,
                '&location=' + location,
                '&sprop=&sprop=name:'
            ].join(''));

            this.calHref.ical = encodeURI(
            'data:text/calendar;charset=utf8,' + [
                'BEGIN:VCALENDAR',
                'VERSION:2.0',
                'BEGIN:VEVENT',
                'URL:' + document.URL,
                'DTSTART:' + (startTime || ''),
                'DTEND:' + (endTime || ''),
                'SUMMARY:' + title,
                'DESCRIPTION:' + description,
                'LOCATION:' + location,
                'END:VEVENT',
                'END:VCALENDAR'].join('\n'));

            this.calHref.outlook = this.calHref.ical;

            var yahooEventDuration = '0010';

            // Remove timezone from event time
            var yahooStart = this.formatTime(new Date(testStartDate - (testStartDate.getTimezoneOffset() * 60 * 1000))) || '';

            this.calHref.yahoo = encodeURI([
            'https://calendar.yahoo.com/?v=60&view=d&type=20',
                '&TITLE=' + title,
                '&ST=' + yahooStart,
                '&DUR=' + yahooEventDuration,
                '&DESC=' + description,
                '&in_loc=' + location,
            ].join(''));


        }
    }

    formatTime (date) {
        if (date.toISOString) return date.toISOString().replace(/-|:|\.\d+/g, '');
        else return '';
    };


    get scheduledStartFormatted() {
        try {
            return new Intl.DateTimeFormat(LOCALE,
                {
                    year: "numeric",
                    month: "long",
                    day: "2-digit",
                    weekday: "long",
                    timeZone: "Europe/London",
                    hour: "2-digit",
                    minute: "2-digit",
                    hour12: false,
                })
                .format(Date.parse(this.test.Scheduled_Appointment__r.SchedStartTime));
        } catch (e) {
            console.error(e);
            return '';
        }
    }

    get alreadyScheduled() {
        return this.test && this.test.Scheduled_Appointment__r;
    }

    openScheduleModal() {
        this.triggerOpenScheduleModal = true;
    }

    closeScheduleModal() {
        this.triggerOpenScheduleModal = false;
    }

    openEditModal() {
        this.triggerOpenEditModal = true;
    }

    closeEditModal() {
        this.triggerOpenEditModal = false;
    }

    handleUpdated(e) {
        e.preventDefault();
        e.stopPropagation();
        this.closeEditModal();
        this.dispatchEvent(new CustomEvent('updated'));
    }

    handleBooked(e) {
        e.preventDefault();
        e.stopPropagation();
        this.closeScheduleModal();
        this.dispatchEvent(new CustomEvent('booked', {detail: e.detail}));
    }


}