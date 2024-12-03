/**
 * Created 2.8.2022..
 */

@IsTest
private class OnlPasswordChangeInvocableTest {

    @TestSetup
    static void dataSetup() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';
        accounts[0].Online_Registration_Date__c = Datetime.now();
        update accounts[0];
    }

    @IsTest
    static void test_sendEmail() {
        
        List<Account> accs = [SELECT Id FROM Account LIMIT 1];
        OnlPasswordChangeInvocable.sendEmail(accs);
    }
}