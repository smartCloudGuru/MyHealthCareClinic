/**
 * Created 22.2.2023..
 */

@IsTest
private class MemPdfContractResourceTest {

    @TestSetup
    static void dataSetup() {

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';
        update accounts[0];
    }

    @IsTest
    static void testBehavior() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/util/mempdf';
        req.requestBody = Blob.valueOf('{"accountId":"' + [SELECT Id FROM Account LIMIT 1].Id + '","body":"abody"}');

        RestContext.request = req;

        Test.startTest();
        MemPdfContractResource.doPost();
        Test.stopTest();

        System.debug(res?.statusCode);
    }
}