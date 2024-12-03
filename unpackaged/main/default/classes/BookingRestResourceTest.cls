/**
 * Created 20.6.2022..
 */

@IsTest
private class BookingRestResourceTest {

    @TestSetup
    static void dataSetup() {

        Id pbid = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(Id = pbid);
        pb.IsActive = true;
        update pb;

        List<Account> accounts = TestDataFactory.createPersonAccounts(1, true);
        accounts[0].PersonEmail = 'emai@example.com';
        accounts[0].Store_password__c = 'pass';
        update accounts[0];

        WorkTypeGroup wtg1 = new WorkTypeGroup(Name = 'WTG 1', Heydoc_Id__c = 'mock_hd_wtg_id', Service_Type__c = 'Medical', IsActive=true);
        insert wtg1;

        WorkType wt1 = new WorkType(Name = 'WT for ' + wtg1.Name, EstimatedDuration = 40);
        insert wt1;

        WorkTypeGroupMember wtgm1 = new WorkTypeGroupMember();
        wtgm1 = new WorkTypeGroupMember(WorkTypeGroupId = wtg1.Id, WorkTypeId = wt1.Id);
        insert wtgm1;

        Product2 product = new Product2(Name = 'GP 1', Work_Type_Group__c = wtg1.Id, IsActive = true, Available_in_Stores__c = 'Appointments', Include_in_Store__c = true, Appointment__c = true);

        insert product;

        insert new PricebookEntry(Pricebook2Id = pb.Id, Product2Id = product.Id, IsActive = true, UnitPrice = 10);

        OperatingHours oh1 = new OperatingHours();
        oh1.Name = 'test Opening Hours';
        insert oh1;

        ServiceTerritory st1 = new ServiceTerritory();
        st1.Name = 'unit test location';
        st1.Heydoc_Id__c = 'test_st_hd_id';
        st1.IsActive = true;
        st1.OperatingHoursId = oh1.Id;
        insert st1;

        Asset asset1 = new Asset(Name = 'A1');
        insert asset1;

        ServiceResource sr1 = new ServiceResource();
        sr1.Name = 'SR1';
        sr1.IsActive = true;
        sr1.ResourceType = 'S';
        sr1.AssetId = asset1.Id;
        sr1.Heydoc_Id__c = 'mock_hd_sr_id';
        insert sr1;

        ServiceTerritoryWorkType stwt = new ServiceTerritoryWorkType(ServiceTerritoryId = st1.Id, WorkTypeId = wt1.Id);
        insert stwt;


    }

    @IsTest
    static void testGetServiceCentersForProduct() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'GET';
        req.requestURI = '/m/book/locations/product/' + [SELECT Id FROM Product2 LIMIT 1].Id;
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        BookingRestResource.getRecord();
        Test.stopTest();

        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void testGetTimeslots_fail() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'GET';
        req.requestURI = '/m/book/timeslots/';
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        BookingRestResource.getRecord();
        Test.stopTest();

        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void testGetTimeslots_ok() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String wtgid = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        String stid = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        String dt ='2022-05-01';

        req.httpMethod = 'GET';
        req.requestURI = '/m/book/timeslots';
        req.params.put('wtgid', wtgid);
        req.params.put('stid', stid);
        req.params.put('date', dt);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        BookingRestResource.getRecord();
        Test.stopTest();

        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void testGetResources_ok() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String wtgid = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;

        req.httpMethod = 'GET';
        req.requestURI = '/m/book/resources';
        req.params.put('wtgid', wtgid);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        BookingRestResource.getRecord();
        Test.stopTest();

        System.debug(res.responseBody.toString());
    }


    @IsTest
    static void testGetTimeslotsByProduct_ok() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String productid = [SELECT Id FROM Product2 LIMIT 1].Id;
        String stid = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        String dt ='2022-05-01';

        req.httpMethod = 'GET';
        req.requestURI = '/m/book/timeslots';
        req.params.put('productid', productid);
        req.params.put('stid', stid);
        req.params.put('date', dt);
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        BookingRestResource.getRecord();
        Test.stopTest();

        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void testGetQuote_fail() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'GET';
        req.requestURI = '/m/book/quote';
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        BookingRestResource.getRecord();
        Test.stopTest();

        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void testGetQuote_ok() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'GET';
        req.requestURI = '/m/book/quote';
        req.params.put('quoteid', '1');
        req.params.put('appid', '1');
        RestContext.request = req;
        RestContext.response= res;

        Test.startTest();
        BookingRestResource.getRecord();
        Test.stopTest();

        System.debug(res.responseBody.toString());
    }

    @IsTest
    static void testPost() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        OnlBookUI.BookRequest bookRequest = new OnlBookUI.BookRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(bookRequest));

        RestContext.request = req;
        RestContext.response= res;

        req.httpMethod = 'POST';
        req.requestURI = '/m/book';

        Test.startTest();
        BookingRestResource.doPost();
        Test.stopTest();

        System.debug(res.responseBody.toString());

    }
}