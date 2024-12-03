/**
 * Created by Matija on 12.6.2023..
 */


global class emailService_SembleQnaires implements Messaging.InboundEmailHandler {

    public static final String TEST_SUBJECT_HAS = 'filled in a new';
    public static final String TEST_BODY_HAS_Ozempic = 'Ozempic Questionnaire';
    public static final String TEST_BODY_HAS_Wegovy = 'Wegovy Questionnaire';

    public static final String TEST_SUBJECT_REGEX = 'ID:.+(\\w{24})';

    public static final Id PERSON_ACCOUNT_RECORD_TYPE_ID = Cache.recordTypeId(AccountManager.RT_PERSON_ACCOUNT);

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        // Create an InboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        result.success = false;

        if (email == null) {
            result.success = true;
            return result;
        }

        try {

            System.debug('::handleInboundEmail:email from:' + email.fromAddress);
            System.debug('::handleInboundEmail:email subject:' + email.subject);

            processIfTreatmentEmail(email, TEST_BODY_HAS_Ozempic, 'Ozempic');
            processIfTreatmentEmail(email, TEST_BODY_HAS_Wegovy, 'Wegovy');

            result.success = true;
            return result;
        }

        catch (Exception ex) {
            result.message = String.format('Error while processing Semble email: {0}, from: {3}. Message {1}. Details {2}!', new List<String>{
                    email.subject, ex.getMessage(), ex.getStackTraceString(), email.fromAddress
            });
            Error_Log__c errorLog = new Error_Log__c(Related_Message__c = String.format('Error while processing Semble email: {0}, from: {1}. Message {2}.', new List<String>{email.subject, email.fromAddress, ex.getMessage()}), Stack__c = ex.getStackTraceString(), Related_Class_Name__c = 'emailService_SembleQnaires', Severity__c = 'Error');
            System.debug(LoggingLevel.ERROR, 'message: ' + result.message);
            insert errorLog;
        }

        return result;
    }

    public void processIfTreatmentEmail(Messaging.InboundEmail email, String body_has, String treatmentType) {

        String emailSubject = email.subject;

        if (!String.isBlank(emailSubject) && emailSubject.toLowerCase().contains(TEST_SUBJECT_HAS)) {

            String txtBody = email.plainTextBody;
            String htmlBody = email.htmlBody;

            if ((!String.isBlank(txtBody) && txtBody.contains(body_has)) || (!String.isBlank(htmlBody) && htmlBody.contains(body_has))) {
                System.debug('::handleInboundEmail:processing email with body containing:' + body_has);
                String patientId = null;

                Pattern resultPattern = Pattern.compile(TEST_SUBJECT_REGEX);
                Matcher pm = resultPattern.matcher(emailSubject);

                if (pm.find ()) {
                    patientId = pm.group (1);
                }
                else {
                    System.debug(LoggingLevel.ERROR, 'patient ID not found in subject: ' + emailSubject);
                    insert new Error_Log__c(Related_Message__c = 'Error while processing Semble treatment email, patient ID not found in subject: ' + email.subject, Related_Class_Name__c = 'emailService_SembleQnaires', Severity__c = 'Warning');
                }

                if (patientId != null) {
                    List<Account> accs = [SELECT Id, FirstName, LastName FROM Account WHERE HeyDoc_Id__c = :patientId LIMIT 1 FOR UPDATE];

                    if (!accs.isEmpty()) {
                        //accs[0].Date_Ozempic_Consent_Signed__c = Datetime.now();
                        //update accs[0];
                        addTreatmentToAccount(accs[0], treatmentType);
                    }
                    else {
                        System.debug(LoggingLevel.ERROR, 'no such patient with Semble id: ' + patientId);

                        //retrieve this patient from Semble
                        HeyDocService.Patient unknownPatient = HeyDocService.getPatient(patientId);
                        if (unknownPatient != null) unknownPatient.id = patientId;
                        Account ret = createOrUpdateUnknownPatient(unknownPatient);
                        if (ret != null) addTreatmentToAccount(ret, treatmentType);
                    }
                }
            }
        }
    }

    public static Treatment__c addTreatmentToAccount(Account acc, String treatmentName) {
        //add Treatment
        Treatment__c treatment = new Treatment__c();
        treatment.Account__c = acc?.Id;
        treatment.Date_Consent_Given__c = Datetime.now();
        treatment.Status__c = 'Consent Given';
        treatment.Type__c = treatmentName; //'Ozempic';
        treatment.Name = acc?.FirstName + ' ' + acc?.LastName + ' ' + treatment.Type__c + ' ' + Datetime.now().format('yyyy-MM-dd', 'Europe/London');
        insert treatment;
        return treatment;
    }

    // we don't know this patient by id, so it's either an existing one without that Id, or a new one
    public static Account createOrUpdateUnknownPatient(HeyDocService.Patient patient) {
        if (patient == null || patient.dob == null || String.isBlank(patient.email)) return null;

        patient.dob = patient.dob.addHours(3); //move the dob midday because Semble ignores timezones

        List<Account> ourPatients = [
                SELECT Id, FirstName, LastName
                FROM Account
                WHERE PersonEmail = :patient.email
                AND Date_of_Birth__c = :patient.dob.date()
                AND RecordTypeId = :PERSON_ACCOUNT_RECORD_TYPE_ID
        ];

        if (ourPatients.isEmpty()) {
            //create
            Account accNew = ExternalSyncJobRetrievePatients.newAccountFromPatient(patient);
            //accNew.Date_Ozempic_Consent_Signed__c = Datetime.now();
            insert accNew;
            return accNew;
        }
        else {
            //ourPatients[0].Date_Ozempic_Consent_Signed__c = Datetime.now();
            //update ourPatients[0];
            return ourPatients[0];
        }
    }
}