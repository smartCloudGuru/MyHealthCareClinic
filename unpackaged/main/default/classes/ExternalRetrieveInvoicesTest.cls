/**
 * Created by Matija on 20.6.2023..
 */

@IsTest
public class ExternalRetrieveInvoicesTest {

    @TestSetup
    static void setUp() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].HeyDoc_Id__c = '6491ad67b0a15e0012e9aef5'; // from mock response for the ozempic treatment
        update accounts[0];

        Treatment__c t = new Treatment__c();
        t.Type__c = 'Ozempic';
        t.Account__c = accounts[0].Id;
        insert t;
    }

    @IsTest
    static void testBehavior() {
        HeyDocServiceMock.setAsMock();
        Test.startTest();
        ExternalRetrieveInvoices.getInvoices();
        Test.stopTest();

        List<Treatment_Invoice__c> tis = [SELECT Id, Account__c FROM Treatment_Invoice__c];

        System.assert(!tis.isEmpty());
        System.assert(tis[0].Account__c == [SELECT Id FROM Account LIMIT 1].Id);

        List<Treatment__c> ts = [SELECT Id, Account__c, Total_Invoiced__c, Total_Paid__c, Total_Outstanding__c FROM Treatment__c];

        for (Treatment__c treatment : ts) {
            System.debug(treatment);
        }
    }

}