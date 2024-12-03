/**
 * Created by Atlas on 27.01.2021.
 */

@RestResource(UrlMapping='/AppointmentIntegration/v1/*')

global without sharing class AppointmentIntegration {

    private static IntegrationErrorReporter errorReporter = new IntegrationErrorReporter();

    public static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);

    @HttpPost
    global static void doPost(){

        String patientRetrieveEndpoint;

        AeronaIntegrationSettings__mdt endpoints = [
                SELECT Id, DeveloperName, appointmentTypeListEndpoint__c,
                        loginEndpoint__c, patientRetrieveEndpoint__c,
                        practiceListEndpoint__c, Username__c, PIN__c, Password__c
                FROM AeronaIntegrationSettings__mdt WHERE DeveloperName = 'Aerona1Live'
        ][0];


        RestRequest req = RestContext.request;
        Blob body = req.requestBody;

        String requestString = blobToString(body, 'UTF-8');
        String replacedCharactersAfterEncoding= requestString.replaceAll('\n','').replaceAll('\r','');

        AeronaAppointment.Appointment wrapper = (AeronaAppointment.Appointment) JSON.deserialize(replacedCharactersAfterEncoding, AeronaAppointment.Appointment.class);
        AeronaAppointment.Appointment appointment = new AeronaAppointment.Appointment(wrapper.appointmentStatusId);

        System.debug('appointmentWrapper');
        System.debug(wrapper);

        appointment.practiceId = wrapper.practiceId;
        appointment.patientId = wrapper.patientId;
        appointment.userId = wrapper.userId;
        appointment.appointmentId = wrapper.appointmentId;
        appointment.appointmentTypeId = wrapper.appointmentTypeId;
        appointment.appointmentStatusId = wrapper.appointmentStatusId;
        appointment.appointmentTime = wrapper.appointmentTime;
        appointment.appointmentNotes = wrapper.appointmentNotes;
        appointment.emergency = wrapper.emergency;
        appointment.duration = wrapper.duration;

        //LOGIN TOKEN TO GET THE PATIENT ID

        HttpRequest login = new HttpRequest();
        login.setMethod('POST');
        login.setEndpoint(endpoints.loginEndpoint__c);
        login.setHeader('content-type' , 'application/json');

        AeronaAppointment.login loginDetails = new AeronaAppointment.login();
        loginDetails.username = endpoints.Username__c;
        loginDetails.password = endpoints.Password__c;
        loginDetails.pin = endpoints.PIN__c;

        login.setBody(JSON.serialize(loginDetails));

        HttpResponse loginResponse = new HttpResponse();
        Http http = new Http();

        if(!Test.isRunningTest()) {
            loginResponse = http.send(login);
        }

        String authToken = loginResponse.getHeader('AERONA-AUTH-TOKEN');
        if(Test.isRunningTest()) authToken = '12345';

        System.debug('authToken');
        System.debug(authToken);

        patientRetrieveEndpoint = endpoints.patientRetrieveEndpoint__c + appointment.patientId;

        HttpRequest patientRequest = new HttpRequest();
        //patientRequest.setBody('{}');
        patientRequest.setMethod('POST');
        patientRequest.setEndpoint(patientRetrieveEndpoint);
        patientRequest.setHeader('content-type', 'application/json');
        patientRequest.setHeader('AERONA-AUTH-TOKEN', authToken);

        HttpResponse patientRetrieveResponse = new HttpResponse();
        Http http2 = new Http();


        if(!Test.isRunningTest()){
            try {
                patientRetrieveResponse = http2.send(patientRequest);
            } catch (Exception e) {
                System.debug('Integration error ' + e .getMessage());
                errorReporter.addError('Aerona', null, e.getMessage(), null, JSON.serialize(patientRetrieveResponse));
                errorReporter.persistLogs();
            }
        } else {
            patientRetrieveResponse.setBody(AppointmentIntegrationTest.patientInfoJSON);
            patientRetrieveResponse.setBody(AppointmentIntegrationTest.patientInfoJSON2);
            patientRetrieveResponse.setBody(AppointmentIntegrationTest.patientInfoJSON3);
            patientRetrieveResponse.setBody(AppointmentIntegrationTest.patientInfoJSON4);

        }

        System.debug('patientRetrieveCalloutResponse');
        System.debug(patientRetrieveResponse.getBody());

        AeronaPatient2.RetrieveResponse patientResponseWrapper = (AeronaPatient2.RetrieveResponse) JSON.deserialize(patientRetrieveResponse.getBody(), AeronaPatient2.RetrieveResponse.class);
        AeronaPatient2.Patient patient = new AeronaPatient2.Patient(patientResponseWrapper.result.patientTypeId, patientResponseWrapper.result.genderId, patientResponseWrapper.result.statusId);

        System.debug('patientResponseWrapper');
        System.debug(patientResponseWrapper);

        patient.patientId = appointment.patientId;
        patient.practiceId = appointment.practiceId;
        patient.patientTypeId = patientResponseWrapper.result.patientTypeId;
        patient.statusId = patientResponseWrapper.result.statusId;
        patient.insRefNumber2 = patientResponseWrapper.result.insRefNumber2;
        patient.insRefNumber = patientResponseWrapper.result.insRefNumber;
        patient.forename = patientResponseWrapper.result.forename;
        patient.surname = patientResponseWrapper.result.surname;
        patient.occupation = patientResponseWrapper.result.occupation;
        patient.dob = patientResponseWrapper.result.dob;
        patient.address1 = patientResponseWrapper.result.address1;
        patient.address2 = patientResponseWrapper.result.address2;
        patient.address3 = patientResponseWrapper.result.address3;
        patient.address4 = patientResponseWrapper.result.address4;
        patient.code = patientResponseWrapper.result.code;
        patient.emailAddress = patientResponseWrapper.result.emailAddress;
        patient.mobileNumber = patientResponseWrapper.result.mobileNumber;
        patient.homeNumber = patientResponseWrapper.result.homeNumber;
        patient.allowEmail = patientResponseWrapper.result.allowEmail;
        patient.allowText = patientResponseWrapper.result.allowText;
        patient.allowPrint = patientResponseWrapper.result.allowPrint;
        patient.statusId =  patientResponseWrapper.result.statusId;
        patient.insExpiry1 = patientResponseWrapper.result.insExpiry1;
        patient.insExpiry2 = patientResponseWrapper.result.insExpiry2;

        System.debug('patientDEBUG');
        System.debug(patient);

        HttpRequest practiceListRequest = new HttpRequest();
        practiceListRequest.setMethod('POST');
        practiceListRequest.setBody('{}');
        practiceListRequest.setEndpoint(endpoints.practiceListEndpoint__c);
        practiceListRequest.setHeader('content-type', 'application/json');
        practiceListRequest.setHeader('AERONA-AUTH-TOKEN', authToken);

        HttpResponse practiceListResponse = new HttpResponse();
        Http http3 = new Http();

        if(!Test.isRunningTest()) {
            practiceListResponse = http3.send(practiceListRequest);
        } else {
            practiceListResponse.setBody(AppointmentIntegrationTest.practiceInfoJSON);
        }

        List<AeronaPatient2.AeronaPracticeList> practiceResponseWrapper = (List<AeronaPatient2.AeronaPracticeList>) JSON.deserialize(practiceListResponse.getBody(), List<AeronaPatient2.AeronaPracticeList>.class);

        Map<String, String> praticeIdByName = new map<String, String>();

        for(AeronaPatient2.AeronaPracticeList practice: practiceResponseWrapper){
            praticeIdByName.put(practice.key, practice.value);
        }

        appointment.siteName = praticeIdByName.get(appointment.practiceId);

        System.debug('practiceDebug');
        System.debug(practiceResponseWrapper);


        HttpRequest appointmentTypeForPracticeListRequest = new HttpRequest();
        AeronaAppointment.AppointmentTypeRequest typeRequest = new AeronaAppointment.AppointmentTypeRequest();

        //typeRequest.practiceId = appointment.practiceId; Other practice ids are returning empty practiceId returns list of all values
        typeRequest.practiceId = '130';

        appointmentTypeForPracticeListRequest.setMethod('POST');
        appointmentTypeForPracticeListRequest.setBody(JSON.serialize(typeRequest));
        appointmentTypeForPracticeListRequest.setEndpoint(endpoints.appointmentTypeListEndpoint__c);
        appointmentTypeForPracticeListRequest.setHeader('content-type', 'application/json');
        appointmentTypeForPracticeListRequest.setHeader('AERONA-AUTH-TOKEN', authToken);

        HttpResponse appointmentTypeForPracticeListRequestResponse = new HttpResponse();
        Http http4 = new Http();

        if(!Test.isRunningTest()) {
            appointmentTypeForPracticeListRequestResponse = http4.send(appointmentTypeForPracticeListRequest);
        } else {
            appointmentTypeForPracticeListRequestResponse.setBody(AppointmentIntegrationTest.appointmentTypeListJSON);
        }

        System.debug('appointmentTypeForPracticeListRequestResponse');
        System.debug(appointmentTypeForPracticeListRequestResponse.getBody());
        System.debug(appointmentTypeForPracticeListRequestResponse);

        AeronaAppointment.AppointmentTypeResult typeRequestResult = (AeronaAppointment.AppointmentTypeResult) JSON.deserialize(appointmentTypeForPracticeListRequestResponse.getBody(), AeronaAppointment.AppointmentTypeResult.class);

        System.debug('typeRequestResult');
        System.debug(typeRequestResult);

        Map<String, String> appointmentTypeIdByName = new map<String, String>();

        for(AeronaAppointment.appointmentType appointmentType : typeRequestResult.result){
            appointmentTypeIdByName.put(appointmentType.id, appointmentType.type);
        }

        appointment.AppointmentTypename = appointmentTypeIdByName.get(appointment.appointmentTypeId);

        System.debug('APPOINTMENTOBJDEBUG');
        System.debug(appointment);

        try {
            createProposedAppointments(appointment, appointment.siteName, appointment.AppointmentTypename, patient);
        } catch (Exception e) {
            System.debug('createProposedAppointments error ' + e .getMessage());
            errorReporter.addError('Apex', null, e.getMessage(), null, JSON.serialize(appointment));
            errorReporter.persistLogs();
        }

    }

    public static void createProposedAppointments(AeronaAppointment.Appointment appointment, String siteName, String appointmentTypeName, AeronaPatient2.Patient patient) {

        Boolean createPatient;
        Boolean updatePatient;
        Boolean useExistingPatient;



        PatientMatcher patientMatcher = new PatientMatcher();
        Schema.DescribeFieldResult aeronaId = Account.Aerona_Id__c.getDescribe();
        Schema.sObjectField aeronaIdSObjectField = aeronaId.getSObjectField();

        if(patient?.emailAddress != null) {
            patientMatcher.addEmail(patient.emailAddress);
        }

        if(appointment.patientId != null){
            patientMatcher.setExternalIdField(aeronaIdSObjectField);
            patientMatcher.addExternalId(appointment.patientId);
        }

        Map<String, Account> matchedPatients = patientMatcher.getPatients();
        Id latestPatientRecordId;

        System.debug('matchedPatients');
        System.debug(matchedPatients);


        if(matchedPatients.containsKey(appointment?.patientId) || matchedPatients.containsKey(patient.emailAddress)){
            Account matchedPatient = matchedPatients.containsKey(appointment.patientId)
                    ? matchedPatients.get(appointment.patientId)
                    : matchedPatients.get(patient.emailAddress);

            Datetime patientDT = DateTime.newInstance(long.valueOf(patient.dob));
            Date patientDOB = date.newinstance(PatientDT.year(), PatientDT.month(), PatientDT.day());



            System.debug('matchedPatient');
            System.debug(matchedPatient);
            
            if(matchedPatient != null){
                if(patient.emailAddress != matchedPatient.PersonEmail ||
                                patient.mobileNumber != matchedPatient.PersonMobilePhone ||
                                patientDOB != matchedPatient.Date_of_Birth__c){
                    updatePatient = true;
                    latestPatientRecordId = matchedPatient.Id;
                } else {
                    useExistingPatient = true;
                    latestPatientRecordId = matchedPatient.Id;
                }
            }
        } else {
            createPatient = true;
        }

        System.debug('latestPatientRecordId');
        System.debug(latestPatientRecordId);

        System.debug('siteRecord');
        System.debug(siteName);

        SiteMatcher siteMatcher = new SiteMatcher();
        siteMatcher.addSite(siteName);

        Map<String, Id> siteIdByName = siteMatcher.getSiteIds();

        Map<Id, Site__c> siteMap = new map<Id, Site__c> ([SELECT Id, Name FROM Site__c WHERE Id = :siteIdByName.values()]);
        Site__c siteRecord = siteMap.values()[0];

        AppointmentTypeMatcher appointmentTypeMatcher = new AppointmentTypeMatcher();
        appointmentTypeMatcher.addAppointmentType(appointmentTypeName);

        Map<String, Id> appointmentIdByName = appointmentTypeMatcher.getAppointmentTypeIds();
        Map<Id, Appointment_Type__c> apptTypeMap = new Map<Id, Appointment_Type__c> ([SELECT Id, Name FROM Appointment_Type__c WHERE Id = :appointmentIdByName.values()]);
        Appointment_Type__c apptTypeRecord = apptTypeMap.values()[0];

        Proposed_Appointment__c proposedAppointment = new Proposed_Appointment__c();
        Datetime patientDT = DateTime.newInstance(long.valueOf(patient.dob));
        Date patientDOB = date.newinstance(PatientDT.year(), PatientDT.month(), PatientDT.day());

        if (createPatient == true) {
            Account newPatient = new Account();
            newPatient.FirstName = patient.forename;
            newPatient.RecordTypeId = PERSON_ACCOUNT_RECORD_TYPE_ID;
            newPatient.LastName = patient.surname;
            newPatient.Aerona_Id__c = patient.patientId;
            newPatient.Home_Clinic__c = siteName;
            newPatient.PersonEmail = patient.emailAddress;
            newPatient.Date_of_Birth__c = patientDOB;
            newPatient.Aerona_Id__c = patient.patientId;
            newPatient.Patient_Type__c = 'Registered';
            newPatient.PersonMobilePhone = patient.mobileNumber;

            insert newPatient;

            proposedAppointment.Site__c = siteRecord.Id;
            proposedAppointment.Start__c = convertStringToDatetime(appointment.appointmentTime);
            proposedAppointment.Booking_DateTime__c = System.now();
            proposedAppointment.Appointment_Notes__c = appointment.appointmentNotes;
            proposedAppointment.Appointment_Type__c = apptTypeRecord.Id;
            proposedAppointment.Aerona_Id__c = appointment.appointmentId;
            proposedAppointment.Patient__c = newPatient.Id;
            proposedAppointment.State__c = 'Booked';

            System.debug('proposedAppointmentInsert');
            System.debug(JSON.serialize(proposedAppointment));

            upsert proposedAppointment Aerona_Id__c;

        } else if (updatePatient == true) {

            Account existingPatient = new Account();
            existingPatient.Id = latestPatientRecordId;
            existingPatient.FirstName = patient.forename;
            existingPatient.RecordTypeId = PERSON_ACCOUNT_RECORD_TYPE_ID;
            existingPatient.LastName = patient.surname;
            existingPatient.Aerona_Id__c = patient.patientId;
            existingPatient.Home_Clinic__c = siteName;
            existingPatient.Date_of_Birth__c = patientDOB;
            existingPatient.Aerona_Id__c = patient.patientId;
            existingPatient.Patient_Type__c = 'Registered';
            existingPatient.PersonMobilePhone = patient.mobileNumber;
            existingPatient.PersonEmail = patient.emailAddress;

            update existingPatient;

            proposedAppointment.Site__c = siteRecord.Id;
            proposedAppointment.Start__c = convertStringToDatetime(appointment.appointmentTime);
            proposedAppointment.Appointment_Notes__c = appointment.appointmentNotes;
            proposedAppointment.Booking_DateTime__c = System.now();
            proposedAppointment.Appointment_Type__c = apptTypeRecord.Id;
            proposedAppointment.Aerona_Id__c = appointment.appointmentId;
            proposedAppointment.Patient__c = latestPatientRecordId;
            proposedAppointment.State__c = 'Booked';

            System.debug('proposedAppointmentUpdate');
            System.debug(JSON.serialize(proposedAppointment));

            upsert proposedAppointment Aerona_Id__c;

        } else if (useExistingPatient == true){

            proposedAppointment.Site__c = siteRecord.Id;
            proposedAppointment.Start__c = convertStringToDatetime(appointment.appointmentTime);
            proposedAppointment.Appointment_Notes__c = appointment.appointmentNotes;
            proposedAppointment.Booking_DateTime__c = System.now();
            proposedAppointment.Appointment_Type__c = apptTypeRecord.Id;
            proposedAppointment.Aerona_Id__c = appointment.appointmentId;
            proposedAppointment.Patient__c = latestPatientRecordId;
            proposedAppointment.State__c = 'Booked';

            System.debug('proposedAppointmentUseExisting');
            System.debug(JSON.serialize(proposedAppointment));

            upsert proposedAppointment Aerona_Id__c;

        }
    }

    public static String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i) {
            bytes[i] = hex.mid(i << 1, 2);
        }
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }

    public static Datetime convertStringToDatetime(String DateTimeString){

        List<String> dateAndTime = String.valueOf(DateTimeString).split(' ');

        String dateString = dateAndTime[0];
        List<String> datesNumbers =  dateString.split('-');

        Integer year = Integer.valueOf(datesNumbers[0]);
        Integer month = Integer.valueOf(datesNumbers[1]);
        Integer day = Integer.valueOf(datesNumbers[2]);

        String hourString = dateAndTime[1];
        List<String> datesHours =  hourString.split(':');

        Integer hour = Integer.valueOf(datesHours[0]);
        Integer minute = Integer.valueOf(datesHours[1]);

        Datetime d = Datetime.newInstance(Date.newInstance(year, month, day), Time.newInstance(hour, minute, 0, 0));

        return d;
    }
}