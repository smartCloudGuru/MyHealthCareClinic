/**
 * Created by david on 25/03/2021.
 */

@IsTest
global class TH_CovidTest_GenerateCertificateTest {

    @IsTest
    static void doTest() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        Account account = accounts[0];
        Opportunity op = new Opportunity();
        op.StageName = 'Closed Won';
        op.AccountId = account.Id;
        op.CloseDate = Date.today();
        op.Amount = 0;
        insert op;
        COVID_Test__c ct = new COVID_Test__c();
        ct.Opportunity__c = op.id;
        ct.Test_Type__c='Day 2 Test';
        ct.COVID_Test_Status__c='Positive';
        ct.Test_URN__c='R1234567890';
        insert ct;

        ct.COVID_Test_Status__c = 'Negative';
        update ct;


//        Queueable_COVID_Test_Certificate covidTestCertificate = new Queueable_COVID_Test_Certificate();
//        covidTestCertificate.covidTestIds = new Set<Id> {ct.Id};
//        covidTestCertificate.execute(null);


    }



}