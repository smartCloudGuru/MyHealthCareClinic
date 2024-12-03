/**
 * Created 12.11.2021..
 */

@IsTest
public class createOneTimeDiscountCtrlTest {

    @TestSetup
    public static void setUp() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
    }

    @IsTest
    private static void test_createOneTimeDiscount() {

        COVID_Test__c ctest = new COVID_Test__c();
        ctest.Test_Type__c = 'PCR Test';
        insert ctest;

        createOneTimeDiscountCtrl.InputForm iform = new createOneTimeDiscountCtrl.InputForm();
        iform.dorefund = false;
        iform.docoupon = true;
        iform.docancel = true;
        iform.recordId = ctest.Id;
        iform.code = '12387';

        createOneTimeDiscountCtrl.createOneTimeDiscount(JSON.serialize(iform));
    }

    @IsTest
    private static void test_refund() {

        List<Account> acc = [SELECT Id FROM Account];
        String priceBookId = [SELECT Id FROM Pricebook2 LIMIT 1].Id;

        Opportunity opp = new Opportunity(
                AccountId = acc[0].Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Pricebook2Id = priceBookId
        );

        insert opp;

        bt_stripe__Transaction__c tx = new bt_stripe__Transaction__c();
        tx.Opportunity__c = opp.Id;
        tx.bt_stripe__Transaction_Status__c = 'Completed';
        tx.bt_stripe__Payment_Status__c = 'Captured';
        tx.bt_stripe__Amount__c = 22.54;
        tx.Dummy__c = true;
        insert tx;


        COVID_Test__c ctest = new COVID_Test__c();
        ctest.Test_Type__c = 'PCR Test';
        ctest.Opportunity__c = opp.Id;
        insert ctest;

        /*
        String errMsg = createOneTimeDiscountCtrl.refund(ctest.Id, 10.5);
        System.debug(LoggingLevel.ERROR,'refund result: ' + errMsg);
        //System.assert(errMsg==null);
         */

        createOneTimeDiscountCtrl.InputForm iform = new createOneTimeDiscountCtrl.InputForm();
        iform.dorefund = true;
        iform.docoupon = false;
        iform.docancel = false;
        iform.recordId = ctest.Id;
        iform.code = '12387';
        iform.amount = 1.5;

        System.debug(createOneTimeDiscountCtrl.createOneTimeDiscount(JSON.serialize(iform)));


    }

}