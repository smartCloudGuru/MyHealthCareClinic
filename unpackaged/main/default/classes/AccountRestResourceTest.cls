/**
 * Created 27.2.2023..
 */

@IsTest
private class AccountRestResourceTest {

    @TestSetup
    static void dataSetup() {
        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].FirstName = 'DFN';
        accounts[0].LastName = 'DLN';
        accounts[0].Date_of_Birth__c = Date.today();
        update accounts[0];
    }

    @IsTest
    static void doPost_test() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/m/account';

        Account acc = new Account();
        acc.FirstName = 'FN';
        acc.LastName = 'LN';
        acc.PersonEmail = 'fnln@example.com';

        req.requestBody = Blob.valueOf(JSON.serialize(acc));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        AccountRestResource.doPost();
        Test.stopTest();

        System.assert(res.responseBody != null);
        System.assert(res.statusCode == 200);
        System.debug(res.responseBody.toString());

        AccountRestResource.MHCAPIResponse apiResp =
                (AccountRestResource.MHCAPIResponse)
                        JSON.deserialize(res.responseBody.toString(), AccountRestResource.MHCAPIResponse.class);

        System.assert(apiResp?.message != null);

        Account acc2 = [SELECT Id, PersonEmail, Patient_Type__c FROM Account WHERE Id = :apiResp.message];
        System.assert(acc2.PersonEmail == acc.PersonEmail);
        System.assert(acc2.Patient_Type__c == 'New');

    }

    @IsTest
    static void doPost_duplicate_test() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/m/account';

        Account acc = [SELECT Id, FirstName, LastName, PersonEmail, Date_of_Birth__c FROM Account LIMIT 1];
        acc.Id = null;

        req.requestBody = Blob.valueOf(JSON.serialize(acc));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        AccountRestResource.doPost();
        Test.stopTest();

        System.assert(res.responseBody != null);
        System.assert(res.statusCode == 400);
        System.debug(res.responseBody.toString());

    }

    @IsTest
    static void getRelatedRecords_test() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Account acc = [SELECT Id, FirstName, LastName, PersonEmail FROM Account LIMIT 1];

        req.httpMethod = 'GET';
        req.requestURI = '/m/account/' + acc.Id + '/related';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        List<Account> retAccs = AccountRestResource.getRelatedRecords();
        Test.stopTest();

        System.assert(retAccs != null);
        System.debug(JSON.serializePretty(retAccs, true));
    }

    @IsTest
    static void doPatchPassword_test() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Account acc = [SELECT Id FROM Account LIMIT 1];

        req.httpMethod = 'PATCH';
        req.requestURI = '/m/account/';

        acc.Store_password__c = 'test';

        req.requestBody = Blob.valueOf(JSON.serialize(acc));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        AccountRestResource.doPatch();
        Test.stopTest();

        System.assert(res.responseBody != null);
        System.assert(res.statusCode == 200);
        System.debug(res.responseBody.toString());

        acc = [SELECT Id, Online_Registration_Date__c FROM Account LIMIT 1];
        System.assert(acc.Online_Registration_Date__c!=null);

    }

    @IsTest
    static void resFromMHCApiResponse_test() {
        RestResponse res = new RestResponse();
        AccountRestResource.resFromMHCApiResponse(res, 201, 'test');
        System.assert(res.statusCode == 201);
    }
}