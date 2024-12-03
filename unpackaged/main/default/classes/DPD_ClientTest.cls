/**
 * @author Zoran Zunko
 *
 * @date 5/14/21
 */
@IsTest
public class DPD_ClientTest {
    @TestSetup
    static void dataSetup() {

        DPD_Configuration__c config = new DPD_Configuration__c();
        config.Api_Url__c = 'mock:';
        insert config;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        Account acc = accounts[0];

        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.StageName = 'Closed Won';
        opp.CloseDate = Date.today();
        insert opp;

    }

    @IsTest static void login_test() {


        Test.setMock(HttpCalloutMock.class, new MockDPDCallout());

        Test.startTest();
        String session = DPD_Client.login();
        Test.stopTest();

        System.assertEquals(session, '11111111-83b7-2222-9740-333333333333');
    }

    @IsTest static void insertShipment_test() {


        Test.setMock(HttpCalloutMock.class, new MockDPDCallout());

        String oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        DPD_Client.InsertShipmentRequest req = new DPD_Client.InsertShipmentRequest();
        req.oppId = oppId;
        String shipmentId = DPD_Client.insertShipment(JSON.serialize(req));
        Test.stopTest();

        System.assertEquals(shipmentId, '777777777');


    }


}