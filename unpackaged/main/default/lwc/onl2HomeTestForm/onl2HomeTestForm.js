/**
 * Created 19.4.2021..
 */

import {LightningElement, api, wire} from 'lwc';
import getCovidTestForUUID from '@salesforce/apex/onl_HomeTestCtrl.getCovidTestForUUID';
import verifyOTP from '@salesforce/apex/onl_HomeTestCtrl.verifyOTP';
import getCustomSettings from '@salesforce/apex/onl_HomeTestCtrl.getCustomSettings';
import storeHomeTestResult from '@salesforce/apex/onl_HomeTestCtrl.storeHomeTestResult';
import getPicklistOptions from '@salesforce/apex/onl_HomeTestCtrl.getHomeTestResultTypeOptions';
import contactPhone from '@salesforce/label/c.Store_Contact_Phone';

/**
 * Notes
 * used for:
 * 1) regular use case when link is provided in email to provide result for Self Test (uuid needs to be is provided)
 * 2) Bundle use case, where N (5 or 10) covid test are preprovisioned, and link is to a "lateral test", for which we have to first ask the type (genericCovidTest=true) (uuid needs to be is provided)
 * 3) Resellers use case, where we have no test precreated, and 'c' query parameter is present (otp code)
 */
export default class Onl2HomeTestForm extends LightningElement {

    @api queryParameters;

    @wire(getCustomSettings)
    myCustomSettings;

    loading = false;
    saving = false;
    saved = false;
    saved_Booking_Reference__c
    dataReady = false;
    fetchError = false;
    ctestNotApplicable = false;
    ctestAlreadyProcessed = false;
    saveError = false;
    genericCovidTest = false;
    resellerUseCase = false;
    invalid_OTP = false;

    filesRequired = false;

    isFitToFly = false;
    isDay2 = false;
    isDay5 = false;
    isDay8 = false;
    isUkEntry = false;

    preselectedPostalCode;
    provisionalPostCode;

    _contactPhone = contactPhone;

    form;
    uuid;
    otpcode;
    ctestid;

    waitForPin = false;

    dobDateValid = true;
    inputDobDate = null;

    get isDay2or8() {
        return this.isDay2 || this.isDay8
    }

    get uploadPhotoLabel() {
        if (this.filesRequired) return '* Photo: (REQUIRED)'
        else return 'Photo:'
    }

    attachment1 = {};
    attachment2 = {};
    attachment3 = {};

    productSelected = false;

    ddOptions = [];
    mmOptions = [];
    yyOptions = [];

    get acceptedFormats() {
        return ['.bmp', '.png', '.gif', '.jpg', '.jpeg'];
    }

    countryOptions = [
        {
            "value": "1",
            "label": "United Kingdom"
        },
        {
            "value": "153",
            "label": "Ireland"
        },
        {
            "value": "154",
            "label": "Afghanistan"
        },
        {
            "value": "155",
            "label": "Åland Islands"
        },
        {
            "value": "156",
            "label": "Albania"
        },
        {
            "value": "157",
            "label": "Algeria"
        },
        {
            "value": "158",
            "label": "American Samoa"
        },
        {
            "value": "159",
            "label": "Andorra"
        },
        {
            "value": "160",
            "label": "Angola"
        },
        {
            "value": "161",
            "label": "Anguilla"
        },
        {
            "value": "162",
            "label": "Antarctica"
        },
        {
            "value": "163",
            "label": "Antigua and Barbuda"
        },
        {
            "value": "164",
            "label": "Argentina"
        },
        {
            "value": "165",
            "label": "Armenia"
        },
        {
            "value": "166",
            "label": "Aruba"
        },
        {
            "value": "167",
            "label": "Australia"
        },
        {
            "value": "168",
            "label": "Austria"
        },
        {
            "value": "169",
            "label": "Azerbaijan"
        },
        {
            "value": "170",
            "label": "Bahamas"
        },
        {
            "value": "171",
            "label": "Bahrain"
        },
        {
            "value": "172",
            "label": "Bangladesh"
        },
        {
            "value": "173",
            "label": "Barbados"
        },
        {
            "value": "174",
            "label": "Belarus"
        },
        {
            "value": "175",
            "label": "Belgium"
        },
        {
            "value": "176",
            "label": "Belize"
        },
        {
            "value": "177",
            "label": "Benin"
        },
        {
            "value": "178",
            "label": "Bermuda"
        },
        {
            "value": "179",
            "label": "Bhutan"
        },
        {
            "value": "152",
            "label": "Bolivia"
        },
        {
            "value": "151",
            "label": "Bosnia and Herzegovina"
        },
        {
            "value": "150",
            "label": "Botswana"
        },
        {
            "value": "135",
            "label": "Bouvet Island"
        },
        {
            "value": "123",
            "label": "Brazil"
        },
        {
            "value": "124",
            "label": "British Indian Ocean Territory"
        },
        {
            "value": "125",
            "label": "Brunei Darussalam"
        },
        {
            "value": "126",
            "label": "Bulgaria"
        },
        {
            "value": "127",
            "label": "Burkina Faso"
        },
        {
            "value": "128",
            "label": "Burundi"
        },
        {
            "value": "129",
            "label": "Cambodia"
        },
        {
            "value": "130",
            "label": "Cameroon"
        },
        {
            "value": "131",
            "label": "Canada"
        },
        {
            "value": "132",
            "label": "Cape Verde"
        },
        {
            "value": "133",
            "label": "Cayman Islands"
        },
        {
            "value": "134",
            "label": "Central African Republic"
        },
        {
            "value": "136",
            "label": "Chad"
        },
        {
            "value": "149",
            "label": "Chile"
        },
        {
            "value": "137",
            "label": "China"
        },
        {
            "value": "138",
            "label": "Christmas Island"
        },
        {
            "value": "139",
            "label": "Cocos (Keeling) Islands"
        },
        {
            "value": "140",
            "label": "Colombia"
        },
        {
            "value": "141",
            "label": "Comoros"
        },
        {
            "value": "142",
            "label": "Congo"
        },
        {
            "value": "143",
            "label": "Congo, The Democratic Republic of the"
        },
        {
            "value": "144",
            "label": "Cook Islands"
        },
        {
            "value": "145",
            "label": "Costa Rica"
        },
        {
            "value": "146",
            "label": "Cote D\"Ivoire"
        },
        {
            "value": "147",
            "label": "Croatia"
        },
        {
            "value": "148",
            "label": "Cuba"
        },
        {
            "value": "180",
            "label": "Cyprus"
        },
        {
            "value": "182",
            "label": "Czech Republic"
        },
        {
            "value": "241",
            "label": "Denmark"
        },
        {
            "value": "183",
            "label": "Djibouti"
        },
        {
            "value": "214",
            "label": "Dominica"
        },
        {
            "value": "215",
            "label": "Dominican Republic"
        },
        {
            "value": "216",
            "label": "Ecuador"
        },
        {
            "value": "217",
            "label": "Egypt"
        },
        {
            "value": "218",
            "label": "El Salvador"
        },
        {
            "value": "219",
            "label": "Equatorial Guinea"
        },
        {
            "value": "220",
            "label": "Eritrea"
        },
        {
            "value": "221",
            "label": "Estonia"
        },
        {
            "value": "222",
            "label": "Ethiopia"
        },
        {
            "value": "223",
            "label": "Falkland Islands (Malvinas)"
        },
        {
            "value": "224",
            "label": "Faroe Islands"
        },
        {
            "value": "225",
            "label": "Fiji"
        },
        {
            "value": "226",
            "label": "Finland"
        },
        {
            "value": "227",
            "label": "France"
        },
        {
            "value": "228",
            "label": "French Guiana"
        },
        {
            "value": "229",
            "label": "French Polynesia"
        },
        {
            "value": "230",
            "label": "French Southern Territories"
        },
        {
            "value": "231",
            "label": "Gabon"
        },
        {
            "value": "232",
            "label": "Gambia"
        },
        {
            "value": "233",
            "label": "Georgia"
        },
        {
            "value": "234",
            "label": "Germany"
        },
        {
            "value": "235",
            "label": "Ghana"
        },
        {
            "value": "236",
            "label": "Gibraltar"
        },
        {
            "value": "237",
            "label": "Greece"
        },
        {
            "value": "238",
            "label": "Greenland"
        },
        {
            "value": "239",
            "label": "Grenada"
        },
        {
            "value": "240",
            "label": "Guadeloupe"
        },
        {
            "value": "213",
            "label": "Guam"
        },
        {
            "value": "212",
            "label": "Guatemala"
        },
        {
            "value": "211",
            "label": "Guernsey"
        },
        {
            "value": "196",
            "label": "Guinea"
        },
        {
            "value": "184",
            "label": "Guinea-Bissau"
        },
        {
            "value": "185",
            "label": "Guyana"
        },
        {
            "value": "186",
            "label": "Haiti"
        },
        {
            "value": "187",
            "label": "Heard Island and Mcdonald Islands"
        },
        {
            "value": "188",
            "label": "Vatican City State"
        },
        {
            "value": "189",
            "label": "Honduras"
        },
        {
            "value": "190",
            "label": "Hong Kong"
        },
        {
            "value": "191",
            "label": "Hungary"
        },
        {
            "value": "192",
            "label": "Iceland"
        },
        {
            "value": "193",
            "label": "India"
        },
        {
            "value": "194",
            "label": "Indonesia"
        },
        {
            "value": "195",
            "label": "Iran, Islamic Republic Of"
        },
        {
            "value": "197",
            "label": "Iraq"
        },
        {
            "value": "210",
            "label": "Isle of Man"
        },
        {
            "value": "198",
            "label": "Israel"
        },
        {
            "value": "199",
            "label": "Italy"
        },
        {
            "value": "200",
            "label": "Jamaica"
        },
        {
            "value": "201",
            "label": "Japan"
        },
        {
            "value": "202",
            "label": "Jersey"
        },
        {
            "value": "203",
            "label": "Jordan"
        },
        {
            "value": "204",
            "label": "Kazakhstan"
        },
        {
            "value": "205",
            "label": "Kenya"
        },
        {
            "value": "206",
            "label": "Kiribati"
        },
        {
            "value": "207",
            "label": "Korea, Democratic People\"s Republic of"
        },
        {
            "value": "208",
            "label": "Korea, Republic of"
        },
        {
            "value": "209",
            "label": "Kuwait"
        },
        {
            "value": "122",
            "label": "Kyrgyzstan"
        },
        {
            "value": "121",
            "label": "Lao People\"s Democratic Republic"
        },
        {
            "value": "120",
            "label": "Latvia"
        },
        {
            "value": "119",
            "label": "Lebanon"
        },
        {
            "value": "32",
            "label": "Lesotho"
        },
        {
            "value": "33",
            "label": "Liberia"
        },
        {
            "value": "34",
            "label": "Libyan Arab Jamahiriya"
        },
        {
            "value": "35",
            "label": "Liechtenstein"
        },
        {
            "value": "36",
            "label": "Lithuania"
        },
        {
            "value": "37",
            "label": "Luxembourg"
        },
        {
            "value": "38",
            "label": "Macao"
        },
        {
            "value": "39",
            "label": "Macedonia, The Former Yugoslav Republic of"
        },
        {
            "value": "40",
            "label": "Madagascar"
        },
        {
            "value": "41",
            "label": "Malawi"
        },
        {
            "value": "42",
            "label": "Malaysia"
        },
        {
            "value": "43",
            "label": "Maldives"
        },
        {
            "value": "45",
            "label": "Mali"
        },
        {
            "value": "58",
            "label": "Malta"
        },
        {
            "value": "46",
            "label": "Marshall Islands"
        },
        {
            "value": "47",
            "label": "Martinique"
        },
        {
            "value": "48",
            "label": "Mauritania"
        },
        {
            "value": "49",
            "label": "Mauritius"
        },
        {
            "value": "50",
            "label": "Mayotte"
        },
        {
            "value": "51",
            "label": "Mexico"
        },
        {
            "value": "52",
            "label": "Micronesia, Federated States of"
        },
        {
            "value": "53",
            "label": "Moldova, Republic of"
        },
        {
            "value": "54",
            "label": "Monaco"
        },
        {
            "value": "55",
            "label": "Mongolia"
        },
        {
            "value": "56",
            "label": "Montserrat"
        },
        {
            "value": "57",
            "label": "Morocco"
        },
        {
            "value": "31",
            "label": "Mozambique"
        },
        {
            "value": "44",
            "label": "Myanmar"
        },
        {
            "value": "30",
            "label": "Namibia"
        },
        {
            "value": "14",
            "label": "Nauru"
        },
        {
            "value": "2",
            "label": "Nepal"
        },
        {
            "value": "3",
            "label": "Netherlands"
        },
        {
            "value": "4",
            "label": "Netherlands Antilles"
        },
        {
            "value": "5",
            "label": "New Caledonia"
        },
        {
            "value": "6",
            "label": "New Zealand"
        },
        {
            "value": "7",
            "label": "Nicaragua"
        },
        {
            "value": "8",
            "label": "Niger"
        },
        {
            "value": "9",
            "label": "Nigeria"
        },
        {
            "value": "10",
            "label": "Niue"
        },
        {
            "value": "11",
            "label": "Norfolk Island"
        },
        {
            "value": "12",
            "label": "Northern Mariana Islands"
        },
        {
            "value": "13",
            "label": "Norway"
        },
        {
            "value": "15",
            "label": "Oman"
        },
        {
            "value": "28",
            "label": "Pakistan"
        },
        {
            "value": "16",
            "label": "Palau"
        },
        {
            "value": "17",
            "label": "Panama"
        },
        {
            "value": "18",
            "label": "Papua New Guinea"
        },
        {
            "value": "19",
            "label": "Paraguay"
        },
        {
            "value": "20",
            "label": "Peru"
        },
        {
            "value": "21",
            "label": "Philippines"
        },
        {
            "value": "22",
            "label": "Pitcairn"
        },
        {
            "value": "23",
            "label": "Poland"
        },
        {
            "value": "24",
            "label": "Portugal"
        },
        {
            "value": "25",
            "label": "Puerto Rico"
        },
        {
            "value": "26",
            "label": "Qatar"
        },
        {
            "value": "27",
            "label": "Reunion"
        },
        {
            "value": "29",
            "label": "Romania"
        },
        {
            "value": "59",
            "label": "Russian Federation"
        },
        {
            "value": "60",
            "label": "Rwanda"
        },
        {
            "value": "61",
            "label": "Saint Helena"
        },
        {
            "value": "92",
            "label": "Saint Kitts and Nevis"
        },
        {
            "value": "93",
            "label": "Saint Lucia"
        },
        {
            "value": "94",
            "label": "Saint Pierre and Miquelon"
        },
        {
            "value": "95",
            "label": "Saint Vincent and the Grenadines"
        },
        {
            "value": "96",
            "label": "Samoa"
        },
        {
            "value": "97",
            "label": "San Marino"
        },
        {
            "value": "98",
            "label": "Sao Tome and Principe"
        },
        {
            "value": "99",
            "label": "Saudi Arabia"
        },
        {
            "value": "100",
            "label": "Senegal"
        },
        {
            "value": "101",
            "label": "Serbia and Montenegro"
        },
        {
            "value": "102",
            "label": "Seychelles"
        },
        {
            "value": "103",
            "label": "Sierra Leone"
        },
        {
            "value": "104",
            "label": "Singapore"
        },
        {
            "value": "105",
            "label": "Slovakia"
        },
        {
            "value": "106",
            "label": "Slovenia"
        },
        {
            "value": "107",
            "label": "Solomon Islands"
        },
        {
            "value": "108",
            "label": "Somalia"
        },
        {
            "value": "109",
            "label": "South Africa"
        },
        {
            "value": "110",
            "label": "South Georgia and the South Sandwich Islands"
        },
        {
            "value": "111",
            "label": "Spain"
        },
        {
            "value": "112",
            "label": "Sri Lanka"
        },
        {
            "value": "113",
            "label": "Sudan"
        },
        {
            "value": "114",
            "label": "Suriname"
        },
        {
            "value": "115",
            "label": "Svalbard and Jan Mayen"
        },
        {
            "value": "116",
            "label": "Swaziland"
        },
        {
            "value": "117",
            "label": "Sweden"
        },
        {
            "value": "118",
            "label": "Switzerland"
        },
        {
            "value": "91",
            "label": "Syrian Arab Republic"
        },
        {
            "value": "90",
            "label": "Taiwan, Province of China"
        },
        {
            "value": "89",
            "label": "Tajikistan"
        },
        {
            "value": "74",
            "label": "Tanzania, United Republic of"
        },
        {
            "value": "62",
            "label": "Thailand"
        },
        {
            "value": "63",
            "label": "Timor-Leste"
        },
        {
            "value": "64",
            "label": "Togo"
        },
        {
            "value": "65",
            "label": "Tokelau"
        },
        {
            "value": "66",
            "label": "Tonga"
        },
        {
            "value": "67",
            "label": "Trinidad and Tobago"
        },
        {
            "value": "68",
            "label": "Tunisia"
        },
        {
            "value": "69",
            "label": "Turkey"
        },
        {
            "value": "70",
            "label": "Turkmenistan"
        },
        {
            "value": "71",
            "label": "Turks and Caicos Islands"
        },
        {
            "value": "72",
            "label": "Tuvalu"
        },
        {
            "value": "73",
            "label": "Uganda"
        },
        {
            "value": "75",
            "label": "Ukraine"
        },
        {
            "value": "88",
            "label": "United Arab Emirates"
        },
        {
            "value": "76",
            "label": "United States"
        },
        {
            "value": "77",
            "label": "United States Minor Outlying Islands"
        },
        {
            "value": "78",
            "label": "Uruguay"
        },
        {
            "value": "79",
            "label": "Uzbekistan"
        },
        {
            "value": "80",
            "label": "Vanuatu"
        },
        {
            "value": "81",
            "label": "Venezuela"
        },
        {
            "value": "82",
            "label": "Vietnam"
        },
        {
            "value": "83",
            "label": "Virgin Islands, British"
        },
        {
            "value": "84",
            "label": "Virgin Islands, U.S."
        },
        {
            "value": "85",
            "label": "Wallis and Futuna"
        },
        {
            "value": "86",
            "label": "Western Sahara"
        },
        {
            "value": "87",
            "label": "Yemen"
        },
        {
            "value": "181",
            "label": "Zambia"
        },
        {
            "value": "242",
            "label": "Zimbabwe"
        }
    ];

    _vacStatusOptions = [{"value": "Yes", "label": "Fully Vaccinated"}, {"value": "No", "label": "Not Fully Vaccinated"}];
    /*
    _testTypeOptions = [

        {"value": "Fit to Fly", "label": "Fit to Fly"},
        {"value": "Day 2 Test", "label": "Day 2 Test"},
        {"value": "UK Entry Test","label": "UK Entry Test"}
    ];
     */

    _testTypeOptions = [];

    get vacStatusOptions() {
        return this._vacStatusOptions;
    }

    connectedCallback() {
        // console.log('cc', this.queryParameters);
        this.uuid = this.queryParameters['uid'];
        this.otpcode = this.queryParameters['c'];

        if (this.otpcode) {
            this.otpcode = this.otpcode.toUpperCase();
            this.resellerUseCase = true;
            this.genericCovidTest = true;
        }

        //console.log('r|g',(this.resellerUseCase?'t|':'f') +(this.genericCovidTest?'t':'f'))
        this.form = {};

        if (!this.uuid && !this.otpcode) {
            this.fetchError = false;
            this.waitForPin = true;
            this.resellerUseCase = true;
            this.genericCovidTest = true;
            this.filesRequired = true;
            this.dataReady = true;
        } else if (this.queryParameters && this.uuid) {
            this.fetchData(this.uuid);
        } else if (this.queryParameters && this.otpcode) {
            this.verifyPinCode(this.otpcode);
            //this.dataReady = true;
        } else {
            this.fetchError = true;
            return;
        }

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

        this.fetchPicklistOptions();

        Date.prototype.isSameAs = function (y, m, d) {
            if (this.getTime() !== this.getTime()) return false;

            if (this.getFullYear() !== y) return false;
            if ((this.getMonth() + 1) !== m) return false;
            if (this.getDate() !== d) return false;

            return true;
        };
    }

    fetchPicklistOptions() {
        getPicklistOptions()
            .then(result => {
                console.log('::htf:fetchPicklistOptions:result', result);
                this._testTypeOptions = JSON.parse(result);
            })
            .catch(error => {
                console.error('::htf:fetchPicklistOptions:failed', error);
            })
            .finally(() => {
                }
            );

    }

    fetchData(uid) {

        if (uid) {
            this.loading = true;
            console.log('::htf:getCovidTestForUUID:uuid=', uid);
            getCovidTestForUUID({uuid: uid})
                .then(result => {
                    console.log('::htf:getCovidTestForUUID:result', result);

                    if (result) {
                        let covidTest = JSON.parse(result);

                        if (covidTest) {

                            delete covidTest.attributes;

                            this.ctestid = covidTest.Id;

                            if (!covidTest.Is_Home_Kit_Test__c) {
                                this.ctestNotApplicable = true;
                            } else if (
                                (covidTest.COVID_Test_Status__c !== 'New')
                                && (covidTest.COVID_Test_Status__c !== 'Registered')
                                && (covidTest.COVID_Test_Status__c !== 'Received')
                                && (covidTest.COVID_Test_Status__c !== 'Unclear')
                            ) {
                                this.ctestAlreadyProcessed = true;
                            } else {

                                this.processTestType(covidTest.Test_Type__c);

                                if (this.genericCovidTest) {
                                    covidTest.Test_Type__c = null;
                                }


                                this.form = covidTest;

                                if (this.form.Provided_Date_of_Birth__c) {
                                    try {
                                        let splits = this.form.Provided_Date_of_Birth__c.split('-');
                                        if (splits.length === 3) {
                                            this.form.dob_y = '' + parseInt(splits[0]);
                                            this.form.dob_m = '' + parseInt(splits[1]);
                                            this.form.dob_d = '' + parseInt(splits[2]);
                                        }
                                    } catch (ex) {}
                                }

                                if (covidTest.Provided_Postal_Code__c) {
                                    let list_pc = [];
                                    list_pc.push({id: covidTest.Provided_Postal_Code__c, title: covidTest.Provided_Postal_Code__c});
                                    this.preselectedPostalCode = list_pc;
                                }

                                //if covid test is still new, require all files
                                this.filesRequired = (covidTest.COVID_Test_Status__c === 'New');
                                console.log('this.filesRequired:' + this.filesRequired);


                                this.dataReady = true;
                            }
                        } else {
                            this.fetchError = true;
                        }
                    } else {
                        this.fetchError = true;
                    }
                })
                .catch(error => {
                    console.error('::htf:getOpportunity:failed', error);
                    this.fetchError = true;
                })
                .finally(() => {
                        this.loading = false;
                    }
                );
        }
    }

    verifyPinCode(otp) {

        if (otp) {
            this.loading = true;
            console.log('::htf:vpc', otp);
            verifyOTP({otp: otp})
                .then(result => {
                    console.log('::htf:getCovidTestForUUID:result', result);

                    if (result) {
                        let covidTest = JSON.parse(result);

                        if (covidTest) {

                            delete covidTest.attributes;

                            this.ctestid = covidTest.Id;

                            if (
                                (covidTest.COVID_Test_Status__c !== 'New')
                                && (covidTest.COVID_Test_Status__c !== 'Registered')
                                && (covidTest.COVID_Test_Status__c !== 'Received')
                                && (covidTest.COVID_Test_Status__c !== 'Unclear')
                            ) {
                                this.ctestAlreadyProcessed = true;
                            } else {

                                this.processTestType(covidTest.Test_Type__c);

                                if (this.genericCovidTest) {
                                    covidTest.Test_Type__c = null;
                                }

                                this.form = covidTest;

                                if (this.form.Provided_Date_of_Birth__c) {
                                    try {
                                        let splits = this.form.Provided_Date_of_Birth__c.split('-');
                                        if (splits.length === 3) {
                                            this.form.dob_y = '' + parseInt(splits[0]);
                                            this.form.dob_m = '' + parseInt(splits[1]);
                                            this.form.dob_d = '' + parseInt(splits[2]);
                                        }
                                    } catch (ex) {}
                                }

                                if (covidTest.Provided_Postal_Code__c) {
                                    let list_pc = [];
                                    list_pc.push({id: covidTest.Provided_Postal_Code__c, title: covidTest.Provided_Postal_Code__c});
                                    this.preselectedPostalCode = list_pc;
                                }

                                //if covid test is still new, require all files
                                this.filesRequired = (covidTest.COVID_Test_Status__c === 'New');
                                console.log('this.filesRequired:' + this.filesRequired);

                                this.dataReady = true;
                            }
                        } else {
                            this.fetchError = true;
                        }
                    } else {
                        this.fetchError = true;
                    }
                })
                .catch(error => {
                    console.error('::htf:vpc:failed', error);
                    this.fetchError = true;
                })
                .finally(() => {
                        this.loading = false;
                    }
                );
        }
    }

    processTestType(tip) {
        let _type = tip.toLowerCase();

        this.isFitToFly = false;
        this.isDay5 = false;
        this.isDay2 = false;
        this.isDay8 = false;
        this.isUkEntry = false;

        if (_type.indexOf('fit to fly') >= 0) {
            this.isFitToFly = true;
        } else if ((_type.indexOf('test to release') >= 0) || (_type.indexOf('day 5') >= 0)) {
            this.isDay5 = true;
        } else if (_type.indexOf('day 2') >= 0) {
            this.isDay2 = true;
        } else if (_type.indexOf('day 8') >= 0) {
            this.isDay8 = true;
        } else if (_type.indexOf('uk entry') >= 0) {
            this.isUkEntry = true;
        } else if (_type === 'lateral flow') {
            this.genericCovidTest = true;
        }

    }

    // on file-upload control finished, add name and documentIds to local arrays
    handleUploadFinished1(event) {
        if (event.detail.files.length > 0) {
            this.attachment1 = event.detail.files[0];
        }
    }

    handleUploadFinished2(event) {
        if (event.detail.files.length > 0) {
            this.attachment2 = event.detail.files[0];
        }
    }

    handleUploadFinished3(event) {
        if (event.detail.files.length > 0) {
            this.attachment3 = event.detail.files[0];
        }
    }

    handleSubmit() {

        if (!this.validateForm()) {
            //console.log('validation failed');
        } else {
            //console.log('validation ok');

            // save to form the combination of year/month/date entered for DOB
            this.form.Provided_Date_of_Birth__c = this.inputDobDate;

            //RAW value in postcode is postcode#uprn, we need only UPRN
            if (this.form.Provided_Postal_Code__c && this.form.Provided_Postal_Code__c.indexOf('#') > 0) this.form.Provided_Postal_Code__c = this.form.Provided_Postal_Code__c.split('#')[0];
            if (!this.form.Provided_Postal_Code__c && this.provisionalPostCode) this.form.Provided_Postal_Code__c = this.provisionalPostCode;


            let params = {};
            params.otpc = this.form.Provided_OtpCode;
            params.test = this.form;
            params.uuid = this.uuid;
            params.attachment1 = this.attachment1;
            params.attachment2 = this.attachment2;
            params.attachment3 = this.attachment3;

            let _params_json = JSON.stringify(params);
            // console.log('::handleSubmit:storeHomeTestResult:params', params);

            this.saving = true;
            storeHomeTestResult({params: _params_json})
                .then(result => {
                    if (result == 'INVALID_OTP') {
                        console.log('::hs:r', result);
                        this.invalid_OTP = true;
                    } else {
                        this.saved_Booking_Reference__c = result;
                        this.saved = true;
                    }
                })
                .catch(error => {
                    console.error('::handleSubmit:failed', error);
                })
                .finally(() => {
                        this.saving = false;
                    }
                );
        }
    }

    validateForm() {
        let inputs = this.template.querySelectorAll('[data-id]');
        let valid = true;
        if (inputs) {
            for (let input of inputs) {
                if (input.required) {
                    if (!(input.value || input.checked)) valid = false;
                }
                this.form[input.getAttribute('data-id')] = input.value;
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }
        valid = valid && this.validateDOB();
        valid = valid && this.validateAttachments();

        return valid;
    }


    handlePostcodeSelection(event) {
        let al1Node = this.template.querySelector('[data-id="Provided_Address_Line1__c"]');
        let al2Node = this.template.querySelector('[data-id="Provided_Address_Line2__c"]');
        let cityNode = this.template.querySelector('[data-id="Provided_City__c"]');
        let countryNode = this.template.querySelector('[data-id="Provided_Country__c"]');

        if (event && event.detail && event.detail.length > 0 && event.detail[0].id && event.detail[0].data) {
            let hit = event.detail[0].data;
            console.log('selected ev', JSON.stringify(hit));


            if (al1Node) {
                al1Node.value = hit.line_1;
                al1Node.showHelpMessageIfInvalid();
            }
            if (al2Node) {
                al2Node.value = hit.line_2;
                al2Node.showHelpMessageIfInvalid();
            }
            if (cityNode) {
                cityNode.value = hit.post_town;
                cityNode.showHelpMessageIfInvalid();
            }
            if (countryNode) {
                countryNode.value = "1";
                countryNode.showHelpMessageIfInvalid();
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
            if (cityNode) {
                cityNode.value = null;
                cityNode.showHelpMessageIfInvalid();
            }
            if (countryNode) {
                countryNode.value = null;
                countryNode.showHelpMessageIfInvalid();
            }

        }
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

    handleTestTypeChanged(e) {
        this.processTestType(e.target.value);
    }


    validateAttachments() {
        if (!this.filesRequired) return true;

        let inputs = this.template.querySelectorAll('lightning-input');
        let valid = true;
        if (inputs) {
            for (let input of inputs) {
                if (input.required) {
                    if (!(input.value || input.checked)) valid = false;
                }
                if (input && input.showHelpMessageIfInvalid) input.showHelpMessageIfInvalid();
            }
        }

        let attachmentsOk = this.attachment1 && this.attachment2 && this.attachment3
            && this.attachment1.name && this.attachment2.name && this.attachment3.name
            && this.attachment1.documentId && this.attachment2.documentId && this.attachment3.documentId;

        if (!attachmentsOk) {
            alert('Please upload all the required photos');
        }

        return attachmentsOk;
    }


    // validates if the entered date + month + year is a valid date
    validateDOB() {

        this.dobDateValid = false;

        let f_dobD = this.template.querySelector('[data-id="dob_d"]');
        let f_dobM = this.template.querySelector('[data-id="dob_m"]');
        let f_dobY = this.template.querySelector('[data-id="dob_y"]');

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
            f_dobY.setCustomValidity();
            f_dobM.setCustomValidity();
            f_dobD.setCustomValidity();
        }

        f_dobY.showHelpMessageIfInvalid();
        f_dobM.showHelpMessageIfInvalid();
        f_dobD.showHelpMessageIfInvalid();

        return this.dobDateValid;

    }

    handleOTPChanged(e) {
        this.invalid_OTP = (!e.target.value || (e.target.value.length != 6));
    }

    handleContinue(e) {
        let input = this.template.querySelector('[data-id="otpcode"]');
        if (input) {
            window.location = '?c=' + input.value;
        }

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