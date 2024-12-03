/**
 * Created 2.5.2024..
 */

@IsTest
private class BookingBusinessRulesTest {
    @TestSetup
    static void setup() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        // Create mock Opportunity
        Opportunity testOpp = new Opportunity(
                Member_Benefit_Applicable__c = true,
                AccountId = accounts[0].Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Name = 'TEST OPP'
        );
        insert testOpp;

        // Create mock WorkType
        WorkType testWT = new WorkType(Name = 'Mock WT', Membership_Duration__c = 15, EstimatedDuration = 30);
        insert testWT;

        // Create mock ServiceAppointment
        ServiceAppointment testApp = new ServiceAppointment(ParentRecordId = accounts[0].Id, WorkTypeId = testWT.Id, SchedStartTime = Datetime.now().addMonths(1));
        insert testApp;
    }

    @IsTest
    static void TestCalcAppointmentDurationOverride() {
        Opportunity testOpp = [SELECT Id, AccountId, Member_Benefit_Applicable__c FROM Opportunity LIMIT 1];
        ServiceAppointment testApp = [SELECT Id, WorkTypeId, SchedStartTime FROM ServiceAppointment LIMIT 1];

        Test.startTest();
        Integer overrideDuration = BookingBusinessRules.calcAppointmentDuration(testOpp, testApp);
        Test.stopTest();

        System.assertEquals(null, overrideDuration);
    }

    @IsTest
    static void TestCalcAppointmentDurationNoOverride_existing_appointment() {

        Opportunity testOpp = [SELECT Id, AccountId, Member_Benefit_Applicable__c FROM Opportunity LIMIT 1];
        ServiceAppointment testApp = [SELECT Id, WorkTypeId, SchedStartTime FROM ServiceAppointment LIMIT 1];

        // Create mock ServiceAppointment
        ServiceAppointment prevApp = new ServiceAppointment(
                ParentRecordId = testOpp.AccountId,
                WorkTypeId = testApp.WorkTypeId,
                SchedStartTime = Datetime.now().addMonths(-3), Status = 'Scheduled');
        insert prevApp;

        Test.startTest();
        Integer overrideDuration = BookingBusinessRules.calcAppointmentDuration(testOpp, testApp);
        Test.stopTest();

        System.assertEquals(15, overrideDuration);
    }

    @IsTest
    static void TestCalcAppointmentDurationNoOverride_Noexisting_appointment() {

        Opportunity testOpp = [SELECT Id, AccountId, Member_Benefit_Applicable__c FROM Opportunity LIMIT 1];
        ServiceAppointment testApp = [SELECT Id, WorkTypeId, SchedStartTime FROM ServiceAppointment LIMIT 1];

        // Create mock ServiceAppointment
        ServiceAppointment prevApp = new ServiceAppointment(
                ParentRecordId = testOpp.AccountId,
                WorkTypeId = testApp.WorkTypeId,
                SchedStartTime = Datetime.now().addMonths(-8), Status = 'Scheduled');
        insert prevApp;

        Test.startTest();
        Integer overrideDuration = BookingBusinessRules.calcAppointmentDuration(testOpp, testApp);
        Test.stopTest();

        System.assertEquals(null, overrideDuration);
    }
}