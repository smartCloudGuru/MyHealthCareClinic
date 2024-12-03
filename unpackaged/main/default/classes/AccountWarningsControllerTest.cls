/**
 * Created 24.4.2023..
 */

@IsTest
global class AccountWarningsControllerTest {

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
    }

    @IsTest
    static void getPatientWarnings_test() {
        Account acc = [Select Id FROM Account];
        Patient_Warning__c pw = new Patient_Warning__c(Patient__c=acc.Id);
        insert pw;

        String ret = AccountWarningsController.getPatientWarnings(acc.Id);
        System.assert(ret!=null);

    }

    @IsTest
    static void getAeronaNotes_test() {
        Account acc = [Select Id FROM Account];

        String ret = AccountWarningsController.getAeronaNotes(acc.Id);
        System.assert(ret!=null);

    }

    @IsTest
    static void sembleCommentsToList_test() {

        System.assert(AccountWarningsController.sembleCommentsToList(null) == null);
        System.assert(AccountWarningsController.sembleCommentsToList('aalkjsh').size() == 1);
        System.assert(AccountWarningsController.sembleCommentsToList('aalkj\nsh').size() == 2);
        System.assert(AccountWarningsController.sembleCommentsToList('aalkj\n\nsh').size() == 2);
    }

    @IsTest
    static void testNewAuraHandledException() {
        AccountWarningsController.newAuraHandledException('test');
    }
}