/**
 * @author Zoran Zunko
 *
 * @date 5/14/21
 */
@IsTest
public class eml_YourTestResultsCtrlTest {
    @TestSetup
    static void dataSetup() {

    }

    @IsTest static void testPageLoad() {

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


        eml_YourTestResultsCtrl ctrl = new eml_YourTestResultsCtrl();
        ctrl.recId = ct.Id;

    }


}