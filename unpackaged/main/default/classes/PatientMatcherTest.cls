@IsTest
public class PatientMatcherTest {
    @TestSetup
    static void makeData() {
        Account testAccount = new Account(
            FirstName = 'test',
            LastName = 'test',
            HeyDoc_Id__c = '12345',
            PersonEmail = 'test@test.com',
            RecordTypeId = PatientMatcher.PERSON_ACCOUNT_RECORD_TYPE_ID
        );
        insert testAccount;
    }

    @IsTest
    static void getPatientsTest() {
        PatientMatcher matcher = new PatientMatcher();
        matcher.setExternalIdField(Account.HeyDoc_Id__c);
        matcher.addExternalId('12345');
        matcher.addEmail('test@test.com');

        Map<String, Account> patients = matcher.getPatients();

        System.assertNotEquals(null, patients.get('12345'));
        System.assertNotEquals(null, patients.get('test@test.com'));
    }
}