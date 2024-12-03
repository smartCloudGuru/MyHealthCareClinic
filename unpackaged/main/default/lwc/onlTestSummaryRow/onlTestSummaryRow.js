/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';
import LOCALE from '@salesforce/i18n/locale';

export default class OnlTestSummaryRow extends LightningElement {

    @api test;

    connectedCallback() {
    }

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

}