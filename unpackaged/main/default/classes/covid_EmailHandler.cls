/**
 * Inbound Covid test result/status updates email handling.
 * Handles following email subjects:
 * <ul>
 * <li><b>Corporate Account Kit Registrations for {results@myhealthcareclinic.com}</b> - confirmation email for registering the kit
 * <li><b>Covid-19 Kit Received {R402030078}</b> - confirmation email for reception of the kit
 * <li><b>Covid-19 Tests R402005328</b> - test resutls email
 * </ul>
 * @author Zoran Zunko
 * @date 2/19/21
*/
global class covid_EmailHandler implements Messaging.InboundEmailHandler {
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_REGISTERED = 'Registered';
    public static final String STATUS_RECEIVED = 'Received';
    public static final String STATUS_POSITIVE = 'Positive';
    public static final String STATUS_NEGATIVE = 'Negative';
    public static final String STATUS_UNCLEAR = 'Unclear';

    public static final String KIT_REGISTRATION_SUBJECT = 'Corporate Account Kit Registrations for ';
    public static final String KIT_RECEIVED_SUBJECT = 'Covid-19 Kit Received';
    public static final String KIT_REGISTERED_SUBJECT = 'Covid-19 Kit Registration';
    public static final String KIT_RESULTS_SUBJECT = 'Covid-19 Tests';
    public static final String KIT_SERIAL_NUMBER_REGEX = '((?s).*)((?s)(M|R|RD|PD)\\d{8,12})((?s).*)';
    public static final String TEST_NEGATIVE_POSITIVE_REGEX = 'test result is.{1,100}(negative|positive|unclear)';
    public static final String TEST_RESULT_FILE_REGEX = '(R|M|RD|PD)\\d{8,12}.pdf';
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail confirmationEmail,
            Messaging.InboundEnvelope env) {
        // Create an InboundEmailResult object for returning the result of the
        // Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            String emailSubject = confirmationEmail?.subject.toUpperCase();
            String covidTestURN = null;
            String covidTestStatus = null;
            if (String.isNotBlank(emailSubject)) {
                System.debug('::handleInboundEmail:emailSubject:' + emailSubject);
                if (emailSubject.contains(KIT_REGISTRATION_SUBJECT.toUpperCase())) {
                    System.debug('::handleInboundEmail:this is KIT_REGISTRATION_SUBJECT');
                    covidTestURN = retrieveKitUrnFromText(confirmationEmail.htmlBody.escapeUnicode());
                    covidTestStatus = STATUS_REGISTERED;
                } else if (emailSubject.contains(KIT_REGISTERED_SUBJECT.toUpperCase())) {
                    //added 2022-03-21
                    System.debug('::handleInboundEmail:this is KIT_REGISTERED_SUBJECT');
                    covidTestURN = retrieveKitUrnFromText(emailSubject);
                    covidTestStatus = null; // no change needed for these emails
                } else if (emailSubject.contains(KIT_RECEIVED_SUBJECT.toUpperCase())) {
                    System.debug('::handleInboundEmail:this is KIT_RECEIVED_SUBJECT');
                    covidTestURN = retrieveKitUrnFromText(emailSubject);
                    covidTestStatus = STATUS_RECEIVED;
                } else if (emailSubject.contains(KIT_RESULTS_SUBJECT.toUpperCase())) {
                    System.debug('::handleInboundEmail:this is KIT_RESULTS_SUBJECT');
                    covidTestURN = retrieveKitUrnFromText(emailSubject);
                    System.debug('::handleInboundEmail:KIT_RESULTS:covidTestURN:' + covidTestURN);
                    covidTestStatus = retrieveTestResultFromText(confirmationEmail.htmlBody.escapeUnicode())?.capitalize();
                    System.debug('::handleInboundEmail:KIT_RESULTS:covidTestStatus:' + covidTestStatus);
                } else {
                    Error_Log__c errorLog = new Error_Log__c(
                            Related_Message__c = String.format('Error while processing confirmation email: {0}, from: {2}. Message {1}',
                                    new List<String>{
                                            confirmationEmail.subject
                                            , 'Subject unknown'
                                            , confirmationEmail.fromAddress
                                    }),
                            Related_Class_Name__c = 'covid_EmailHandler',
                            Severity__c = 'Warning'

                    );
                    System.debug(LoggingLevel.ERROR, 'message: ' + errorLog.Related_Message__c);
                    insert errorLog;
                    result.success = false;
                    result.message = errorLog.Related_Message__c;
                    return result;
                }
            }
            if (String.isNotBlank(covidTestURN)) {
                COVID_Test__c covidTest = getCovidTestForURN(covidTestURN);
                if(covidTest != null) {
                    if(String.isNotBlank(covidTestStatus)) covidTest.COVID_Test_Status__c = covidTestStatus;
                    if (covidTest.Id == null) {
                        insert covidTest;
                    } else {
                        update covidTest;
                    }
                    EmailMessage createdEmail = new EmailMessage(
                            Subject = confirmationEmail.subject + ' [EmailService]',
                            Status = '1',
                            FromAddress = confirmationEmail.fromAddress,
                            FromName = confirmationEmail.fromName,
                            Headers = JSON.serialize(confirmationEmail.headers),
                            HtmlBody = confirmationEmail.htmlBody,
                            TextBody = confirmationEmail.plainTextBody,
                            Incoming = true,
                            RelatedToId = covidTest.Id,
                            MessageDate = Datetime.now()
                    );
                    insert createdEmail;
                    List<Id> recordIds = new List<Id>{
                            covidTest.Id, createdEmail.Id
                    };
                    if (String.isNotBlank(covidTest.Patient__c)) recordIds.add(covidTest.Patient__c);
                    createContentDocumentLinks(confirmationEmail.binaryAttachments, recordIds);
                    result.success = true;
                }
                else {
                    Error_Log__c errorLog = new Error_Log__c(
                            Related_Message__c = String.format('Error while processing confirmation email: {0}, from: {2}. Message {1}',
                                    new List<String>{
                                            confirmationEmail.subject,
                                            'No URN found in database',
                                            confirmationEmail.fromAddress
                                    }),
                            Related_Class_Name__c = 'covid_EmailHandler',
                            Severity__c = 'Warning'

                    );
                    System.debug(LoggingLevel.ERROR, 'message: ' + errorLog.Related_Message__c);
                    insert errorLog;
                    result.success = false;
                    result.message = errorLog.Related_Message__c;
                    return result;
                }
            } else {
                Error_Log__c errorLog = new Error_Log__c(
                        Related_Message__c = String.format('Error while processing confirmation email: {0}, from: {2}. Message {1}',
                                new List<String>{
                                        confirmationEmail.subject,
                                        'No URN found in email',
                                        confirmationEmail.fromAddress
                                }),
                        Related_Class_Name__c = 'covid_EmailHandler',
                        Severity__c = 'Warning'

                );
                System.debug(LoggingLevel.ERROR, 'message: ' + errorLog.Related_Message__c);
                insert errorLog;
                result.success = false;
                result.message = errorLog.Related_Message__c;
            }
        } catch (Exception ex) {
            result.success = false;
            result.message = String.format('Error while processing confirmation email: {0}, from: {3}. Message {1}. Details {2}!',
                    new List<String>{
                            confirmationEmail.subject,
                            ex.getMessage(),
                            ex.getStackTraceString(),
                            confirmationEmail.fromAddress
                    });
            Error_Log__c errorLog = new Error_Log__c(
                    Related_Message__c = String.format('Error while processing confirmationEmail: {0}, from: {1}. Message {2}.',
                            new List<String>{
                                    confirmationEmail.subject,
                                    confirmationEmail.fromAddress,
                                    ex.getMessage()
                            }),
                    Stack__c = ex.getStackTraceString(),
                    Related_Class_Name__c = 'covid_EmailHandler',
                    Severity__c = 'Error'

            );
            System.debug(LoggingLevel.ERROR, 'message: ' + result.message);
            insert errorLog;

        }
        if (confirmationEmail?.fromAddress!=null)
        {
            if (confirmationEmail.fromAddress.indexOf('nhs.test.and.trace.service')>=0) {
                result.success = true;
            }
        }
        return result;
    }

    /**
     * Retrieves Kit number from a piece of text can be multiline. @see covid_EmailHandler.KIT_SERIAL_NUMBER_REGEX
     * <p>
     *     Example:
     *  <code>
     *      Pattern p = Pattern.compile('((?s).*)((?s)R\\d{9})((?s).*)');
     *      Matcher pm = p.matcher('*** IMPORTANT INFORMATION CONTAINED IN THIS EMAIL ***\n' +
     *         '\n' +
     *         'Thank you for registering your Corporate Account Kit Registrations on the Randox Health portal.\n' +
     *         '\n' +
     *         'We can confirm you have successfully registered with the following URNs:\n' +
     *         '\n' +
     *         '- R402231413\n' +
     *         '\n' +
     *         'Please ensure you keep this information safe and secure. You will need this information if you have any queries regarding your sample.\n' +
     *         '\n' +
     *         'If you have any questions regarding this process, please check our FAQ [https://www.randoxhealth.com/covid-19-testing-faq/] or contact the NHS contact centre on: 03003032713\n' +
     *         '\n' +
     *         'Please do not reply to this email\n' +
     *         '\n' +
     *         'Kind regards,\n' +
     *         '\n' +
     *         'Randox Health');
     *      if( pm.matches() ){
     *          System.debug(LoggingLevel.ERROR, ' - : ' + pm.groupCount());
     *          System.debug(LoggingLevel.ERROR, ' - : ' + pm.group(0));
     *          System.debug(LoggingLevel.ERROR, ' - : ' + pm.group(1));
     *          System.debug(LoggingLevel.ERROR, ' - : ' + pm.group(2));
     *          System.debug(LoggingLevel.ERROR, ' - : ' + pm.group(3));
     *      }
     *  </code>
     *  </p>
     * @param kitText text to match against
     * @return {String} kit number or null if not found
     */
    @TestVisible static String retrieveKitUrnFromText(String kitText) {
        //kit number is always group 2
        Pattern kitSerialPattern = Pattern.compile(KIT_SERIAL_NUMBER_REGEX);
        Matcher pm = kitSerialPattern.matcher(kitText);
        if (pm.matches()) {
            return pm.group(2);
        }
        return null;
    }

    /**
     * Retrieves test result from a piece of text can be multiline. @see covid_EmailHandler.TEST_NEGATIVE_POSITIVE_REGEX
     * <p>
     *     Example:
     *  <code>
     *      Pattern p = Pattern.compile('((?s).*)((?s)(test result is )(negative|positive))((?s).*)');
     *      Matcher pm = p.matcher('From: Randox Health <no-reply@randoxhealth.com>\n' +
     *              'Sent: 15 February 2021 08:58\n' +
     *              'To: Results <results@myhealthcareclinic.com>\n' +
     *              'Subject: Covid-19 Tests R402005328\n' +
     *              '\n' +
     *              'Your coronavirus (COVID-19) test result is positive. You do not have the virus.\n' +
     *              'You can return to work if you’ve not had a high temperature for 48 hours and feel well. Talk to your employer first.\n' +
     *              'If you feel well but someone you live with tests positive, self-isolate for 10 days from when that person’s symptoms started. If you get symptoms of coronavirus, self-isolate for 10 days.\n' +
     *              '\n' +
     *              'Contact 111 if you need medical help. For a medical emergency, dial 999.\n' +
     *              '\n' +
     *              'Kind regards,\n' +
     *              '\n' +
     *              'Randox Health\n' +
     *              '\n' +
     *              '\t');
     *              if( pm.matches() ){
     *                System.debug(LoggingLevel.ERROR, ' - : ' + pm.groupCount());
     *                System.debug(LoggingLevel.ERROR, ' - : ' + pm.group(4));
     *              }
     *  </code>
     *  </p>
     * @param resultText text to match against
     * @return {String} test result or null if not found
     */
    @TestVisible static String retrieveTestResultFromText(String resultText) {
        //result is always group 4
        Pattern resultPattern = Pattern.compile(TEST_NEGATIVE_POSITIVE_REGEX);
        Matcher pm = resultPattern.matcher(resultText);

        if (pm.find()) {
            return pm.group(1);
        }
        return null;
    }


    /**
     * Inserts email attachments if they conform to the test results file name pattern @see covid_EmailHandler.TEST_RESULT_FILE_REGEX and links them to inserted Email Message, COVID Test and Patient associated with COVID Test
     * @param binAttachList email attachments
     * @param recordIds a list of records the attachments should be associated with
     */
    @TestVisible static void createContentDocumentLinks(Messaging.InboundEmail.BinaryAttachment[] binAttachList, List<Id> recordIds) {
        List<ContentVersion>cvList = new List<ContentVersion>();
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        if (binAttachList == null) {
            return;
        }
        Pattern resultPattern = Pattern.compile(TEST_RESULT_FILE_REGEX);

        for (Messaging.InboundEmail.BinaryAttachment binAttach : binAttachList) {
            if (String.isNotBlank(binAttach.fileName)) {
                Matcher pm = resultPattern.matcher(binAttach.fileName);
                if (pm.matches()) {
                    ContentVersion cv = new ContentVersion();
                    cv.Title = 'EXTERNAL->' + binAttach.fileName;
                    cv.VersionData = binAttach.body;
                    cv.PathOnClient = '/' + binAttach.fileName ;
                    cvList.add(cv);
                }
            }
        }
        if (!cvList.isEmpty()) {
            insert cvList;
            cvList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvList];
            for (ContentVersion cv : cvList) {
                for (Id recordId : recordIds) {
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.ContentDocumentId = cv.ContentDocumentId;
                    cdl.LinkedEntityId = recordId;
                    cdl.ShareType = 'V';
                    cdl.Visibility = 'AllUsers';
                    cdlList.add(cdl);
                }
            }
            insert cdlList;
        }
    }

    /**
     * Searches for COVID Test reocrds based on the URN and retrieves the matching one. If no records are found returns an empty record with @see COVID_Test__c.Test_URN__c set to the passed value
     * @param urn URN of the test record
     *
     * @return {COVID_Test__c} record found or new record if one does not exist in the database
     */
    @TestVisible static COVID_Test__c getCovidTestForURN(String urn) {
        //TODO covid test certificate should go out automatically once generated.
        List<COVID_Test__c> covidTests = [SELECT Id, COVID_Test_Status__c, Patient__c, Test_URN__c FROM COVID_Test__c WHERE Test_URN__c = :urn];
        if (covidTests.isEmpty()) {
            return null;
        }
        return covidTests[0];
    }
}