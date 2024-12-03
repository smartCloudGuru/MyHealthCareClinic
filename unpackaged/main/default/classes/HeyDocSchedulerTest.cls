@IsTest
public class HeyDocSchedulerTest {
    /*
    @IsTest
    static void noMatchTest() {
        performTest();
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Account
                WHERE HeyDoc_Id__c = :HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID
            ]
        );
        System.assertEquals(
            HeyDocServiceMock.MOCK_RESULT_COUNT,
            [
                SELECT COUNT()
                FROM Proposed_Appointment__c
                WHERE Patient__r.HeyDoc_Id__c = :HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID
            ]
        );
    }

    @IsTest
    static void matchTest() {
        Account testAcc = new Account(
            HeyDoc_Id__c = HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID,
            FirstName = 'TEST',
            LastName = 'TEST',
            RecordTypeId = PatientMatcher.PERSON_ACCOUNT_RECORD_TYPE_ID
        );

        insert testAcc;

        performTest();

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Account
                WHERE HeyDoc_Id__c = :HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID
            ]
        );
        System.assertEquals(
            HeyDocServiceMock.MOCK_RESULT_COUNT,
            [
                SELECT COUNT()
                FROM Proposed_Appointment__c
                WHERE Patient__r.HeyDoc_Id__c = :HeyDocServiceMock.MOCK_HEYDOC_PATIENT_ID
            ]
        );
    }

    private static void performTest() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        HeyDocScheduler.HeyDocQueueable testJob = new HeyDocScheduler.HeyDocQueueable(1);
        System.enqueueJob(testJob);
        Test.stopTest();
    }
    */

    @IsTest
    static void testest() {
        HeyDocScheduler hs = new HeyDocScheduler();
        hs.execute(null);
    }
}