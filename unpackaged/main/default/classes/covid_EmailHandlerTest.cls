/**
* @author Zoran Zunko
* @date 2/19/21
*
*/
@IsTest class covid_EmailHandlerTest {
    static String testResultEmailTextPositive = 'From: Randox Health <no-reply@randoxhealth.com>\n' +
            'Sent: 15 February 2021 08:58\n' +
            'To: Results <results@myhealthcareclinic.com>\n' +
            'Subject: Covid-19 Tests R402005328\n' +
            '\n' +
            'Your coronavirus (COVID-19) test result is positive. You do not have the virus.\n' +
            'You can return to work if you’ve not had a high temperature for 48 hours and feel well. Talk to your employer first.\n' +
            'If you feel well but someone you live with tests positive, self-isolate for 10 days from when that person’s symptoms started. If you get symptoms of coronavirus, self-isolate for 10 days.\n' +
            '\n' +
            'Contact 111 if you need medical help. For a medical emergency, dial 999.\n' +
            '\n' +
            'Kind regards,\n' +
            '\n' +
            'Randox Health\n' +
            '\n' +
            '\t';

    static String testRegistrationEmail = 'From: Randox Health <no-reply@randoxhealth.com>\n' +
            'Sent: 15 February 2021 08:58\n' +
            'To: Results <results@myhealthcareclinic.com>\n' +
            'Subject: Covid-19 Kit Registration R402005111\n' +
            '\n' +
            'Your ...';


    static String testResultEmailTextNegative = 'From: Randox Health <no-reply@randoxhealth.com>\n' +
            'Sent: 15 February 2021 08:58\n' +
            'To: Results <results@myhealthcareclinic.com>\n' +
            'Subject: Covid-19 Tests R402005328\n' +
            '\n' +
            'Your coronavirus (COVID-19) test result is *negative*. You do not have the virus.\n' +
            'You can return to work if you’ve not had a high temperature for 48 hours and feel well. Talk to your employer first.\n' +
            'If you feel well but someone you live with tests positive, self-isolate for 10 days from when that person’s symptoms started. If you get symptoms of coronavirus, self-isolate for 10 days.\n' +
            '\n' +
            'Contact 111 if you need medical help. For a medical emergency, dial 999.\n' +
            '\n' +
            'Kind regards,\n' +
            '\n' +
            'Randox Health\n' +
            '\n' +
            '\t';

    static String testResultEmailTextNegative_HTML = '<body style="margin: 0px; direction: ltr;"><span style="display: inline-block;">Dear Dush Gunasekera,</span>\n' +
            '\n' +
            '<br>\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">Birth date: 14/Dec/1972</span>\n' +
            '\n' +
            '<br>\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">Your coronavirus (COVID-19) test result is <strong>negative</strong>, meaning you did not have the virus when the test was done.</span>\n' +
            '\n' +
            '<br>\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">Please continue to follow your local government guidelines.</span> \n' +
            '\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">Contact 112 if you need medical help. For a medical emergency, dial 999.</span> \n' +
            '\n' +
            '<br>\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">For more advice:</span>\n' +
            '\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">If you reside in the United Kingdom, go to <a href="https://www.gov.uk/coronavirus">https://www.gov.uk/coronavirus</a></span>\n' +
            '\n' +
            '<br>\n' +
            '\n' +
            '<span>If you reside in the Republic of Ireland, go to <a href="https://www.gov.ie/en">https://www.gov.ie/en/</a></span>\n' +
            '\n' +
            '<br>\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">To help future customers make an informed decision, please do share your experience of the Randox Health Covid-19 Testing Service on Trustpilot. <a href="https://www.trustpilot.com/review/www.randoxhealth.com">https://www.trustpilot.com/review/www.randoxhealth.com</a> </span>\n' +
            '\n' +
            '<br>\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;">Kind regards,</span>\n' +
            '\n' +
            '<br>\n' +
            '<br>\n' +
            '\n' +
            '<span style="display: inline-block;"><strong>Randox Health</strong></span><img style="height:1px !important;width:1px !important;border-width:0 !important;margin-top:0 !important;margin-bottom:0 !important;margin-right:0 !important;margin-left:0 !important;padding-top:0 !important;padding-bottom:0 !important;padding-right:0 !important;padding-left:0 !important;" border="0" height="1" width="1" alt="" src="https://u15579038.ct.sendgrid.net/wf/open?upn=qxQ46ouquUk8YsFAnxAf7LCc3ND-2Bfuh6Fn-2F3lZYEVxLM0oUkOCGpkvW74qWBfGeFESW-2B7CKYLo4c75s2s77C22Sa1t9QwkKhymSG-2BgGvKKcdD8cHm6oIC1bz7o0qSMWlLDlrp8AjsnjWbYrUdD-2FC1tqke8ipI1Lhx-2B-2Fq0oGR7mUCyFGuALvCuyXoPWwuEwnHdrGrfxYE6pywAIVUH83k0-2Bye6GklEH-2BPWkLF1uoN8fIV-2B2NvmUjPKK2wcNjxhvi5" lh4tqp5ks="">\n' +
            '<br><br><span style="font-family:Arial; Font-size:10.0pt"> <hr width="100%"> This email has been scanned for email related threats and delivered safely by Mimecast.<br> For more information please visit <a href="http://www.mimecast.com">http://www.mimecast.com</a> <hr width="100%"> </span></body>';

    static String testResultEmailTextUnclear = 'From: Randox Health <no-reply@randoxhealth.com>\n' +
            'Sent: 15 February 2021 08:58\n' +
            'To: Results <results@myhealthcareclinic.com>\n' +
            'Subject: Covid-19 Tests R402005328\n' +
            '\n' +
            'Your coronavirus (COVID-19) test result is *unclear*. You do not have the virus.\n' +
            'You can return to work if you’ve not had a high temperature for 48 hours and feel well. Talk to your employer first.\n' +
            'If you feel well but someone you live with tests positive, self-isolate for 10 days from when that person’s symptoms started. If you get symptoms of coronavirus, self-isolate for 10 days.\n' +
            '\n' +
            'Contact 111 if you need medical help. For a medical emergency, dial 999.\n' +
            '\n' +
            'Kind regards,\n' +
            '\n' +
            'Randox Health\n' +
            '\n' +
            '\t';

    static String testRegisteredEmail = '*** IMPORTANT INFORMATION CONTAINED IN THIS EMAIL ***\n' +
            '\n' +
            'Thank you for registering your Corporate Account Kit Registrations on the Randox Health portal.\n' +
            '\n' +
            'We can confirm you have successfully registered with the following URNs:\n' +
            '\n' +
            '- R402231413\n' +
            '\n' +
            'Please ensure you keep this information safe and secure. You will need this information if you have any queries regarding your sample.\n' +
            '\n' +
            'If you have any questions regarding this process, please check our FAQ [https://www.randoxhealth.com/covid-19-testing-faq/] or contact the NHS contact centre on: 03003032713\n' +
            '\n' +
            'Please do not reply to this email\n' +
            '\n' +
            'Kind regards,\n' +
            '\n' +
            'Randox Health';


    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<COVID_Test__c> covidTests = TestDataFactory.createCovidTests(accounts, 1, false);
        covidTests[0].Test_URN__c = 'R123456789';
        Opportunity opp = new Opportunity();
        opp.AccountId=accounts[0].Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        insert opp;
        covidTests[0].Opportunity__c = opp.Id;
        insert covidTests;
    }

    @IsTest static void getCovidTestForURN_TestExists_test() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        covidTest = covid_EmailHandler.getCovidTestForURN(covidTest.Test_URN__c);
        System.assert(covidTest.Patient__c != null);
        System.assert(covidTest.Id != null);
    }

    @IsTest static void getCovidTestForURN_TestDoesntExists_test() {
        COVID_Test__c covidTest = covid_EmailHandler.getCovidTestForURN('123456');
        System.assert(covidTest == null);
    }

    @IsTest static void retrieveTestResultFromText_test() {
        System.assertEquals('positive', covid_EmailHandler.retrieveTestResultFromText(testResultEmailTextPositive));
        System.assertEquals('negative', covid_EmailHandler.retrieveTestResultFromText(testResultEmailTextNegative));
        System.assertEquals('negative', covid_EmailHandler.retrieveTestResultFromText(testResultEmailTextNegative_HTML));
        System.assertEquals('unclear', covid_EmailHandler.retrieveTestResultFromText(testResultEmailTextUnclear));
        System.assert(String.isBlank(covid_EmailHandler.retrieveTestResultFromText('sjklagfhalsdghlasdkljg' +
                'asdfasd' +
                'fasd' +
                'fas' +
                'df' +
                'asdf' +
                'as')));
    }

    @IsTest static void retrieveKitUrnFromText_test() {
        System.assertEquals('R402231413', covid_EmailHandler.retrieveKitUrnFromText(testRegisteredEmail));
        System.assertEquals('R402005111', covid_EmailHandler.retrieveKitUrnFromText('Covid-19 Kit Registration R402005111'));
        System.assertEquals('R402030078', covid_EmailHandler.retrieveKitUrnFromText('asdasdadasR402030078asdasdada'));
        System.assertEquals('RD402030078', covid_EmailHandler.retrieveKitUrnFromText('asdasdadasRD402030078asdasdada'));
        System.assertEquals('M402030078', covid_EmailHandler.retrieveKitUrnFromText('asdasdadasM402030078asdasdada'));
        System.assert(String.isBlank(covid_EmailHandler.retrieveKitUrnFromText('sjklagfhalsdghlasdkljg' +
                'asdfasd' +
                'fasd' +
                'fas' +
                'df' +
                'asdf' +
                'as')));
    }

    @IsTest static void createContentDocumentLinks_test() {
        Messaging.InboundEmail.BinaryAttachment[] binAttachList = new List<Messaging.InboundEmail.BinaryAttachment> ();
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.fileName = 'R123456789.pdf';
        binaryAttachment.body = Blob.valueOf('Test Content');

        Messaging.InboundEmail.BinaryAttachment binaryAttachmentNoPdf = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachmentNoPdf.fileName = '123456789.pdf';
        binaryAttachmentNoPdf.body = Blob.valueOf('Test Content');

        Messaging.InboundEmail.BinaryAttachment binaryAttachmentNoName = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachmentNoName.body = Blob.valueOf('Test Content');

        binAttachList.add(binaryAttachment);
        binAttachList.add(binaryAttachmentNoPdf);
        binAttachList.add(binaryAttachmentNoName);

        covid_EmailHandler.createContentDocumentLinks(binAttachList, new List<Id>{
                covidTest.Id, covidTest.Patient__c
        });

        List<ContentDocument> cds = [SELECT Id FROM ContentDocument];
        System.assertEquals(1, cds.size());

        List<ContentDocumentLink> cdls = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cds[0].Id];
        System.debug(LoggingLevel.ERROR, 'createContentDocumentLinks_test - : ' + cdls);
        //one shared to user +1 to the ones genreated
        System.assertEquals(3, cdls.size());
    }

    @IsTest static void regexString_test() {
        System.assertEquals(covid_EmailHandler.KIT_REGISTRATION_SUBJECT, 'Corporate Account Kit Registrations for ');
        System.assertEquals(covid_EmailHandler.KIT_RECEIVED_SUBJECT, 'Covid-19 Kit Received');
        System.assertEquals(covid_EmailHandler.KIT_RESULTS_SUBJECT, 'Covid-19 Tests');
        System.assertEquals(covid_EmailHandler.KIT_SERIAL_NUMBER_REGEX, '((?s).*)((?s)(M|R|RD|PD)\\d{8,12})((?s).*)');
        System.assertEquals(covid_EmailHandler.TEST_RESULT_FILE_REGEX, '(R|M|RD|PD)\\d{8,12}.pdf');
    }

    @IsTest static void testRegistrationCovidTestExists() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_REGISTRATION_SUBJECT + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testRegisteredEmail.replace('R402231413', covidTest.Test_URN__c);
        email.htmlBody = testRegisteredEmail.replace('R402231413', covidTest.Test_URN__c);

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(result.success);
        System.assertEquals(1, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());
        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_REGISTERED, covidTest.COVID_Test_Status__c);

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, emailMessages.size());
    }
    @IsTest static void testRegistrationCovidTestDoesntExist() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_REGISTRATION_SUBJECT + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testRegisteredEmail;
        email.htmlBody = testRegisteredEmail;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(!result.success);
        System.assertEquals(1, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());
        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        System.assertEquals(0, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Test_URN__c = 'R402231413'].size());

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());
    }

    @IsTest static void testReceiveCovidTestExists() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_RECEIVED_SUBJECT + covidTest.Test_URN__c;
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = ' Hi Dush \n' +
                '\n' +
                'This is hte email received when the kit has made it to the lab and has been checked prior to running the test\n' +
                '\n' +
                'Alannah';
        email.htmlBody = email.plainTextBody;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(result.success);
        System.assertEquals(1, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());

        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_RECEIVED, covidTest.COVID_Test_Status__c);

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, emailMessages.size());
    }
    @IsTest static void testReceiveCovidTestDoesntExist() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_RECEIVED_SUBJECT + 'R402005328adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = ' Hi Dush \n' +
                '\n' +
                'This is hte email received when the kit has made it to the lab and has been checked prior to running the test\n' +
                '\n' +
                'Alannah';
        email.htmlBody = email.plainTextBody;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(!result.success);
//        System.assertEquals(2, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());

        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        System.assertEquals(0, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Test_URN__c = 'R402005328'].size());

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());
    }

    @IsTest static void testResultCovidTestExists() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_RESULTS_SUBJECT + covidTest.Test_URN__c + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testResultEmailTextNegative;
        email.htmlBody = testResultEmailTextNegative;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(result.success);
        System.assertEquals(1, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());
        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_NEGATIVE, covidTest.COVID_Test_Status__c);

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, emailMessages.size());
    }
    @IsTest static void testResultCovidTestExists_unclear() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_RESULTS_SUBJECT + covidTest.Test_URN__c + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testResultEmailTextUnclear;
        email.htmlBody = testResultEmailTextUnclear;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(result.success);
        System.assertEquals(1, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());
        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_UNCLEAR, covidTest.COVID_Test_Status__c);

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, emailMessages.size());
    }

    @IsTest static void testKIT_REGISTERED_SUBJECT_New() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_REGISTERED_SUBJECT + covidTest.Test_URN__c + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testRegistrationEmail;
        email.htmlBody = testRegistrationEmail;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(result.success);
        System.assertEquals(1, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());
        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(1, emailMessages.size());
    }
    @IsTest static void testResultCovidTestDoesntExist() {
        COVID_Test__c covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_RESULTS_SUBJECT + 'R402005328' +'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testResultEmailTextPositive;
        email.htmlBody = testResultEmailTextPositive;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(!result.success);
        System.assertEquals(1, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c].size());
        covidTest = [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Id = :covidTest.Id];
        System.assertEquals(covid_EmailHandler.STATUS_NEW, covidTest.COVID_Test_Status__c);

        System.assertEquals(0, [SELECT Id, Patient__c, COVID_Test_Status__c, Test_URN__c FROM COVID_Test__c WHERE Test_URN__c = 'R402005328'].size());

        emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());
    }

    @IsTest static void test_NoUrn() {
        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_RESULTS_SUBJECT + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testResultEmailTextPositive;
        email.htmlBody = testResultEmailTextPositive;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(!result.success);
        System.assert(result.message.contains('No URN found in email'));
    }


    @IsTest static void test_NoSubject() {
        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = testResultEmailTextPositive;
        email.htmlBody = testResultEmailTextPositive;

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(!result.success);
        System.assert(result.message.contains('Subject unknown'));

    }

    @IsTest static void test_Exception() {
        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = '123123' + covid_EmailHandler.KIT_REGISTRATION_SUBJECT + 'adasda';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = null;
        email.htmlBody = null;


        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        covid_EmailHandler cvEmailHandler = new covid_EmailHandler();
        Messaging.InboundEmailResult result = cvEmailHandler.handleInboundEmail(email, env);

        System.assert(!result.success);
        System.assert(result.message.contains('. Details '));

    }


  
}