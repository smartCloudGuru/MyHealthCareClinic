/**
 * Created 22.11.2021..
 */

public without sharing class ExternalSyncPatients {

    public static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);

    private final static String countryCodes =
            '{"ZW":"Zimbabwe","ZM":"Zambia","ZA":"South Africa","YT":"Mayotte","YE":"Yemen","WS":"Samoa","WF":"Wallis and Futuna","VU":"Vanuatu","VN":"Vietnam","VG":"Virgin Islands, British","VE":"Venezuela, Bolivarian Republic of","VC":"Saint Vincent and the Grenadines","VA":"Holy See (Vatican City State)","UZ":"Uzbekistan","UY":"Uruguay","US":"United States","UG":"Uganda","UA":"Ukraine","TZ":"Tanzania, United Republic of","TW":"Taiwan","TV":"Tuvalu","TT":"Trinidad and Tobago","TR":"Turkey","TO":"Tonga","TN":"Tunisia","TM":"Turkmenistan","TL":"Timor-Leste","TK":"Tokelau","TJ":"Tajikistan","TH":"Thailand","TG":"Togo","TF":"French Southern Territories","TD":"Chad","TC":"Turks and Caicos Islands","SZ":"Swaziland","SY":"Syrian Arab Republic","SX":"Sint Maarten (Dutch part)","SV":"El Salvador","ST":"Sao Tome and Principe","SS":"South Sudan","SR":"Suriname","SO":"Somalia","SN":"Senegal","SM":"San Marino","SL":"Sierra Leone","SK":"Slovakia","SJ":"Svalbard and Jan Mayen","SI":"Slovenia","SH":"Saint Helena, Ascension and Tristan da Cunha","SG":"Singapore","SE":"Sweden","SD":"Sudan","SC":"Seychelles","SB":"Solomon Islands","SA":"Saudi Arabia","RW":"Rwanda","RU":"Russian Federation","RS":"Serbia","RO":"Romania","RE":"Reunion","QA":"Qatar","PY":"Paraguay","PT":"Portugal","PS":"Palestine","PN":"Pitcairn","PM":"Saint Pierre and Miquelon","PL":"Poland","PK":"Pakistan","PH":"Philippines","PG":"Papua New Guinea","PF":"French Polynesia","PE":"Peru","PA":"Panama","OM":"Oman","NZ":"New Zealand","NU":"Niue","NR":"Nauru","NP":"Nepal","NO":"Norway","NL":"Netherlands","NI":"Nicaragua","NG":"Nigeria","NF":"Norfolk Island","NE":"Niger","NC":"New Caledonia","NA":"Namibia","MZ":"Mozambique","MY":"Malaysia","MX":"Mexico","MW":"Malawi","MV":"Maldives","MU":"Mauritius","MT":"Malta","MS":"Montserrat","MR":"Mauritania","MQ":"Martinique","MO":"Macao","MN":"Mongolia","MM":"Myanmar","ML":"Mali","MK":"Macedonia, the former Yugoslav Republic of","MG":"Madagascar","MF":"Saint Martin (French part)","ME":"Montenegro","MD":"Moldova, Republic of","MC":"Monaco","MA":"Morocco","LY":"Libya","LV":"Latvia","LU":"Luxembourg","LT":"Lithuania","LS":"Lesotho","LR":"Liberia","LK":"Sri Lanka","LI":"Liechtenstein","LC":"Saint Lucia","LB":"Lebanon","LA":"Lao People’s Democratic Republic","KZ":"Kazakhstan","KY":"Cayman Islands","KW":"Kuwait","KR":"Korea, Republic of","KP":"Korea, Democratic People’s Republic of","KN":"Saint Kitts and Nevis","KM":"Comoros","KI":"Kiribati","KH":"Cambodia","KG":"Kyrgyzstan","KE":"Kenya","JP":"Japan","JO":"Jordan","JM":"Jamaica","JE":"Jersey","IT":"Italy","IS":"Iceland","IR":"Iran, Islamic Republic of","IQ":"Iraq","IO":"British Indian Ocean Territory","IN":"India","IM":"Isle of Man","IL":"Israel","IE":"Ireland","ID":"Indonesia","HU":"Hungary","HT":"Haiti","HR":"Croatia","HN":"Honduras","HM":"Heard Island and McDonald Islands","GY":"Guyana","GW":"Guinea-Bissau","GT":"Guatemala","GS":"South Georgia and the South Sandwich Islands","GR":"Greece","GQ":"Equatorial Guinea","GP":"Guadeloupe","GN":"Guinea","GM":"Gambia","GL":"Greenland","GI":"Gibraltar","GH":"Ghana","GG":"Guernsey","GF":"French Guiana","GE":"Georgia","GD":"Grenada","GB":"United Kingdom","GA":"Gabon","FR":"France","FO":"Faroe Islands","FK":"Falkland Islands (Malvinas)","FJ":"Fiji","FI":"Finland","ET":"Ethiopia","ES":"Spain","ER":"Eritrea","EH":"Western Sahara","EG":"Egypt","EE":"Estonia","EC":"Ecuador","DZ":"Algeria","DO":"Dominican Republic","DM":"Dominica","DK":"Denmark","DJ":"Djibouti","DE":"Germany","CZ":"Czech Republic","CY":"Cyprus","CX":"Christmas Island","CW":"Curaçao","CV":"Cape Verde","CU":"Cuba","CR":"Costa Rica","CO":"Colombia","CN":"China","CM":"Cameroon","CL":"Chile","CK":"Cook Islands","CI":"Cote d’Ivoire","CH":"Switzerland","CG":"Congo","CF":"Central African Republic","CD":"Congo, the Democratic Republic of the","CC":"Cocos (Keeling) Islands","CA":"Canada","BZ":"Belize","BY":"Belarus","BW":"Botswana","BV":"Bouvet Island","BT":"Bhutan","BS":"Bahamas","BR":"Brazil","BQ":"Bonaire, Sint Eustatius and Saba","BO":"Bolivia, Plurinational State of","BN":"Brunei Darussalam","BM":"Bermuda","BL":"Saint Barthélemy","BJ":"Benin","BI":"Burundi","BH":"Bahrain","BG":"Bulgaria","BF":"Burkina Faso","BE":"Belgium","BD":"Bangladesh","BB":"Barbados","BA":"Bosnia and Herzegovina","AZ":"Azerbaijan","AX":"Aland Islands","AW":"Aruba","AU":"Australia","AT":"Austria","AR":"Argentina","AQ":"Antarctica","AO":"Angola","AM":"Armenia","AL":"Albania","AI":"Anguilla","AG":"Antigua and Barbuda","AF":"Afghanistan","AE":"United Arab Emirates","AD":"Andorra"}';

    @InvocableMethod(Category='Patient' Label='External Sync - sync Patients' Description='Sync patients to eternal systems(s)')
    public static List<Account> syncPatient(List<Account> accounts) {

        if (accounts == null) return null;

        List<String> accIds = new List<String>();
        for (Account acc : accounts) {
            accIds.add(acc.Id);
        }

        try {
            accounts = [
                    SELECT
                            Id,
                            HeyDoc_Id__c,
                            Aerona_Id__c,
                            FirstName,
                            LastName,
                            Date_of_Birth__c,
                            PersonEmail,
                            Gender__c,
                            BillingStreet,
                            BillingCity,
                            BillingCountry,
                            BillingPostalCode,
                            BillingState,
                            PersonMobilePhone,
                            HeyDoc_Fingerprint__c,
                            Aerona_Fingerprint__c,
                            Aerona_Practice_Id__c,
                            Aerona_PatientTypeId__c,
                            NeedsSyncTo__c,
                            DoNotSync__pc
                    FROM Account
                    WHERE Id IN :accIds
                    AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID
                    AND DoNotSync__pc != TRUE
            ];

            Set<String> accountsToSyncAppointmentsFor = new Set<String>();
            List<Account> accountsToUpdate = new List<Account>();
            String hid = null;
            String aid = null;
            String currentSfFingerprint = null;
            Boolean accountNeedUpdate = false;
            for (Account acc : accounts) {
                hid = null;
                aid = null;
                if (acc.DoNotSync__pc) continue;

                accountNeedUpdate = false;

                //if we do not have a birth date, set it to 1/1/1900 because otherwise HeyDoc will not accept the data
                if (acc.Date_of_Birth__c == null) acc.Date_of_Birth__c = Date.newInstance(1900, 1, 1);

                currentSfFingerprint = calcFingerprint(acc);

                System.debug('::syncPatient:calcFP:' + currentSfFingerprint);
                System.debug('::syncPatient:smblFP:' + acc.HeyDoc_Fingerprint__c);

                //SYNC TO HEYDOC
                try {
                    //if the current fingerprint is the same as last known heydoc fingerprint, do not sync
                    if (!String.isBlank(acc.HeyDoc_Id__c) && (acc.HeyDoc_Fingerprint__c == currentSfFingerprint)) {
                        hid = acc.HeyDoc_Id__c;
                    }
                    else {
                        if (String.isBlank(acc.HeyDoc_Id__c)) {
                            hid = createPatientOnHeydoc(acc); // CREATE ON HEYDOC
                            if (hid != null) {
                                accountsToSyncAppointmentsFor.add(acc.Id);
                            }
                        }
                        else {
                            hid = updatePatientOnHeydoc(acc); // UPDATE ON HEYDOC
                        }

                        if (hid != null) {
                            acc.HeyDoc_Id__c = hid;
                            acc.HeyDoc_Fingerprint__c = currentSfFingerprint;
                            acc.NeedsSyncTo__c = ExternalSyncUtility.removeItemFromMultiPicklist(acc.NeedsSyncTo__c, 'EXT');
                            accountNeedUpdate = true;
                        }
                    }

                    if (hid == null) {
                        publishIntegrationLog(true, acc.Id, 'syncPatient', JSON.serialize(acc), 'unable to create/update patient on Semble, no id returned', 0);
                        acc.NeedsSyncTo__c = ExternalSyncUtility.addItemToMultiPicklist(acc.NeedsSyncTo__c, 'EXT'); // marks account for later watchdog processing
                        accountNeedUpdate = true;
                    }
                }
                catch (Exception e) {
                    publishIntegrationLog(true, acc.Id, 'syncPatient', JSON.serialize(acc), 'unable to create/update patient on Semble ' + e.getMessage(), 0);
                    acc.NeedsSyncTo__c = ExternalSyncUtility.addItemToMultiPicklist(acc.NeedsSyncTo__c, 'EXT'); // marks account for later watchdog processing
                    //if the Semble id is invalid, remove the Semble id
                    if (e.getMessage()!=null && (e.getMessage().contains('Patient must exist') || e.getMessage().contains('INVALID_PATIENT_SEMBLE_ID'))) acc.HeyDoc_Id__c = null;
                    accountNeedUpdate = true;
                }


                //AERONA
                if (AeronaService.isIntegrationEnabled()) {
                    try {
                        //if the current fingerprint is the same as last known heydoc fingerprint, do not sync
                        if (!String.isBlank(acc.Aerona_Id__c) && (acc.Aerona_Fingerprint__c == currentSfFingerprint)) {
                            aid = acc.Aerona_Id__c;
                        }
                        else {
                            if (String.isBlank(acc.Aerona_Id__c)) {
                                aid = ExternalSyncPatientsToAerona.createPatientOnAerona(acc); // CREATE ON AERONA
                                if (aid != null) {
                                    accountsToSyncAppointmentsFor.add(acc.Id);
                                }
                            }
                            else {
                                aid = ExternalSyncPatientsToAerona.updatePatientOnAerona(acc); // UPDATE ON AERONA
                            }

                            if (aid != null) {
                                acc.Aerona_Id__c = aid;
                                acc.Aerona_Fingerprint__c = currentSfFingerprint;
                                acc.NeedsSyncTo__c = ExternalSyncUtility.removeItemFromMultiPicklist(acc.NeedsSyncTo__c, 'AERONA');
                                accountNeedUpdate = true;
                            }

                        }

                        if (aid == null) {
                            publishIntegrationLog(true, acc.Id, 'syncPatient', JSON.serialize(acc), 'unable to create/update patient on Aerona, no id returned', 0);
                            acc.NeedsSyncTo__c = ExternalSyncUtility.addItemToMultiPicklist(acc.NeedsSyncTo__c, 'AERONA'); // marks account for later watchdog processing
                            accountNeedUpdate = true;
                        }
                    }
                    catch (Exception e) {
                        publishIntegrationLog(true, acc.Id, 'syncPatient', JSON.serialize(acc), 'unable to create/update patient on Aerona ' + e.getMessage(), 0);
                        acc.NeedsSyncTo__c = ExternalSyncUtility.addItemToMultiPicklist(acc.NeedsSyncTo__c, 'AERONA'); // marks account for later watchdog processing
                        accountNeedUpdate = true;
                    }
                }

                if (accountNeedUpdate) {
                    accountsToUpdate.add(acc);
                }
            }

            List<Database.SaveResult> saveResults = Database.update(accountsToUpdate, false);
            for (Database.SaveResult saveResult : saveResults) {
                if ((saveResult.success != true) && (saveResult.getErrors() != null)) publishIntegrationLog(true, saveResult.getId(), 'syncPatient', 'Database.update', JSON.serialize(saveResult.getErrors()), 0);
            }

            if (!accountsToSyncAppointmentsFor.isEmpty()) {
                //find eventual service appointments and sync them now that we have the patient id
                ExternalSyncAppsForPatient esap = new ExternalSyncAppsForPatient(accountsToSyncAppointmentsFor);
                System.enqueueJob(esap);
            }
        }
        catch (Exception e) {
            publishIntegrationLog(true, null, 'syncPatient', e.getMessage(), e.getStackTraceString(), 0);
        }


        return accounts;
    }


    public static String createPatientOnHeydoc(Account patient) {

        if (patient.Date_of_Birth__c == null) {
            System.debug(LoggingLevel.WARN, 'SE: unable to create patient without DOB: ' + patient.Id);
            return null;
        }

        String extHeydocId = null;

        //[2023-05] Before doing create, check if a patient with same email and DOB already exists

        if (String.isNotBlank(patient.PersonEmail)) {
            try {
                HeyDocService.PatientData patients = HeyDocService.searchPatients(patient.PersonEmail?.trim(), null, null);

                if (patients?.data != null && patients.data.size() > 0) {
                    for (HeyDocService.Patient semblePatient : patients.data) {
                        if (semblePatient != null && semblePatient.email != null && semblePatient.email == patient.PersonEmail?.trim() && semblePatient.dob != null && semblePatient.dob.date() == patient.Date_of_Birth__c) {
                            String ret = semblePatient.id;

                            //check if we maybe already have that ID, if we do it's better to just create a new patient
                            List<Account> existingAccsBySembleID = [SELECT Id FROM Account WHERE HeyDoc_Id__c=:ret];
                            if (existingAccsBySembleID.isEmpty()) {

                                //System.debug(LoggingLevel.INFO, '**dbg SE: returning: ' + ret);
                                return ret;
                            }
                            // else continue with creating but publish an error
                            else {
                                publishIntegrationLog(true, existingAccsBySembleID?.get(0)?.Id, 'createPatientOnSemble', JSON.serialize(patient), 'Potential duplicate on Semble and SF', 601);
                            }

                        }
                    }
                }
            }
            catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'SE: patient search threw: ' + ex.getMessage());
            }
        }

        // create on heydoc
        HeyDocService.CreatePatientDataInput input = new HeyDocService.CreatePatientDataInput();
        input.first = patient.FirstName;
        input.last = patient.LastName;
        input.dob = patient.Date_of_Birth__c;
        input.email = patient.PersonEmail?.trim();
        input.gender = mapToHeydocGender(patient.Gender__c);
        input.address = patient.BillingStreet;
        input.city = patient.BillingCity;
        input.postcode = patient.BillingPostalCode;
        input.country = mapToCountryCode(patient.BillingCountry);
        if (String.isNotBlank(patient.PersonMobilePhone)) {
            input.phoneType = 'Mobile';
            input.phoneNumber = patient.PersonMobilePhone;
        }

        extHeydocId = HeyDocService.createPatient(input);

        if (String.isNotBlank(extHeydocId)) patient.HeyDoc_Id__c = extHeydocId;

        return extHeydocId;
    }

    public static String updatePatientOnHeydoc(Account patient) {

        String extHeydocId = null;

        // update on heydoc
        HeyDocService.UpdatePatientDataInput input = new HeyDocService.UpdatePatientDataInput();
        input.first = patient.FirstName;
        input.last = patient.LastName;
        if (patient.Date_of_Birth__c != null) input.dob = patient.Date_of_Birth__c;
        input.email = patient.PersonEmail?.trim();
        input.gender = mapToHeydocGender(patient.Gender__c);
        input.address = patient.BillingStreet;
        input.city = patient.BillingCity;
        input.postcode = patient.BillingPostalCode;
        input.country = mapToCountryCode(patient.BillingCountry);

        extHeydocId = HeyDocService.updatePatient(patient.HeyDoc_Id__c, input);

        //get the patient phone numbers so we can update mobile phone no

        try {
            HeyDocService.Patient sPatient = HeyDocService.getPatient(patient.HeyDoc_Id__c);
            if (sPatient != null) {
                String mobilePhoneId = null;
                //check if there is already a mobile phone number
                for (HeyDocService.Phone ph : sPatient.phones) {
                    //System.debug('::dbg:looking at Phone ' + ph);
                    if (ph.phoneType == 'Mobile') {
                        mobilePhoneId = ph.phoneId;
                        break;
                    }
                }

                //System.debug('::dbg:mobilePhoneId:' + mobilePhoneId);
                if (mobilePhoneId == null) {
                    if (!String.isEmpty(patient.PersonMobilePhone)) {
                        HeyDocService.AddPhoneData addPhoneData = new HeyDocService.AddPhoneData();
                        addPhoneData.phoneType = 'Mobile';
                        addPhoneData.phoneNumber = patient.PersonMobilePhone;
                        HeyDocService.addPatientPhoneNumber(patient.HeyDoc_Id__c, addPhoneData);
                    }
                }
                else {
                    if (!String.isEmpty(patient.PersonMobilePhone)) {
                        HeyDocService.UpdatePhoneData updatePhoneData = new HeyDocService.UpdatePhoneData();
                        updatePhoneData.phoneType = 'Mobile';
                        updatePhoneData.phoneNumber = patient.PersonMobilePhone;
                        HeyDocService.updatePatientPhoneNumber(patient.HeyDoc_Id__c, mobilePhoneId, updatePhoneData);
                    }
                    else {
                        HeyDocService.removePatientPhoneNumber(patient.HeyDoc_Id__c, mobilePhoneId);
                    }
                }

            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Failed patient update phone number ' + ex);
        }


        return extHeydocId;
    }


    public static String updatePatientCommentOnHeydoc(String semblePatientId, Datetime createdAt, String commentNote) {

        if (semblePatientId == null) return semblePatientId;
        if (String.isBlank(commentNote)) return semblePatientId;

        String oldComments = null;

        HeyDocService.UpdatePatientDataInput input = null;

        //get old patient with old comments
        try {
            HeyDocService.Patient sPatient = HeyDocService.getPatient(semblePatientId);
            if (sPatient != null) {

                oldComments = sPatient.comments;


                if (String.isNotBlank(oldComments)) {
                    oldComments = '\n\n' + oldComments;
                }
                else {
                    oldComments = '';
                }

                input = new HeyDocService.UpdatePatientDataInput();
                input.comments = createdAt.format('dd/MM/yyyy') + ' (SF): ' + commentNote + oldComments;
            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Failed Semble Patient retrieve ' + ex);
        }

        if (input != null) {
            return HeyDocService.updatePatient(semblePatientId, input);
        }

        return semblePatientId;
    }


    /**
     * mapping utility function - gender
     *
     * @param gender SF gender String
     *
     * @return
     */
    public static String mapToHeydocGender(String gender) {
        if (String.isNotBlank(gender)) {
            if (gender == 'Male') return 'male';
            if (gender == 'Female') return 'female';
        }

        return 'not specified';
    }


    /**
     * mapping utility function - gender
     *
     * @param gender SF gender String
     *
     * @return
     */
    public static String mapFromHeyDocGender(String gender) {
        if (String.isNotBlank(gender)) {
            if (gender == 'male') return 'Male';
            if (gender == 'female') return 'Female';
        }
        return null;
    }

    public static String mapToCountryCode(String country) {
        if (country == null) return null;
        Map<String, String> mp = (Map<String, String>) JSON.deserialize(countryCodes, Map<String, String>.class);
        for (String cc : mp.keySet()) {
            if (mp.get(cc).toUpperCase() == country.toUpperCase()) return cc;
        }
        return null;
    }

    public static String mapToCountry(String countryCode) {
        if (countryCode == null) return null;
        return ((Map<String, String>) JSON.deserialize(countryCodes, Map<String, String>.class)).get(countryCode.toUpperCase());
    }


    /**
     * For a given Account, calculate fingerprint
     *
     * @param acc
     *
     * @return
     */
    public static String calcFingerprint(Account acc) {
        String content = '-';
        content += acc.FirstName;
        content = content + '-';
        content += acc.LastName;
        content = content + '-';
        content += acc.Date_of_Birth__c;
        content = content + '-';
        content += acc.PersonEmail;
        content = content + '-';
        content += acc.Gender__c;
        content = content + '-';
        content += acc.BillingStreet;
        content = content + '-';
        content += acc.BillingCity;
        content = content + '-';
        content += acc.BillingCountry;
        content = content + '-';
        content += acc.BillingPostalCode;
        content = content + '-';
        content += acc.BillingState;
        content = content + '-';
        content += acc.PersonMobilePhone;
        content = content + '-';

        content = content.replaceAll('-null-', '--');

        Blob requestBlob = Blob.valueOf(content);
        Blob hash = Crypto.generateDigest('MD5', requestBlob);
        return EncodingUtil.convertToHex(hash);

    }

    public static void publishIntegrationLog(Boolean isError, String relatedId, String operation, String request, String detail, Integer httpCode) {
        try {

            if (request != null && request.length() > 10000) request = request.substring(0, 10000);
            if (detail != null && detail.length() > 20000) detail = detail.substring(0, 20000);

            List<Integration_Log__e> events = new List<Integration_Log__e>();
            events.add(new Integration_Log__e(
                    System__c = 'Sync',
                    Detail__c = detail,
                    Error__c = isError,
                    Http_Code__c = '' + httpCode,
                    Related_Id__c = relatedId,
                    Request__c = request,
                    Operation__c = operation
            ));
            EventBus.publish(events);
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'Unable to publish Integration_Log__e:' + ex.getMessage());
        }
    }
}