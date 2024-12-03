/**
* @author Zoran Zunko
* @date 4/16/21
*
*/
@IsTest
private class Queueable_COVID_Test_CertificateTest {
    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        List<WorkTypeGroup> workTypeGroups = (List<WorkTypeGroup>) JSON.deserialize(onl_CheckoutCtrlTest.WORK_TYPE_GROUP_STRING, List<WorkTypeGroup>.class);
        for (WorkTypeGroup workTypeGroup : workTypeGroups) {
            workTypeGroup.Id = null;
            System.debug(LoggingLevel.ERROR, 'dataSetup - work: ' + workTypeGroup.Name);
        }

        insert workTypeGroups;

        List<COVID_Test__c> covidTests = TestDataFactory.createCovidTests(accounts, 1, false);
        covidTests[0].Test_URN__c = 'R123456789';
        covidTests[0].COVID_Test_Status__c = 'Negative';
        AnthologyTriggerDispatch.noTriggers = true;
        insert covidTests;
    }
    @IsTest static void generateCertificate_test() {
        System.assert([SELECT Id FROM ContentVersion].isEmpty());
        List<COVID_Test__c> covidTests = [
                SELECT
                        Id
                FROM COVID_Test__c
        ];
        covidTests[0].Work_Type_Group__c = [SELECT Id FROM WorkTypeGroup WHERE Name = 'Fit to Fly PCR Next Day'].Id;
        update covidTests;

        Test.startTest();
        Queueable_COVID_Test_Certificate covidTestCertificate = new Queueable_COVID_Test_Certificate();
        covidTestCertificate.covidTestIds = new Set<Id> {covidTests[0].Id};
        covidTestCertificate.execute(null);
        Test.stopTest();

        System.assert(![SELECT Id FROM ContentVersion].isEmpty());
    }

    @IsTest static void generateCertificate_queue_job_test() {
        System.assert([SELECT Id FROM ContentVersion].isEmpty());
        List<COVID_Test__c> covidTests = [
                SELECT
                        Id
                FROM COVID_Test__c
        ];
        covidTests[0].Work_Type_Group__c = [SELECT Id FROM WorkTypeGroup WHERE Name = 'Fit to Fly PCR Next Day'].Id;
        update covidTests;


        Test.startTest();
        Queueable_COVID_Test_Certificate.queueJob(new Set<Id> {covidTests[0].Id});
        Test.stopTest();

        System.assert(![SELECT Id FROM ContentVersion].isEmpty());
    }
}