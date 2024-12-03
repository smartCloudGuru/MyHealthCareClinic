/**
 * Created 27.2.2023..
 */

@IsTest
private class StorePasswordMngRestResourceTest {

    @TestSetup
    static void dataSetup() {

    }

    @IsTest
    static void doPost_test() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'POST';
        req.requestURI = '/m/passwordvalidation';

        StorePasswordMngRestResource.PasswordValidationRequest pvr = new StorePasswordMngRestResource.PasswordValidationRequest();

        pvr.Email = 'e@e.com';
        pvr.Password = '1234';

        req.requestBody = Blob.valueOf(JSON.serialize(pvr));

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        StorePasswordMngRestResource.doPost();
        Test.stopTest();

        System.debug(res.responseBody);
        System.debug(res.statusCode);
        System.assert(res.responseBody != null);
        System.assert(res.statusCode == 404);

    }
}