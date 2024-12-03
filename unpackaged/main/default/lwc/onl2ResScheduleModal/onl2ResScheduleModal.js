/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

// search by String postalcode, String radius, String covidTestId
import getLocations from '@salesforce/apex/onl_CheckoutCtrl.getLocations';
// String covidTestId, String serviceCenterId, Date slotDate
import getAvailableSlots from '@salesforce/apex/onl_CheckoutCtrl.getAvailableSlots';
import getServiceCenters from '@salesforce/apex/onl_CheckoutCtrl.getServiceCenters';
import LOCALE from '@salesforce/i18n/locale';

import scheduleAppointment from '@salesforce/apex/onl_CheckoutCtrl.scheduleAppointment';

export default class Onl2ReScheduleModal extends LightningElement {

    @api defaultLocation;
    @api test;
    @api reschedule;
    @api dev;

    /*
    steps:
    - prebook
    - locationselected
    - confirm
    - booking
     */
    step = {prebook: true};

    locations = [];
    daysQueried = 0;
    noLocations = false;

    errorMessage = null;

    _defaults = {};

    distanceOptions = [
        {label: '5 miles', value: '5'},
        {label: '10 miles', value: '10'},
        {label: '25 miles', value: '25'},
        {label: '50 miles', value: '50'},
        {label: '100 miles', value: '100'}
        // {label: 'Any distance', value: null}
    ];

    loading = false;
    loadingSlots = false;
    loadingBook = false;

    serviceCenterOptions;

    selectedServiceCenterId = null;
    selectedServiceCenterPostalCode = null;
    selectedLocation = null;
    selectedDate = null;

    currentSlots = [];
    defaultEmptySlots = [];
    selectedSlot = null;

    get hasSlots() {
        return this.currentSlots && this.currentSlots.length > 0;
    }

    get formattedSelectedSlot() {
        return new Intl.DateTimeFormat(LOCALE,
            {
                year: "numeric",
                month: "2-digit",
                day: "2-digit",
                timeZone: "Europe/London",
                hour: "2-digit",
                minute: "2-digit",
                hour12: false,
            })
            .format(Date.parse(this.selectedSlot.startTime));
    }

    get locationSelected() {
        return this.selectedServiceCenterPostalCode != null;
    }

    connectedCallback() {

        if (this.dev) console.log('::dbg::o2rsm:cc:test', JSON.stringify(this.test));
        //console.log('::dbg:::test', JSON.stringify(this.test));
        if (this.test && this.test.defaultPostalCode && this.test.defaultServiceCenterId) {
            this.searchLocations(this.test.defaultPostalCode, "1");
            this.selectedServiceCenterPostalCode = this.test.defaultPostalCode;
        } else
            try {
                this._defaults.postalcode = this.defaultLocation.postalcode;
                this._defaults.distance = this.defaultLocation.distance;
                this.searchLocations(this._defaults.postalcode, this._defaults.distance);
            } catch (e) {
                console.error('::onl2_rsm:cc:ex', e);
            }

        this.retrieveServiceCenters();

        for (let hour = 8; hour < 20; hour++)
            for (let minute = 0; minute < 60; minute += 10) {
                this.defaultEmptySlots.push({
                    label: (hour < 10 ? '0' + hour : hour) + ':' + (minute < 10 ? '0' + minute : minute),
                    fullHour: (minute === 0)
                })
            }

        // console.log('::cc:defaultEmptySlots', this.defaultEmptySlots);
    }

    retrieveServiceCenters() {
        getServiceCenters()
            .then(results => {
                console.log('::onl2_rsm:getServiceCenters:result', results);

                if (results) {
                    this.allServiceCenters = JSON.parse(results);

                    this.serviceCenterOptions = [];

                    for (let sc of this.allServiceCenters) {
                        if (this.testProductToSchedule
                            && this.testProductToSchedule.defaultLocation
                            && this.testProductToSchedule.defaultLocation.postalcode === sc.PostalCode) {
                            this.selectedServiceCenterId = sc.Id;
                            this.selectedLocation = sc;
                        }

                        this.serviceCenterOptions.push({
                            label: sc.Name + ', ' + sc.PostalCode + ' ' + sc.City,
                            value: sc.PostalCode
                        })
                    }

                }

            })
            .catch(error => {
                console.error('::getServiceCenters:failed', error);
                this.showServiceCenters = false;
            })
            .finally(() => {
                this.searchSlots();
            });
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    doSearch() {
        let _form = {};
        let inputs = this.template.querySelectorAll('[data-formfield]');
        if (inputs) {
            for (let input of inputs) {
                _form[input.getAttribute('data-formfield')] = input.value;
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }
        if (_form.postalcode && _form.distance)
            this.searchLocations(_form.postalcode, _form.distance);
    }

    searchLocations(postalcode, distance) {
        console.log('::getLocations', postalcode, distance, this.test.Id);
        if (postalcode && distance) {
            this.loading = true;
            if (postalcode && distance && this.test && this.test.Id) {
                getLocations({postalcode: postalcode, radius: distance, covidTestId: this.test.Id})
                    .then(results => {
                        console.log('::getLocations:result', results);
                        let ret = JSON.parse(results);
                        this.locations = ret.locations;
                        this.daysQueried = ret.daysQueried;
                    })
                    .catch(error => {
                        console.error('::getLocations:failed', error);
                        this.locations = [];
                    })
                    .finally(() => {
                        console.log('::getLocations:finally:locations', this.locations);
                        this.noLocations = (!this.locations || this.locations.length === 0);
                        // console.log('::getLocations:finally:noLocations', this.noLocations);

                        // for (let loc of this.locations) {
                        //     loc.origDate = this.today();
                        //     if (!loc.firstAvailable) {
                        //         if (!this.daysQueried) {
                        //             loc.firstAvailable = 'Availability not known';
                        //         } else {
                        //             loc.firstAvailable = 'Not available within next ' + this.daysQueried + ' days';
                        //         }
                        //         loc.class = 'noslot';
                        //     } else {
                        //         loc.origDate = loc.firstAvailable;
                        //         loc.firstAvailable = new Intl.DateTimeFormat(LOCALE,
                        //             {
                        //                 year: "numeric",
                        //                 month: "2-digit",
                        //                 day: "2-digit",
                        //                 timeZone: "Europe/London",
                        //                 hour: "2-digit",
                        //                 minute: "2-digit",
                        //                 hour12: false,
                        //             })
                        //             .format(Date.parse(loc.firstAvailable));
                        //     }
                        // }

                        this.loading = false;
                    });
            }
        }
    }

    handleLocationClick(event) {
        this.selectedServiceCenterId = event.currentTarget.dataset.id;

        this.currentSlots = [];
        this.selectedSlot = null;
        this.selectedLocation = null;

        for (let loc of this.locations) {
            if (this.selectedServiceCenterId === loc.id) {
                this.selectedLocation = loc;
                break;
            }

        }

        this.step = {locationselected: true};

        this.selectedDate = event.currentTarget.dataset.date;

        // scroll to top of page
        let scr_div = this.template.querySelector('.scrollable-div');
        if (scr_div) {
            scr_div.scrollTop = 0;
        }
        this.searchSlots();
    }

    searchSlots() {
        if (!this.selectedDate) this.selectedDate = this.today();
        this.errorMessage = null;

        if (this.selectedDate && this.selectedDate.indexOf('T')) this.selectedDate = this.selectedDate.split('T')[0];

        if (this.selectedServiceCenterId && this.selectedDate) {
            this.loadingSlots = true;

            let request = {
                covidTestId: this.test.Id,
                serviceCenterId: this.selectedServiceCenterId,
                slotDate: this.selectedDate
            };

            console.log('::c.getAvailableSlots:request', request);
            getAvailableSlots(request)
                .then(results => {
                    console.log('::getAvailableSlots:result', results);

                    let receivedSlots = JSON.parse(results);

                    this.currentSlots = [];
                    let contains00s = false;
                    let contains30s = false;
                    let contains05s = false;
                    let containsDetailedSlots = false;

                    for (let rs of receivedSlots) {
                        rs.label = new Intl.DateTimeFormat(LOCALE,
                            {
                                timeZone: "Europe/London",
                                hour: "2-digit",
                                minute: "2-digit",
                                hour12: false,
                            })
                            .format(Date.parse(rs.startTime));
                        if (rs.label.endsWith('00')) {
                            contains00s = true;
                        } else if (rs.label.endsWith('30')) {
                            contains30s = true;
                        }
                        else if (
                            rs.label.endsWith('05')
                            || rs.label.endsWith('15')
                            || rs.label.endsWith('25')
                            || rs.label.endsWith('35')
                            || rs.label.endsWith('45')
                            || rs.label.endsWith('55')
                        ) {
                            contains05s = true;
                        }
                        else {
                            containsDetailedSlots = true;
                        }
                    }

                    let interval = 10;
                    if (contains05s) interval = 5
                    else if (containsDetailedSlots) interval = 10;
                    else if (contains30s) interval = 30;
                    else if (contains00s) interval = 60;
                    else interval = 10;

                    this.defaultEmptySlots = [];
                    for (let hour = 8; hour < 20; hour++)
                        for (let minute = 0; minute < 60; minute += interval) {
                            this.defaultEmptySlots.push({
                                label: (hour < 10 ? '0' + hour : hour) + ':' + (minute < 10 ? '0' + minute : minute),
                                fullHour: (minute === 0)
                            })
                        }

                    for (let ds of this.defaultEmptySlots) {
                        let found = null;

                        for (let rs of receivedSlots) {
                            if (rs.label === ds.label) {
                                found = rs;
                                break;
                            }
                        }

                        if (found === null) {
                            this.currentSlots.push({
                                label: ds.label,
                                fullHour: ds.fullHour
                            });
                        } else {
                            this.currentSlots.push({
                                label: ds.label,
                                startTime: found.startTime,
                                endTime: found.endTime,
                                fullHour: ds.fullHour,
                                resource : found.resources[0]
                            })
                        }
                    }

                })
                .catch(error => {
                    console.error('::getAvailableSlots:failed', error);
                    this.currentSlots = this.defaultEmptySlots.slice();
                })
                .finally(() => {
                    // console.log('::getAvailableSlots:currentSlots', this.currentSlots);
                    this.loadingSlots = false;
                });
        }
    }


    handleTimeSlotSelected(event) {
        this.errorMessage = null;
        this.selectedSlot = {
            startTime: event.currentTarget.dataset.start,
            endTime: event.currentTarget.dataset.end,
            resource: event.currentTarget.dataset.resource
        };

        console.log('::handleTimeSlotSelected:selectedSlot', this.selectedSlot);

        this.step = {confirm: true};
    }

    handleBackToLocations() {
        this.step = {prebook: true}
    }

    handleBackToSlots() {
        this.errorMessage = null;
        this.step = {locationselected: true};
        this.searchSlots();
    }

    handleDateNext() {
        this.selectedDate = this.addDays(this.selectedDate, 1);
        // console.log(this.selectedDate);
        this.searchSlots();
    }

    handleDatePrevious() {
        this.selectedDate = this.addDays(this.selectedDate, -1);
        // console.log(this.selectedDate);
        this.searchSlots();
    }

    handleDateInputChange(event) {
        this.selectedDate = event.currentTarget.value;
        // console.log('::handleDateInputChange:selectedDate',this.selectedDate);
        this.searchSlots();
    }

    addDays(dte, days) {
        let dte2 = new Date();

        if (dte) {
            dte2 = new Date(Date.parse(dte));
            try {
                dte2.setDate(dte2.getDate() + days);
            } catch (e) {
                console.error(e);
                dte2 = new Date();
            }
        }
        // console.log('::addDays:dte2', dte2);
        return this.dateToDatepickerDate(dte2);
    }

    doBook() {
        this.step = {booking: true}
        console.log('::doBook:selectedSlot', JSON.stringify(this.selectedSlot));

        let params = {
            covidTestId: this.test.Id,
            serviceCenterId: this.selectedServiceCenterId,
            startTime: this.selectedSlot.startTime,
            endTime: this.selectedSlot.endTime,
            selectedResourceId: this.selectedSlot.resource
        };

        if (!this.selectedSlot || !this.selectedSlot.startTime || !this.selectedSlot.endTime) {
            console.error('Slot start/end not set');
            return;
        }

        console.log('::scheduleAppointment:params', JSON.stringify(params));

        scheduleAppointment(params)
            .then(results => {
                console.log('::scheduleAppointment:result', results);
                if (results) {
                    this.dispatchEvent(new CustomEvent('booked', {detail: {reschedule: this.reschedule}}));
                } else {
                    this.errorMessage = 'Test slot is not free any more. Please try a different time.';
                    this.step = {confirm: true};
                }

            })
            .catch(error => {
                console.error('::scheduleAppointment:failed', error);
                this.errorMessage = 'Unable to schedule at this time. Please try again with a different time.';
                this.step = {confirm: true};
            })
            .finally(() => {

            });

    }

    today() {
        return this.dateToDatepickerDate(new Date());
    }

    dateToDatepickerDate(dte) {
        if (!dte) dte = new Date();
        let month = dte.getMonth() + 1 < 10 ? '0' + (dte.getMonth() + 1) : (dte.getMonth() + 1);
        let day = dte.getDate() < 10 ? '0' + dte.getDate() : dte.getDate();
        return dte.getFullYear() + '-' + month + '-' + day;
    }


    handleLocationChanged(event) {
        console.log('::2ResScheduleModal:handleLocationChanged:', event.target.value);
        this.searchLocations(event.target.value, "1");

        // this.selectedServiceCenterId = event.target.value;
        //
        // this.selectedLocation = this.getServiceCenter(this.selectedServiceCenterId);
        //
        // //scroll to top of page
        // let scr_div = this.template.querySelector('.scrollable-div');
        // if (scr_div) {
        //     scr_div.scrollTop = 0;
        // }
        // this.searchSlots();

    }


}