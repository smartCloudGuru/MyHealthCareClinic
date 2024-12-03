/**
 * Created 19.4.2021..
 */

import {LightningElement, api, wire} from 'lwc';
import getCovidTestForUUID from '@salesforce/apex/onl_InfoFormCtrl.getCovidTestForUUID';
import getCustomSettings from '@salesforce/apex/onl_InfoFormCtrl.getCustomSettings';
import storeCovidTest from '@salesforce/apex/onl_InfoFormCtrl.storeCovidTest';
import contactPhone from '@salesforce/label/c.Store_Contact_Phone';

export default class OnlTestForm extends LightningElement {

    @api queryParameters;

    @wire(getCustomSettings)
    myCustomSettings;

    loading = false;
    saving = false;
    saved = false;
    dataReady = false;
    fetchError = false;
    saveError = false;

    isFitToFly = false;
    isDay2 = false;
    isDay5 = false;
    isDay8 = false;
    isUkEntry = false;

    preselectedPostalCode;
    provisionalPostCode;

    _contactPhone = contactPhone;

    form;

    dobDateValid = true;
    inputDobDate = null;

    get isDay2or8() {
        return this.isDay2 || this.isDay8
    }

    ddOptions = [];
    mmOptions = [];
    yyOptions = [];


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

    ethnicityOptions = [
        {
            "value": "1",
            "label": "White"
        },
        {
            "value": "2",
            "label": "Asian/Asian British"
        },
        {
            "value": "3",
            "label": "African"
        }, {
            "value": "4",
            "label": "Black/African/Caribbean/Black British"
        }, {
            "value": "5",
            "label": "Chinese"
        }, {
            "value": "6",
            "label": "Arab"
        }, {
            "value": "7",
            "label": "Other ethnic group",
        }, {
            "value": "8",
            "label": "Irish Traveller",
        }, {
            "value": "9",
            "label": "Mixed/Multiple ethnic groups"
        }, {
            "value": "10",
            "label": "Not Provided"
        }, {
            "value": "11",
            "label": "White and Asian"
        }, {
            "value": "12",
            "label": "White and Black African"
        }, {
            "value": "13",
            "label": "White British"
        }, {
            "value": "14",
            "label": "Any Other Ethnic Category"
        }, {
            "value": "15",
            "label": "Any Other Mixed Group"
        }, {
            "value": "16",
            "label": "Indian"
        }, {
            "value": "17",
            "label": "Black - African"
        }, {
            "value": "18",
            "label": "Black - Caribbean"
        }, {
            "value": "19",
            "label": "Black - Other"
        }, {
            "value": "20",
            "label": "Bangladeshi"
        }, {
            "value": "21",
            "label": "Pakistani"
        }, {
            "value": "22",
            "label": "Unknown"
        }, {
            "value": "23",
            "label": "Other / Mixed"
        }, {
            "value": "24",
            "label": "White Other"
        }];

    genderOptions = [
        {
            "value": "Male",
            "label": "Male"
        },
        {
            "value": "Female",
            "label": "Female"
        }
    ];

    connectedCallback() {
        console.log('cc', this.queryParameters);
        this.form = {};

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

        if (this.queryParameters) {
            this.fetchData(this.queryParameters["cid"]);
        }

        Date.prototype.isSameAs = function (y, m, d) {
            if (this.getTime() !== this.getTime()) return false;

            if (this.getFullYear() !== y) return false;
            if ((this.getMonth() + 1) !== m) return false;
            if (this.getDate() !== d) return false;

            return true;
        };
    }

    _vacStatusOptions = [{"value": "Yes", "label": "Fully Vaccinated"}, {"value": "No", "label": "Not Fully Vaccinated"}];
    get vacStatusOptions() {
        return this._vacStatusOptions;
    }

    fetchData(cid) {

        if (cid) {
            console.log('::OnlTestForm:getCovidTestForUUID', cid);
            this.loading = true;
            getCovidTestForUUID({uuid: cid})
                .then(result => {
                    console.log('::OnlTestForm:getCovidTestForUUID:result', result);

                    if (result) {
                        let covidTest = JSON.parse(result);
                        /* example result
                            {
                                "Name": "COVID-00312",
                                "Provided_Email__c": "m@m.m",
                                "Provided_First_Name__c": "m",
                                "Provided_Last_Name__c": "m",
                                "Provided_Mobile_Phone__c": "1",
                                "Provided_Phone_Number__c": "1",
                                "Test_Type__c": "Fit to Fly",
                                "UUID__c": "33b58f69-2612-4b6b-b030-c82b6c1a40be",
                                "Id": null
                            }
                     */

                        if (covidTest && covidTest.Test_Type__c) {

                            delete covidTest.attributes;

                            let _type = covidTest.Test_Type__c.toLowerCase();

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


                            this.dataReady = true;
                        }
                    }
                })
                .catch(error => {
                    console.error('::OnlTestForm:getCovidTestForUUID:failed', error);
                    this.fetchError = true;
                })
                .finally(() => {
                        this.loading = false;
                    }
                );
        }
    }

    handleSubmit() {
        if (!this.validateForm()) {
            console.log('validation failed');
            //todo display message
        } else {
            console.log('validation ok');

            // save to form the combination of year/month/date entered for DOB
            this.form.Provided_Date_of_Birth__c = this.inputDobDate;

            //RAW value in postcode is postcode#uprn, we need only UPRN
            if (this.form.Provided_Postal_Code__c && this.form.Provided_Postal_Code__c.indexOf('#') > 0) this.form.Provided_Postal_Code__c = this.form.Provided_Postal_Code__c.split('#')[0];
            if (!this.form.Provided_Postal_Code__c && this.provisionalPostCode) this.form.Provided_Postal_Code__c = this.provisionalPostCode;

            let params = JSON.stringify(this.form);
            console.log('::handleSubmit:storeCovidTest:params', params);

            this.saving = true;
            storeCovidTest({covidTestString: params})
                .then(result => {
                    console.log('::handleSubmit:saved', result);
                    this.saved = true;
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
        return valid;
    }


    handlePostcodeSelection(event) {
        let al1Node = this.template.querySelector('[data-id="Provided_Address_Line1__c"]');
        let al2Node = this.template.querySelector('[data-id="Provided_Address_Line2__c"]');
        let cityNode = this.template.querySelector('[data-id="Provided_City__c"]');
        let postcodeNode = this.template.querySelector('[data-id="Provided_Postal_Code__c"]');
        let countryNode = this.template.querySelector('[data-id="Provided_Country__c"]');

        if (event && event.detail && event.detail.length > 0 && event.detail[0].id && event.detail[0].data) {
            let hit = event.detail[0].data;
            //console.log('selected ev', JSON.stringify(hit));


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
            if (postcodeNode)
            {
                postcodeNode.value = hit.postcode;
                postcodeNode.showHelpMessageIfInvalid();
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
            if (postcodeNode)
            {
                postcodeNode.value = null;
                postcodeNode.showHelpMessageIfInvalid();
            }

        }
    }

    handlePostcodeSearch(event) {

        if (!event || !event.detail || !event.detail.searchTerm) return;
        const target = event.target;

        let query = event.detail.searchTerm;

        //console.log('query0' + query);

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

                            list.push({id: hit.postcode + '#' + hit.uprn, title: hit.postcode, subtitle: hit.line_1 + ' ' + hit.line_2, data: hit});

                        }
                        // console.log('list', list);
                    }

                    target.setSearchResults(list);
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

    httpGetAsync(theUrl, callback) {
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

    checkDateIsValid(y, m, d) {
        let dte = new Date(y + '/' + m + '/' + d);

        if (!dte.isSameAs(y, m, d)) return null; else return (
            y + '-' +
            (m < 10 ? '0' + m : m)
            + '-' +
            (d < 10 ? '0' + d : d));
    }


}