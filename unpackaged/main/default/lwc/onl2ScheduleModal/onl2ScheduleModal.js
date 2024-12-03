/**
 * Created 10.3.2021..
 */

import {api, LightningElement} from 'lwc';

import getServiceCenters from '@salesforce/apex/onl_CheckoutCtrl.getServiceCenters';

import getReservationHeldTime from '@salesforce/apex/onl_CheckoutCtrl.getReservationHeldTime';
import getAvailableSlotsDefaultTest from '@salesforce/apex/onl_CheckoutCtrl.getAvailableSlotsDefaultTest';
import scheduleAppointmentAndAddToBasket from '@salesforce/apex/onl_CheckoutCtrl.scheduleAppointmentAndAddToBasket';

// String covidTestId, String serviceCenterId, Date slotDate
import LOCALE from '@salesforce/i18n/locale';

import {
    getBasketIdFromCookie,
    storeBasketIdToCookie
} from 'c/onl2Basket';

/** Covid-test only (v2) version of schedule Covid test modal */
export default class Onl2ScheduleModal extends LightningElement {

    @api storeConfig;
    @api defaultLocation;
    @api defaultPersonalDetails;
    @api testProductToSchedule;
    @api appProductToSchedule;
    @api testToSchedule;
    @api appToSchedule;
    @api dev;

    selectedLocation;
    _formBook;

    _reservationHeldTime = 60;

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

    bookingToSchedule;
    productToSchedule;
    isCovidBooking = false;
    isAppointmentBooking = false;

    subtitle = '';

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

        // if (this.dev) console.log('::o2smodal:testToSchedule', JSON.stringify(this.testToSchedule));
        // if (this.dev) console.log('::o2smodal:testProductToSchedule', JSON.stringify(this.testProductToSchedule));
        // if (this.dev) console.log('::o2smodal:appToSchedule', JSON.stringify(this.appToSchedule));
        // if (this.dev) console.log('::o2smodal:appProductToSchedule', JSON.stringify(this.appProductToSchedule));

        if (this.testToSchedule) {
            if (this.dev) console.log('::dbg:in test to schedule');
            this.isCovidBooking = true;
            this.isAppointmentBooking = false;
            this.bookingToSchedule = this.testToSchedule;
            this.productToSchedule = this.testProductToSchedule;
            if (this.testToSchedule.COVID_Test_Type__c && this.testToSchedule.Turnaround_Time__c)
                this.subtitle = this.testToSchedule.COVID_Test_Type__c + ', ' + this.testToSchedule.Turnaround_Time__c;
        } else {
            if (this.dev) console.log('::dbg:in else');
            this.isCovidBooking = false;
            this.isAppointmentBooking = true;
            this.bookingToSchedule = this.appToSchedule;
            this.productToSchedule = this.appProductToSchedule;
            if (this.appToSchedule && this.appToSchedule.Work_Type_Group__r && this.appToSchedule.Work_Type_Group__r.Name) {
                this.subtitle = this.appToSchedule.Work_Type_Group__r.Name;
            }
        }

        if (this.dev) console.log('::o2smodal:bookingToSchedule', JSON.stringify(this.bookingToSchedule));
        if (this.dev) console.log('::o2smodal:productToSchedule', JSON.stringify(this.productToSchedule));
        if (this.dev) console.log('::o2smodal:isCovidBooking', (this.isCovidBooking));
        if (this.dev) console.log('::o2smodal:isAppointmentBooking', (this.isAppointmentBooking));

        if (this.bookingToSchedule) this.bookingToSchedule = JSON.parse(JSON.stringify(this.bookingToSchedule));
        // console.log('::this.testtoschedule', JSON.stringify(this.testToSchedule));

        if (this.productToSchedule && this.productToSchedule.defaultLocation)
            this.selectedDate = this.productToSchedule.defaultLocation.firstAvailable;

        // if "copyFrom" parameters were present
        if (this.defaultPersonalDetails && this.testToSchedule) {
            this.bookingToSchedule.Provided_Email__c = this.defaultPersonalDetails.email;
            this.bookingToSchedule.Provided_First_Name__c = this.defaultPersonalDetails.firstName;
            this.bookingToSchedule.Provided_Last_Name__c = this.defaultPersonalDetails.lastName;
            this.bookingToSchedule.Provided_Phone_Number__c = this.defaultPersonalDetails.phone;
        }

        this.retrieveReservationHeldTime();
        this.retrieveServiceCenters();

        let interval = 10;

        for (let hour = 8; hour < 20; hour++)
            for (let minute = 0; minute < 60; minute += interval) {
                this.defaultEmptySlots.push({
                    label: (hour < 10 ? '0' + hour : hour) + ':' + (minute < 10 ? '0' + minute : minute),
                    fullHour: (minute === 0)
                })
            }

        // console.log('::cc:defaultEmptySlots', this.defaultEmptySlots);
    }

    retrieveServiceCenters() {
        if (this.isCovidBooking) {
            getServiceCenters()
                .then(results => {
                    // console.log('::getServiceCenters:result', results);

                    if (results) {
                        this.allServiceCenters = JSON.parse(results);

                        this.serviceCenterOptions = [];

                        for (let sc of this.allServiceCenters) {

                            if (this.productToSchedule
                                && this.productToSchedule.defaultLocation
                                && this.productToSchedule.defaultLocation.postalcode === sc.PostalCode) {
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
        } else if (this.isAppointmentBooking) {
            console.error('::getServiceCenters:not supported for appointment booking', error);
        }
    }

    retrieveReservationHeldTime() {
        getReservationHeldTime()
            .then(result => {
                console.log('::getReservationHeldTime:result', result);

                if (result) {
                    this._reservationHeldTime = result;
                }

            })
            .catch(error => {
                console.error('::getReservationHeldTime:failed', error);
                this.showServiceCenters = false;
            })
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


        if (this.selectedServiceCenterId && this.selectedDate) {
            this.loadingSlots = true;

            let request = {
                defaultId: this.bookingToSchedule.Id,
                serviceCenterId: this.selectedServiceCenterId,
                slotDate: this.selectedDate
            };


            let fcionToCall = getAvailableSlotsDefaultTest;
            console.log('::getAvailableSlotsDefaultTest:request', request);


            fcionToCall(request)
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
                        else if (rs.label.endsWith('05')
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
                                resource: found.resources[0]
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
        if (this.isAppointmentBooking) return true;

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

        if (!this.validateForm()) {
            console.log('::osm2:doBook:validation failed');
            return;
        }

        this.step = {booking: true}
        console.log('::doBook', this.selectedSlot);

        let basketId = getBasketIdFromCookie();

        let params = {
            basketId: basketId,
            quantity: this.bookingToSchedule.quantity ? this.bookingToSchedule.quantity : 1,
            productId: this.productToSchedule.product.Id,
            serviceCenterId: this.selectedServiceCenterId,
            startTime: this.selectedSlot.startTime,
            endTime: this.selectedSlot.endTime,
            personalDetails: this._formBook,
            store: this.storeConfig.storeName,
            resourceId: this.selectedSlot.resource
        };

        if (this.isAppointmentBooking) {
            params.defaultAppointmentId = this.bookingToSchedule.Id;
        } else if (this.isCovidBooking) {
            params.defaultCovidTestId = this.bookingToSchedule.Id;
        }


        if (!this.selectedSlot || !this.selectedSlot.startTime || !this.selectedSlot.endTime) {
            console.error('Slot start/end not set');
            return;
        }

        let params_string = JSON.stringify(params);
        console.log('::scheduleAppointmentAndAddToBasket:params', params_string);


        scheduleAppointmentAndAddToBasket({params: params_string})
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

    handleContinueToCheckout() {
        this.dispatchEvent(new CustomEvent('gocheckout'));
    }


}