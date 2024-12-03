/**
 * Created 25.5.2022.
 */

import {api, LightningElement, wire} from 'lwc';

import LOCALE from '@salesforce/i18n/locale';
// import registerAndLogin from '@salesforce/apex/OnlBookUI.registerAndLogin';

import getCustomSettings from '@salesforce/apex/OnlBookUI.getCustomSettings';
import checkAccountLogin from '@salesforce/apex/OnlBookUI.checkAccountLoginWithConnectedAccounts';
import activateRegistrationByCode from '@salesforce/apex/OnlBookUI.activateRegistrationByCode';
import queuePassChange from '@salesforce/apex/OnlBookUI.queuePassChange';
import queueRegister from '@salesforce/apex/OnlBookUI.queueRegister';

import {
    clearLoggedInCookie,
    storeLoggedInToCookie
} from 'c/onl2Basket';

/** Covid-test only (v2) version of schedule Covid test modal */
export default class Onl2LoginModal extends LightningElement {

    @api storeConfig;
    @api defaultPersonalDetails;
    @api beforeLoginCtx;
    @api branding;
    @api dev;

    // css if it's going to be modal or not
    get modalCss() {
        return "slds-modal slds-modal_large slds-fade-in-open " + this.branding;
    }

    passwordPattern = '.{8,}';

    genderOptions = [
        {"value": "Male", "label": "Male"},
        {"value": "Female", "label": "Female"}
    ];

    @wire(getCustomSettings)
    myCustomSettings;

    msgEmail;
    msgRegister;

    /*
    steps (state machine showing different parts of the component):
     */
    step = {email: true};

    loading = false;
    loadingActivationCode = false;
    registrationEmail;
    msgActivation;

    mainPatientUUID;
    selectedAccountToBook;
    connectedAccounts;

    ddOptions;
    mmOptions;
    yyOptions;

    inputDobDate;
    dobDateValid;

    connectedCallback() {

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

        if (this.defaultPersonalDetails == null) this.defaultPersonalDetails = {};
        if (this.dev) console.log('::lm:cc:ctx', JSON.stringify(this.beforeLoginCtx));
    }


    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleRegisterFormChange(e) {
        //this.msgRegister = null;
        let regEmailNode = this.template.querySelector('[data-formfield="regEmail"]');
        let regEmailNode2 = this.template.querySelector('[data-formfield="regEmail2"]');
        if (regEmailNode.value !== regEmailNode2.value) {
            regEmailNode2.setCustomValidity('Email fields must match');
        } else {
            regEmailNode2.setCustomValidity('');
        }
        regEmailNode2.reportValidity();

        let passNode = this.template.querySelector('[data-formfield="password1"]');
        let passNode2 = this.template.querySelector('[data-formfield="password2"]');
        if (passNode.value !== passNode2.value) {
            passNode2.setCustomValidity('Password fields must match');
        } else {
            passNode2.setCustomValidity('');
        }
        passNode2.reportValidity();
    }

    handleEmailFormChange(e) {
        //this.msgEmail = null;
    }

    handleStartRegister(e) {
        this.step = {register: true, showBack: true}
    }

    handleBackToLogin(e) {
        this.step = {email: true};
    }

    handleForgotPassword(e) {
        this.step = {forgot: true, showBack: true};
    }

    handleLogin(e) {

        let emailNode = this.template.querySelector('[data-formfield="email"]');
        let passNode = this.template.querySelector('[data-formfield="password"]');
        let dobNode = this.template.querySelector('[data-formfield="dob"]');

        if (emailNode) emailNode.reportValidity();
        if (dobNode) dobNode.reportValidity();
        if (passNode) passNode.reportValidity();

        // if (!emailNode || !dobNode) return;
        if (!emailNode || !passNode) return;

        if (!emailNode.validity.valid || !passNode.validity.valid) return;

        this.loading = true;
        clearLoggedInCookie();
        checkAccountLogin({identification: emailNode.value, password: passNode.value})
            .then(results => {
                if (this.dev) console.log('::checkAccountLogin:result', results);

                if (results) {
                    let response = JSON.parse(results);
                    this.dispatchEvent(new CustomEvent('sessionchange', {
                        detail: {
                            stage: 'loginOk',
                            uuid: response.main.Store_UUID__c,
                            contactId: response.main.ContactId__c,
                            email: response.main.PersonEmail,
                            patientType: response.main.Patient_Type__c,
                            membershipType: response.main.Membership_Type__c
                        }
                    }));
                    this.mainPatientUUID = response.main.Store_UUID__c;
                    this.selectedAccountToBook = this.mainPatientUUID;

                    // 2023-10-20 moved multiple account to booking modal
                    // this.connectedAccounts = [];
                    // for (let acc of response.connected) {
                    //
                    //     //Store_UUID__c, FirstName, LastName, Date_of_Birth__c
                    //     let dob = '';
                    //     if (acc.Date_of_Birth__c) {
                    //         try {
                    //             dob = ' (' + acc.Date_of_Birth__c.substring(8, 10) + '/' + acc.Date_of_Birth__c.substring(5, 7) + '/' + acc.Date_of_Birth__c.substring(0, 4) + ')';
                    //         } catch (ignore) {}
                    //     }
                    //     this.connectedAccounts.push({
                    //         label: acc.FirstName + ' ' + acc.LastName + dob,
                    //         value: acc.Store_UUID__c
                    //     })
                    // }

                    // if (this.connectedAccounts.length > 1) this.step = {multipleConnected: true};
                    // else {
                    //     this.handleContinueFromMultiple();
                    // }

                    this.handleContinueFromMultiple();

                } else {
                    //unknown email
                    this.msgEmail = 'Provided login information is incorrect. If you recently registered, have you activated your account from the e-mail you received?';
                }

            })
            .catch(error => {
                console.error('::getAppointmentTypes:failed', error);
                this.msgEmail = 'There was a problem looking up your Account. Please contact us for assistance.';
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handleRegister(e) {
        let firstNameNode = this.template.querySelector('[data-formfield="firstName"]');
        let lastNameNode = this.template.querySelector('[data-formfield="lastName"]');
        let regEmailNode = this.template.querySelector('[data-formfield="regEmail"]');
        let passNode = this.template.querySelector('[data-formfield="password1"]');
        //let regDobNode = this.template.querySelector('[data-formfield="regDob"]');
        let regPhone = this.template.querySelector('[data-formfield="regPhone"]');

        let a1node = this.template.querySelector('[data-formfield="address1"]');
        let a2node = this.template.querySelector('[data-formfield="address2"]');
        let a3node = this.template.querySelector('[data-formfield="address3"]');
        let postalCodeNode = this.template.querySelector('[data-formfield="postalCode"]');
        let cityNode = this.template.querySelector('[data-formfield="city"]');
        let countyNode = this.template.querySelector('[data-formfield="county"]');
        let genderNode = this.template.querySelector('[data-formfield="gender"]');


        firstNameNode.reportValidity();
        lastNameNode.reportValidity();
        regEmailNode.reportValidity();
        passNode.reportValidity();
        regPhone.reportValidity();
        genderNode.reportValidity();
        let dobValid = this.validateDOB();

        a1node.reportValidity();
        a2node.reportValidity();
        a3node.reportValidity();
        postalCodeNode.reportValidity();
        cityNode.reportValidity();
        countyNode.reportValidity();

        let regEmailNode2 = this.template.querySelector('[data-formfield="regEmail2"]');
        let emailsSame = true;
        if (regEmailNode.value !== regEmailNode2.value) {
            regEmailNode2.setCustomValidity('E-mail fields must match');
            emailsSame = false;
        } else {
            regEmailNode2.setCustomValidity('');
        }
        regEmailNode2.reportValidity();

        let passNode2 = this.template.querySelector('[data-formfield="password2"]');
        let passSame = true;
        if (passNode.value !== passNode2.value) {
            passNode2.setCustomValidity('Password fields must match');
            passSame = false;
        } else {
            passNode2.setCustomValidity('');
        }
        regEmailNode2.reportValidity();

        if (!firstNameNode.validity.valid
            || !lastNameNode.validity.valid
            || !regEmailNode.validity.valid
            || !genderNode.validity.valid
            || !emailsSame
            || !dobValid
            || !regPhone.validity.valid
            || !passNode.validity.valid
            || !passNode2.validity.valid
            || !passSame
        ) return;

        this.loading = true;
        clearLoggedInCookie();

        let req = {
            firstName: firstNameNode.value,
            lastName: lastNameNode.value,
            email: regEmailNode.value,
            dob: this.inputDobDate,
            phone: regPhone.value,
            address1: a1node.value,
            address2: a2node.value,
            address3: a3node.value,
            postalCode: postalCodeNode.value,
            city: cityNode.value,
            county: countyNode.value,
            password: passNode.value,
            gender: genderNode.value
        };

        this.registrationEmail = req.email;

        if (this.dev) console.log('::queueRegister:req:', req);
        queueRegister({request: JSON.stringify(req)})
            .then(results => {
                if (this.dev) console.log('::queueRegister:result', results);

                if (results) {

                    if (results.indexOf('EMAIL_ALREADY_REGISTERED_WITH_PASSWORD') >= 0) {
                        this.msgRegister = 'There is already an Account registered with that email address. Please contact us at the details shown below and we will help you with the registration process';
                    } else if (results.indexOf('DOB_DIFFERENT') >= 0) {
                        this.msgRegister = 'There is already an Account with your e-mail in the system, please contact us for assistance';
                    } else if (results.indexOf('MULTIPLE_CANDIDATES') >= 0) {
                        this.msgRegister = 'You currently have multiple records with the same email address. Please contact us at the details shown below and we will help you with the registration process';
                    } else {
                        if (this.dev) console.error('::queueRegister:failed', results);
                        this.msgRegister = 'There was a problem registering your Account. Please try later';
                    }
                } else {

                    this.dispatchEvent(new CustomEvent('sessionchange', {
                        detail: {
                            stage: 'registerRequested',
                            email: req.email
                        }
                    }));
                    this.step = {finish: true};
                }

            })
            .catch(error => {
                if (this.dev) console.error('::queueRegister:ex', error);
                this.msgRegister = '';
            })
            .finally(() => {
                this.loading = false;
            });
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

    handlePassChangeRequest(e) {
        if (this.dev) console.log('::handlePassChangeRequest');
        let emailNode = this.template.querySelector('[data-formfield="email4pass"]');
        if (!emailNode || !emailNode.value) return;

        this.loading = true;

        queuePassChange({email: emailNode.value})
            .then(results => {
                if (this.dev) console.log('::queuePassChange:result', results);
                if (!results) {
                    this.step = {finishedPassRequest: true};
                } else {
                    if (results.indexOf('ERR_NOT_REGISTERED') >= 0) {
                        this.msgRegister = 'The provided e-mail is not registered with us. Kindly register to start using our service.';
                    } else {
                        this.msgRegister = 'There was a problem requesting password change. Please try later.';
                    }
                }
            })
            .catch(error => {
                if (this.dev) console.error('::queuePassChange:ex', error);
                this.msgRegister = 'There was a problem requesting password change. Please try later.';
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handlePostcodeSearch(event) {

        if (!event || !event.detail || !event.detail.searchTerm) return;
        const target = event.target;

        let query = event.detail.searchTerm;

        // console.log('query0', query);

        if (query && query.length >= 2) {
            if (query.length > 16) query = query.substring(0, 16);

            this.provisionalPostCode = query;

            query = query.replace(/[^a-z0-9 ]/gi, ''); //.replace(/[ ]/gi,'+');

            //console.log('query1', query);

            let xmlHttp = new XMLHttpRequest();
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4 && xmlHttp.status === 200) {
                    //console.log(xmlHttp.responseText);
                    let res = JSON.parse(xmlHttp.responseText);
                    let list = [];
                    if (res && res.result && res.result.total > 0 && res.result.hits && res.result.hits.length > 0) {

                        for (let hit of res.result.hits) {
                            // console.log('hit', hit);

                            list.push({
                                id: hit.postcode + '#' + hit.uprn,
                                title: hit.postcode,
                                subtitle: hit.line_1 + ' ' + hit.line_2,
                                data: hit
                            });

                        }
                        // console.log('list', list);
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

    handleContinueFromMultiple() {
        this.dispatchEvent(new CustomEvent('login', {
            detail: {
                ptu: this.selectedAccountToBook
            }
        }));
    }

    handleAccountChanged(e) {
        this.selectedAccountToBook = e.currentTarget.value;
        if (this.dev) console.log(':::selectedAccountToBook', this.selectedAccountToBook);
    }

    handleProceed(e) {
        //check activation code
        this.loadingActivationCode = true;
        this.msgActivation = null;

        let acNode = this.template.querySelector('[data-id="activationCode"]');

        this.dispatchEvent(new CustomEvent('sessionchange', {
            detail: {
                stage: 'registerActivated',
                email: this.registrationEmail
            }
        }));

        let activationCode;
        if (acNode) activationCode = acNode.value;
        if (this.dev) console.log('::activateRegistrationByCode:req', {email: this.registrationEmail, code: activationCode});
        activateRegistrationByCode({email: this.registrationEmail, code: activationCode})
            .then(results => {
                if (this.dev) console.log('::activateRegistrationByCode:result', results);
                if (results) {
                    this.dispatchEvent(new CustomEvent('login', {
                        detail: {
                            ptu: results
                        }
                    }));
                } else this.msgActivation = 'Not a valid activation code';

            })
            .catch(error => {
                console.error('::activateRegistrationByCode:failed', error);
                this.msgActivation = 'There was a problem activating your Account. Please try later';
            })
            .finally(() => {
                this.loadingActivationCode = false;
            });

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

    checkDateIsValid(y, m, d) {
        let dte = new Date(y + '/' + m + '/' + d);

        if (!dte.isSameAs(y, m, d)) return null; else return (
            y + '-' +
            (m < 10 ? '0' + m : m)
            + '-' +
            (d < 10 ? '0' + d : d));
    }
}