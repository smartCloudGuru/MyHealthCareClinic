/**
 * Created by Matija on 10.8.2023..
 */

@IsTest
private class ExternalAppointmentsImportTest {

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);

        accounts[0].HeyDoc_Id__c = 'mock_hd_pat_id';
        accounts[0].Aerona_Id__c = '1111';
        update accounts;
    }

    @IsTest
    static void testBehavior_Aerona() {

        AeronaServiceMock.setAsMock();
        Test.startTest();
        List<Account> accounts = [SELECT Id, Aerona_Id__c, HeyDoc_Id__c FROM Account WHERE Aerona_Id__c='1111'];
        ExternalAppointmentsImport.getAllAeronaAppointmentsForPatient(accounts.get(0));
        Test.stopTest();
    }

    @IsTest
    static void testBehavior_Semble() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        List<Account> accounts = [SELECT Id, Aerona_Id__c, HeyDoc_Id__c FROM Account WHERE Aerona_Id__c='1111'];
        ExternalAppointmentsImport.getAllSembleAppointmentsForPatient(accounts.get(0));
        Test.stopTest();
    }
}