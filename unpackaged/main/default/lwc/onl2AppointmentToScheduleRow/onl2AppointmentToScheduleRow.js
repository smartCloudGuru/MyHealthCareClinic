/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';
import LOCALE from '@salesforce/i18n/locale';

export default class onl2AppointmentToScheduleRow extends LightningElement {

    @api app;
    @api defaultLocation;
    @api storeConfig;
    @api isBundled;
    @api isClosedWon

    triggerOpenScheduleModal = false;
    triggerOpenEditModal = false;
    title;

    calHref;

    connectedCallback() {
        this.calHref =
            {
                google: '',
                yahoo: '',
                ical: '',
                outlook: ''
            };

        let title = this.app?.WorkType?.Name;
        this.title = title;

        if (this.isClosedWon && this.app && this.app.SchedStartTime)
        {

            let appStartDate = new Date(Date.parse(this.app.SchedStartTime));
            let appEndDate = new Date(Date.parse(this.app.SchedEndTime));

            let startTime = this.formatTime(appStartDate);
            let endTime = this.formatTime(appEndDate);

            let description = '';

            let location;

            if (this.app.ServiceTerritory) {
                location = this.app.ServiceTerritory.Name;
                if (this.app.ServiceTerritory.Address) {
                    location = location + ', ' + this.app.ServiceTerritory.Address.street;
                    location = location + ', ' + this.app.ServiceTerritory.Address.postalCode;
                    location = location + ', ' + this.app.ServiceTerritory.Address.city;
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

            var yahooEventDuration = '0060'; // todo fix

            // Remove timezone from event time
            var yahooStart = this.formatTime(new Date(appStartDate - (appStartDate.getTimezoneOffset() * 60 * 1000))) || '';

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
                .format(Date.parse(this.app.SchedStartTime));
        } catch (e) {
            console.error(e);
            return '';
        }
    }

    get alreadyScheduled() {
        return this.app && this.app.SchedStartTime;
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