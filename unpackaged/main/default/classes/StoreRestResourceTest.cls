/**
 * Created 17.5.2023..
 */

@IsTest
private class StoreRestResourceTest {


    @TestSetup
    static void dataSetup() {
    }

    @IsTest
    static void getDepartmentsByService_test_ok() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'GET';
        req.requestURI = '/m/store/departments?service=Medical';
        req.params.put('service', 'Medical');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        StoreRestResource.getRecord();
        Test.stopTest();

    }

    @IsTest
    static void getDepartmentsByService_test_400() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'GET';
        req.requestURI = '/m/store/departments';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        StoreRestResource.getRecord();
        Test.stopTest();

    }

    @IsTest
    static void getDiscountCode_test_404() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'GET';
        req.requestURI = '/m/store/discount?code=A100&productId=01t26000009sz8yAAA&locationId=0Hh4H0000004CZFSA2';
        req.params.put('code', 'A100');
        req.params.put('productId', '01t26000009sz8yAAA');
        req.params.put('locationId', '0Hh4H0000004CZFSA2');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        StoreRestResource.getRecord();
        Test.stopTest();

    }

}