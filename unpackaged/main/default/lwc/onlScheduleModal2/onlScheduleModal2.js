/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import getServiceCenters from '@salesforce/apex/onl_CheckoutCtrl.getServiceCenters';
import getAvailableSlotsDefaultTest from '@salesforce/apex/onl_CheckoutCtrl.getAvailableSlotsDefaultTest';
import scheduleAppointmentAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.scheduleAppointmentAndAddToBasket';

// String covidTestId, String serviceCenterId, Date slotDate
import LOCALE from '@salesforce/i18n/locale';

import {
    getBasketIdFromCookie,
    storeBasketIdToCookie
} from 'c/onlBasket2';

/** Covid-test only (v2) version of schedule Covid test modal */
export default class OnlScheduleModal2 extends LightningElement {

    @api defaultLocation;
    @api testProductToSchedule;
    @api storeConfig;

    test;
    selectedLocation;
    _formBook;

    allServiceCenters;

    /*
    steps (state machine showing different parts of the component):
    - location
    - confirm
    - booking
    - postChoice
     */
    step = {location: true};

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

    connectedCallback() {

        this.test = this.testProductToSchedule.product.Default_COVID_Tests__r.records[0];
        if (this.testProductToSchedule && this.testProductToSchedule.defaultLocation)
            this.selectedDate = this.testProductToSchedule.defaultLocation.firstAvailable;

        this.retrieveServiceCenters();

        for (let hour = 8; hour < 18; hour++)
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
                console.log('::getServiceCenters:result', results);

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
                            value: sc.Id
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

    getServiceCenter(serviceCenterId) {
        if (this.allServiceCenters) {
            for (let sc of this.allServiceCenters) {
                if (sc.Id === serviceCenterId) return sc;
            }
        }
        return {};
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    searchSlots() {
        if (!this.selectedDate) this.selectedDate = this.today();
        this.errorMessage = null;

        console.log('::searchSlots', this.test.Id, this.selectedServiceCenterId, this.selectedDate);

        if (this.selectedServiceCenterId && this.selectedDate) {
            this.loadingSlots = true;

            getAvailableSlotsDefaultTest({
                defaultCovidTestId: this.test.Id,
                serviceCenterId: this.selectedServiceCenterId,
                slotDate: this.selectedDate
            })
                .then(results => {
                    console.log('::getAvailableSlots:result', results);

                    let receivedSlots = JSON.parse(results);

                    this.currentSlots = [];

                    for (let rs of receivedSlots) {
                        rs.label = new Intl.DateTimeFormat(LOCALE,
                            {
                                timeZone: "Europe/London",
                                hour: "2-digit",
                                minute: "2-digit",
                                hour12: false,
                            })
                            .format(Date.parse(rs.startTime));
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
                                fullHour: ds.fullHour
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


    handleLocationChanged(event) {
        this.selectedServiceCenterId = event.target.value;

        this.selectedLocation = this.getServiceCenter(this.selectedServiceCenterId);

        //scroll to top of page
        let scr_div = this.template.querySelector('.scrollable-div');
        if (scr_div) {
            scr_div.scrollTop = 0;
        }
        this.searchSlots();
    }


    handleTimeSlotSelected(event) {
        this.errorMessage = null;
        this.selectedSlot = {
            startTime: event.currentTarget.dataset.start,
            endTime: event.currentTarget.dataset.end
        };

        console.log('::handleTimeSlotSelected:selectedSlot', this.selectedSlot);

        this.step = {confirm: true};
    }

    handleBackToLocations() {
        this.step = {prebook: true}
    }

    handleBackToSlots() {
        this.errorMessage = null;
        this.step = {location: true};
        this.searchSlots();
    }

    handleDateInputChange(event) {
        this.selectedDate = event.currentTarget.value;
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

    limitLength(s) {
        if (s && s.length > 50) return s.substring(0, 50);
        return s;
    }

    validateForm() {
        this._formBook = {}
        let inputs = this.template.querySelectorAll('[data-formfield]');
        if (inputs) {
            for (let input of inputs) {
                this._formBook[input.getAttribute('data-formfield')] = this.limitLength(input.value);
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }

        return !!this._formBook.lastName && !!this._formBook.firstName && !!this._formBook.email && !!this._formBook.phone;
    }

    doBook() {

        if (!this.validateForm())
        {
            console.log('::osm2:doBook:validation failed');
            return;
        }

        this.step = {booking: true}
        console.log('::doBook', this.selectedSlot);

        let basketId = getBasketIdFromCookie();

        let params = {
            basketId : basketId,
            productId : this.testProductToSchedule.product.Id,
            defaultCovidTestId: this.test.Id,
            serviceCenterId: this.selectedServiceCenterId,
            startTime: this.selectedSlot.startTime,
            endTime: this.selectedSlot.endTime,
            personalDetails : this._formBook,
            store: this.storeConfig.storeName
        };

        if (!this.selectedSlot || !this.selectedSlot.startTime || !this.selectedSlot.endTime) {
            console.error('Slot start/end not set');
            return;
        }

        let params_string = JSON.stringify(params);
        console.log('::scheduleAppointmentAndAddToBasket:params', params_string);


        scheduleAppointmentAndAddToBasket({params:params_string})
            .then(result => {
                console.log('::scheduleAppointmentAndAddToBasket:result', result);
                if (result) {
                    this.dispatchEvent(new CustomEvent('booked'));
                    storeBasketIdToCookie(result);
                    this.step = {postChoice: true};
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

    handleContinueToCheckout()
    {
        this.dispatchEvent(new CustomEvent('gocheckout'));
    }



}