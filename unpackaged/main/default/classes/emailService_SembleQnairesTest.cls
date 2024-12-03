/**
 * Created by Matija on 12.6.2023..
 */

@IsTest
private class emailService_SembleQnairesTest {

    @TestSetup
    static void doSetup()
    {
        List<Account> accs = TestDataFactory.createPersonAccounts(1, true);

        accs[0].HeyDoc_Id__c = '62bc0235d5c7e100142e4ec0';

        update accs[0];
    }

    @IsTest
    static void testBehavior_Ozempic() {

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Patient ID: 62bc0235d5c7e100142e4ec0 filled in a new questionnaire';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = 'etc etc something Ozempic Questionnaire A questionnaire has been submitted';
        email.htmlBody = 'etc etc something Ozempic Questionnaire A questionnaire has been submitted';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        emailService_SembleQnaires emailHandler = new emailService_SembleQnaires();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, env);

        System.assert(result.success);

        List<Account> accs = [SELECT Id FROM Account WHERE HeyDoc_Id__c = '62bc0235d5c7e100142e4ec0' LIMIT 1];
        System.assert(!accs.isEmpty());

        //check treatment exists
        List<Treatment__c> trs = [SELECT Id, Account__c FROM Treatment__c];
        System.assert(trs.size()==1);
        System.assert(trs[0].Account__c == accs[0].Id);


    }

    @IsTest
    static void testBehavior_Wegovy() {

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Patient ID: 62bc0235d5c7e100142e4ec0 filled in a new questionnaire';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = 'etc etc something Wegovy Questionnaire A questionnaire has been submitted';
        email.htmlBody = 'etc etc something Wegovy Questionnaire A questionnaire has been submitted';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        emailService_SembleQnaires emailHandler = new emailService_SembleQnaires();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, env);

        System.assert(result.success);

        List<Account> accs = [SELECT Id, Date_Wegovy_Consent_Signed__c FROM Account WHERE HeyDoc_Id__c = '62bc0235d5c7e100142e4ec0' LIMIT 1];
        System.assert(!accs.isEmpty());

        //check treatment exists
        List<Treatment__c> trs = [SELECT Id, Account__c FROM Treatment__c];
        System.assert(trs.size()==1);
        System.assert(trs[0].Account__c == accs[0].Id);


    }


    @IsTest
    static void testWhenNoExistingPatientWithThatId() {

        String unknownId = '6ddddddddddddddddddddddd';

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        List<Messaging.InboundEmail.Header> headers = new List<Messaging.InboundEmail.Header>();
        Messaging.InboundEmail.Header header = new Messaging.InboundEmail.Header();
        header.name = 'Test';
        header.value = 'Test';
        headers.add(header);
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Patient ID: ' + unknownId + ' filled in a new questionnaire';
        email.fromAddress = 'test@example.com';
        email.fromName = 'Test Example';
        email.headers = headers;
        email.plainTextBody = 'etc etc something Ozempic Questionnaires A questionnaire has been submitted';
        email.htmlBody = 'etc etc something Ozempic Questionnaires A questionnaire has been submitted';

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        HeyDocServiceMock.setAsMock();
        Test.startTest();
        emailService_SembleQnaires emailHandler = new emailService_SembleQnaires();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, env);
        Test.stopTest();
        System.assert(result.success);

        List<Account> accs = [SELECT Id, Date_Ozempic_Consent_Signed__c FROM Account WHERE HeyDoc_Id__c = : unknownId LIMIT 1];
        System.assert(!accs.isEmpty());

        //check treatment exists
        List<Treatment__c> trs = [SELECT Id, Account__c FROM Treatment__c];
        System.assert(trs.size()==1);
        System.assert(trs[0].Account__c == accs[0].Id);
    }

    @IsTest
    static void testNoEmailBehavior() {

        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        System.assertEquals(0, emailMessages.size());

        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        emailService_SembleQnaires emailHandler = new emailService_SembleQnaires();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(null, env);

        System.assert(result.success);



    }
}