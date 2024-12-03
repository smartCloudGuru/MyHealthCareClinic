/**
 * Created 8.5.2023..
 */

@IsTest
private class PatientNotesInvocableTest {

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        Patient_Warning__c pw = new Patient_Warning__c();
        pw.Note_Warning__c = 'test';
        pw.Patient__c = accounts[0].Id;
        insert pw;
    }

    @IsTest
    static void testBehavior() {

        List<Patient_Warning__c> notes = [SELECT ID FROM Patient_Warning__c LIMIT 1];
        PatientNotesInvocable.addCommentToPatientOnExternal(notes);

    }
}